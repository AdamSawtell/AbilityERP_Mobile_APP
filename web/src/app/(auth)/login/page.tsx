"use client";

import Image from "next/image";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handlePasswordLogin(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error ?? "Login failed");
      }

      router.replace("/open-shifts");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  function handleMicrosoftLogin() {
    window.location.href = "/api/auth/ms-start";
  }

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-lg flex-col justify-center bg-gray-50 px-4 py-8">
      <div className="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col items-center text-center">
          <Image
            src="/icons/icon-192.png"
            alt="AbilityERP"
            width={72}
            height={72}
            className="h-[72px] w-[72px] rounded-2xl"
            priority
          />
          <h1 className="mt-4 text-2xl font-semibold text-gray-900">Worker sign in</h1>
        </div>
        <p className="mt-2 text-sm text-gray-600">
          Support workers only. Same experience as AbilityVua worker app — powered by AbilityERP.
        </p>

        <button
          type="button"
          onClick={handleMicrosoftLogin}
          className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-[#2f2f2f] px-4 py-3 text-sm font-medium text-white"
        >
          Sign in with Microsoft
        </button>

        <div className="my-6 flex items-center gap-3">
          <div className="h-px flex-1 bg-gray-200" />
          <span className="text-xs text-gray-400">or use ERP login</span>
          <div className="h-px flex-1 bg-gray-200" />
        </div>

        <form className="space-y-4" onSubmit={handlePasswordLogin}>
          <div>
            <label htmlFor="username" className="block text-sm font-medium text-gray-700">
              Username or email
            </label>
            <input
              id="username"
              type="text"
              autoComplete="username"
              required
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm outline-none ring-blue-500 focus:ring-2"
            />
          </div>
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700">
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm outline-none ring-blue-500 focus:ring-2"
            />
          </div>

          {error ? <p className="text-sm text-red-600">{error}</p> : null}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-medium text-white disabled:opacity-60"
          >
            {loading ? "Signing in…" : "Sign in"}
          </button>
        </form>
      </div>
    </div>
  );
}
