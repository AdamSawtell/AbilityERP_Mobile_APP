import { Router } from "express";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();

router.use(requireAuth, requireSupportWorker);

router.get("/", (_req, res) => {
  res.json({ items: [], message: "Profile endpoint — implementation pending" });
});

router.put("/", (_req, res) => {
  res.status(501).json({ error: "Profile update — implementation pending" });
});

export default router;
