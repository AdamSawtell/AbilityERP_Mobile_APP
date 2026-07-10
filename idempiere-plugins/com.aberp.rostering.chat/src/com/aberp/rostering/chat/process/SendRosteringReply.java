package com.aberp.rostering.chat.process;

import java.sql.Timestamp;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MRequestUpdate;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;

/**
 * Send a rostering officer reply using the Last Result field on the request header.
 * Inserts R_RequestUpdate, assigns back to the worker, and clears the role queue.
 */
public class SendRosteringReply extends SvrProcess {
	@Override
	protected void prepare() {
		// Reply text comes from LastResult on the selected R_Request record.
	}

	@Override
	protected String doIt() throws Exception {
		if (getTable_ID() != MTable.getTable_ID(MRequest.Table_Name)) {
			throw new AdempiereException("Run Send to Worker from a Rostering Chat request");
		}

		final int requestId = getRecord_ID();
		if (requestId <= 0) {
			throw new AdempiereException("Select a chat thread first");
		}

		final MRequest request = new MRequest(getCtx(), requestId, get_TrxName());
		if (request.get_ID() <= 0) {
			throw new AdempiereException("Request not found");
		}

		if (getInt(request.get_Value("AbERP_Rostered_Shift_ID")) > 0) {
			throw new AdempiereException("This window is for standalone mobile chat only");
		}

		assertRosteringChatType(request);

		final String trimmed = request.getLastResult() == null ? "" : request.getLastResult().trim();
		if (trimmed.isEmpty()) {
			throw new AdempiereException("Enter your reply in Last Result, then click Send to Worker");
		}
		if (trimmed.length() > 2000) {
			throw new AdempiereException("Last Result is too long (max 2000 characters)");
		}

		final int workerUserId = resolveWorkerUserId(request);
		if (workerUserId <= 0) {
			throw new AdempiereException("Could not resolve worker user for this chat thread");
		}

		final MRequestUpdate update = new MRequestUpdate(request);
		update.setResult(trimmed);
		if (!update.save()) {
			throw new AdempiereException("Failed to save reply");
		}

		request.setAD_User_ID(workerUserId);
		request.setAD_Role_ID(0);
		request.setLastResult(trimmed);
		request.setDateLastAction(new Timestamp(System.currentTimeMillis()));
		if (!request.save()) {
			throw new AdempiereException("Reply saved but failed to update request header");
		}

		final MUser worker = MUser.get(getCtx(), workerUserId);
		final String workerName = worker != null && worker.get_ID() > 0 ? worker.getName() : String.valueOf(workerUserId);
		addLog(update.get_ID(), null, null, "Reply sent to " + workerName);
		return "@OK@";
	}

	/** Worker who opened the mobile chat — AD_User on request, else user linked to C_BPartner. */
	private int resolveWorkerUserId(MRequest request) {
		if (request.getAD_User_ID() > 0) {
			return request.getAD_User_ID();
		}

		if (request.getC_BPartner_ID() > 0) {
			final int userId = DB.getSQLValueEx(get_TrxName(),
					"SELECT AD_User_ID FROM AD_User WHERE C_BPartner_ID=? AND IsActive='Y' ORDER BY AD_User_ID ASC",
					request.getC_BPartner_ID());
			if (userId > 0) {
				return userId;
			}
		}

		return DB.getSQLValueEx(get_TrxName(),
				"SELECT ru.CreatedBy FROM R_RequestUpdate ru "
						+ "WHERE ru.R_Request_ID=? AND ru.IsActive='Y' "
						+ "ORDER BY ru.Created ASC",
				request.get_ID());
	}

	private static void assertRosteringChatType(MRequest request) {
		final String typeName = DB.getSQLValueString(request.get_TrxName(),
				"SELECT Name FROM R_RequestType WHERE R_RequestType_ID=?",
				request.getR_RequestType_ID());
		if (!"Rostering Chat".equals(typeName)) {
			throw new AdempiereException("This process is for Rostering Chat threads only");
		}
	}

	private static int getInt(Object value) {
		if (value == null) {
			return 0;
		}
		if (value instanceof Number) {
			return ((Number) value).intValue();
		}
		try {
			return Integer.parseInt(String.valueOf(value));
		} catch (NumberFormatException ex) {
			return 0;
		}
	}
}
