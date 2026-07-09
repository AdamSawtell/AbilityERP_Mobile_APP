import { Router } from "express";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();

router.use(requireAuth, requireSupportWorker);

router.get("/", (_req, res) => {
  res.json({ items: [], message: "Leave list — implementation pending" });
});

router.post("/", (_req, res) => {
  res.status(501).json({ error: "Leave request — implementation pending" });
});

export default router;
