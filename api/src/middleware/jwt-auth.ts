import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import type { JwtPayload } from "../types";

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET is not configured");
  }
  return secret;
}

export function signToken(payload: JwtPayload): string {
  return jwt.sign(payload, getJwtSecret(), { expiresIn: "8h" });
}

function normalizeUser(payload: jwt.JwtPayload): JwtPayload {
  return {
    adUserId: Number(payload.adUserId),
    adClientId: Number(payload.adClientId),
    cBPartnerId: Number(payload.cBPartnerId),
    name: String(payload.name ?? ""),
    email: String(payload.email ?? ""),
    roles: Array.isArray(payload.roles) ? payload.roles.map(String) : [],
  };
}

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;

  if (!token) {
    res.status(401).json({ error: "Authentication required" });
    return;
  }

  try {
    const decoded = jwt.verify(token, getJwtSecret()) as jwt.JwtPayload;
    req.user = normalizeUser(decoded);
    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

export function requireSupportWorker(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  if (!req.user?.roles.includes("Support Worker")) {
    res.status(403).json({ error: "Support Worker role required" });
    return;
  }
  next();
}
