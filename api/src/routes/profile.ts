import { Router } from "express";
import { z } from "zod";
import { getProfile, updateProfile } from "../db/queries/profile";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

const updateSchema = z.object({
  phone: z.string().min(1).optional(),
  email: z.string().email().optional(),
});

router.get("/", async (req, res) => {
  const profile = await getProfile(req.user!.adUserId);
  if (!profile) {
    res.status(404).json({ error: "Profile not found" });
    return;
  }
  res.json({
    profile: {
      adUserId: profile.ad_user_id,
      name: profile.name,
      email: profile.bp_email ?? profile.email,
      phone: profile.bp_phone ?? profile.phone,
      employeeNo: profile.employee_no,
      firstName: profile.first_name,
      lastName: profile.last_name,
      preferredName: profile.preferred_name,
      address: {
        line1: profile.address1,
        city: profile.city,
        postal: profile.postal,
        region: profile.region,
      },
    },
  });
});

router.put("/", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid profile payload" });
    return;
  }
  if (!parsed.data.phone && !parsed.data.email) {
    res.status(400).json({ error: "Nothing to update" });
    return;
  }

  await updateProfile(req.user!.adUserId, req.user!.cBPartnerId, parsed.data);
  const profile = await getProfile(req.user!.adUserId);
  res.json({ profile });
});

export default router;
