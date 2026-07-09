import { Router } from "express";
import { applyForShift, getMyShifts, getOpenShifts } from "../db/queries/shifts";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

router.get("/open", async (_req, res) => {
  const items = await getOpenShifts();
  res.json({ items });
});

router.get("/mine", async (req, res) => {
  const items = await getMyShifts(req.user!.cBPartnerId, req.user!.adUserId);
  res.json({ items });
});

router.post("/:shiftId/apply", async (req, res) => {
  const shiftId = Number(req.params.shiftId);
  if (!Number.isFinite(shiftId)) {
    res.status(400).json({ error: "Invalid shift ID" });
    return;
  }

  const result = await applyForShift(
    shiftId,
    req.user!.cBPartnerId,
    req.user!.adUserId,
    req.user!.adClientId,
  );

  if (!result.applied) {
    res.status(409).json({ error: result.message });
    return;
  }

  res.json(result);
});

export default router;
