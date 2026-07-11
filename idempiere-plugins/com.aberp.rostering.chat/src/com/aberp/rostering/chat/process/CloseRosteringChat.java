package com.aberp.rostering.chat.process;

import java.sql.Timestamp;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MTable;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Env;

/**
 * Close a mobile rostering chat thread so the worker can start a new conversation.
 * Uses SQL only for status resolution (avoids cross-tenant R_Status PO reads).
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

		final int closedStatusId = resolveClosedStatusId(request);
		if (request.getR_Status_ID() == closedStatusId) {
			throw new AdempiereException("This chat is already closed");
		}

		final String closeNote = "Chat closed by rostering";
		final Timestamp now = new Timestamp(System.currentTimeMillis());

		// Public Updates row (same path the app timeline reads)
		insertPublicUpdate(request, closeNote, now);

		final int rows = DB.executeUpdateEx(
				"UPDATE R_Request SET R_Status_ID=?, AD_Role_ID=0, LastResult=?, "
						+ "DateLastAction=?, AbERP_RosteringReply=NULL "
						+ "WHERE R_Request_ID=?",
				new Object[] {
						closedStatusId,
						closeNote,
						now,
						requestId
				},
				get_TrxName());
		if (rows <= 0) {
			throw new AdempiereException("Failed to close chat");
		}

		addLog(requestId, null, null, "Chat closed — worker can start a new conversation in the app");
		// Keep a short OK for Close (less frequent); Send Reply stays fully silent.
		return "@OK@ Chat closed";
	}

	/**
	 * Prefer a Closed status in this request type's category (tenant-safe).
	 * Never load R_Status via PO — System Closed (102) triggers cross-tenant errors.
	 */
	private int resolveClosedStatusId(MRequest request) {
		int id = DB.getSQLValue(get_TrxName(),
				"SELECT rs.R_Status_ID FROM R_Status rs "
						+ "JOIN R_RequestType rt ON rt.R_StatusCategory_ID = rs.R_StatusCategory_ID "
						+ "WHERE rt.R_RequestType_ID=? AND rs.IsActive='Y' AND rs.IsClosed='Y' "
						+ "ORDER BY rs.SeqNo NULLS LAST, rs.R_Status_ID ASC",
				request.getR_RequestType_ID());
		if (id > 0) {
			return id;
		}
		id = DB.getSQLValue(get_TrxName(),
				"SELECT R_Status_ID FROM R_Status "
						+ "WHERE IsActive='Y' AND IsClosed='Y' AND AD_Client_ID IN (0,?) "
						+ "ORDER BY CASE WHEN LOWER(Name)='closed' THEN 0 ELSE 1 END, R_Status_ID ASC",
				Env.getAD_Client_ID(getCtx()));
		if (id > 0) {
			return id;
		}
		// AbilityERP Core Status — Complete (Close Request)
		return 1000002;
	}

	private void insertPublicUpdate(MRequest request, String result, Timestamp now) {
		try {
			final int nextId = DB.getSQLValue(get_TrxName(),
					"SELECT COALESCE(MAX(R_RequestUpdate_ID),0)+1 FROM R_RequestUpdate");
			if (nextId <= 0) {
				return;
			}
			DB.executeUpdateEx(
					"INSERT INTO R_RequestUpdate ("
							+ "R_RequestUpdate_ID, AD_Client_ID, AD_Org_ID, IsActive, "
							+ "Created, CreatedBy, Updated, UpdatedBy, "
							+ "R_Request_ID, Result, ConfidentialTypeEntry"
							+ ") VALUES (?,?,?,'Y',?,?,?,?,?,?,'A')",
					new Object[] {
							nextId,
							request.getAD_Client_ID(),
							request.getAD_Org_ID(),
							now,
							getAD_User_ID(),
							now,
							getAD_User_ID(),
							request.get_ID(),
							result
					},
					get_TrxName());
		} catch (Exception ignored) {
			// Non-fatal — header status close is enough for the app
		}
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
