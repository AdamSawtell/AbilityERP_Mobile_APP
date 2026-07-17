package com.aberp.activityaudit.process;

/** SAW028 — Open Employee window from Activity Viewer. */
public class OpenActivityEmployee extends OpenActivityLink {

	@Override
	protected LinkType linkType() {
		return LinkType.EMPLOYEE;
	}
}
