SET search_path TO adempiere;
UPDATE ad_modelvalidator
SET isactive = 'N', updated = NOW(), updatedby = 100
WHERE modelvalidationclass IN (
  'com.zitomedia.updatereference.model.UpdateReferenceModelValidator',
  'com.aberp.rostering.models.validator.ResponseValidator'
);
SELECT ad_modelvalidator_id, name, modelvalidationclass, isactive FROM ad_modelvalidator
WHERE modelvalidationclass ILIKE '%ResponseValidator%' OR modelvalidationclass ILIKE '%UpdateReference%';
