package com.aberp.rostering.staffinfo.factory;

import org.adempiere.webui.factory.IInfoFactory;
import org.adempiere.webui.info.InfoWindow;
import org.adempiere.webui.panel.InfoPanel;
import org.compiere.model.GridField;
import org.compiere.model.Lookup;
import org.compiere.model.MInfoWindow;
import org.compiere.model.MTable;
import org.compiere.util.Env;
import com.aberp.rostering.staffinfo.info.StaffRosteringInfoWindow;

/**
 * Returns {@link StaffRosteringInfoWindow} for the Staff Rostering Info UU.
 * Higher service.ranking so InfoManager prefers this over DefaultInfoFactory.
 */
public class StaffRosteringInfoFactory implements IInfoFactory {

	@Override
	public InfoPanel create(int windowNo, String tableName, String keyColumn, String value,
			boolean multiSelection, String whereClause, int AD_InfoWindow_ID, boolean lookup) {
		if (!StaffRosteringInfoWindow.matchesInfoWindow(AD_InfoWindow_ID)) {
			return null;
		}
		return new StaffRosteringInfoWindow(windowNo, tableName, keyColumn, value, multiSelection, whereClause,
				AD_InfoWindow_ID, lookup);
	}

	@Override
	public InfoPanel create(Lookup lookup, GridField field, String tableName, String keyColumn,
			String queryValue, boolean multiSelection, String whereClause, int AD_InfoWindow_ID) {
		if (!StaffRosteringInfoWindow.matchesInfoWindow(AD_InfoWindow_ID)) {
			return null;
		}
		int windowNo = 0;
		if (field != null) {
			windowNo = field.getGridTab() != null ? field.getGridTab().getWindowNo() : field.getWindowNo();
		}
		return new StaffRosteringInfoWindow(windowNo, tableName, keyColumn, queryValue, multiSelection, whereClause,
				AD_InfoWindow_ID, true, field);
	}

	@Override
	public InfoWindow create(int AD_InfoWindow_ID) {
		if (!StaffRosteringInfoWindow.matchesInfoWindow(AD_InfoWindow_ID)) {
			return null;
		}
		MInfoWindow miw = MInfoWindow.getInfoWindow(AD_InfoWindow_ID);
		if (miw == null) {
			return null;
		}
		String tableName = MTable.getTableName(Env.getCtx(), miw.getAD_Table_ID());
		String keyColumn = tableName + "_ID";
		return new StaffRosteringInfoWindow(0, tableName, keyColumn, "", false, "", AD_InfoWindow_ID, false);
	}
}
