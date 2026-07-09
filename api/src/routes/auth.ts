import { Router } from "express";
import { z } from "zod";
import {
  findAdUserByEmail,
  findAdUserByLogin,
  getUserRoles,
  userHasSupportWorkerRole,
} from "../db/queries/auth";
import { requireAuth, signToken } from "../middleware/jwt-auth";
import type { JwtPayload } from "../types";

const router = Router();

const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

const ssoSchema = z.object({
  email: z.string().email(),
  name: z.string().optional(),
});

async function buildTokenForUser(
  user: Awaited<ReturnType<typeof findAdUserByEmail>>,
): Promise<{ token: string; payload: JwtPayload } | { error: string; status: number }> {
  if (!user) {
    return { error: "User not found", status: 404 };
  }
  if (user.islocked === "Y") {
    return { error: "Account is locked", status: 403 };
  }
  if (!user.c_bpartner_id) {
    return { error: "User is not linked to an employee record", status: 403 };
  }

  const hasRole = await userHasSupportWorkerRole(user.ad_user_id);
  if (!hasRole) {
    return { error: "Support Worker role required", status: 403 };
  }

  const roles = await getUserRoles(user.ad_user_id);
  const payload: JwtPayload = {
    adUserId: user.ad_user_id,
    adClientId: user.ad_client_id,
    cBPartnerId: user.c_bpartner_id,
    name: user.name,
    email: user.email ?? "",
    roles,
  };

  return { token: signToken(payload), payload };
}

router.post("/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid login payload" });
    return;
  }

  const { username, password } = parsed.data;
  const user = await findAdUserByLogin(username);

  if (!user || user.password !== password) {
    res.status(401).json({ error: "Invalid username or password" });
    return;
  }

  const result = await buildTokenForUser(user);
  if ("error" in result) {
    res.status(result.status).json({ error: result.error });
    return;
  }

  res.json({ token: result.token, user: result.payload });
});

router.post("/sso", async (req, res) => {
  const parsed = ssoSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid SSO payload" });
    return;
  }

  const user = await findAdUserByEmail(parsed.data.email);
  const result = await buildTokenForUser(user);
  if ("error" in result) {
    res.status(result.status).json({ error: result.error });
    return;
  }

  res.json({ token: result.token, user: result.payload });
});

router.get("/me", requireAuth, (req, res) => {
  res.json({ user: req.user });
});

export default router;
