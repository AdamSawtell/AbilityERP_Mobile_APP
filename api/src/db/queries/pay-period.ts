import { pool } from "../pool";
import { formatTimestamp } from "../helpers";

export type PayPeriodKey = "current" | "next";

export interface PayPeriod {
  id: number;
  name: string;
  value: string | null;
  period_no: number;
  start_date: string;
  end_date: string;
  key: PayPeriodKey;
}

interface PayPeriodRow {
  id: number;
  name: string;
  value: string | null;
  period_no: number;
  start_date: Date;
  end_date: Date;
}

function mapPeriod(row: PayPeriodRow, key: PayPeriodKey): PayPeriod {
  return {
    id: row.id,
    name: row.name,
    value: row.value,
    period_no: row.period_no,
    start_date: formatTimestamp(row.start_date) ?? "",
    end_date: formatTimestamp(row.end_date) ?? "",
    key,
  };
}

export async function getCurrentPayPeriod(): Promise<PayPeriod | null> {
  const result = await pool.query<PayPeriodRow>(
    `SELECT
       aberp_pr_period_id AS id,
       name,
       value,
       aberp_pr_period_no AS period_no,
       startdate AS start_date,
       enddate AS end_date
     FROM aberp_pr_period
     WHERE isactive = 'Y'
       AND startdate <= NOW()
       AND enddate >= NOW()
     ORDER BY startdate DESC
     LIMIT 1`,
  );
  const row = result.rows[0];
  return row ? mapPeriod(row, "current") : null;
}

export async function getNextPayPeriod(current: PayPeriod | null): Promise<PayPeriod | null> {
  if (current) {
    const result = await pool.query<PayPeriodRow>(
      `SELECT
         aberp_pr_period_id AS id,
         name,
         value,
         aberp_pr_period_no AS period_no,
         startdate AS start_date,
         enddate AS end_date
       FROM aberp_pr_period
       WHERE isactive = 'Y'
         AND startdate > $1::timestamp
       ORDER BY startdate ASC
       LIMIT 1`,
      [current.end_date],
    );
    const row = result.rows[0];
    if (row) return mapPeriod(row, "next");
  }

  const fallback = await pool.query<PayPeriodRow>(
    `SELECT
       aberp_pr_period_id AS id,
       name,
       value,
       aberp_pr_period_no AS period_no,
       startdate AS start_date,
       enddate AS end_date
     FROM aberp_pr_period
     WHERE isactive = 'Y'
       AND startdate > NOW()
     ORDER BY startdate ASC
     LIMIT 1`,
  );
  const row = fallback.rows[0];
  return row ? mapPeriod(row, "next") : null;
}

export async function getPayPeriods(): Promise<{ current: PayPeriod | null; next: PayPeriod | null }> {
  const current = await getCurrentPayPeriod();
  const next = await getNextPayPeriod(current);
  return { current, next };
}

export async function resolvePayPeriod(key: PayPeriodKey): Promise<PayPeriod | null> {
  const { current, next } = await getPayPeriods();
  return key === "next" ? next : current;
}

export function periodDateRange(period: PayPeriod): { start: string; end: string } {
  return { start: period.start_date, end: period.end_date };
}
