package com.aberp.skipdates.copyfrom;

import java.util.List;
import java.util.UUID;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MTable;
import org.compiere.model.PO;
import org.compiere.model.Query;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;

/**
 * Copy AbERP_Dates lines from a selected Skip Dates header into the current header.
 * Mirrors the Service Booking "Copy Lines" UX (source Search parameter + confirmation help).
 */
public class CopyDatesFrom extends SvrProcess {

	public static final String TABLE_SKIP_DATES = "AbERP_Skip_Dates";
	public static final String TABLE_DATES = "AbERP_Dates";
	public static final String COL_SKIP_DATES_ID = "AbERP_Skip_Dates_ID";

	private static final String REVIEW_WARNING =
			"The copied records contain specific dates. Please review all copied dates and update the year or individual dates where required before using this Skip Dates record.";

	private int p_Source_SkipDates_ID = 0;

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			String name = para.getParameterName();
			if (para.getParameter() == null && para.getParameter_To() == null) {
				continue;
			}
			if (COL_SKIP_DATES_ID.equals(name)) {
				p_Source_SkipDates_ID = para.getParameterAsInt();
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		final int skipDatesTableId = MTable.getTable_ID(TABLE_SKIP_DATES);
		if (getTable_ID() != skipDatesTableId) {
			throw new AdempiereException("Run Copy Dates From from a Skip Dates record");
		}

		final int targetId = getRecord_ID();
		if (targetId <= 0) {
			throw new AdempiereException("Save the Skip Dates header before copying dates");
		}

		if (p_Source_SkipDates_ID <= 0) {
			throw new AdempiereException("Select a Skip Dates record to copy from");
		}

		if (p_Source_SkipDates_ID == targetId) {
			throw new AdempiereException("Cannot copy dates from the same Skip Dates record");
		}

		final PO target = MTable.get(getCtx(), TABLE_SKIP_DATES).getPO(targetId, get_TrxName());
		if (target == null || target.get_ID() <= 0) {
			throw new AdempiereException("Target Skip Dates record not found");
		}

		final PO source = MTable.get(getCtx(), TABLE_SKIP_DATES).getPO(p_Source_SkipDates_ID, get_TrxName());
		if (source == null || source.get_ID() <= 0) {
			throw new AdempiereException("Source Skip Dates record not found");
		}

		final List<PO> sourceLines = new Query(getCtx(), TABLE_DATES, "AbERP_Skip_Dates_ID=?", get_TrxName())
				.setParameters(p_Source_SkipDates_ID)
				.setOnlyActiveRecords(false)
				.setOrderBy("StartDate, AbERP_Dates_ID")
				.list();

		if (sourceLines.isEmpty()) {
			throw new AdempiereException("Source Skip Dates has no date lines to copy");
		}

		int copied = 0;
		for (PO srcLine : sourceLines) {
			PO newLine = MTable.get(getCtx(), TABLE_DATES).getPO(0, get_TrxName());
			PO.copyValues(srcLine, newLine);
			newLine.set_ValueNoCheck(COL_SKIP_DATES_ID, Integer.valueOf(targetId));
			newLine.set_ValueNoCheck("AD_Client_ID", Integer.valueOf(target.getAD_Client_ID()));
			newLine.setAD_Org_ID(target.getAD_Org_ID());
			newLine.set_ValueNoCheck("AbERP_Dates_UU", UUID.randomUUID().toString());
			if (newLine.get_Value("IsActive") == null) {
				newLine.set_ValueOfColumn("IsActive", "Y");
			}
			if (!newLine.save()) {
				throw new AdempiereException("Failed to save copied date line (source AbERP_Dates_ID="
						+ srcLine.get_ID() + ")");
			}
			copied++;
		}

		addLog(0, null, null, REVIEW_WARNING);
		final String sourceName = String.valueOf(source.get_Value("Name"));
		return "Copied " + copied + " date record(s) from \"" + sourceName
				+ "\". " + REVIEW_WARNING;
	}
}
