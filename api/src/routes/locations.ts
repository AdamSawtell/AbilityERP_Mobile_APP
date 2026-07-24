import { Router } from "express";
import { getLocationDetail, listMyLocations } from "../db/queries/locations";
import { requireAuth, requireSupportWorker } from "../middleware/jwt-auth";

const router = Router();
router.use(requireAuth, requireSupportWorker);

function parseId(raw: string): number | null {
  const id = Number(raw);
  return Number.isFinite(id) ? id : null;
}

router.get("/", async (req, res) => {
  const items = await listMyLocations(req.user!.cBPartnerId, req.user!.adUserId);
  res.json({ items });
});

router.get("/:locationId", async (req, res) => {
  const locationId = parseId(req.params.locationId);
  if (locationId === null) {
    res.status(400).json({ error: "Invalid location ID" });
    return;
  }

  const location = await getLocationDetail(
    locationId,
    req.user!.cBPartnerId,
    req.user!.adUserId,
  );
  if (!location) {
    res.status(404).json({ error: "Location not found" });
    return;
  }

  res.json({ location });
});

export default router;
