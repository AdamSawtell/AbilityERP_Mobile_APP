-- Fix Accept button field causing Response Log row load timeout.
SET search_path TO adempiere;

-- Form button columns on child tabs should not use toolbar flag 'B'.
UPDATE ad_column
SET istoolbarbutton = 'N', updated = NOW(), updatedby = 100
WHERE columnname = 'AbERP_AcceptShiftRequest';

-- Keep button on detail form only; simplify display logic; avoid grid/toolbar paths.
UPDATE ad_field
SET isfieldonly = 'Y',
    isdisplayedgrid = 'N',
    istoolbarbutton = 'N',
    displaylogic = '@AbERP_RosteredResponse@=''REQ'' & @IsReviewed@=''N'' & @IsSuperseded@=''N''',
    updated = NOW(),
    updatedby = 100
WHERE ad_tab_id = 1000366
  AND ad_column_id = (SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_AcceptShiftRequest');
