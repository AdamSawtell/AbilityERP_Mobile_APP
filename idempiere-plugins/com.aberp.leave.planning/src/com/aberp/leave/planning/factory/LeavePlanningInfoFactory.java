package com.aberp.leave.planning.factory;

import org.adempiere.webui.factory.IInfoFactory;
import org.adempiere.webui.info.InfoWindow;
import org.adempiere.webui.panel.InfoPanel;
import org.compiere.model.GridField;
import org.compiere.model.Lookup;
import org.compiere.model.MInfoWindow;
import org.compiere.model.MTable;
import org.compiere.util.Env;

import com.aberp.leave.planning.info.LeavePlanningInfoWindow;

/**
 * Returns {@link LeavePlanningInfoWindow} for Leave Planning Info UU.
 * Higher service.ranking so InfoManager prefers this over DefaultInfoFactory.
 */
public class LeavePlanningInfoFactory implements IInfoFactory {

	@Override
	public InfoPanel create(int windowNo, String tableName, String keyColumn, String value,
			boolean multiSelection, String whereClause, int AD_InfoWindow_ID, boolean lookup) {
		if (!LeavePlanningInfoWindow.matchesInfoWindow(AD_InfoWindow_ID)) {
			return null;
		}
		return new LeavePlanningInfoWindow(windowNo, tableName, keyColumn, value, multiSelection, whereClause,
				AD_InfoWindow_ID, lookup);
	}

	@Override
	public InfoPanel create(Lookup lookup, GridField field, String tableName, String keyColumn,
			String queryValue, boolean multiSelection, String whereClause, int AD_InfoWindow_ID) {
		if (!LeavePlanningInfoWindow.matchesInfoWindow(AD_InfoWindow_ID)) {
			return null;
		}
		int windowNo = 0;
		if (field != null) {
			windowNo = field.getGridTab() != null ? field.getGridTab().getWindowNo() : field.getWindowNo();
		}
		return new LeavePlanningInfoWindow(windowNo, tableName, keyColumn, queryValue, multiSelection, whereClause,
				AD_InfoWindow_ID, true, field);
	}

	@Override
	public InfoWindow create(int AD_InfoWindow_ID) {
		if (!LeavePlanningInfoWindow.matchesInfoWindow(AD_InfoWindow_ID)) {
			return null;
		}
		MInfoWindow miw = MInfoWindow.getInfoWindow(AD_InfoWindow_ID);
		if (miw == null) {
			return null;
		}
		String tableName = MTable.getTableName(Env.getCtx(), miw.getAD_Table_ID());
		String keyColumn = tableName + "_ID";
		return new LeavePlanningInfoWindow(0, tableName, keyColumn, "", false, "", AD_InfoWindow_ID, false);
	}
}
