SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_field'
  AND column_name IN ('isquickentry','isdefaultfocus','numlines','columnspan','xposition','seqnogrid','isdisplayedgrid')
ORDER BY 1;
