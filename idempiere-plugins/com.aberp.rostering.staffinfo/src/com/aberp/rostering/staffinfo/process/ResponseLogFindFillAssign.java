package com.aberp.rostering.staffinfo.process;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.model.PO;
import org.compiere.model.Query;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Trx;

/**
 * SAW011 — assign selected Find and Fill worker onto a vacant Employee line
 * and mark the Response Log reviewed (same vacancy / publish rules as Accept).
 */
public final class ResponseLogFindFillAssign {

	private static final String TABLE_RESPONSE_LOG = "AbERP_RosteredResponseLog";
	private static final String TABLE_SHIFT = "AbERP_Rostered_Shift";
	private static final String TABLE_SHIFT_STAFF = "AbERP_Rostered_ShiftStaff";

	private ResponseLogFindFillAssign() {
	}

	public static String assign(int responseLogId, int selectedUserId) {
		if (responseLogId <= 0) {
			throw new AdempiereException("Missing response log");
		}
		if (selectedUserId <= 0) {
			throw new AdempiereException("Select a worker in Find and Fill first");
		}

		String trxName = Trx.createTrxName("SAW011_FindFill");
		Trx trx = Trx.get(trxName, true);
		try {
			PO responseLog = MTable.get(Env.getCtx(), TABLE_RESPONSE_LOG).getPO(responseLogId, trxName);
			if (responseLog == null || responseLog.get_ID() <= 0) {
				throw new AdempiereException("Response log record not found");
			}
			if (isYes(responseLog.get_Value("IsReviewed"))) {
				throw new AdempiereException("This response has already been reviewed");
			}

			int shiftId = getInt(responseLog.get_Value("AbERP_Rostered_Shift_ID"));
			if (shiftId <= 0) {
				throw new AdempiereException("Response log is missing a shift");
			}

			MUser user = MUser.get(Env.getCtx(), selectedUserId);
			if (user == null || user.get_ID() <= 0) {
				throw new AdempiereException("Selected worker not found");
			}
			int staffBPartnerId = user.getC_BPartner_ID();
			if (staffBPartnerId <= 0) {
				throw new AdempiereException("Selected worker has no linked business partner");
			}

			PO shiftStaff = findOpenStaffLine(shiftId, trxName);
			boolean hasVacant = shiftStaff != null;

			if (isWorkerAlreadyOnShift(shiftId, selectedUserId, staffBPartnerId, trxName)) {
				// Never overwrite an allocated line. If a vacant slot remains, force a
				// different worker — marking reviewed here would "complete" against the
				// filled line and leave Unfilled Staff unchanged.
				if (hasVacant) {
					throw new AdempiereException(user.getName()
							+ " is already allocated on Employee. Select a different worker for the vacant slot");
				}
				responseLog.set_ValueOfColumn("IsReviewed", "Y");
				if (!responseLog.save()) {
					throw new AdempiereException("Worker already on Employee but failed to mark response reviewed");
				}
				finalizeShiftAfterFill(shiftId, trxName);
				trx.commit(true);
				return user.getName() + " already on Employee; response marked reviewed";
			}

			if (shiftStaff == null) {
				throw new AdempiereException("This shift has no vacant employee slot");
			}

			// Refuse to write if the chosen line is no longer vacant (race / bad query).
			if (getInt(shiftStaff.get_Value("AbERP_User_Contact_ID")) > 0
					|| getInt(shiftStaff.get_Value("C_BPartner_Staff_ID")) > 0) {
				throw new AdempiereException("Refusing to overwrite an allocated Employee line");
			}

			shiftStaff.set_ValueOfColumn("C_BPartner_Staff_ID", staffBPartnerId);
			shiftStaff.set_ValueOfColumn("AbERP_User_Contact_ID", selectedUserId);
			shiftStaff.set_ValueOfColumn("AbERP_RequestShift", "N");
			shiftStaff.set_ValueOfColumn("AbERP_DeclineShift", "N");
			if (!shiftStaff.save()) {
				throw new AdempiereException("Failed to assign worker to shift staff");
			}

			responseLog.set_ValueOfColumn("IsReviewed", "Y");
			if (!responseLog.save()) {
				throw new AdempiereException("Worker assigned but failed to mark response as reviewed");
			}

			finalizeShiftAfterFill(shiftId, trxName);

			trx.commit(true);
			return "Filled Employee slot with " + user.getName() + "; response marked reviewed";
		} catch (RuntimeException e) {
			trx.rollback();
			throw e;
		} catch (Exception e) {
			trx.rollback();
			throw new AdempiereException(e.getMessage());
		} finally {
			trx.close();
		}
	}

	/**
	 * First vacant Employee line only — never a line with user or staff BP set.
	 * Matches AbERP_NoOfUnfilledStaff (null contact) and also blocks BP-only fills.
	 */
	private static PO findOpenStaffLine(int shiftId, String trxName) {
		final String whereClause = ""
				+ "AbERP_Rostered_Shift_ID=? AND IsActive='Y' "
				+ "AND COALESCE(AbERP_User_Contact_ID,0)=0 "
				+ "AND COALESCE(C_BPartner_Staff_ID,0)=0";
		return new Query(Env.getCtx(), TABLE_SHIFT_STAFF, whereClause, trxName)
				.setParameters(shiftId)
				.setOrderBy("Line ASC")
				.first();
	}

	/** True only when this worker already fills an Employee line (user contact set). */
	private static boolean isWorkerAlreadyOnShift(int shiftId, int userContactId, int staffBPartnerId,
			String trxName) {
		final String whereClause = ""
				+ "AbERP_Rostered_Shift_ID=? AND IsActive='Y' "
				+ "AND COALESCE(AbERP_User_Contact_ID,0)>0 "
				+ "AND (AbERP_User_Contact_ID=? OR C_BPartner_Staff_ID=?)";
		return new Query(Env.getCtx(), TABLE_SHIFT_STAFF, whereClause, trxName)
				.setParameters(shiftId, userContactId, staffBPartnerId)
				.match();
	}

	private static void finalizeShiftAfterFill(int shiftId, String trxName) {
		final PO shift = MTable.get(Env.getCtx(), TABLE_SHIFT).getPO(shiftId, trxName);
		if (shift == null || shift.get_ID() <= 0) {
			throw new AdempiereException("Shift record not found");
		}
		if (shift.get_Value("AbERP_IsShowingAsAvailable") != null) {
			shift.set_ValueOfColumn("AbERP_IsShowingAsAvailable", "N");
		}
		shift.set_ValueOfColumn("R_Status_ID", resolvePublishedStatusId(trxName));
		if (!shift.save()) {
			throw new AdempiereException("Worker assigned but failed to publish shift");
		}
	}

	private static int resolvePublishedStatusId(String trxName) {
		final int clientId = Env.getAD_Client_ID(Env.getCtx());
		int statusId = DB.getSQLValue(trxName,
				"SELECT rs.R_Status_ID FROM R_Status rs "
						+ "JOIN R_StatusCategory c ON c.R_StatusCategory_ID=rs.R_StatusCategory_ID "
						+ "WHERE rs.IsActive='Y' AND c.IsActive='Y' "
						+ "AND c.Name='Shift Status' AND rs.Name='Published' "
						+ "AND rs.AD_Client_ID IN (0,?) "
						+ "ORDER BY rs.R_Status_ID ASC",
				clientId);
		if (statusId <= 0) {
			statusId = DB.getSQLValue(trxName,
					"SELECT R_Status_ID FROM R_Status "
							+ "WHERE IsActive='Y' AND Name='Published' AND AD_Client_ID IN (0,?) "
							+ "ORDER BY R_Status_ID ASC",
					clientId);
		}
		if (statusId <= 0) {
			throw new AdempiereException("Published status not found under category 'Shift Status'");
		}
		return statusId;
	}

	private static boolean isYes(Object value) {
		if (value == null) {
			return false;
		}
		if (value instanceof Boolean) {
			return ((Boolean) value).booleanValue();
		}
		final String s = String.valueOf(value);
		return "Y".equalsIgnoreCase(s) || "true".equalsIgnoreCase(s);
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
