package com.aberp.invoicecapture.process;

import java.util.List;

import org.compiere.model.PO;
import org.compiere.model.Query;
import org.compiere.process.SvrProcess;
import org.compiere.util.Env;

import com.aberp.invoicecapture.service.InvoiceCaptureResult;
import com.aberp.invoicecapture.service.InvoiceCaptureService;

/**
 * Batch / scheduler entry point. Processes all eligible pending captures via the shared service.
 */
public class ProcessInvoiceCaptureBatch extends SvrProcess {

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		final int clientId = Env.getAD_Client_ID(getCtx());
		final String where = "AD_Client_ID=? AND IsActive='Y' AND CaptureStatus IN ("
				+ InvoiceCaptureService.ELIGIBLE_STATUS_SQL_IN + ")";

		List<PO> rows = new Query(getCtx(), InvoiceCaptureService.TABLE_CAPTURE, where, get_TrxName())
				.setParameters(Integer.valueOf(clientId))
				.setOrderBy("AbERP_InvoiceCapture_ID")
				.list();

		if (rows.isEmpty()) {
			return "No eligible Invoice Capture records to process";
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
