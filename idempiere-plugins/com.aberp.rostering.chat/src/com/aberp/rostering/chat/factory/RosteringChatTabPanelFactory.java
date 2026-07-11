package com.aberp.rostering.chat.factory;

import org.adempiere.webui.adwindow.IADTabpanel;
import org.adempiere.webui.factory.IADTabPanelFactory;

import com.aberp.rostering.chat.webui.RosteringChatTabPanel;

public class RosteringChatTabPanelFactory implements IADTabPanelFactory {

	@Override
	public IADTabpanel getInstance(String type) {
		if (type != null && RosteringChatTabPanel.TAB_TYPE.equalsIgnoreCase(type.trim())) {
			return new RosteringChatTabPanel();
		}
		return null;
	}
}
