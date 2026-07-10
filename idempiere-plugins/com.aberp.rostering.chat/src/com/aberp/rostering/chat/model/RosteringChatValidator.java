package com.aberp.rostering.chat.model;

import java.sql.Timestamp;

import org.compiere.model.MClient;
import org.compiere.model.MRequest;
import org.compiere.model.MRequestUpdate;
import org.compiere.model.ModelValidationEngine;
import org.compiere.model.ModelValidator;
import org.compiere.model.PO;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Util;

/**
 * Keeps Rostering Chat header in sync when Updates are added from iDempiere,
 * and stamps new requests created in this flow with the Rostering Chat type.
 */
public class RosteringChatValidator implements ModelValidator {
	private static final String TYPE_NAME = "Rostering Chat";
	private static final int ROSTERING_ROLE_ID = 1000012;

	private int smallClientId = -1;

	@Override
	public void initialize(ModelValidationEngine engine, MClient client) {
		smallClientId = client != null ? client.getAD_Client_ID() : -1;
		engine.addModelChange(MRequestUpdate.Table_Name, this);
		engine.addModelChange(MRequest.Table_Name, this);
	}

	@Override
	public int getAD_Client_ID() {
		return smallClientId;
	}

	@Override
	public String login(int AD_Org_ID, int AD_Role_ID, int AD_User_ID) {
		return null;
	}

	@Override
	public String modelChange(PO po, int type) throws Exception {
		if (po instanceof MRequestUpdate
				&& (type == TYPE_AFTER_NEW || type == TYPE_AFTER_CHANGE)) {
			return afterRequestUpdate((MRequestUpdate) po);
		}
		if (po instanceof MRequest && type == TYPE_BEFORE_NEW) {
			return beforeRequestNew((MRequest) po);
		}
		return null;
	}

	@Override
	public String docValidate(PO po, int timing) {
		return null;
	}

	private String beforeRequestNew(MRequest request) {
		// If request type empty, default to Rostering Chat when role queue is rostering
		// or when summary looks like a mobile/rostering chat.
		final int typeId = DB.getSQLValue(request.get_TrxName(),
				"SELECT R_RequestType_ID FROM R_RequestType WHERE Name=? AND IsActive='Y' ORDER BY R_RequestType_ID",
				TYPE_NAME);
		if (typeId > 0 && request.getR_RequestType_ID() <= 0) {
			request.setR_RequestType_ID(typeId);
		}
		if (request.getAD_Role_ID() <= 0 && isRosteringChat(request)) {
			request.setAD_Role_ID(ROSTERING_ROLE_ID);
		}
		if (Util.isEmpty(request.getSummary()) && isRosteringChat(request)) {
			request.setSummary("Message to Rostering");
		}
		return null;
	}

	private String afterRequestUpdate(MRequestUpdate update) {
		final int requestId = update.getR_Request_ID();
		if (requestId <= 0) {
			return null;
		}

		final MRequest request = new MRequest(update.getCtx(), requestId, update.get_TrxName());
		if (request.get_ID() <= 0 || !isRosteringChat(request)) {
			return null;
		}

		final String result = update.getResult();
		if (Util.isEmpty(result)) {
			return null;
		}

		final int workerUserId = request.getAD_User_ID();
		final int authorId = update.getCreatedBy();
		final boolean fromWorker = workerUserId > 0 && authorId == workerUserId;

		if (fromWorker) {
			DB.executeUpdateEx(
					"UPDATE R_Request SET LastResult=?, AD_Role_ID=?, DateLastAction=?, "
							+ "Updated=?, UpdatedBy=? WHERE R_Request_ID=?",
					new Object[] {
							result.trim(),
							ROSTERING_ROLE_ID,
							new Timestamp(System.currentTimeMillis()),
							new Timestamp(System.currentTimeMillis()),
							authorId,
							requestId
					},
					update.get_TrxName());
		} else {
			// Officer (or anyone else) replied — clear queue so app shows awaiting worker
			DB.executeUpdateEx(
					"UPDATE R_Request SET LastResult=?, AD_Role_ID=0, DateLastAction=?, "
							+ "Updated=?, UpdatedBy=? WHERE R_Request_ID=?",
					new Object[] {
							result.trim(),
							new Timestamp(System.currentTimeMillis()),
							new Timestamp(System.currentTimeMillis()),
							authorId > 0 ? authorId : Env.getAD_User_ID(update.getCtx()),
							requestId
					},
					update.get_TrxName());
		}
		return null;
	}

	private boolean isRosteringChat(MRequest request) {
		final String typeName = DB.getSQLValueString(request.get_TrxName(),
				"SELECT Name FROM R_RequestType WHERE R_RequestType_ID=?",
				request.getR_RequestType_ID());
		return TYPE_NAME.equals(typeName);
	}
}
