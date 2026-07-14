package com.aberp.invoicecapture.process;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MTable;
import org.compiere.process.SvrProcess;

import com.aberp.invoicecapture.service.InvoiceCaptureResult;
import com.aberp.invoicecapture.service.InvoiceCaptureService;

/**
 * Manual single-record process for the Invoice Capture window.
 * Delegates entirely to {@link InvoiceCaptureService} (same path as nightly batch).
 */
public class ProcessSelectedInvoice extends SvrProcess {

	public static final String TABLE_NAME = InvoiceCaptureService.TABLE_CAPTURE;

	@Override
	protected void prepare() {
		// no parameters — operates on current record
	}

	@Override
	protected String doIt() throws Exception {
		final int tableId = MTable.getTable_ID(TABLE_NAME);
		if (getTable_ID() != tableId) {
			throw new AdempiereException("Run Process Selected Invoice from an Invoice Capture record");
		}
		final int captureId = getRecord_ID();
		if (captureId <= 0) {
			throw new AdempiereException("Save the Invoice Capture record before processing");
		}

		InvoiceCaptureResult result = new InvoiceCaptureService(getCtx(), get_TrxName(), this)
				.processOne(captureId, "Manual");
		addLog(0, null, null, result.getUserMessage());
		if (result.getInvoiceId() > 0) {
			addLog(result.getInvoiceId(), null, null, "Draft Vendor Invoice ID=" + result.getInvoiceId());
		}
		return result.getUserMessage();
	}
}
