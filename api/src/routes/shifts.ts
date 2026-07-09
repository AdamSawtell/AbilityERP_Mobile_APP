import { Router } from "express";
import { z } from "zod";
import { getPayPeriods } from "../db/queries/pay-period";
import {
  applyForShift,
  getMyShiftResponsesForPeriod,
  getMyShiftsForPeriod,
  getOpenShiftsForPeriod,
  recordShiftResponse,
} from "../db/queries/shifts";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

const periodSchema = z.enum(["current", "next"]);
const responseSchema = z.enum(["REQ", "DEC"]);

function parsePeriod(value: unknown): "current" | "next" {
  const parsed = periodSchema.safeParse(value);
  return parsed.success ? parsed.data : "current";
}

router.get("/periods", async (_req, res) => {
  const periods = await getPayPeriods();
  res.json(periods);
});

router.get("/open", async (req, res) => {
  const periodKey = parsePeriod(req.query.period);
  const result = await getOpenShiftsForPeriod(
    periodKey,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  res.json(result);
});

router.get("/responses", async (req, res) => {
  const periodKey = parsePeriod(req.query.period);
  const result = await getMyShiftResponsesForPeriod(
    periodKey,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  res.json(result);
});

router.get("/applications", async (req, res) => {
  const periodKey = parsePeriod(req.query.period);
  const result = await getMyShiftResponsesForPeriod(
    periodKey,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  res.json(result);
});

router.get("/mine", async (req, res) => {
  const periodKey = parsePeriod(req.query.period);
  const result = await getMyShiftsForPeriod(
    periodKey,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  res.json(result);
});

router.post("/:shiftId/response", async (req, res) => {
  const shiftId = Number(req.params.shiftId);
  if (!Number.isFinite(shiftId)) {
    res.status(400).json({ error: "Invalid shift ID" });
    return;
  }

  const parsed = responseSchema.safeParse(req.body?.response);
  if (!parsed.success) {
    res.status(400).json({ error: "Response must be REQ (request) or DEC (decline)" });
    return;
  }

  const result = await recordShiftResponse(
    shiftId,
    parsed.data,
    req.user!.cBPartnerId,
    req.user!.adUserId,
    req.user!.adClientId,
  );

  if (!result.recorded) {
    res.status(409).json({ error: result.message });
    return;
  }

  res.json(result);
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
