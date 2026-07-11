import { Router } from "express";
import { getCredentialCount, getCredentials } from "../db/queries/credentials";
import { getProfile } from "../db/queries/profile";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

router.get("/", async (req, res) => {
  const items = await getCredentials(req.user!.cBPartnerId, req.user!.adUserId);
  res.json({ items });
});

router.get("/id-card", async (req, res) => {
  const profile = await getProfile(req.user!.adUserId);
  const credentialCount = await getCredentialCount(
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );

  res.json({
    idCard: {
      name: profile?.preferred_name ?? profile?.name ?? req.user!.name,
      employeeNo: profile?.employee_no ?? String(req.user!.cBPartnerId),
      email: profile?.bp_email ?? profile?.email ?? req.user!.email,
      roles: req.user!.roles,
      credentialCount,
    },
  });
});

export default router;
