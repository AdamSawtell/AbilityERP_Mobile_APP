package com.aberp.activityaudit.process;

/** SAW028 — Open Support Location window from Activity Viewer. */
public class OpenActivitySupportLocation extends OpenActivityLink {

	@Override
	protected LinkType linkType() {
		return LinkType.SUPPORT_LOCATION;
	}
}