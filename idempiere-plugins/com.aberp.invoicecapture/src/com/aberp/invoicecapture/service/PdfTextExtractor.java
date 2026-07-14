package com.aberp.invoicecapture.service;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;

import org.compiere.util.CLogger;

/**
 * Same-box open-source text extraction: poppler pdftotext first, Tesseract OCR fallback.
 */
public class PdfTextExtractor {

	private static final CLogger log = CLogger.getCLogger(PdfTextExtractor.class);
	private static final int MIN_USEFUL_CHARS = 40;
	private static final long CMD_TIMEOUT_SEC = 120;

	public static class ExtractOutcome {
		public final String text;
		public final String method;
		public final String error;

		public ExtractOutcome(String text, String method, String error) {
			this.text = text == null ? "" : text;
			this.method = method;
			this.error = error;
		}

		public boolean hasUsefulText() {
			return text != null && text.replaceAll("\\s+", "").length() >= MIN_USEFUL_CHARS;
		}
	}

	public ExtractOutcome extract(File pdfFile) {
		if (pdfFile == null || !pdfFile.isFile()) {
			return new ExtractOutcome("", null, "PDF file not found");
		}

		ExtractOutcome digital = runPdftotext(pdfFile);
		if (digital.hasUsefulText()) {
			return digital;
		}

		ExtractOutcome ocr = runTesseract(pdfFile);
		if (ocr.hasUsefulText()) {
			return ocr;
		}

		String err = "PDF unreadable";
		if (digital.error != null) {
			err += " (pdftotext: " + digital.error + ")";
		}
		if (ocr.error != null) {
			err += " (tesseract: " + ocr.error + ")";
		}
		return new ExtractOutcome("", null, err);
	}

	private ExtractOutcome runPdftotext(File pdfFile) {
		try {
			ProcessBuilder pb = new ProcessBuilder("pdftotext", "-layout", "-enc", "UTF-8",
					pdfFile.getAbsolutePath(), "-");
			pb.redirectErrorStream(true);
			String out = runProcess(pb);
			return new ExtractOutcome(out, "pdftotext", null);
		} catch (Exception ex) {
			log.log(Level.WARNING, "pdftotext failed", ex);
			return new ExtractOutcome("", "pdftotext", ex.getMessage());
		}
	}

	private ExtractOutcome runTesseract(File pdfFile) {
		File workDir = null;
		try {
			workDir = Files.createTempDirectory("aberp-ic-ocr-").toFile();
			ProcessBuilder raster = new ProcessBuilder("pdftoppm", "-png", "-r", "200",
					pdfFile.getAbsolutePath(), new File(workDir, "page").getAbsolutePath());
			raster.redirectErrorStream(true);
			runProcess(raster);

			File[] pages = workDir.listFiles((dir, name) -> name.startsWith("page") && name.endsWith(".png"));
			if (pages == null || pages.length == 0) {
				return new ExtractOutcome("", "tesseract", "pdftoppm produced no page images");
			}
			List<File> sorted = new ArrayList<>();
			for (File p : pages) {
				sorted.add(p);
			}
			sorted.sort(Comparator.comparing(File::getName));

			StringBuilder sb = new StringBuilder();
			int limit = Math.min(sorted.size(), 5);
			for (int i = 0; i < limit; i++) {
				File page = sorted.get(i);
				File outBase = new File(workDir, "ocr-" + i);
				ProcessBuilder ocr = new ProcessBuilder("tesseract", page.getAbsolutePath(),
						outBase.getAbsolutePath(), "-l", "eng", "--psm", "6");
				ocr.redirectErrorStream(true);
				runProcess(ocr);
				File txt = new File(workDir, "ocr-" + i + ".txt");
				if (txt.isFile()) {
					sb.append(Files.readString(txt.toPath(), StandardCharsets.UTF_8)).append('\n');
				}
			}
			return new ExtractOutcome(sb.toString(), "tesseract", null);
		} catch (Exception ex) {
			log.log(Level.WARNING, "tesseract OCR failed", ex);
			return new ExtractOutcome("", "tesseract", ex.getMessage());
		} finally {
			cleanupDir(workDir);
		}
	}

	private String runProcess(ProcessBuilder pb) throws Exception {
		Process p = pb.start();
		StringBuilder out = new StringBuilder();
		try (BufferedReader br = new BufferedReader(
				new InputStreamReader(p.getInputStream(), StandardCharsets.UTF_8))) {
			String line;
			while ((line = br.readLine()) != null) {
				out.append(line).append('\n');
			}
		}
		boolean finished = p.waitFor(CMD_TIMEOUT_SEC, TimeUnit.SECONDS);
		if (!finished) {
			p.destroyForcibly();
			throw new IllegalStateException("Command timed out: " + pb.command());
		}
		if (p.exitValue() != 0 && out.length() == 0) {
			throw new IllegalStateException("Command failed (" + p.exitValue() + "): " + pb.command());
		}
		return out.toString();
	}

	private void cleanupDir(File dir) {
		if (dir == null || !dir.isDirectory()) {
			return;
		}
		File[] files = dir.listFiles();
		if (files != null) {
			for (File f : files) {
				if (!f.delete()) {
					f.deleteOnExit();
				}
			}
		}
		if (!dir.delete()) {
			dir.deleteOnExit();
		}
	}
}
