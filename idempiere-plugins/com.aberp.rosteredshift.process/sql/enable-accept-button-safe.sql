-- Re-enable Accept Shift Request button on Response Log tab (safe config).
-- Matches ShiftOfferNotification pattern: physical column + toolbar button flag B.
-- No displaylogic (process validates REQ/reviewed/superseded) to avoid row-1 timeout.
SET search_path TO adempiere;

ALTER TABLE aberp_rosteredresponselog
  ADD COLUMN IF NOT EXISTS aberp_acceptshiftrequest character(1);

UPDATE ad_column
SET istoolbarbutton = 'B',
    issyncdatabase = 'Y',
    fieldlength = 1,
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_field
SET isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isfieldonly = 'N',
    istoolbarbutton = 'N',
    displaylogic = NULL,
    seqno = 61,
    columnspan = 2,
    xposition = 5,
    updated = NOW(),
    updatedby = 100
WHERE ad_tab_id = 1000366
  AND ad_column_id = (
    SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_AcceptShiftRequest'
  );

UPDATE ad_toolbarbutton
SET isactive = 'N',
    displaylogic = NULL,
    updated = NOW(),
    updatedby = 100
WHERE ad_tab_id = 1000366
  AND name = 'Accept Shift Request';
