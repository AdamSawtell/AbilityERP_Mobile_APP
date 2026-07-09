import { Router } from "express";
import { z } from "zod";
import { createLeaveRequest, getLeaveRecords } from "../db/queries/leave";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

const leaveSchema = z.object({
  startDate: z.string().min(1),
  endDate: z.string().min(1),
  note: z.string().optional(),
});

router.get("/", async (req, res) => {
  const items = await getLeaveRecords(req.user!.cBPartnerId);
  res.json({ items });
});

router.post("/", async (req, res) => {
  const parsed = leaveSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid leave request" });
    return;
  }

  const result = await createLeaveRequest(
    req.user!.cBPartnerId,
    req.user!.adUserId,
    req.user!.adClientId,
    parsed.data,
  );

  res.status(201).json(result);
});

export default router;
