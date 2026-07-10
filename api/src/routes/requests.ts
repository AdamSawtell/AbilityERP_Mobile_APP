import { Router } from "express";
import { z } from "zod";
import {
  addTaskMessage,
  closeRosteringChat,
  createStandaloneRequest,
  getRosteringChatState,
  getTaskMessages,
  getWorkerTask,
  getWorkerTasks,
  startRosteringChat,
} from "../db/queries/requests";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

const messageSchema = z.object({
  body: z.string().min(1).max(2000),
});

const createSchema = z.object({
  summary: z.string().max(255).optional(),
  body: z.string().min(1).max(2000),
});

router.get("/", async (req, res) => {
  const items = await getWorkerTasks(req.user!.adUserId, req.user!.cBPartnerId);
  res.json({ items });
});

router.get("/chat", async (req, res) => {
  const { task, messages } = await getRosteringChatState(
    req.user!.adUserId,
    req.user!.cBPartnerId,
    req.user!.adClientId,
  );
  res.json({ task, messages });
});

router.post("/chat", async (req, res) => {
  const parsed = messageSchema.safeParse(req.body);
  const firstMessage = parsed.success ? parsed.data.body : undefined;

  try {
    const task = await startRosteringChat(
      req.user!.adUserId,
      req.user!.cBPartnerId,
      req.user!.adClientId,
      firstMessage,
    );
    const messages = await getTaskMessages(task.id, req.user!.adUserId, req.user!.cBPartnerId);
    res.json({ task, messages });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to start chat";
    res.status(400).json({ error: message });
  }
});

router.post("/", async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Message body is required" });
    return;
  }

  try {
    const result = await createStandaloneRequest(
      req.user!.adUserId,
      req.user!.cBPartnerId,
      req.user!.adClientId,
      parsed.data,
    );
    res.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to create request";
    res.status(400).json({ error: message });
  }
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

router.post("/:requestId/close", async (req, res) => {
  const requestId = Number(req.params.requestId);
  if (!Number.isFinite(requestId)) {
    res.status(400).json({ error: "Invalid request ID" });
    return;
  }

  try {
    const task = await closeRosteringChat(
      requestId,
      req.user!.adUserId,
      req.user!.cBPartnerId,
    );
    if (!task) {
      res.status(404).json({ error: "Request not found" });
      return;
    }
    res.json({ task });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to close chat";
    res.status(400).json({ error: message });
  }
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
