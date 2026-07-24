import { Router } from "express";
import { z } from "zod";
import {
  createActivity,
  getCarePlan,
  getClientDetail,
  listActivities,
  listMyClients,
} from "../db/queries/clients";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

const activityBodySchema = z.object({
  description: z.string().min(1).max(2000),
  comments: z.string().max(8000).optional(),
  type: z.string().min(1).max(40).optional(),
});

function parseClientId(raw: string): number | null {
  const id = Number(raw);
  return Number.isFinite(id) ? id : null;
}

router.get("/", async (req, res) => {
  const items = await listMyClients(req.user!.cBPartnerId, req.user!.adUserId);
  res.json({ items });
});

router.get("/:clientId", async (req, res) => {
  const clientId = parseClientId(req.params.clientId);
  if (clientId === null) {
    res.status(400).json({ error: "Invalid client ID" });
    return;
  }

  const client = await getClientDetail(
    clientId,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  if (!client) {
    res.status(404).json({ error: "Client not found" });
    return;
  }

  res.json({ client });
});

router.get("/:clientId/care-plan", async (req, res) => {
  const clientId = parseClientId(req.params.clientId);
  if (clientId === null) {
    res.status(400).json({ error: "Invalid client ID" });
    return;
  }

  const carePlan = await getCarePlan(
    clientId,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  // null carePlan can mean no plan OR no access — distinguish via detail probe only when needed
  if (carePlan === null) {
    const client = await getClientDetail(
      clientId,
      req.user!.cBPartnerId,
      req.user!.adUserId,
    );
    if (!client) {
      res.status(404).json({ error: "Client not found" });
      return;
    }
  }
  res.json({ carePlan });
});

router.get("/:clientId/activities", async (req, res) => {
  const clientId = parseClientId(req.params.clientId);
  if (clientId === null) {
    res.status(400).json({ error: "Invalid client ID" });
    return;
  }

  const items = await listActivities(
    clientId,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  if (items === null) {
    res.status(404).json({ error: "Client not found" });
    return;
  }

  res.json({ items });
});

router.post("/:clientId/activities", async (req, res) => {
  const clientId = parseClientId(req.params.clientId);
  if (clientId === null) {
    res.status(400).json({ error: "Invalid client ID" });
    return;
  }

  const parsed = activityBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Description is required" });
    return;
  }

  try {
    const activity = await createActivity(
      clientId,
      req.user!.cBPartnerId,
      req.user!.adUserId,
      req.user!.adClientId,
      parsed.data,
    );
    if (!activity) {
      res.status(404).json({ error: "Client not found" });
      return;
    }
    res.status(201).json({ activity });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Create failed";
    res.status(400).json({ error: message });
  }
});

export default router;
