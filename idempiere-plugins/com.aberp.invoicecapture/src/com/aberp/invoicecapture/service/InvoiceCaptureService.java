package com.aberp.invoicecapture.service;

import java.io.File;
import java.io.FileOutputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Properties;
import java.util.UUID;
import java.util.logging.Level;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.compiere.model.MAttachment;
import org.compiere.model.MAttachmentEntry;
import org.compiere.model.MInvoice;
import org.compiere.model.MInvoiceLine;
import org.compiere.model.MTable;
import org.compiere.model.PO;
import org.compiere.process.SvrProcess;
import org.compiere.util.CLogger;
import org.compiere.util.DB;
import org.compiere.util.Env;

/**
 * Shared Invoice Capture pipeline for manual (single-record) and batch processing.
 * Do not duplicate OCR / invoice-create logic outside this class.
 */
public class InvoiceCaptureService {

	public static final String TABLE_CAPTURE = "AbERP_InvoiceCapture";
	public static final String TABLE_LOG = "AbERP_InvoiceCaptureLog";

	public static final String ST_PENDING = "PE";
	public static final String ST_PROCESSING = "PR";
	public static final String ST_REQUIRES_REVIEW = "RR";
	public static final String ST_VENDOR_NOT_MATCHED = "VN";
	public static final String ST_VALIDATION_FAILED = "VF";
	public static final String ST_PROCESSING_ERROR = "ER";
	public static final String ST_SUCCESS = "OK";
	public static final String ST_POSSIBLE_DUPLICATE = "DU";
	public static final String ST_PDF_UNREADABLE = "PU";

	/** Statuses eligible for (re)processing. */
	public static final String ELIGIBLE_STATUS_SQL_IN = "'PE','RR','VN','VF','ER','DU','PU'";

	private static final CLogger log = CLogger.getCLogger(InvoiceCaptureService.class);

	// Require word boundary — bare "inv" must not match inside "INVOICE" (was capturing "OICE")
	private static final Pattern INV_NO = Pattern.compile(
			"(?i)\\binvoice\\s*(?:no\\.?|number|#)\\s*[:#]?\\s*([A-Z0-9][A-Z0-9\\-/]{2,})");
	private static final Pattern ABN = Pattern.compile("(?i)\\bABN\\s*[:#]?\\s*([0-9][0-9\\s]{8,14}\\d)");
	private static final Pattern TOTAL = Pattern.compile(
			"(?i)(?:amount\\s*due|balance\\s*due|total\\s*(?:due|amount)?|grand\\s*total|invoice\\s*total)\\s*[:]?\\s*\\$?\\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\\.[0-9]{2})|[0-9]+\\.[0-9]{2})");
	private static final Pattern DATE = Pattern.compile(
			"(?i)(?:invoice\\s*date|date\\s*of\\s*invoice|dated?)\\s*[:]?\\s*(\\d{1,2}[\\-/]\\d{1,2}[\\-/]\\d{2,4}|\\d{4}[\\-/]\\d{1,2}[\\-/]\\d{1,2})");

	private final Properties ctx;
	private final String trxName;
	private final SvrProcess process;

	public InvoiceCaptureService(Properties ctx, String trxName, SvrProcess process) {
		this.ctx = ctx;
		this.trxName = trxName;
		this.process = process;
	}

	public InvoiceCaptureResult processOne(int captureId, String trigger) {
		PO capture = MTable.get(ctx, TABLE_CAPTURE).getPO(captureId, trxName);
		if (capture == null || capture.get_ID() <= 0) {
			return fail(null, InvoiceCaptureResult.Code.PROCESSING_ERROR, ST_PROCESSING_ERROR,
					"Processing error: capture record not found", trigger, 0);
		}

		String status = str(capture.get_Value("CaptureStatus"));
		int existingInvoiceId = intVal(capture.get_Value("C_Invoice_ID"));
		if (ST_SUCCESS.equals(status) && existingInvoiceId > 0) {
			String msg = "Already processed — Draft Vendor Invoice linked (C_Invoice_ID=" + existingInvoiceId
					+ "). Duplicate Vendor Invoice creation prevented.";
			appendLog(capture, InvoiceCaptureResult.Code.ALREADY_PROCESSED.name(), msg, existingInvoiceId, trigger);
			capture.set_ValueOfColumn("LastResult", msg);
			capture.saveEx();
			return new InvoiceCaptureResult(InvoiceCaptureResult.Code.ALREADY_PROCESSED, msg, existingInvoiceId,
					ST_SUCCESS);
		}

		if (!isEligible(status)) {
			String msg = "Validation failed: status '" + statusLabel(status)
					+ "' is not eligible for processing";
			return fail(capture, InvoiceCaptureResult.Code.VALIDATION_FAILED, ST_VALIDATION_FAILED, msg, trigger, 0);
		}

		File pdfFile = null;
		boolean tempFile = false;
		try {
			capture.set_ValueOfColumn("CaptureStatus", ST_PROCESSING);
			capture.set_ValueOfColumn("LastResult", "Processing…");
			capture.saveEx();

			ResolvedPdf pdf = resolvePdf(capture);
			if (pdf == null) {
				return fail(capture, InvoiceCaptureResult.Code.PDF_UNREADABLE, ST_PDF_UNREADABLE,
						"PDF unreadable: attach a PDF or set a valid server File Path", trigger, 0);
			}
			pdfFile = pdf.file;
			tempFile = pdf.temporary;

			PdfTextExtractor.ExtractOutcome extracted = new PdfTextExtractor().extract(pdfFile);
			if (!extracted.hasUsefulText()) {
				return fail(capture, InvoiceCaptureResult.Code.PDF_UNREADABLE, ST_PDF_UNREADABLE,
						"PDF unreadable: " + nvl(extracted.error, "no text extracted"), trigger, 0);
			}

			ParsedFields fields = parseFields(extracted.text);
			capture.set_ValueOfColumn("ExtractedText", truncate(extracted.text, 4000));
			if (fields.invoiceNo != null) {
				capture.set_ValueOfColumn("VendorInvoiceNo", fields.invoiceNo);
			}
			if (fields.invoiceDate != null) {
				capture.set_ValueOfColumn("InvoiceDate", fields.invoiceDate);
			}
			if (fields.grandTotal != null) {
				capture.set_ValueOfColumn("GrandTotal", fields.grandTotal);
			}
			if (fields.abn != null) {
				capture.set_ValueOfColumn("TaxID", fields.abn);
			}
			if (fields.vendorHint != null && empty(str(capture.get_Value("Name")))) {
				capture.set_ValueOfColumn("Name", truncate(fields.vendorHint, 120));
			}
			capture.saveEx();

			if (empty(fields.invoiceNo) || fields.grandTotal == null || fields.grandTotal.signum() <= 0) {
				String msg = "Validation failed: could not extract invoice number and/or total amount from PDF"
						+ " (method=" + extracted.method + ")";
				return fail(capture, InvoiceCaptureResult.Code.VALIDATION_FAILED, ST_VALIDATION_FAILED, msg, trigger, 0);
			}

			int bpartnerId = intVal(capture.get_Value("C_BPartner_ID"));
			if (bpartnerId <= 0) {
				bpartnerId = matchVendor(capture.getAD_Client_ID(), fields);
			}
			if (bpartnerId <= 0) {
				capture.set_ValueOfColumn("CaptureStatus", ST_VENDOR_NOT_MATCHED);
				String msg = "Vendor not matched — review Tax ID / vendor name and set Business Partner, then process again";
				finish(capture, msg, trigger, InvoiceCaptureResult.Code.VENDOR_NOT_MATCHED, 0);
				return new InvoiceCaptureResult(InvoiceCaptureResult.Code.VENDOR_NOT_MATCHED, msg, 0,
						ST_VENDOR_NOT_MATCHED);
			}
			capture.set_ValueOfColumn("C_BPartner_ID", Integer.valueOf(bpartnerId));
			capture.saveEx();

			int dupInvoiceId = findDuplicateInvoice(capture.getAD_Client_ID(), bpartnerId, fields.invoiceNo,
					fields.grandTotal);
			if (dupInvoiceId > 0) {
				capture.set_ValueOfColumn("CaptureStatus", ST_POSSIBLE_DUPLICATE);
				capture.set_ValueOfColumn("C_Invoice_ID", Integer.valueOf(dupInvoiceId));
				String msg = "Possible duplicate — existing Vendor Invoice C_Invoice_ID=" + dupInvoiceId
						+ " (same vendor + invoice no). No new Draft created.";
				finish(capture, msg, trigger, InvoiceCaptureResult.Code.POSSIBLE_DUPLICATE, dupInvoiceId);
				return new InvoiceCaptureResult(InvoiceCaptureResult.Code.POSSIBLE_DUPLICATE, msg, dupInvoiceId,
						ST_POSSIBLE_DUPLICATE);
			}

			int chargeId = resolveChargeId(capture.getAD_Client_ID());
			if (chargeId <= 0) {
				return fail(capture, InvoiceCaptureResult.Code.VALIDATION_FAILED, ST_VALIDATION_FAILED,
						"Validation failed: no Charge available for Draft invoice line "
								+ "(create a Charge named 'Invoice Capture' or any active Charge)",
						trigger, 0);
			}

			int docTypeId = resolveApDocTypeId(capture.getAD_Client_ID());
			if (docTypeId <= 0) {
				return fail(capture, InvoiceCaptureResult.Code.VALIDATION_FAILED, ST_VALIDATION_FAILED,
						"Validation failed: AP Invoice document type not found", trigger, 0);
			}

			MInvoice invoice = createDraftVendorInvoice(capture, bpartnerId, docTypeId, chargeId, fields, pdf);
			int invoiceId = invoice.getC_Invoice_ID();

			capture.set_ValueOfColumn("C_Invoice_ID", Integer.valueOf(invoiceId));
			capture.set_ValueOfColumn("CaptureStatus", ST_SUCCESS);
			String msg = "Draft Vendor Invoice created (C_Invoice_ID=" + invoiceId
					+ ", DocNo/PORef=" + fields.invoiceNo + "). Left in Draft for review.";
			finish(capture, msg, trigger, InvoiceCaptureResult.Code.DRAFT_CREATED, invoiceId);
			return new InvoiceCaptureResult(InvoiceCaptureResult.Code.DRAFT_CREATED, msg, invoiceId, ST_SUCCESS);

		} catch (Exception ex) {
			log.log(Level.SEVERE, "Invoice capture failed id=" + captureId, ex);
			return fail(capture, InvoiceCaptureResult.Code.PROCESSING_ERROR, ST_PROCESSING_ERROR,
					"Processing error: " + ex.getMessage(), trigger, 0);
		} finally {
			if (tempFile && pdfFile != null && pdfFile.isFile()) {
				if (!pdfFile.delete()) {
					pdfFile.deleteOnExit();
				}
			}
		}
	}

	private boolean isEligible(String status) {
		if (status == null || status.isEmpty()) {
			return true;
		}
		return ST_PENDING.equals(status) || ST_REQUIRES_REVIEW.equals(status)
				|| ST_VENDOR_NOT_MATCHED.equals(status) || ST_VALIDATION_FAILED.equals(status)
				|| ST_PROCESSING_ERROR.equals(status) || ST_POSSIBLE_DUPLICATE.equals(status)
				|| ST_PDF_UNREADABLE.equals(status);
	}

	private ResolvedPdf resolvePdf(PO capture) throws Exception {
		String path = str(capture.get_Value("FilePath"));
		if (!empty(path)) {
			File f = new File(path);
			if (f.isFile() && f.canRead()) {
				return new ResolvedPdf(f, false, f.getName());
			}
		}

		MAttachment att = MAttachment.get(ctx, capture.get_Table_ID(), capture.get_ID());
		if (att != null && att.getEntryCount() > 0) {
			for (int i = 0; i < att.getEntryCount(); i++) {
				MAttachmentEntry entry = att.getEntry(i);
				if (entry == null) {
					continue;
				}
				String name = entry.getName() == null ? "" : entry.getName().toLowerCase();
				byte[] data = entry.getData();
				if (data == null || data.length == 0) {
					continue;
				}
				if (name.endsWith(".pdf") || looksLikePdf(data)) {
					File tmp = File.createTempFile("aberp-ic-", ".pdf");
					try (FileOutputStream fos = new FileOutputStream(tmp)) {
						fos.write(data);
					}
					String fileName = entry.getName() != null ? entry.getName() : tmp.getName();
					return new ResolvedPdf(tmp, true, fileName);
				}
			}
		}
		return null;
	}

	private static boolean looksLikePdf(byte[] data) {
		return data.length > 4 && data[0] == '%' && data[1] == 'P' && data[2] == 'D' && data[3] == 'F';
	}

	private ParsedFields parseFields(String text) {
		ParsedFields f = new ParsedFields();
		Matcher m = INV_NO.matcher(text);
		if (m.find()) {
			f.invoiceNo = m.group(1).trim();
		}
		m = ABN.matcher(text);
		if (m.find()) {
			f.abn = m.group(1).replaceAll("\\s+", "");
		}
		m = TOTAL.matcher(text);
		if (m.find()) {
			try {
				f.grandTotal = new BigDecimal(m.group(1).replace(",", ""));
			} catch (Exception ignore) {
				// leave null
			}
		}
		m = DATE.matcher(text);
		if (m.find()) {
			f.invoiceDate = parseDate(m.group(1));
		}
		if (f.invoiceDate == null) {
			f.invoiceDate = new Timestamp(System.currentTimeMillis());
		}
		f.vendorHint = firstMeaningfulLine(text);
		return f;
	}

	private String firstMeaningfulLine(String text) {
		if (text == null) {
			return null;
		}
		for (String line : text.split("\\R")) {
			String t = line.trim();
			if (t.length() >= 3 && t.length() <= 80 && !t.toLowerCase().contains("invoice")
					&& !t.toLowerCase().contains("tax invoice") && !t.matches("(?i)^page\\s*\\d.*")) {
				return t;
			}
		}
		return null;
	}

	private Timestamp parseDate(String raw) {
		String[] patterns = { "dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "yyyy-MM-dd", "dd/MM/yy", "d/M/yy" };
		for (String p : patterns) {
			try {
				return new Timestamp(new SimpleDateFormat(p).parse(raw.trim()).getTime());
			} catch (Exception ignore) {
				// try next
			}
		}
		return null;
	}

	private int matchVendor(int clientId, ParsedFields fields) {
		if (!empty(fields.abn)) {
			Integer id = DB.getSQLValue(trxName,
					"SELECT C_BPartner_ID FROM C_BPartner WHERE AD_Client_ID=? AND IsVendor='Y' AND IsActive='Y' "
							+ "AND regexp_replace(COALESCE(TaxID,''), '[^0-9]', '', 'g') = ? ORDER BY C_BPartner_ID FETCH FIRST 1 ROW ONLY",
					clientId, fields.abn.replaceAll("[^0-9]", ""));
			if (id != null && id > 0) {
				return id;
			}
		}
		if (!empty(fields.vendorHint)) {
			Integer id = DB.getSQLValue(trxName,
					"SELECT C_BPartner_ID FROM C_BPartner WHERE AD_Client_ID=? AND IsVendor='Y' AND IsActive='Y' "
							+ "AND UPPER(Name) = UPPER(?) ORDER BY C_BPartner_ID FETCH FIRST 1 ROW ONLY",
					clientId, fields.vendorHint);
			if (id != null && id > 0) {
				return id;
			}
			id = DB.getSQLValue(trxName,
					"SELECT C_BPartner_ID FROM C_BPartner WHERE AD_Client_ID=? AND IsVendor='Y' AND IsActive='Y' "
							+ "AND UPPER(Name) LIKE UPPER(?) ORDER BY LENGTH(Name), C_BPartner_ID FETCH FIRST 1 ROW ONLY",
					clientId, "%" + fields.vendorHint + "%");
			if (id != null && id > 0) {
				return id;
			}
		}
		return 0;
	}

	private int findDuplicateInvoice(int clientId, int bpartnerId, String vendorInvNo, BigDecimal amount) {
		String sql = "SELECT C_Invoice_ID FROM C_Invoice WHERE AD_Client_ID=? AND C_BPartner_ID=? AND IsSOTrx='N' "
				+ "AND IsActive='Y' AND (DocumentNo=? OR POReference=?) "
				+ "ORDER BY C_Invoice_ID DESC FETCH FIRST 1 ROW ONLY";
		Integer id = DB.getSQLValue(trxName, sql, clientId, bpartnerId, vendorInvNo, vendorInvNo);
		return id == null ? 0 : id.intValue();
	}

	private int resolveApDocTypeId(int clientId) {
		Integer id = DB.getSQLValue(trxName,
				"SELECT C_DocType_ID FROM C_DocType WHERE AD_Client_ID=? AND DocBaseType='API' AND IsActive='Y' "
						+ "AND IsSOTrx='N' ORDER BY IsDefault DESC, C_DocType_ID FETCH FIRST 1 ROW ONLY",
				clientId);
		return id == null ? 0 : id.intValue();
	}

	private int resolveChargeId(int clientId) {
		Integer id = DB.getSQLValue(trxName,
				"SELECT C_Charge_ID FROM C_Charge WHERE AD_Client_ID=? AND IsActive='Y' AND UPPER(Name)=UPPER('Invoice Capture') "
						+ "ORDER BY C_Charge_ID FETCH FIRST 1 ROW ONLY",
				clientId);
		if (id != null && id > 0) {
			return id;
		}
		id = DB.getSQLValue(trxName,
				"SELECT C_Charge_ID FROM C_Charge WHERE AD_Client_ID=? AND IsActive='Y' "
						+ "ORDER BY C_Charge_ID FETCH FIRST 1 ROW ONLY",
				clientId);
		return id == null ? 0 : id.intValue();
	}

	private MInvoice createDraftVendorInvoice(PO capture, int bpartnerId, int docTypeId, int chargeId,
			ParsedFields fields, ResolvedPdf pdf) throws Exception {
		MInvoice inv = new MInvoice(ctx, 0, trxName);
		inv.setAD_Org_ID(capture.getAD_Org_ID());
		inv.setC_BPartner_ID(bpartnerId);
		inv.setIsSOTrx(false);
		inv.setC_DocTypeTarget_ID(docTypeId);
		inv.setC_DocType_ID(docTypeId);
		inv.setDateInvoiced(fields.invoiceDate);
		inv.setDateAcct(fields.invoiceDate);
		inv.setPOReference(truncate(fields.invoiceNo, 60));
		inv.setDescription(truncate("Invoice Capture #" + capture.get_ID()
				+ (empty(fields.vendorHint) ? "" : " — " + fields.vendorHint), 255));
		inv.setDocStatus(MInvoice.DOCSTATUS_Drafted);
		inv.setDocAction(MInvoice.DOCACTION_Complete);
		inv.setProcessed(false);
		int currencyId = Env.getContextAsInt(ctx, "$C_Currency_ID");
		if (currencyId <= 0) {
			Integer cid = DB.getSQLValue(trxName,
					"SELECT C_Currency_ID FROM C_AcctSchema WHERE AD_Client_ID=? AND IsActive='Y' ORDER BY C_AcctSchema_ID FETCH FIRST 1 ROW ONLY",
					capture.getAD_Client_ID());
			currencyId = cid == null ? 0 : cid.intValue();
		}
		if (currencyId > 0) {
			inv.setC_Currency_ID(currencyId);
		}
		inv.saveEx();

		MInvoiceLine line = new MInvoiceLine(inv);
		line.setC_Charge_ID(chargeId);
		line.setQty(Env.ONE);
		line.setPrice(fields.grandTotal);
		line.setDescription(truncate("Captured total from PDF (" + fields.invoiceNo + ")", 255));
		line.saveEx();

		byte[] bytes = Files.readAllBytes(pdf.file.toPath());
		MAttachment att = inv.createAttachment();
		att.addEntry(pdf.fileName, bytes);
		att.saveEx();

		return inv;
	}

	private InvoiceCaptureResult fail(PO capture, InvoiceCaptureResult.Code code, String status, String msg,
			String trigger, int invoiceId) {
		if (capture != null) {
			try {
				capture.set_ValueOfColumn("CaptureStatus", status);
				finish(capture, msg, trigger, code, invoiceId);
			} catch (Exception ex) {
				log.log(Level.WARNING, "Could not persist failure state", ex);
			}
		}
		return new InvoiceCaptureResult(code, msg, invoiceId, status);
	}

	private void finish(PO capture, String msg, String trigger, InvoiceCaptureResult.Code code, int invoiceId) {
		capture.set_ValueOfColumn("LastResult", truncate(msg, 255));
		capture.set_ValueOfColumn("Processed", "Y");
		capture.saveEx();
		appendLog(capture, code.name(), msg, invoiceId, trigger);
	}

	private void appendLog(PO capture, String resultCode, String message, int invoiceId, String trigger) {
		try {
			PO logPo = MTable.get(ctx, TABLE_LOG).getPO(0, trxName);
			logPo.set_ValueOfColumn("AD_Client_ID", Integer.valueOf(capture.getAD_Client_ID()));
			logPo.setAD_Org_ID(capture.getAD_Org_ID());
			logPo.set_ValueOfColumn("AbERP_InvoiceCapture_ID", Integer.valueOf(capture.get_ID()));
			logPo.set_ValueOfColumn("AbERP_InvoiceCaptureLog_UU", UUID.randomUUID().toString());
			logPo.set_ValueOfColumn("ProcessedAt", new Timestamp(System.currentTimeMillis()));
			logPo.set_ValueOfColumn("ResultCode", truncate(resultCode, 40));
			logPo.set_ValueOfColumn("Message", truncate(message, 2000));
			logPo.set_ValueOfColumn("TriggerType", truncate(trigger, 20));
			if (invoiceId > 0) {
				logPo.set_ValueOfColumn("C_Invoice_ID", Integer.valueOf(invoiceId));
			}
			logPo.set_ValueOfColumn("IsActive", "Y");
			logPo.saveEx();
		} catch (Exception ex) {
			log.log(Level.WARNING, "Failed to append capture log", ex);
			if (process != null) {
				process.addLog(0, null, null, "Warning: could not write processing log — " + ex.getMessage());
			}
		}
	}

	private static String statusLabel(String status) {
		if (status == null) {
			return "null";
		}
		switch (status) {
		case ST_PENDING:
			return "Pending";
		case ST_PROCESSING:
			return "Processing";
		case ST_REQUIRES_REVIEW:
			return "Requires Review";
		case ST_VENDOR_NOT_MATCHED:
			return "Vendor Not Matched";
		case ST_VALIDATION_FAILED:
			return "Validation Failed";
		case ST_PROCESSING_ERROR:
			return "Processing Error";
		case ST_SUCCESS:
			return "Successfully Processed";
		case ST_POSSIBLE_DUPLICATE:
			return "Possible Duplicate";
		case ST_PDF_UNREADABLE:
			return "PDF Unreadable";
		default:
			return status;
		}
	}

	private static String str(Object v) {
		return v == null ? null : String.valueOf(v).trim();
	}

	private static boolean empty(String s) {
		return s == null || s.isEmpty();
	}

	private static String nvl(String a, String b) {
		return empty(a) ? b : a;
	}

	private static int intVal(Object v) {
		if (v == null) {
			return 0;
		}
		if (v instanceof Number) {
			return ((Number) v).intValue();
		}
		try {
			return Integer.parseInt(String.valueOf(v));
		} catch (Exception e) {
			return 0;
		}
	}

	private static String truncate(String s, int max) {
		if (s == null) {
			return null;
		}
		return s.length() <= max ? s : s.substring(0, max);
	}

	private static class ResolvedPdf {
		final File file;
		final boolean temporary;
		final String fileName;

		ResolvedPdf(File file, boolean temporary, String fileName) {
			this.file = file;
			this.temporary = temporary;
			this.fileName = fileName;
		}
	}

	private static class ParsedFields {
		String invoiceNo;
		String abn;
		BigDecimal grandTotal;
		Timestamp invoiceDate;
		String vendorHint;
	}
}
