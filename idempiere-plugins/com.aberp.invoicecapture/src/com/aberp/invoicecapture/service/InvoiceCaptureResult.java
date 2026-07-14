package com.aberp.invoicecapture.service;

/**
 * Outcome of a single capture processing attempt (manual or batch).
 */
public class InvoiceCaptureResult {

	public enum Code {
		DRAFT_CREATED,
		VENDOR_NOT_MATCHED,
		POSSIBLE_DUPLICATE,
		VALIDATION_FAILED,
		PDF_UNREADABLE,
		PROCESSING_ERROR,
		ALREADY_PROCESSED,
		REQUIRES_REVIEW
	}

	private final Code code;
	private final String userMessage;
	private final int invoiceId;
	private final String status;

	public InvoiceCaptureResult(Code code, String userMessage, int invoiceId, String status) {
		this.code = code;
		this.userMessage = userMessage;
		this.invoiceId = invoiceId;
		this.status = status;
	}

	public Code getCode() {
		return code;
	}

	public String getUserMessage() {
		return userMessage;
	}

	public int getInvoiceId() {
		return invoiceId;
	}

	public String getStatus() {
		return status;
	}

	/** True when a draft invoice was created (or already linked successfully). */
	public boolean isSuccessPath() {
		return code == Code.DRAFT_CREATED || code == Code.ALREADY_PROCESSED;
	}
}
