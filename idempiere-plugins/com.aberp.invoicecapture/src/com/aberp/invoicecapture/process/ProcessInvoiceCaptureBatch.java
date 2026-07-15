package com.aberp.invoicecapture.process;

import java.util.List;

import org.compiere.model.PO;
import org.compiere.model.Query;
import org.compiere.process.SvrProcess;
import org.compiere.util.Env;

import com.aberp.invoicecapture.service.InvoiceCaptureResult;
import com.aberp.invoicecapture.service.InvoiceCaptureService;

/**
 * Batch / scheduler entry point. Processes captures that have not been processed yet
 * ({@code Processed='N'}). Records already run manually or in a prior batch are skipped.
 */
public class ProcessInvoiceCaptureBatch extends SvrProcess {

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		final int clientId = Env.getAD_Client_ID(getCtx());
		// Only never-processed rows. Manual Process may still retry review/error statuses;
		// overnight batch must not re-drive records that already finished once.
		final String where = "AD_Client_ID=? AND IsActive='Y' AND Processed='N' AND CaptureStatus IN ("
				+ InvoiceCaptureService.ELIGIBLE_STATUS_SQL_IN + ")";

		List<PO> rows = new Query(getCtx(), InvoiceCaptureService.TABLE_CAPTURE, where, get_TrxName())
				.setParameters(Integer.valueOf(clientId))
				.setOrderBy("AbERP_InvoiceCapture_ID")
				.list();

		if (rows.isEmpty()) {
			return "No unprocessed Invoice Capture records to process";
		}

		InvoiceCaptureService service = new InvoiceCaptureService(getCtx(), get_TrxName(), this);
		int ok = 0;
		int fail = 0;
		for (PO row : rows) {
			try {
				InvoiceCaptureResult r = service.processOne(row.get_ID(), "Batch");
				addLog(0, null, null, "Capture " + row.get_ID() + ": " + r.getUserMessage());
				if (r.isSuccessPath()) {
					ok++;
				} else {
					fail++;
				}
			} catch (Exception ex) {
				fail++;
				addLog(0, null, null, "Capture " + row.get_ID() + ": Processing error — " + ex.getMessage());
			}
		}
		return "Batch complete: " + rows.size() + " record(s), " + ok + " actionable success, "
				+ fail + " needs attention / errors";
	}
}
