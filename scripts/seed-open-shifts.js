/**
 * Seed 5 open available shifts in the current pay fortnight.
 * Run on EC2: cd /opt/ability-erp-pwa/api && node seed-open-shifts.js
 */
const { pool } = require("./dist/db/pool");

const AD_CLIENT_ID = 1000002;
const AD_ORG_ID = 0;
const CREATED_BY = 100;
const SHIFT_TYPE_ID = 1000000; // Service Delivery - Direct (unpaid Break)
const LOCATION_ID = 1000014; // Rover Road
const STATUS_ID = 1000039; // Drafted
const PRICE_LIST_ID = 1000000;

const SHIFTS = [
  {
    name: "PWA Open Shift - Thu 10 Jul",
    day: "Thursday",
    startdate: "2026-07-09T23:30:00.000Z",
    enddate: "2026-07-10T05:30:00.000Z",
    hours: "6.00",
  },
  {
    name: "PWA Open Shift - Fri 11 Jul",
    day: "Friday",
    startdate: "2026-07-11T00:30:00.000Z",
    enddate: "2026-07-11T06:30:00.000Z",
    hours: "6.00",
  },
  {
    name: "PWA Open Shift - Sat 12 Jul",
    day: "Saturday",
    startdate: "2026-07-11T22:30:00.000Z",
    enddate: "2026-07-12T04:30:00.000Z",
    hours: "6.00",
  },
  {
    name: "PWA Open Shift - Mon 14 Jul",
    day: "Monday",
    startdate: "2026-07-14T03:30:00.000Z",
    enddate: "2026-07-14T09:30:00.000Z",
    hours: "6.00",
  },
  {
    name: "PWA Open Shift - Wed 16 Jul",
    day: "Wednesday",
    startdate: "2026-07-15T21:30:00.000Z",
    enddate: "2026-07-16T03:30:00.000Z",
    hours: "6.00",
  },
];

async function nextId(sequenceName) {
  const result = await pool.query(
    `UPDATE ad_sequence
     SET currentnext = currentnext + incrementno
     WHERE name = $1
     RETURNING (currentnext - incrementno) AS id`,
    [sequenceName],
  );
  const row = result.rows[0];
  if (!row) throw new Error(`Sequence not found: ${sequenceName}`);
  return Number(row.id);
}

async function main() {
  await pool.query("BEGIN");
  await pool.query("SET search_path TO adempiere");

  const created = [];

  try {
    for (const shift of SHIFTS) {
      const shiftId = await nextId("AbERP_Rostered_Shift");
      const documentNo = String(await nextId("DocumentNo_AbERP_Rostered_Shift"));
      const staffId = await nextId("AbERP_Rostered_ShiftStaff");

      await pool.query(
        `INSERT INTO aberp_rostered_shift (
           aberp_rostered_shift_id, ad_client_id, ad_org_id, isactive,
           created, createdby, updated, updatedby,
           documentno, name, description,
           startdate, enddate, starttime, endtime,
           aberp_support_start_day, aberp_support_end_day,
           aberp_shift_type_id, aberp_masterlocation_id, r_status_id,
           aberp_isshiftrosteredtemplate, aberp_isshowingasavailable,
           aberp_transport_required, aberp_claimable, aberp_manual_cost_comp,
           aberp_isvalidated, aberp_shift_cost, aberp_timebasedqty, processed,
           aberp_isresponselogreviewrequired, iscancelled
         ) VALUES (
           $1, $2, $3, 'Y',
           NOW(), $4, NOW(), $4,
           $5, $6, 'Seeded for AbilityERP Worker PWA testing',
           $7::timestamp, $8::timestamp, $7::timestamp, $8::timestamp,
           $9, $9,
           $10, $11, $12,
           'N', 'Y',
           'N', 'N', 'N',
           'N', '0', $13, 'N',
           'N', 'N'
         )`,
        [
          shiftId,
          AD_CLIENT_ID,
          AD_ORG_ID,
          CREATED_BY,
          documentNo,
          shift.name,
          shift.startdate,
          shift.enddate,
          shift.day,
          SHIFT_TYPE_ID,
          LOCATION_ID,
          STATUS_ID,
          shift.hours,
        ],
      );

      await pool.query(
        `INSERT INTO aberp_rostered_shiftstaff (
           aberp_rostered_shiftstaff_id, ad_client_id, ad_org_id, isactive,
           created, createdby, updated, updatedby, line,
           aberp_rostered_shift_id, m_pricelist_id,
           aberp_units, aberp_listprice, aberp_estimatedcost,
           aberp_clockin, aberp_clockout,
           aberp_clockincreatedby, aberp_clockoutcreatedby,
           aberp_clockinupdatedby, aberp_clockoutupdatedby
         ) VALUES (
           $1, $2, $3, 'Y',
           NOW(), $4, NOW(), $4, 10,
           $5, $6,
           0, 0, 0,
           'N', 'N',
           $4, $4, $4, $4
         )`,
        [staffId, AD_CLIENT_ID, AD_ORG_ID, CREATED_BY, shiftId, PRICE_LIST_ID],
      );

      created.push({ shiftId, documentNo, name: shift.name, startdate: shift.startdate });
    }

    await pool.query("COMMIT");
    console.log("Created 5 open shifts:");
    console.log(JSON.stringify(created, null, 2));
  } catch (error) {
    await pool.query("ROLLBACK");
    throw error;
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
