import { Router } from "express";
import { getNotificationSummary } from "../db/queries/notifications";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

router.get("/", async (req, res) => {
  const summary = await getNotificationSummary(
    req.user!.adUserId,
    req.user!.cBPartnerId,
  );
  res.json(summary);
});

export default router;
