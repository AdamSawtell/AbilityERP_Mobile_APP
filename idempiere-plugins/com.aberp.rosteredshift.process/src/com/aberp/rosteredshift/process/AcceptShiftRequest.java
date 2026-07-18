package com.aberp.rosteredshift.process;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.model.PO;
import org.compiere.model.Query;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
/**
 * Accept a pending shift request from the Response Log tab.
 * Assigns the requesting worker to the rostered shift staff line and marks the log reviewed.
 */
public class AcceptShiftRequest extends SvrProcess {
	private static final String TABLE_RESPONSE_LOG = "AbERP_RosteredResponseLog";
	private static final String TABLE_SHIFT = "AbERP_Rostered_Shift";
	private static final String TABLE_SHIFT_STAFF = "AbERP_Rostered_ShiftStaff";
	private static final String RESPONSE_REQUEST = "REQ";
	/** Shift Status category name — R_Status_ID differs per client; resolve at runtime. */
	private static final String STATUS_CATEGORY_SHIFT = "Shift Status";
	private static final String STATUS_PUBLISHED_NAME = "Published";

	@Override
	protected void prepare() {
		// Record context comes from the Response Log tab selection.
	}

	@Override
	protected String doIt() throws Exception {
		final int responseLogTableId = MTable.getTable_ID(TABLE_RESPONSE_LOG);
		if (getTable_ID() != responseLogTableId) {
			throw new AdempiereException("Run Accept Request from a Response Log record");
		}

		final int responseLogId = getRecord_ID();
		if (responseLogId <= 0) {
			throw new AdempiereException("Select a response log row first");
		}

		final PO responseLog = MTable.get(getCtx(), TABLE_RESPONSE_LOG).getPO(responseLogId, get_TrxName());
		if (responseLog == null || responseLog.get_ID() <= 0) {
			throw new AdempiereException("Response log record not found");
		}

		final String response = String.valueOf(responseLog.get_Value("AbERP_RosteredResponse"));
		if (!RESPONSE_REQUEST.equals(response)) {
			throw new AdempiereException("Only Request (REQ) responses can be accepted");
		}

		if (isYes(responseLog.get_Value("IsSuperseded"))) {
			throw new AdempiereException("This response has been superseded");
		}

		if (isYes(responseLog.get_Value("IsReviewed"))) {
			throw new AdempiereException("This response has already been reviewed");
		}

		final int shiftId = getInt(responseLog.get_Value("AbERP_Rostered_Shift_ID"));
		if (shiftId <= 0) {
			throw new AdempiereException("Response log is missing a shift");
		}

		final int userContactId = getInt(responseLog.get_Value("AbERP_User_Contact_ID"));
		if (userContactId <= 0) {
			throw new AdempiereException("Response log is missing the requesting user");
		}

		final MUser user = MUser.get(getCtx(), userContactId);
		if (user == null || user.get_ID() <= 0) {
			throw new AdempiereException("Requesting user not found");
		}

		final int staffBPartnerId = user.getC_BPartner_ID();
		if (staffBPartnerId <= 0) {
			throw new AdempiereException("Requesting user has no linked business partner (employee)");
		}

		if (hasConfirmedAssignee(shiftId, staffBPartnerId, userContactId)) {
			throw new AdempiereException("This shift is already assigned to another worker");
		}

		if (hasAnyAssignedStaff(shiftId)) {
			throw new AdempiereException("This shift already has an employee assigned on the Employee tab");
		}

		PO shiftStaff = findOpenStaffLine(shiftId);
		if (shiftStaff == null) {
			shiftStaff = createStaffLine(shiftId, responseLog.getAD_Client_ID(), responseLog.getAD_Org_ID());
		}

		if (getInt(shiftStaff.get_Value("C_BPartner_Staff_ID")) > 0
				&& getInt(shiftStaff.get_Value("C_BPartner_Staff_ID")) != staffBPartnerId) {
			throw new AdempiereException("Shift staff line is already allocated");
		}

		shiftStaff.set_ValueOfColumn("C_BPartner_Staff_ID", staffBPartnerId);
		shiftStaff.set_ValueOfColumn("AbERP_User_Contact_ID", userContactId);
		shiftStaff.set_ValueOfColumn("AbERP_RequestShift", "N");
		shiftStaff.set_ValueOfColumn("AbERP_DeclineShift", "N");
		if (!shiftStaff.save()) {
			throw new AdempiereException("Failed to assign worker to shift staff");
		}

		responseLog.set_ValueOfColumn("IsReviewed", "Y");
		if (!responseLog.save()) {
			throw new AdempiereException("Worker assigned but failed to mark response as reviewed");
		}

		finalizeShiftAfterAccept(shiftId);

		addLog(shiftStaff.get_ID(), null, null, "Assigned worker to shift staff line; shift published");
		return "@Processed@";
	}

	private PO findOpenStaffLine(int shiftId) {
		final String whereClause = ""
				+ "AbERP_Rostered_Shift_ID=? AND IsActive='Y' "
				+ "AND (C_BPartner_Staff_ID IS NULL OR C_BPartner_Staff_ID=0)";
		return new Query(getCtx(), TABLE_SHIFT_STAFF, whereClause, get_TrxName())
				.setParameters(shiftId)
				.setOrderBy("Line ASC")
				.first();
	}

	private PO createStaffLine(int shiftId, int clientId, int orgId) {
		final int nextLine = DB.getSQLValue(get_TrxName(),
				"SELECT COALESCE(MAX(Line),0)+10 FROM AbERP_Rostered_ShiftStaff WHERE AbERP_Rostered_Shift_ID=?",
				shiftId);

		final PO shiftStaff = MTable.get(getCtx(), TABLE_SHIFT_STAFF).getPO(0, get_TrxName());
		shiftStaff.set_ValueOfColumn("AD_Client_ID", clientId);
		shiftStaff.set_ValueOfColumn("AD_Org_ID", orgId);
		shiftStaff.set_ValueOfColumn("AbERP_Rostered_Shift_ID", shiftId);
		shiftStaff.set_ValueOfColumn("Line", nextLine > 0 ? nextLine : 10);
		shiftStaff.set_ValueOfColumn("AbERP_RequestShift", "N");
		shiftStaff.set_ValueOfColumn("AbERP_ClockIn", "N");
		shiftStaff.set_ValueOfColumn("AbERP_ClockOut", "N");
		return shiftStaff;
	}

	private boolean hasAnyAssignedStaff(int shiftId) {
		final String whereClause = ""
				+ "AbERP_Rostered_Shift_ID=? AND IsActive='Y' "
				+ "AND COALESCE(AbERP_User_Contact_ID,0) > 0";
		return new Query(getCtx(), TABLE_SHIFT_STAFF, whereClause, get_TrxName())
				.setParameters(shiftId)
				.match();
	}

	private boolean hasConfirmedAssignee(int shiftId, int staffBPartnerId, int userContactId) {
		final String whereClause = ""
				+ "AbERP_Rostered_Shift_ID=? AND IsActive='Y' "
				+ "AND C_BPartner_Staff_ID IS NOT NULL AND C_BPartner_Staff_ID > 0 "
				+ "AND (AbERP_RequestShift IS NULL OR AbERP_RequestShift <> 'Y') "
				+ "AND C_BPartner_Staff_ID <> ? AND AbERP_User_Contact_ID <> ?";
		return new Query(getCtx(), TABLE_SHIFT_STAFF, whereClause, get_TrxName())
				.setParameters(shiftId, staffBPartnerId, userContactId)
				.match();
	}

	private void finalizeShiftAfterAccept(int shiftId) {
		final PO shift = MTable.get(getCtx(), TABLE_SHIFT).getPO(shiftId, get_TrxName());
		if (shift == null || shift.get_ID() <= 0) {
			throw new AdempiereException("Shift record not found");
		}
		if (shift.get_Value("AbERP_IsShowingAsAvailable") != null) {
			shift.set_ValueOfColumn("AbERP_IsShowingAsAvailable", "N");
		}
		shift.set_ValueOfColumn("R_Status_ID", resolvePublishedStatusId());
		if (!shift.save()) {
			throw new AdempiereException("Worker assigned but failed to publish shift");
		}
	}

	/**
	 * Resolve Published under Shift Status by name (portable across clients).
	 * Seed/dev often used 1000040; HCO builds use a different R_Status_ID.
	 */
	private int resolvePublishedStatusId() {
		final int statusId = DB.getSQLValue(get_TrxName(),
				"SELECT s.R_Status_ID FROM R_Status s"
						+ " INNER JOIN R_StatusCategory c ON c.R_StatusCategory_ID=s.R_StatusCategory_ID"
						+ " WHERE s.IsActive='Y' AND c.IsActive='Y'"
						+ " AND c.Name=? AND s.Name=?"
						+ " ORDER BY s.R_Status_ID"
						+ " LIMIT 1",
				STATUS_CATEGORY_SHIFT, STATUS_PUBLISHED_NAME);
		if (statusId <= 0) {
			throw new AdempiereException(
					"Published status not found under category '" + STATUS_CATEGORY_SHIFT + "'");
		}
		return statusId;
	}

	private static boolean isYes(Object value) {
		return "Y".equals(String.valueOf(value));
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
