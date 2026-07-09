import { Router } from "express";
import { getEmployeeMasterRoster } from "../db/queries/roster";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

router.get("/master", async (req, res) => {
  const roster = await getEmployeeMasterRoster(
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  res.json(roster);
});

export default router;
