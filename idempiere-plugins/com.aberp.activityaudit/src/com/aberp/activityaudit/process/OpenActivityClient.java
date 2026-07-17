package com.aberp.activityaudit.process;

/** SAW028 — Open Client window from Activity Viewer. */
public class OpenActivityClient extends OpenActivityLink {

	@Override
	protected LinkType linkType() {
		return LinkType.CLIENT;
	}
}
