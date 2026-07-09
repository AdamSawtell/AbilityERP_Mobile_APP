import { Router } from "express";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();

router.use(requireAuth, requireSupportWorker);

router.get("/", (_req, res) => {
  res.json({ items: [], message: "Credentials endpoint — implementation pending" });
});

router.get("/id-card", (_req, res) => {
  res.json({ message: "Digital worker ID — implementation pending" });
});

export default router;
