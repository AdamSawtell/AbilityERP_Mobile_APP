"use client";

import { useEffect, useState } from "react";

const DISMISS_KEY = "aberp-pwa-install-dismissed";

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
};

function isStandalone(): boolean {
  if (typeof window === "undefined") return false;
  const media = window.matchMedia("(display-mode: standalone)").matches;
  const iosStandalone =
    "standalone" in navigator &&
    (navigator as Navigator & { standalone?: boolean }).standalone === true;
  return media || Boolean(iosStandalone);
}

function isIosSafari(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent;
  const ios = /iPad|iPhone|iPod/.test(ua);
  const webkit = /WebKit/.test(ua);
  const other = /CriOS|FxiOS|EdgiOS|OPiOS/.test(ua);
  return ios && webkit && !other;
}

export default function PwaClient() {
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null);
  const [mode, setMode] = useState<"hidden" | "chromium" | "ios">("hidden");

  useEffect(() => {
    if ("serviceWorker" in navigator) {
      void navigator.serviceWorker.register("/sw.js").catch(() => {
        /* ignore — SW optional on unsupported hosts */
      });
    }

    if (localStorage.getItem(DISMISS_KEY) === "1" || isStandalone()) {
      return;
    }

    const onBeforeInstall = (event: Event) => {
      event.preventDefault();
      setDeferred(event as BeforeInstallPromptEvent);
      setMode("chromium");
    };
    window.addEventListener("beforeinstallprompt", onBeforeInstall);

    if (isIosSafari()) {
      setMode("ios");
    }

    return () => {
      window.removeEventListener("beforeinstallprompt", onBeforeInstall);
    };
  }, []);

  function dismiss() {
    localStorage.setItem(DISMISS_KEY, "1");
    setMode("hidden");
    setDeferred(null);
  }

  async function install() {
    if (!deferred) return;
    await deferred.prompt();
    await deferred.userChoice;
    dismiss();
  }

  if (mode === "hidden") return null;

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-20 z-20 flex justify-center px-3 sm:bottom-4">
      <div className="pointer-events-auto flex w-full max-w-lg items-start gap-3 border border-blue-200 bg-blue-50 px-3 py-2.5 text-sm text-blue-950 shadow-sm">
        <div className="min-w-0 flex-1">
          {mode === "chromium" ? (
            <p>
              Install <span className="font-medium">AbilityERP</span> on your home screen for
              faster access.
            </p>
          ) : (
            <p>
              On iPhone: tap <span className="font-medium">Share</span>, then{" "}
              <span className="font-medium">Add to Home Screen</span>.
            </p>
          )}
        </div>
        <div className="flex shrink-0 items-center gap-2">
          {mode === "chromium" ? (
            <button
              type="button"
              onClick={() => void install()}
              className="rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-semibold text-white"
            >
              Install
            </button>
          ) : null}
          <button
            type="button"
            onClick={dismiss}
            className="rounded-lg px-2 py-1.5 text-xs font-medium text-blue-800"
            aria-label="Dismiss install hint"
          >
            Not now
          </button>
        </div>
      </div>
    </div>
  );
}
