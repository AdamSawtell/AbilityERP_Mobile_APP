import { Router } from "express";
import { z } from "zod";
import {
  addTaskMessage,
  getTaskByShiftId,
  getTaskMessages,
  getWorkerTask,
  getWorkerTasks,
} from "../db/queries/requests";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

const messageSchema = z.object({
  body: z.string().min(1).max(2000),
});

router.get("/", async (req, res) => {
  const items = await getWorkerTasks(req.user!.adUserId, req.user!.cBPartnerId);
  res.json({ items });
});

router.get("/by-shift/:shiftId", async (req, res) => {
  const shiftId = Number(req.params.shiftId);
  if (!Number.isFinite(shiftId)) {
    res.status(400).json({ error: "Invalid shift ID" });
    return;
  }

  const task = await getTaskByShiftId(shiftId, req.user!.adUserId, req.user!.cBPartnerId);
  if (!task) {
    res.status(404).json({ error: "No request found for this shift" });
    return;
  }
  res.json(task);
});

router.get("/:requestId", async (req, res) => {
  const requestId = Number(req.params.requestId);
  if (!Number.isFinite(requestId)) {
    res.status(400).json({ error: "Invalid request ID" });
    return;
  }

  const task = await getWorkerTask(requestId, req.user!.adUserId, req.user!.cBPartnerId);
  if (!task) {
    res.status(404).json({ error: "Request not found" });
    return;
  }

  const messages = await getTaskMessages(requestId, req.user!.adUserId, req.user!.cBPartnerId);
  res.json({ task, messages });
});

router.post("/:requestId/messages", async (req, res) => {
  const requestId = Number(req.params.requestId);
  if (!Number.isFinite(requestId)) {
    res.status(400).json({ error: "Invalid request ID" });
    return;
  }

  const parsed = messageSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Message body is required" });
    return;
  }

  try {
    const result = await addTaskMessage(
      requestId,
      req.user!.adUserId,
      req.user!.cBPartnerId,
      req.user!.adClientId,
      parsed.data.body,
    );
    if (!result) {
      res.status(404).json({ error: "Request not found" });
      return;
    }
    res.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to send message";
    res.status(400).json({ error: message });
  }
});

export default router;
