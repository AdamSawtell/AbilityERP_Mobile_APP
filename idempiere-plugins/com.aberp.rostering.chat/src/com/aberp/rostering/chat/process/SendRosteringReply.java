package com.aberp.rostering.chat.process;

import java.sql.Timestamp;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Util;

/**
 * Send a rostering officer reply to the worker.
 * Sets AbERP_RosteringReply and lets DB triggers copy it to LastResult + Updates
 * (avoids double inserts and optimistic-lock fights from a second header UPDATE).
 */
public class SendRosteringReply extends SvrProcess {
	private int paramRequestId = 0;
	private String paramReply = null;

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			final String name = para.getParameterName();
			if (Util.isEmpty(name)) {
				continue;
			}
			if ("R_Request_ID".equalsIgnoreCase(name)) {
				paramRequestId = para.getParameterAsInt();
			} else if ("Reply".equalsIgnoreCase(name)
					|| "AbERP_RosteringReply".equalsIgnoreCase(name)
					|| "Message".equalsIgnoreCase(name)) {
				if (para.getParameter() != null) {
					paramReply = para.getParameter().toString();
				}
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		final int requestTableId = MTable.getTable_ID(MRequest.Table_Name);
		final int tableId = getTable_ID();
		if (tableId > 0 && tableId != requestTableId) {
			throw new AdempiereException("Run Send Reply from a Rostering Chat request");
		}

		int requestId = paramRequestId;
		if (requestId <= 0) {
			requestId = getRecord_ID();
		}
		if (requestId <= 0) {
			requestId = RosteringChatContext.resolveRequestId(getCtx(), getProcessInfo());
		}
		if (requestId <= 0) {
			throw new AdempiereException("Select a chat thread first, type Reply, then Send Reply");
		}

		final MRequest request = new MRequest(getCtx(), requestId, get_TrxName());
		if (request.get_ID() <= 0) {
			throw new AdempiereException("Request not found: " + requestId);
		}

		if (getInt(request.get_Value("AbERP_Rostered_Shift_ID")) > 0) {
			throw new AdempiereException("This window is for standalone mobile chat only");
		}

		assertRosteringChatType(request);

		final String trimmed = resolveReplyMessage(request);
		if (trimmed.isEmpty()) {
			throw new AdempiereException("Type your reply in the Reply field, then click Send Reply");
		}
		if (trimmed.length() > 2000) {
			throw new AdempiereException("Reply is too long (max 2000 characters)");
		}

		final int workerUserId = resolveWorkerUserId(request);
		if (workerUserId <= 0) {
			throw new AdempiereException("Could not resolve worker user for this chat thread");
		}

		// One UPDATE of the Reply column — BEFORE trigger copies to LastResult / clears draft /
		// sets AD_Role_ID=0; AFTER trigger inserts Public R_RequestUpdate.
		final int rows = DB.executeUpdateEx(
				"UPDATE R_Request SET AbERP_RosteringReply=?, AD_User_ID=?, "
						+ "Updated=?, UpdatedBy=? WHERE R_Request_ID=?",
				new Object[] {
						trimmed,
						workerUserId,
						new Timestamp(System.currentTimeMillis()),
						getAD_User_ID(),
						requestId
				},
				get_TrxName());
		if (rows <= 0) {
			throw new AdempiereException("Failed to send reply — record may have changed, click ReQuery and try again");
		}

		final int updateId = DB.getSQLValueEx(get_TrxName(),
				"SELECT MAX(R_RequestUpdate_ID) FROM R_RequestUpdate "
						+ "WHERE R_Request_ID=? AND IsActive='Y' "
						+ "AND COALESCE(ConfidentialTypeEntry,'A')='A' "
						+ "AND TRIM(Result)=TRIM(?)",
				requestId, trimmed);

		final MUser worker = MUser.get(getCtx(), workerUserId);
		final String workerName = worker != null && worker.get_ID() > 0
				? worker.getName()
				: String.valueOf(workerUserId);
		addLog(updateId > 0 ? updateId : requestId, null, null,
				"Reply sent to " + workerName);
		return "@OK@ Reply sent to " + workerName;
	}

	private String resolveReplyMessage(MRequest request) {
		if (!Util.isEmpty(paramReply)) {
			return paramReply.trim();
		}

		final String contextDraft = RosteringChatContext.getDraftReply(getCtx());
		if (!Util.isEmpty(contextDraft)) {
			return contextDraft;
		}

		final String dbDraft = DB.getSQLValueStringEx(get_TrxName(),
				"SELECT AbERP_RosteringReply FROM R_Request WHERE R_Request_ID=?",
				request.get_ID());
		if (!Util.isEmpty(dbDraft)) {
			return dbDraft.trim();
		}

		final Object poDraft = request.get_Value("AbERP_RosteringReply");
		if (poDraft != null && !poDraft.toString().trim().isEmpty()) {
			return poDraft.toString().trim();
		}

		return "";
	}

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
