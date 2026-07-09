import { Router } from "express";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();

router.use(requireAuth, requireSupportWorker);

router.get("/current", (_req, res) => {
  res.json({ items: [], message: "Current roster — implementation pending" });
});

router.get("/master", (_req, res) => {
  res.json({ items: [], message: "Master roster — implementation pending" });
});

export default router;
