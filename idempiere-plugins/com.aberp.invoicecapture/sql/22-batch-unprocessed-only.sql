-- =============================================================================
-- SAW019 — Batch processes only unprocessed captures (docs + scheduler help)
-- Runtime filter is in ProcessInvoiceCaptureBatch (Processed='N').
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_process SET
  description = 'Overnight catch-up: process captures that have not been processed yet (Processed=N).',
  help = $h$Processes Invoice Capture records where Processed is No and status is eligible (typically Pending after Upload).

Skips anything already processed manually or in a previous batch. To retry Requires Review / errors, open the record and use Process on the window.

Same OCR → match → Draft AP pipeline as the window Process button.$h$,
  updated = NOW(),
  updatedby = 100
WHERE ad_process_uu = '19a01909-c0d4-4f01-8e15-000000000001'
   OR value = 'AbERP_InvoiceCapture_ProcessBatch';

UPDATE ad_process_trl pt SET
  description = p.description,
  help = p.help,
  istranslated = 'N',
  updated = NOW()
FROM ad_process p
WHERE pt.ad_process_id = p.ad_process_id
  AND (p.ad_process_uu = '19a01909-c0d4-4f01-8e15-000000000001'
       OR p.value = 'AbERP_InvoiceCapture_ProcessBatch');
