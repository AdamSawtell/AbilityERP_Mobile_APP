package com.aberp.invoicecapture.process;

import java.io.File;
import java.io.InputStream;
import java.nio.file.Files;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MAttachment;
import org.compiere.model.MTable;
import org.compiere.model.PO;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;

import com.aberp.invoicecapture.service.InvoiceCaptureService;

/**
 * Upload a PDF onto the current Invoice Capture record as a standard AD attachment.
 */
public class UploadInvoicePdf extends SvrProcess {

	private String p_FilePath;
	private String p_FileName;

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			String name = para.getParameterName();
			if ("FileName".equals(name) || "FilePath".equals(name)) {
				if (para.getParameter() != null) {
					p_FilePath = para.getParameter().toString();
				}
				if (para.getInfo() != null && !para.getInfo().toString().trim().isEmpty()) {
					p_FileName = para.getInfo().toString().trim();
				}
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		final int tableId = MTable.getTable_ID(InvoiceCaptureService.TABLE_CAPTURE);
		if (getTable_ID() != tableId) {
			throw new AdempiereException("Run Upload Invoice PDF from an Invoice Capture record");
		}
		final int captureId = getRecord_ID();
		if (captureId <= 0) {
			throw new AdempiereException("Save the Invoice Capture record before uploading a PDF");
		}
		if (p_FilePath == null || p_FilePath.trim().isEmpty()) {
			throw new AdempiereException("Select a PDF file to upload");
		}

		File file = new File(p_FilePath);
		if (!file.isFile() || !file.canRead()) {
			throw new AdempiereException("Uploaded file is not readable on the server");
		}

		String fileName = p_FileName;
		if (fileName == null || fileName.trim().isEmpty()) {
			fileName = file.getName();
		}
		if (!fileName.toLowerCase().endsWith(".pdf") && !looksLikePdf(file)) {
			throw new AdempiereException("Please upload a PDF file");
		}
		if (!fileName.toLowerCase().endsWith(".pdf")) {
			fileName = fileName + ".pdf";
		}

		byte[] data = Files.readAllBytes(file.toPath());
		if (data.length == 0) {
			throw new AdempiereException("Uploaded PDF is empty");
		}

		MAttachment att = MAttachment.get(getCtx(), tableId, captureId);
		if (att == null) {
			att = new MAttachment(getCtx(), tableId, captureId, get_TrxName());
		} else {
			att.set_TrxName(get_TrxName());
		}
		att.addEntry(fileName, data);
		if (!att.save()) {
			throw new AdempiereException("Failed to save attachment");
		}

		PO capture = MTable.get(getCtx(), InvoiceCaptureService.TABLE_CAPTURE).getPO(captureId, get_TrxName());
		if (capture != null && capture.get_ID() > 0) {
			Object status = capture.get_Value("CaptureStatus");
			if (status == null || String.valueOf(status).trim().isEmpty()) {
				capture.set_ValueOfColumn("CaptureStatus", InvoiceCaptureService.ST_PENDING);
			}
			capture.set_ValueOfColumn("LastResult", "PDF uploaded: " + fileName);
			capture.saveEx();
		}

		return "PDF attached: " + fileName + " (" + data.length + " bytes). You can now run Process Selected Invoice.";
	}

	private static boolean looksLikePdf(File file) throws Exception {
		try (InputStream in = Files.newInputStream(file.toPath())) {
			byte[] head = in.readNBytes(4);
			return head.length == 4 && head[0] == '%' && head[1] == 'P' && head[2] == 'D' && head[3] == 'F';
		}
	}
}
