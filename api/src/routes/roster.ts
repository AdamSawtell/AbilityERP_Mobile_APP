import { Router } from "express";
import { getCurrentRoster, getMasterRoster } from "../db/queries/roster";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

router.get("/current", async (_req, res) => {
  const items = await getCurrentRoster();
  res.json({ items });
});

router.get("/master", async (_req, res) => {
  const items = await getMasterRoster();
  res.json({ items });
});

export default router;
