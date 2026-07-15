package com.aberp.bookinggenerator.bulk;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.adempiere.util.ProcessUtil;
import org.compiere.model.MProcess;
import org.compiere.model.MTable;
import org.compiere.model.PO;
import org.compiere.model.Query;
import org.compiere.process.ProcessInfo;
import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Trx;

/**
 * SAW017 — Bulk / block generate Service Bookings from Booking Generator.
 * Additive: does not change the existing single-record Generate Bookings button.
 * Delegates each row to AD process Generate Bookings (UU below) at runtime.
 */
public class BulkGenerateBookings extends SvrProcess {

	/** Existing Flamingo/Logilite process on HCO / packs */
	public static final String GENERATE_BOOKINGS_PROCESS_UU = "6482f6b8-eaa3-4e7b-a8f6-4e263d44909b";
	public static final String GENERATE_BOOKINGS_VALUE = "Generate Bookings";

	public static final String TABLE_BG = "AbERP_BookingGenerator";

	private Timestamp p_DateFrom;
	private Timestamp p_DateTo;
	private int p_C_Activity_ID;
	private boolean p_IncludeIrregular;
	private boolean p_IncludeSTR;
	private String p_InvoiceRule = "I";
	private boolean p_ForceInvoiceRule = true;
	private String p_DocAction = "DR";

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			String name = para.getParameterName();
			if (para.getParameter() == null && para.getParameter_To() == null) {
				continue;
			}
			if ("DateFrom".equals(name)) {
				p_DateFrom = para.getParameterAsTimestamp();
			} else if ("DateTo".equals(name)) {
				p_DateTo = para.getParameterAsTimestamp();
			} else if ("C_Activity_ID".equals(name)) {
				p_C_Activity_ID = para.getParameterAsInt();
			} else if ("AbERP_IncludeIrregular".equals(name)) {
				p_IncludeIrregular = "Y".equals(para.getParameter());
			} else if ("AbERP_IncludeSTR".equals(name)) {
				p_IncludeSTR = "Y".equals(para.getParameter());
			} else if ("InvoiceRule".equals(name)) {
				Object v = para.getParameter();
				if (v != null) {
					p_InvoiceRule = v.toString();
				}
			} else if ("AbERP_ForceInvoiceRule".equals(name)) {
				p_ForceInvoiceRule = !"N".equals(para.getParameter());
			} else if ("DocAction".equals(name)) {
				Object v = para.getParameter();
				if (v != null) {
					p_DocAction = v.toString();
				}
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		if (p_DateFrom == null || p_DateTo == null) {
			throw new AdempiereException("Date From and Date To are required for the generation period");
		}
		if (p_DateTo.before(p_DateFrom)) {
			throw new AdempiereException("Date To must be on or after Date From");
		}

		final int generateProcessId = resolveGenerateBookingsProcessId();
		if (generateProcessId <= 0) {
			throw new AdempiereException(
					"Generate Bookings process not found (UU "
							+ GENERATE_BOOKINGS_PROCESS_UU
							+ "). Install com.aberp.servicebooking.generator before running bulk generate.");
		}

		final List<Integer> bgIds = selectBookingGenerators();
		addLog(0, null, null, buildRunHeader(bgIds.size()));
		if (bgIds.isEmpty()) {
			String empty = buildRunHeader(0) + " | No Booking Generator rows matched Standards filters for this run";
			addLog(0, null, null, empty);
			return empty;
		}

		int ok = 0;
		int skipped = 0;
		int failed = 0;
		final StringBuilder errors = new StringBuilder();
		final Timestamp runStarted = new Timestamp(System.currentTimeMillis());

		final int bgTableId = MTable.getTable_ID(TABLE_BG);
		final Properties ctx = getCtx();
		final String trxName = get_TrxName();

		for (int bgId : bgIds) {
			PO bg = MTable.get(ctx, TABLE_BG).getPO(bgId, trxName);
			if (bg == null || bg.get_ID() <= 0) {
				skipped++;
				addLog(0, null, null, "Skip ID " + bgId + " — record not found");
				continue;
			}

			final String bgLabel = formatBgLabel(bg, bgId);

			String skipReason = skipReason(bg);
			if (skipReason != null) {
				skipped++;
				addLog(0, null, null, "Skip " + bgLabel + " — " + skipReason);
				continue;
			}

			Timestamp oldStart = (Timestamp) bg.get_Value("StartDate");
			Timestamp oldEnd = (Timestamp) bg.get_Value("EndDate");
			boolean datesChanged = false;
			try {
				if (oldStart == null || !oldStart.equals(p_DateFrom)
						|| oldEnd == null || !oldEnd.equals(p_DateTo)) {
					bg.set_ValueOfColumn("StartDate", p_DateFrom);
					bg.set_ValueOfColumn("EndDate", p_DateTo);
					bg.saveEx();
					datesChanged = true;
				}

				ProcessInfo pi = new ProcessInfo("Generate Bookings", generateProcessId);
				pi.setAD_Client_ID(Env.getAD_Client_ID(ctx));
				pi.setAD_User_ID(Env.getAD_User_ID(ctx));
				pi.setAD_Process_ID(generateProcessId);
				pi.setClassName(MProcess.get(ctx, generateProcessId).getClassname());
				pi.setTable_ID(bgTableId);
				pi.setRecord_ID(bgId);
				pi.setParameter(new ProcessInfoParameter[] {
						new ProcessInfoParameter("DocAction", p_DocAction, null, null, null)
				});

				Trx trx = Trx.get(trxName, false);
				boolean started = ProcessUtil.startJavaProcess(ctx, pi, trx, false);
				if (!started || pi.isError()) {
					failed++;
					String err = pi.getSummary() != null ? pi.getSummary() : "Generate Bookings failed";
					errors.append(bgLabel).append(": ").append(err).append("; ");
					addLog(0, null, null, "FAIL " + bgLabel + " — " + err);
					continue;
				}

				if (p_ForceInvoiceRule && p_InvoiceRule != null && p_InvoiceRule.length() > 0) {
					applyInvoiceRuleToLatestBooking(bgId, p_InvoiceRule, trxName);
				}

				ok++;
				String bookingRef = latestBookingDocumentNo(bgId, runStarted, trxName);
				if (bookingRef != null) {
					addLog(0, null, null, "OK " + bgLabel + " — Service Booking " + bookingRef);
				} else {
					addLog(0, null, null,
							"OK " + bgLabel + " — Generate Bookings completed (no new booking document for this run)");
				}
			} catch (Exception ex) {
				failed++;
				String err = ex.getMessage() != null ? ex.getMessage() : ex.toString();
				errors.append(bgLabel).append(": ").append(err).append("; ");
				addLog(0, null, null, "FAIL " + bgLabel + " — " + err);
				if (log.isLoggable(Level.WARNING)) {
					log.log(Level.WARNING, "Bulk generate failed for BG " + bgId, ex);
				}
			} finally {
				// Keep run dates on BG (period for this generation). Do not restore oldStart/oldEnd.
				if (datesChanged && log.isLoggable(Level.FINE)) {
					log.fine("BG " + bgId + " dates set to run period (was " + oldStart + ".." + oldEnd + ")");
				}
			}
		}

		String summary = buildRunHeader(bgIds.size())
				+ " | Result: ok=" + ok + ", skipped=" + skipped + ", failed=" + failed;
		addLog(0, null, null, summary);
		if (failed > 0) {
			return summary + " | Errors: " + errors;
		}
		return summary;
	}

	/** Human-readable run parameters for the process dialog (does not change generation). */
	private String buildRunHeader(int candidateCount) {
		String activity = "All activities";
		if (p_C_Activity_ID > 0) {
			String name = DB.getSQLValueString(get_TrxName(),
					"SELECT Name FROM C_Activity WHERE C_Activity_ID=?", p_C_Activity_ID);
			activity = name != null && name.length() > 0 ? name : ("Activity ID " + p_C_Activity_ID);
		}
		return "Bulk Generate Bookings — Period "
				+ formatDate(p_DateFrom) + " to " + formatDate(p_DateTo)
				+ "; Activity=" + activity
				+ "; Include Irregular=" + (p_IncludeIrregular ? "Yes" : "No")
				+ "; Include STR=" + (p_IncludeSTR ? "Yes" : "No")
				+ "; Invoice Rule=" + p_InvoiceRule
				+ (p_ForceInvoiceRule ? " (forced)" : "")
				+ "; DocAction=" + p_DocAction
				+ "; Candidates=" + candidateCount;
	}

	private static String formatDate(Timestamp ts) {
		if (ts == null) {
			return "?";
		}
		return ts.toString().substring(0, 10);
	}

	private String formatBgLabel(PO bg, int bgId) {
		Object value = bg.get_Value("Value");
		Object desc = bg.get_Value("Description");
		StringBuilder sb = new StringBuilder();
		if (value != null && value.toString().trim().length() > 0) {
			sb.append(value.toString().trim());
		} else {
			sb.append("ID ").append(bgId);
		}
		if (desc != null && desc.toString().trim().length() > 0) {
			sb.append(" (").append(desc.toString().trim()).append(")");
		}
		String bpName = partnerName(bg.get_ValueAsInt("C_BPartner_ID"));
		String invoicePartner = partnerName(bg.get_ValueAsInt("Bill_BPartner_ID"));
		String targetDocType = docTypeName(bg.get_ValueAsInt("C_DocTypeTarget_ID"));
		sb.append(" | BP=").append(bpName)
				.append("; Invoice Partner=").append(invoicePartner)
				.append("; Target DocType=").append(targetDocType);
		return sb.toString();
	}

	private String partnerName(int bPartnerId) {
		if (bPartnerId <= 0) {
			return "(none)";
		}
		String name = DB.getSQLValueString(get_TrxName(),
				"SELECT Name FROM C_BPartner WHERE C_BPartner_ID=?", bPartnerId);
		return name != null && name.length() > 0 ? name : ("ID " + bPartnerId);
	}

	private String docTypeName(int docTypeId) {
		if (docTypeId <= 0) {
			return "(none)";
		}
		String name = DB.getSQLValueString(get_TrxName(),
				"SELECT Name FROM C_DocType WHERE C_DocType_ID=?", docTypeId);
		return name != null && name.length() > 0 ? name : ("ID " + docTypeId);
	}

	private String latestBookingDocumentNo(int bgId, Timestamp notBefore, String trxName) {
		return DB.getSQLValueString(trxName,
				"SELECT DocumentNo FROM C_Order WHERE AbERP_BookingGenerator_ID=? "
						+ "AND Created >= ? "
						+ "ORDER BY Created DESC, C_Order_ID DESC FETCH FIRST 1 ROW ONLY",
				bgId, notBefore);
	}

	private int resolveGenerateBookingsProcessId() {
		int id = DB.getSQLValue(null,
				"SELECT AD_Process_ID FROM AD_Process WHERE AD_Process_UU=? AND IsActive='Y'",
				GENERATE_BOOKINGS_PROCESS_UU);
		if (id > 0) {
			return id;
		}
		return DB.getSQLValue(null,
				"SELECT AD_Process_ID FROM AD_Process WHERE Value=? AND IsActive='Y' ORDER BY AD_Process_ID",
				GENERATE_BOOKINGS_VALUE);
	}

	private List<Integer> selectBookingGenerators() {
		StringBuilder where = new StringBuilder();
		where.append("IsActive='Y'");
		where.append(" AND UPPER(COALESCE(Description,'')) LIKE 'STANDARD%'");
		where.append(" AND COALESCE(IsTemplate,'N')='N'");
		where.append(" AND COALESCE(AbERP_IsProgramOfSupports,'N')='N'");
		// Exclude Non Binding Offer / quotes by DocType name when present
		where.append(" AND NOT EXISTS (")
				.append("SELECT 1 FROM C_DocType dt WHERE dt.C_DocType_ID=AbERP_BookingGenerator.C_DocTypeTarget_ID")
				.append(" AND dt.Name ILIKE '%Non Binding%')");
		where.append(" AND NOT EXISTS (")
				.append("SELECT 1 FROM C_Activity a WHERE a.C_Activity_ID=AbERP_BookingGenerator.C_Activity_ID")
				.append(" AND a.Name ILIKE '*Do Not Use%')");

		List<Object> params = new ArrayList<>();
		if (p_C_Activity_ID > 0) {
			where.append(" AND C_Activity_ID=?");
			params.add(p_C_Activity_ID);
		}
		if (!p_IncludeIrregular) {
			where.append(" AND UPPER(COALESCE(Description,'')) NOT LIKE 'STANDARD IRR%'");
		}
		if (!p_IncludeSTR) {
			where.append(" AND UPPER(COALESCE(Description,'')) NOT LIKE 'STANDARD STR%'");
			where.append(" AND NOT EXISTS (")
					.append("SELECT 1 FROM C_Activity a WHERE a.C_Activity_ID=AbERP_BookingGenerator.C_Activity_ID")
					.append(" AND a.Name = 'Short Term Accommodation')");
		}
		// Client already exited before the run period starts
		where.append(" AND NOT EXISTS (")
				.append("SELECT 1 FROM C_BPartner bp WHERE bp.C_BPartner_ID=AbERP_BookingGenerator.C_BPartner_ID")
				.append(" AND bp.AbERP_Date_Support_Ceased IS NOT NULL")
				.append(" AND bp.AbERP_Date_Support_Ceased < ?)");
		params.add(p_DateFrom);

		Query q = new Query(getCtx(), TABLE_BG, where.toString(), get_TrxName())
				.setParameters(params)
				.setClient_ID()
				.setOnlyActiveRecords(true)
				.setOrderBy("AbERP_BookingGenerator_ID");
		List<PO> rows = q.list();
		List<Integer> ids = new ArrayList<>();
		for (PO row : rows) {
			ids.add(row.get_ID());
		}
		return ids;
	}

	private String skipReason(PO bg) {
		Timestamp ceased = null;
		int bpId = bg.get_ValueAsInt("C_BPartner_ID");
		if (bpId > 0) {
			ceased = DB.getSQLValueTS(get_TrxName(),
					"SELECT AbERP_Date_Support_Ceased FROM C_BPartner WHERE C_BPartner_ID=?", bpId);
		}
		if (ceased != null && ceased.before(p_DateFrom)) {
			return "support ceased " + ceased;
		}
		return null;
	}

	private void applyInvoiceRuleToLatestBooking(int bgId, String invoiceRule, String trxName) {
		int orderId = DB.getSQLValue(trxName,
				"SELECT C_Order_ID FROM C_Order WHERE AbERP_BookingGenerator_ID=? "
						+ "ORDER BY Created DESC, C_Order_ID DESC FETCH FIRST 1 ROW ONLY",
				bgId);
		if (orderId <= 0) {
			return;
		}
		PO order = MTable.get(getCtx(), "C_Order").getPO(orderId, trxName);
		if (order == null || order.get_ID() <= 0) {
			return;
		}
		Object current = order.get_Value("InvoiceRule");
		if (current == null || !invoiceRule.equals(current.toString())) {
			order.set_ValueOfColumn("InvoiceRule", invoiceRule);
			order.saveEx();
		}
	}
}
