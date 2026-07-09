import { Router } from "express";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();

router.use(requireAuth, requireSupportWorker);

router.get("/open", (_req, res) => {
  res.json({ items: [], message: "Available shifts — implementation pending" });
});

router.get("/mine", (_req, res) => {
  res.json({ items: [], message: "My schedule — implementation pending" });
});

router.post("/:shiftId/apply", (_req, res) => {
  res.status(501).json({ error: "Apply for shift — implementation pending" });
});

export default router;
