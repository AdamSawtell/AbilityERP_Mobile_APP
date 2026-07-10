package com.aberp.rostering.chat.process;

import java.sql.Timestamp;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MRequestUpdate;
import org.compiere.model.MTable;
import org.compiere.util.DB;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;

/**
 * Send a rostering officer reply on a mobile worker chat thread.
 * Inserts R_RequestUpdate and updates the request header (same path as the mobile API).
 */
public class SendRosteringReply extends SvrProcess {
	private String message;

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			if ("Message".equals(para.getParameterName()) && para.getParameter() != null) {
				message = para.getParameter().toString();
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		if (getTable_ID() != MTable.getTable_ID(MRequest.Table_Name)) {
			throw new AdempiereException("Run Send Reply from a Rostering Chat request");
		}

		final int requestId = getRecord_ID();
		if (requestId <= 0) {
			throw new AdempiereException("Select a chat thread first");
		}

		final String trimmed = message == null ? "" : message.trim();
		if (trimmed.isEmpty()) {
			throw new AdempiereException("Message cannot be empty");
		}
		if (trimmed.length() > 2000) {
			throw new AdempiereException("Message is too long (max 2000 characters)");
		}

		final MRequest request = new MRequest(getCtx(), requestId, get_TrxName());
		if (request.get_ID() <= 0) {
			throw new AdempiereException("Request not found");
		}

		if (getInt(request.get_Value("AbERP_Rostered_Shift_ID")) > 0) {
			throw new AdempiereException("This window is for standalone mobile chat only");
		}

		assertRosteringChatType(request);

		final int workerUserId = request.getAD_User_ID();
		if (workerUserId <= 0) {
			throw new AdempiereException("Request has no worker user — cannot reply");
		}

		final MRequestUpdate update = new MRequestUpdate(request);
		update.setResult(trimmed);
		if (!update.save()) {
			throw new AdempiereException("Failed to save reply");
		}

		request.setLastResult(trimmed);
		request.setDateLastAction(new Timestamp(System.currentTimeMillis()));
		if (!request.save()) {
			throw new AdempiereException("Reply saved but failed to update request header");
		}

		addLog(update.get_ID(), null, null, "Reply sent to " + request.getAD_User().getName());
		return "@OK@";
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
