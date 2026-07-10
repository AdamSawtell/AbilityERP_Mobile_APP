package com.aberp.rostering.chat.process;

import java.sql.Timestamp;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MRequestUpdate;
import org.compiere.model.MStatus;
import org.compiere.model.MTable;
import org.compiere.model.Query;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;

/**
 * Close a mobile rostering chat thread so the worker gets a fresh thread on next contact.
 */
public class CloseRosteringChat extends SvrProcess {
	private int paramRequestId = 0;

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			if (para.getParameterName() != null && "R_Request_ID".equalsIgnoreCase(para.getParameterName())) {
				paramRequestId = para.getParameterAsInt();
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		final int requestTableId = MTable.getTable_ID(MRequest.Table_Name);
		final int tableId = getTable_ID();
		if (tableId > 0 && tableId != requestTableId) {
			throw new AdempiereException("Run Close Chat from a Rostering Chat request");
		}

		int requestId = paramRequestId;
		if (requestId <= 0) {
			requestId = getRecord_ID();
		}
		if (requestId <= 0) {
			requestId = RosteringChatContext.resolveRequestId(getCtx(), getProcessInfo());
		}
		if (requestId <= 0) {
			throw new AdempiereException("Select a chat thread first (open the row, then Close Chat)");
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

		final String closeNote = "Chat closed by rostering";
		try {
			final MRequestUpdate update = new MRequestUpdate(request);
			update.setResult(closeNote);
			update.save();
		} catch (Exception ignored) {
			// Non-fatal
		}

		final int rows = DB.executeUpdateEx(
				"UPDATE R_Request SET R_Status_ID=?, AD_Role_ID=0, LastResult=?, "
						+ "DateLastAction=?, Updated=?, UpdatedBy=? WHERE R_Request_ID=?",
				new Object[] {
						closedStatusId,
						closeNote,
						new Timestamp(System.currentTimeMillis()),
						new Timestamp(System.currentTimeMillis()),
						getAD_User_ID(),
						requestId
				},
				get_TrxName());
		if (rows <= 0) {
			throw new AdempiereException("Failed to close chat");
		}

		addLog(requestId, null, null, "Chat closed — worker can start a new conversation in the app");
		return "@OK@ Chat closed";
	}

	private int resolveClosedStatusId() {
		final MStatus closed = new Query(getCtx(), MStatus.Table_Name, "IsActive='Y' AND Name='Closed'", get_TrxName())
				.setOrderBy("R_Status_ID ASC")
				.first();
		if (closed != null && closed.get_ID() > 0) {
			return closed.get_ID();
		}
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
