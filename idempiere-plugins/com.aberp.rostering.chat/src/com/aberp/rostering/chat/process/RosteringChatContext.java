package com.aberp.rostering.chat.process;

import java.util.Properties;

import org.compiere.process.ProcessInfo;
import org.compiere.util.Env;
import org.compiere.util.Util;

/** Resolves WebUI context for Rostering Chat button processes. */
final class RosteringChatContext {
	private static final int WINDOW_SCAN_MAX = 512;

	private RosteringChatContext() {
	}

	static int resolveRequestId(Properties ctx, ProcessInfo processInfo) {
		if (processInfo != null && processInfo.getRecord_ID() > 0) {
			return processInfo.getRecord_ID();
		}

		int requestId = Env.getContextAsInt(ctx, "#R_Request_ID");
		if (requestId > 0) {
			return requestId;
		}

		requestId = Env.getContextAsInt(ctx, "R_Request_ID");
		if (requestId > 0) {
			return requestId;
		}

		requestId = Env.getContextAsInt(ctx, "#Record_ID");
		if (requestId > 0) {
			return requestId;
		}

		// WebUI often stores current record as windowNo|R_Request_ID
		for (int windowNo = 0; windowNo < WINDOW_SCAN_MAX; windowNo++) {
			requestId = Env.getContextAsInt(ctx, windowNo, "R_Request_ID", true);
			if (requestId > 0) {
				return requestId;
			}
			requestId = Env.getContextAsInt(ctx, windowNo, "R_Request_ID", false);
			if (requestId > 0) {
				return requestId;
			}
			// Some builds use TableName_ID only after tab activation
			requestId = Env.getContextAsInt(ctx, windowNo, "R_Request.R_Request_ID", false);
			if (requestId > 0) {
				return requestId;
			}
		}

		return 0;
	}

	static String getDraftReply(Properties ctx) {
		return getDraftReply(ctx, 0);
	}

	/** Prefer draft from the window that holds this request (avoids stale other tabs). */
	static String getDraftReply(Properties ctx, int requestId) {
		if (requestId > 0) {
			for (int windowNo = 0; windowNo < WINDOW_SCAN_MAX; windowNo++) {
				int winReq = Env.getContextAsInt(ctx, windowNo, "R_Request_ID", false);
				if (winReq != requestId) {
					winReq = Env.getContextAsInt(ctx, windowNo, "R_Request_ID", true);
				}
				if (winReq != requestId) {
					continue;
				}
				String draft = Env.getContext(ctx, windowNo, "AbERP_RosteringReply", true);
				if (!Util.isEmpty(draft)) {
					return draft.trim();
				}
				draft = Env.getContext(ctx, windowNo, "AbERP_RosteringReply", false);
				if (!Util.isEmpty(draft)) {
					return draft.trim();
				}
			}
		}

		String draft = Env.getContext(ctx, "#AbERP_RosteringReply");
		if (!Util.isEmpty(draft)) {
			return draft.trim();
		}

		draft = Env.getContext(ctx, "AbERP_RosteringReply");
		if (!Util.isEmpty(draft)) {
			return draft.trim();
		}

		for (int windowNo = 0; windowNo < WINDOW_SCAN_MAX; windowNo++) {
			draft = Env.getContext(ctx, windowNo, "AbERP_RosteringReply", true);
			if (!Util.isEmpty(draft)) {
				return draft.trim();
			}
			draft = Env.getContext(ctx, windowNo, "AbERP_RosteringReply", false);
			if (!Util.isEmpty(draft)) {
				return draft.trim();
			}
		}

		return "";
	}
}
