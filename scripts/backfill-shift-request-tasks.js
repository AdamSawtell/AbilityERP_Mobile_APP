/**
 * One-time backfill: create R_Request tasks for existing shift responselog entries
 * that do not yet have a linked request.
 */
const { pool } = require("./dist/db/pool");

const SHIFT_REQUEST_TYPE_ID = 1000011;
const ROSTERING_ROLE_ID = 1000012;
const REQUEST_STATUS_OPEN = 1000000;
const REQUEST_GROUP_ID = 1000003;
const REQUEST_CATEGORY_ID = 1000031;

async function nextId(name) {
  const r = await pool.query(
    `UPDATE ad_sequence SET currentnext = currentnext + incrementno
     WHERE name = $1 RETURNING (currentnext - incrementno) AS id`,
    [name],
  );
  return Number(r.rows[0].id);
}

async function main() {
  await pool.query("SET search_path TO adempiere");

  const rows = await pool.query(`
    SELECT DISTINCT ON (rl.aberp_rostered_shift_id, rl.aberp_user_contact_id)
      rl.aberp_rostered_shift_id AS shift_id,
      rl.aberp_user_contact_id AS ad_user_id,
      rl.aberp_rosteredresponse AS response,
      rl.ad_client_id,
      u.c_bpartner_id,
      s.documentno AS shift_doc,
      st.name AS shift_type
    FROM aberp_rosteredresponselog rl
    JOIN ad_user u ON u.ad_user_id = rl.aberp_user_contact_id
    JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = rl.aberp_rostered_shift_id
    LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
    WHERE rl.isactive = 'Y'
      AND COALESCE(rl.issuperseded, 'N') <> 'Y'
      AND NOT EXISTS (
        SELECT 1 FROM r_request r
        WHERE r.isactive = 'Y'
          AND r.aberp_rostered_shift_id = rl.aberp_rostered_shift_id
          AND r.ad_user_id = rl.aberp_user_contact_id
      )
    ORDER BY rl.aberp_rostered_shift_id, rl.aberp_user_contact_id, rl.created DESC`);

  console.log("backfill candidates:", rows.rows.length);

  for (const row of rows.rows) {
    const shiftLabel = [row.shift_doc, row.shift_type].filter(Boolean).join(" — ");
    const response = row.response === "DEC" ? "DEC" : "REQ";
    const message =
      response === "REQ"
        ? `I would like to request shift ${shiftLabel}.`
        : `I am declining shift ${shiftLabel}.`;
    const summary =
      response === "REQ" ? `Shift request — ${shiftLabel}` : `Shift decline — ${shiftLabel}`;

    const requestId = await nextId("R_Request");
    const salesRepId = (
      await pool.query(
        `SELECT u.ad_user_id FROM ad_user u
         JOIN ad_user_roles ur ON ur.ad_user_id = u.ad_user_id AND ur.isactive = 'Y'
         WHERE ur.ad_role_id = 1000012 AND u.isactive = 'Y'
         ORDER BY u.ad_user_id ASC LIMIT 1`,
      )
    ).rows[0]?.ad_user_id;

    await pool.query(
      `INSERT INTO r_request (
         r_request_id, ad_client_id, ad_org_id, isactive,
         created, createdby, updated, updatedby,
         documentno, r_requesttype_id, r_group_id, r_category_id, r_status_id,
         summary, priority, duetype, nextaction, confidentialtype, isselfservice, processed,
         ad_user_id, c_bpartner_id, ad_role_id, salesrep_id, aberp_rostered_shift_id,
         datelastaction, lastresult
       ) VALUES (
         $1, $2, 0, 'Y', NOW(), $3, NOW(), $3,
         $14, $4, $5, $6, $7,
         $8, '5', '7', 'F', 'C', 'Y', 'N',
         $3, $9, $10, $11, $12, NOW(), $13
       )`,
      [
        requestId,
        row.ad_client_id,
        row.ad_user_id,
        SHIFT_REQUEST_TYPE_ID,
        REQUEST_GROUP_ID,
        REQUEST_CATEGORY_ID,
        REQUEST_STATUS_OPEN,
        summary,
        row.c_bpartner_id,
        ROSTERING_ROLE_ID,
        salesRepId,
        row.shift_id,
        message,
        String(requestId),
      ],
    );

    const updateId = await nextId("R_RequestUpdate");
    await pool.query(
      `INSERT INTO r_requestupdate (
         r_requestupdate_id, ad_client_id, ad_org_id, isactive,
         created, createdby, updated, updatedby,
         r_request_id, result, confidentialtypeentry
       ) VALUES ($1, $2, 0, 'Y', NOW(), $3, NOW(), $3, $4, $5, 'C')`,
      [updateId, row.ad_client_id, row.ad_user_id, requestId, message],
    );

    console.log("created request", requestId, "for shift", row.shift_id, "user", row.ad_user_id);
  }

  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
