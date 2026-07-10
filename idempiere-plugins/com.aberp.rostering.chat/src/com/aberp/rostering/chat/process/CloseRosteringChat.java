package com.aberp.rostering.chat.process;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MStatus;
import org.compiere.model.MTable;
import org.compiere.model.Query;
import org.compiere.util.DB;
import org.compiere.process.SvrProcess;

/**
 * Close a mobile rostering chat thread so the worker gets a fresh thread on next contact.
 */
public class CloseRosteringChat extends SvrProcess {
	@Override
	protected void prepare() {
		// Record context comes from the Rostering Chat header tab selection.
	}

	@Override
	protected String doIt() throws Exception {
		if (getTable_ID() != MTable.getTable_ID(MRequest.Table_Name)) {
			throw new AdempiereException("Run Close Chat from a Rostering Chat request");
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

		final int closedStatusId = resolveClosedStatusId();
		if (request.getR_Status_ID() == closedStatusId) {
			throw new AdempiereException("This chat is already closed");
		}

		request.setR_Status_ID(closedStatusId);
		if (!request.save()) {
			throw new AdempiereException("Failed to close chat");
		}

		addLog(requestId, null, null, "Chat closed — worker will get a new thread on next mobile message");
		return "@OK@";
	}

	private int resolveClosedStatusId() {
		final MStatus closed = new Query(getCtx(), MStatus.Table_Name, "IsActive='Y' AND Name='Closed'", get_TrxName())
				.setOrderBy("R_Status_ID ASC")
				.first();
		if (closed != null && closed.get_ID() > 0) {
			return closed.get_ID();
		}
		// Fallback used by mobile API when no open thread exists.
		return 102;
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
