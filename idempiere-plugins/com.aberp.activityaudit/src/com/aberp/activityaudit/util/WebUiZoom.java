package com.aberp.activityaudit.util;

import java.lang.reflect.Method;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MQuery;
import org.compiere.util.CLogger;
import org.compiere.util.Env;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;

/**
 * SAW028 / SAW027 — WebUI AEnv.zoom helper (window + MQuery).
 */
public final class WebUiZoom {

	private static final CLogger log = CLogger.getCLogger(WebUiZoom.class);
	private static final String AENV = "org.adempiere.webui.apps.AEnv";

	private WebUiZoom() {
	}

	public static void zoomWindowAsync(int windowId, String keyColumn, int recordId, String okLabel)
			throws Exception {
		if (windowId <= 0) {
			throw new AdempiereException("Target window not found");
		}
		if (recordId <= 0) {
			throw new AdempiereException("Nothing to open");
		}
		final int win = windowId;
		final int rec = recordId;
		final String col = keyColumn;
		Class<?> aenv = loadAEnv();
		Method async = aenv.getMethod("executeAsyncDesktopTask", Runnable.class);
		Runnable task = new Runnable() {
			@Override
			public void run() {
				try {
					zoomWindow(aenv, win, col, rec);
				} catch (AdempiereException e) {
					throw e;
				} catch (Exception e) {
					Throwable cause = e.getCause() != null ? e.getCause() : e;
					throw new RuntimeException(cause);
				}
			}
		};
		async.invoke(null, task);
		log.log(Level.INFO, okLabel + " " + recordId);
	}

	/**
	 * Always zoom a named window + query. Never fall back to table/MQuery-only zoom
	 * (that can open Business Partner or User instead of Client / Employee / Support Location).
	 */
	public static void zoomWindow(Class<?> aenv, int windowId, String keyColumn, int recordId)
			throws Exception {
		MQuery query = MQuery.getEqualQuery(keyColumn, recordId);
		query.setRecordCount(1);
		Method zoomWin = aenv.getMethod("zoom", int.class, MQuery.class);
		zoomWin.invoke(null, Integer.valueOf(windowId), query);
	}

	public static Class<?> loadAEnv() throws ClassNotFoundException {
		try {
			ClassLoader cl = Thread.currentThread().getContextClassLoader();
			if (cl != null) {
				return Class.forName(AENV, true, cl);
			}
		} catch (ClassNotFoundException ignored) {
			// next
		}
		try {
			return Class.forName(AENV);
		} catch (ClassNotFoundException ignored) {
			// OSGi
		}

		Bundle self = FrameworkUtil.getBundle(WebUiZoom.class);
		if (self == null) {
			self = FrameworkUtil.getBundle(Env.class);
		}
		if (self != null && self.getBundleContext() != null) {
			for (Bundle b : self.getBundleContext().getBundles()) {
				String sn = b.getSymbolicName();
				if (sn == null) {
					continue;
				}
				String lower = sn.toLowerCase();
				if (lower.contains("adempiere.ui.zk") || lower.equals("org.adempiere.ui.zk")
						|| lower.contains("webui") || lower.contains("zk.ui")
						|| lower.contains("adempiere.ui")) {
					Class<?> c = tryLoad(b);
					if (c != null) {
						return c;
					}
				}
			}
			for (Bundle b : self.getBundleContext().getBundles()) {
				if (b.getState() != Bundle.ACTIVE) {
					continue;
				}
				Class<?> c = tryLoad(b);
				if (c != null) {
					return c;
				}
			}
		}
		throw new ClassNotFoundException(AENV);
	}

	private static Class<?> tryLoad(Bundle b) {
		try {
			return b.loadClass(AENV);
		} catch (ClassNotFoundException | IllegalStateException ignored) {
			return null;
		}
	}
}
