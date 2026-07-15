-- SAW022 rollback
SET search_path TO adempiere;

UPDATE ad_field
   SET defaultvalue = NULL,
       updated = NOW(),
       updatedby = 100
 WHERE ad_field_uu = '9099644b-d5cf-4b32-9921-1776cac6bd66';

UPDATE ad_userquery
   SET isdefault = 'N',
       isactive = 'N',
       updated = NOW(),
       updatedby = 100
 WHERE ad_userquery_uu = '6b2c9e11-4d8a-4f01-9b2e-a022shift001';
