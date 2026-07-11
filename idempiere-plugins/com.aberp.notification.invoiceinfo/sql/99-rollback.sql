-- Rollback Paid filter from Notification SR Invoice Send Info

SET search_path TO adempiere;

DELETE FROM ad_infocolumn
WHERE ad_infocolumn_uu IN (
  'a8f3c2e1-9b47-4d6a-8e15-2c7f9a1b4d03', -- display
  'b7e4d3f2-0c58-4e7b-9f26-3d8a0b2c5e14'  -- criteria
);

UPDATE ad_infowindow SET updated = NOW(), updatedby = 100
WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';
