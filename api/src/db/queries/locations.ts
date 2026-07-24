import { pool } from "../pool";
import { formatTimestamp } from "../helpers";

/**
 * Matches Support Location / Support Location Mobile window whereclause:
 * AbERP_Support_Location_ID IN (
 *   select l.aberp_support_location_id
 *   from aberp_support_location l
 *   join c_bpartner_location bl
 *     on l.aberp_support_location_id = bl.aberp_support_location_id
 *   where bl.isactive = 'Y'
 * )
 */
const WINDOW_FILTER = `
  EXISTS (
    SELECT 1
    FROM c_bpartner_location bl
    WHERE bl.aberp_support_location_id = l.aberp_support_location_id
      AND bl.isactive = 'Y'
  )
`;

/** Worker may see a location if they have a recent/upcoming rostered shift there. */
const WORKER_LOCATION_ACCESS = `
  EXISTS (
    SELECT 1
    FROM aberp_rostered_shiftstaff ss
    JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
    JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
    JOIN c_bpartner_location bl ON bl.c_bpartner_location_id = ml.c_bpartner_location_id
    WHERE ss.isactive = 'Y'
      AND s.isactive = 'Y'
      AND bl.isactive = 'Y'
      AND bl.aberp_support_location_id = l.aberp_support_location_id
      AND (ss.c_bpartner_staff_id = $1 OR ss.aberp_user_contact_id = $2)
      AND COALESCE(s.starttime, s.startdate) >= NOW() - INTERVAL '90 days'
      AND COALESCE(s.starttime, s.startdate) <= NOW() + INTERVAL '60 days'
  )
`;

export interface LocationListItem {
  id: number;
  name: string;
  address: string | null;
  nextShiftAt: string | null;
  alertCount: number;
  wheelchairAccessible: boolean | null;
}

export interface LocationAlert {
  id: number;
  type: string | null;
  name: string | null;
  description: string | null;
  isAlert: boolean;
}

export interface LocationRoom {
  id: number;
  name: string | null;
  number: string | null;
  details: string | null;
  use: string | null;
}

export interface LocationDetail {
  id: number;
  name: string;
  address: string | null;
  phone: string | null;
  keyboxCode: string | null;
  alarmCode: string | null;
  accessDetails: string | null;
  accessibilityFeatures: string | null;
  wheelchairAccessible: boolean | null;
  capacity: string | null;
  bushfireDangerArea: boolean;
  tenancyType: string | null;
  propertyManager: string | null;
  externalLink1: string | null;
  externalLink2: string | null;
  alerts: LocationAlert[];
  rooms: LocationRoom[];
}

async function assertLocationAccess(
  locationId: number,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<boolean> {
  const result = await pool.query(
    `SELECT 1
     FROM aberp_support_location l
     WHERE l.aberp_support_location_id = $3
       AND l.isactive = 'Y'
       AND ${WINDOW_FILTER}
       AND ${WORKER_LOCATION_ACCESS}
     LIMIT 1`,
    [cBPartnerStaffId, adUserId, locationId],
  );
  return result.rowCount !== null && result.rowCount > 0;
}

export async function listMyLocations(
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<LocationListItem[]> {
  const result = await pool.query(
    `SELECT
       l.aberp_support_location_id AS id,
       l.name,
       (
         SELECT NULLIF(TRIM(CONCAT_WS(', ',
           NULLIF(loc.address1, ''),
           NULLIF(loc.address2, ''),
           NULLIF(loc.city, ''),
           NULLIF(reg.name, ''),
           NULLIF(loc.postal, '')
         )), '')
         FROM c_bpartner_location bl
         JOIN c_location loc ON loc.c_location_id = bl.c_location_id
         LEFT JOIN c_region reg ON reg.c_region_id = loc.c_region_id
         WHERE bl.aberp_support_location_id = l.aberp_support_location_id
           AND bl.isactive = 'Y'
         ORDER BY bl.c_bpartner_location_id
         LIMIT 1
       ) AS address,
       (
         SELECT MIN(COALESCE(s2.starttime, s2.startdate))
         FROM aberp_rostered_shiftstaff ss2
         JOIN aberp_rostered_shift s2 ON s2.aberp_rostered_shift_id = ss2.aberp_rostered_shift_id
         JOIN aberp_masterlocation ml2 ON ml2.aberp_masterlocation_id = s2.aberp_masterlocation_id
         JOIN c_bpartner_location bl2 ON bl2.c_bpartner_location_id = ml2.c_bpartner_location_id
         WHERE ss2.isactive = 'Y' AND s2.isactive = 'Y' AND bl2.isactive = 'Y'
           AND bl2.aberp_support_location_id = l.aberp_support_location_id
           AND (ss2.c_bpartner_staff_id = $1 OR ss2.aberp_user_contact_id = $2)
           AND COALESCE(s2.starttime, s2.startdate) >= date_trunc('day', NOW())
       ) AS next_shift_at,
       (
         SELECT COUNT(*)::int
         FROM aberp_alert a
         WHERE a.aberp_support_location_id = l.aberp_support_location_id
           AND a.isactive = 'Y'
           AND (a.validfrom IS NULL OR a.validfrom::date <= CURRENT_DATE)
           AND (a.validto IS NULL OR a.validto::date >= CURRENT_DATE)
       ) AS alert_count,
       CASE
         WHEN l.aberp_iswheelchairaccessible = 'Y' THEN TRUE
         WHEN l.aberp_iswheelchairaccessible = 'N' THEN FALSE
         ELSE NULL
       END AS wheelchair_accessible
     FROM aberp_support_location l
     WHERE l.isactive = 'Y'
       AND ${WINDOW_FILTER}
       AND ${WORKER_LOCATION_ACCESS}
     ORDER BY l.name
     LIMIT 100`,
    [cBPartnerStaffId, adUserId],
  );

  return result.rows.map((row) => ({
    id: Number(row.id),
    name: String(row.name),
    address: row.address ? String(row.address) : null,
    nextShiftAt: formatTimestamp(row.next_shift_at),
    alertCount: Number(row.alert_count ?? 0),
    wheelchairAccessible:
      row.wheelchair_accessible === null || row.wheelchair_accessible === undefined
        ? null
        : Boolean(row.wheelchair_accessible),
  }));
}

export async function getLocationDetail(
  locationId: number,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<LocationDetail | null> {
  if (!(await assertLocationAccess(locationId, cBPartnerStaffId, adUserId))) {
    return null;
  }

  const profile = await pool.query(
    `SELECT
       l.aberp_support_location_id AS id,
       l.name,
       (
         SELECT NULLIF(TRIM(CONCAT_WS(', ',
           NULLIF(loc.address1, ''),
           NULLIF(loc.address2, ''),
           NULLIF(loc.city, ''),
           NULLIF(reg.name, ''),
           NULLIF(loc.postal, '')
         )), '')
         FROM c_bpartner_location bl
         JOIN c_location loc ON loc.c_location_id = bl.c_location_id
         LEFT JOIN c_region reg ON reg.c_region_id = loc.c_region_id
         WHERE bl.aberp_support_location_id = l.aberp_support_location_id
           AND bl.isactive = 'Y'
         ORDER BY bl.c_bpartner_location_id
         LIMIT 1
       ) AS address,
       (
         SELECT NULLIF(TRIM(bl.phone), '')
         FROM c_bpartner_location bl
         WHERE bl.aberp_support_location_id = l.aberp_support_location_id
           AND bl.isactive = 'Y'
           AND NULLIF(TRIM(bl.phone), '') IS NOT NULL
         ORDER BY bl.c_bpartner_location_id
         LIMIT 1
       ) AS phone,
       NULLIF(TRIM(l.aberp_keyboxaccesscode), '') AS keybox_code,
       NULLIF(TRIM(l.aberp_alarmcode), '') AS alarm_code,
       NULLIF(TRIM(l.aberp_access_details), '') AS access_details,
       NULLIF(TRIM(l.aberp_accessibilityfeatures), '') AS accessibility_features,
       CASE
         WHEN l.aberp_iswheelchairaccessible = 'Y' THEN TRUE
         WHEN l.aberp_iswheelchairaccessible = 'N' THEN FALSE
         ELSE NULL
       END AS wheelchair_accessible,
       NULLIF(TRIM(l.aberp_capacity), '') AS capacity,
       COALESCE(l.aberp_isbushfiredangerarea, 'N') = 'Y' AS bushfire_danger_area,
       tt.name AS tenancy_type,
       pm.name AS property_manager,
       NULLIF(TRIM(l.aberp_external_weblink_1), '') AS external_link_1,
       NULLIF(TRIM(l.aberp_external_weblink_2), '') AS external_link_2
     FROM aberp_support_location l
     LEFT JOIN aberp_tenancytype tt ON tt.aberp_tenancytype_id = l.aberp_tenancytype_id
     LEFT JOIN c_bpartner pm ON pm.c_bpartner_id = l.aberp_property_manager_id
     WHERE l.aberp_support_location_id = $1`,
    [locationId],
  );

  const row = profile.rows[0];
  if (!row) return null;

  const [alertsResult, roomsResult] = await Promise.all([
    pool.query(
      `SELECT
         a.aberp_alert_id AS id,
         t.name AS type,
         a.name,
         a.description,
         COALESCE(a.aberp_isalert, 'N') = 'Y' AS is_alert
       FROM aberp_alert a
       LEFT JOIN aberp_alert_type t ON t.aberp_alert_type_id = a.aberp_alert_type_id
       WHERE a.aberp_support_location_id = $1
         AND a.isactive = 'Y'
         AND (a.validfrom IS NULL OR a.validfrom::date <= CURRENT_DATE)
         AND (a.validto IS NULL OR a.validto::date >= CURRENT_DATE)
       ORDER BY COALESCE(a.aberp_isalert, 'N') DESC, a.line NULLS LAST, a.aberp_alert_id
       LIMIT 30`,
      [locationId],
    ),
    pool.query(
      `SELECT
         r.aberp_roomnum_id AS id,
         NULLIF(TRIM(r.name), '') AS name,
         NULLIF(TRIM(r.aberp_roomnumber::text), '') AS number,
         NULLIF(TRIM(r.aberp_details), '') AS details,
         u.name AS use
       FROM aberp_roomnum r
       LEFT JOIN aberp_roomuse u ON u.aberp_roomuse_id = r.aberp_roomuse_id
       WHERE r.aberp_support_location_id = $1
         AND r.isactive = 'Y'
       ORDER BY r.aberp_roomnumber NULLS LAST, r.name NULLS LAST, r.aberp_roomnum_id
       LIMIT 40`,
      [locationId],
    ),
  ]);

  return {
    id: Number(row.id),
    name: String(row.name),
    address: row.address ? String(row.address) : null,
    phone: row.phone ? String(row.phone) : null,
    keyboxCode: row.keybox_code ? String(row.keybox_code) : null,
    alarmCode: row.alarm_code ? String(row.alarm_code) : null,
    accessDetails: row.access_details ? String(row.access_details) : null,
    accessibilityFeatures: row.accessibility_features
      ? String(row.accessibility_features)
      : null,
    wheelchairAccessible:
      row.wheelchair_accessible === null || row.wheelchair_accessible === undefined
        ? null
        : Boolean(row.wheelchair_accessible),
    capacity: row.capacity ? String(row.capacity) : null,
    bushfireDangerArea: Boolean(row.bushfire_danger_area),
    tenancyType: row.tenancy_type ? String(row.tenancy_type) : null,
    propertyManager: row.property_manager ? String(row.property_manager) : null,
    externalLink1: row.external_link_1 ? String(row.external_link_1) : null,
    externalLink2: row.external_link_2 ? String(row.external_link_2) : null,
    alerts: alertsResult.rows.map((item) => ({
      id: Number(item.id),
      type: item.type ? String(item.type) : null,
      name: item.name ? String(item.name) : null,
      description: item.description ? String(item.description) : null,
      isAlert: Boolean(item.is_alert),
    })),
    rooms: roomsResult.rows.map((item) => ({
      id: Number(item.id),
      name: item.name ? String(item.name) : null,
      number: item.number ? String(item.number) : null,
      details: item.details ? String(item.details) : null,
      use: item.use ? String(item.use) : null,
    })),
  };
}
