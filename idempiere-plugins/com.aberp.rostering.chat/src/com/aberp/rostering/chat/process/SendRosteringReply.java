package com.aberp.rostering.chat.process;

import java.sql.Timestamp;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MRequest;
import org.compiere.model.MRequestUpdate;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Util;

/**
 * Send a rostering officer reply to the worker.
 * Prefer process parameters (R_Request_ID + Reply) so WebUI button context is reliable.
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
			throw new AdempiereException("Run Send to Worker from a Rostering Chat request");
		}

		int requestId = paramRequestId;
		if (requestId <= 0) {
			requestId = getRecord_ID();
		}
		if (requestId <= 0) {
			requestId = RosteringChatContext.resolveRequestId(getCtx(), getProcessInfo());
		}
		if (requestId <= 0) {
			throw new AdempiereException("Select a chat thread first (open the row, then Send to Worker)");
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
			throw new AdempiereException("Enter your reply, then click OK / Send to Worker");
		}
		if (trimmed.length() > 2000) {
			throw new AdempiereException("Reply is too long (max 2000 characters)");
		}

		final int workerUserId = resolveWorkerUserId(request);
		if (workerUserId <= 0) {
			throw new AdempiereException("Could not resolve worker user for this chat thread");
		}

		final int updateId = insertRequestUpdate(request, trimmed);
		if (updateId <= 0) {
			throw new AdempiereException("Failed to save reply into Updates");
		}

		DB.executeUpdateEx(
				"UPDATE R_Request SET AD_User_ID=?, AD_Role_ID=0, LastResult=?, "
						+ "AbERP_RosteringReply=NULL, DateLastAction=?, "
						+ "Updated=?, UpdatedBy=? WHERE R_Request_ID=?",
				new Object[] {
						workerUserId,
						trimmed,
						new Timestamp(System.currentTimeMillis()),
						new Timestamp(System.currentTimeMillis()),
						getAD_User_ID(),
						requestId
				},
				get_TrxName());

		final MUser worker = MUser.get(getCtx(), workerUserId);
		final String workerName = worker != null && worker.get_ID() > 0 ? worker.getName() : String.valueOf(workerUserId);
		addLog(updateId, null, null, "Reply saved to Updates #" + updateId + " and sent to " + workerName);
		return "@OK@ Reply saved to Updates and sent to " + workerName;
	}

	private int insertRequestUpdate(MRequest request, String message) {
		try {
			final MRequestUpdate update = new MRequestUpdate(request);
			update.setResult(message);
			if (update.save()) {
				return update.get_ID();
			}
			log.log(Level.WARNING, "MRequestUpdate.save() returned false — falling back to SQL insert");
		} catch (Exception ex) {
			log.log(Level.WARNING, "MRequestUpdate failed — falling back to SQL insert", ex);
		}

		// Keep sequence ahead of live max to avoid duplicate keys
		DB.executeUpdateEx(
				"UPDATE AD_Sequence SET CurrentNext = GREATEST(CurrentNext, "
						+ "COALESCE((SELECT MAX(R_RequestUpdate_ID)+IncrementNo FROM R_RequestUpdate), CurrentNext)) "
						+ "WHERE Name='R_RequestUpdate'",
				get_TrxName());

		final int updateId = DB.getNextID(request.getAD_Client_ID(), "R_RequestUpdate", get_TrxName());
		if (updateId <= 0) {
			return 0;
		}

		final int rows = DB.executeUpdateEx(
				"INSERT INTO R_RequestUpdate ("
						+ "R_RequestUpdate_ID, AD_Client_ID, AD_Org_ID, IsActive, "
						+ "Created, CreatedBy, Updated, UpdatedBy, "
						+ "R_Request_ID, Result, ConfidentialTypeEntry"
						+ ") VALUES (?, ?, 0, 'Y', ?, ?, ?, ?, ?, ?, 'C')",
				new Object[] {
						updateId,
						request.getAD_Client_ID(),
						new Timestamp(System.currentTimeMillis()),
						getAD_User_ID(),
						new Timestamp(System.currentTimeMillis()),
						getAD_User_ID(),
						request.get_ID(),
						message
				},
				get_TrxName());
		return rows > 0 ? updateId : 0;
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
