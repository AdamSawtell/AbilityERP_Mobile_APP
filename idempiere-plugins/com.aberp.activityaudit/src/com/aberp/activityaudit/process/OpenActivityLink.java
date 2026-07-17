package com.aberp.activityaudit.process;

import java.util.Enumeration;
import java.util.Properties;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Env;

import com.aberp.activityaudit.util.WebUiZoom;

/**
 * SAW028 — Open Client / Employee / Support Location windows from Activity Viewer.
 * Never zooms generic Business Partner or User/Contact.
 */
public abstract class OpenActivityLink extends SvrProcess {

	static final String CLIENT_WINDOW_UU = "f1c9a83a-6589-49b8-a797-458f45e1b8e2";
	static final String EMPLOYEE_WINDOW_UU = "a826f1f8-3097-4d96-a83a-0bd9e1bb48ae";
	static final String SUPPORT_LOCATION_WINDOW_UU = "6ef3c558-3ec8-4f0c-be40-89f35d8acebf";

	enum LinkType {
		CLIENT, EMPLOYEE, SUPPORT_LOCATION
	}

	protected abstract LinkType linkType();

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		int activityId = resolveActivityId();
		if (activityId <= 0) {
			throw new AdempiereException("Select an Activity first");
		}

		LinkType type = linkType();
		try {
			switch (type) {
			case CLIENT:
				return openClient(activityId);
			case EMPLOYEE:
				return openEmployee(activityId);
			case SUPPORT_LOCATION:
				return openSupportLocation(activityId);
			default:
				throw new AdempiereException("Unknown link type");
			}
		} catch (ClassNotFoundException e) {
			throw new AdempiereException("WebUI zoom unavailable for " + type);
		} catch (AdempiereException e) {
			throw e;
		} catch (Exception e) {
			log.log(Level.SEVERE, "OpenActivityLink", e);
			Throwable cause = e.getCause() != null ? e.getCause() : e;
			throw new AdempiereException("Could not open link: " + cause.getMessage());
		}
	}

	private String openClient(int activityId) throws Exception {
		int bpId = resolveClientBpId(activityId);
		if (bpId <= 0) {
			throw new AdempiereException("No Client linked on this Activity");
		}
		int windowId = resolveWindowId(CLIENT_WINDOW_UU, "Client");
		WebUiZoom.zoomWindowAsync(windowId, "C_BPartner_ID", bpId, "Opened Client");
		return "@OK@ Opened Client " + bpId;
	}

	private String openEmployee(int activityId) throws Exception {
		int bpId = resolveEmployeeBpId(activityId);
		if (bpId <= 0) {
			throw new AdempiereException("No Employee linked on this Activity");
		}
		int windowId = resolveWindowId(EMPLOYEE_WINDOW_UU, "Employee");
		WebUiZoom.zoomWindowAsync(windowId, "C_BPartner_ID", bpId, "Opened Employee");
		return "@OK@ Opened Employee " + bpId;
	}

	private String openSupportLocation(int activityId) throws Exception {
		int locId = DB.getSQLValue(get_TrxName(),
				"SELECT COALESCE(AbERP_Support_Location_ID,0) FROM C_ContactActivity "
						+ "WHERE C_ContactActivity_ID=?",
				activityId);
		if (locId <= 0) {
			throw new AdempiereException("No Support Location linked on this Activity");
		}
		int windowId = resolveWindowId(SUPPORT_LOCATION_WINDOW_UU, "Support Location");
		WebUiZoom.zoomWindowAsync(windowId, "AbERP_Support_Location_ID", locId,
				"Opened Support Location");
		return "@OK@ Opened Support Location " + locId;
	}

	/** Client BP: support-receiver when column exists, else IsCustomer and not employee. */
	static int resolveClientBpId(String trx, int activityId) {
		boolean hasReceiver = DB.getSQLValue(trx,
				"SELECT COUNT(*) FROM AD_Column c JOIN AD_Table t ON t.AD_Table_ID=c.AD_Table_ID "
						+ "WHERE t.TableName='C_BPartner' AND c.ColumnName='AbERP_IsSupport_Receiver'") > 0;
		String sql;
		if (hasReceiver) {
			sql = "SELECT a.C_BPartner_ID FROM C_ContactActivity a"
					+ " INNER JOIN C_BPartner bp ON bp.C_BPartner_ID=a.C_BPartner_ID"
					+ " WHERE a.C_ContactActivity_ID=? AND a.C_BPartner_ID>0"
					+ " AND bp.AbERP_IsSupport_Receiver='Y' AND bp.IsActive='Y'";
		} else {
			sql = "SELECT a.C_BPartner_ID FROM C_ContactActivity a"
					+ " INNER JOIN C_BPartner bp ON bp.C_BPartner_ID=a.C_BPartner_ID"
					+ " WHERE a.C_ContactActivity_ID=? AND a.C_BPartner_ID>0"
					+ " AND bp.IsCustomer='Y' AND COALESCE(bp.IsEmployee,'N')='N' AND bp.IsActive='Y'";
		}
		return DB.getSQLValue(trx, sql, activityId);
	}

	private int resolveClientBpId(int activityId) {
		return resolveClientBpId(get_TrxName(), activityId);
	}

	/**
	 * Employee BP: Staff BP (IsEmployee), else AD_User→BP (IsEmployee), else AbERP_User_BP_ID.
	 */
	static int resolveEmployeeBpId(String trx, int activityId) {
		int staff = DB.getSQLValue(trx,
				"SELECT a.C_BPartner_Staff_ID FROM C_ContactActivity a"
						+ " INNER JOIN C_BPartner bp ON bp.C_BPartner_ID=a.C_BPartner_Staff_ID"
						+ " WHERE a.C_ContactActivity_ID=? AND COALESCE(a.C_BPartner_Staff_ID,0)>0"
						+ " AND bp.IsEmployee='Y' AND bp.IsActive='Y'",
				activityId);
		if (staff > 0) {
			return staff;
		}
		int fromUser = DB.getSQLValue(trx,
				"SELECT u.C_BPartner_ID FROM C_ContactActivity a"
						+ " INNER JOIN AD_User u ON u.AD_User_ID=a.AD_User_ID"
						+ " INNER JOIN C_BPartner bp ON bp.C_BPartner_ID=u.C_BPartner_ID"
						+ " WHERE a.C_ContactActivity_ID=? AND COALESCE(a.AD_User_ID,0)>0"
						+ " AND bp.IsEmployee='Y' AND bp.IsActive='Y' AND u.IsActive='Y'",
				activityId);
		if (fromUser > 0) {
			return fromUser;
		}
		return DB.getSQLValue(trx,
				"SELECT a.AbERP_User_BP_ID FROM C_ContactActivity a"
						+ " INNER JOIN C_BPartner bp ON bp.C_BPartner_ID=a.AbERP_User_BP_ID"
						+ " WHERE a.C_ContactActivity_ID=? AND COALESCE(a.AbERP_User_BP_ID,0)>0"
						+ " AND bp.IsEmployee='Y' AND bp.IsActive='Y'",
				activityId);
	}

	private int resolveEmployeeBpId(int activityId) {
		return resolveEmployeeBpId(get_TrxName(), activityId);
	}

	private int resolveWindowId(String uu, String name) {
		int id = DB.getSQLValue(null,
				"SELECT AD_Window_ID FROM AD_Window WHERE AD_Window_UU=? OR Name=?", uu, name);
		if (id <= 0) {
			throw new AdempiereException(name + " window not found");
		}
		return id;
	}

	private int resolveActivityId() {
		int id = getRecord_ID();
		if (isActivity(id)) {
			return id;
		}
		Properties ctx = getCtx();
		int ctxId = Env.getContextAsInt(ctx, "C_ContactActivity_ID");
		if (isActivity(ctxId)) {
			return ctxId;
		}
		for (int w = 0; w < 20; w++) {
			ctxId = Env.getContextAsInt(ctx, w, "C_ContactActivity_ID");
			if (isActivity(ctxId)) {
				return ctxId;
			}
		}
		Enumeration<?> keys = ctx.keys();
		while (keys.hasMoreElements()) {
			Object key = keys.nextElement();
			if (key == null) {
				continue;
			}
			String k = key.toString();
			if (k.endsWith("|C_ContactActivity_ID") || k.equals("C_ContactActivity_ID")) {
				try {
					int v = Integer.parseInt(String.valueOf(ctx.get(key)));
					if (isActivity(v)) {
						return v;
					}
				} catch (Exception ignored) {
					// next
				}
			}
		}
		return id > 0 ? id : 0;
	}

	private boolean isActivity(int id) {
		if (id <= 0) {
			return false;
		}
		Integer exists = DB.getSQLValue(get_TrxName(),
				"SELECT C_ContactActivity_ID FROM C_ContactActivity WHERE C_ContactActivity_ID=?",
				id);
		return exists != null && exists.intValue() > 0;
	}
}
