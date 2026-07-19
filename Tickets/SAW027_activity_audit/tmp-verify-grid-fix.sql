SET search_path TO adempiere;
SELECT t.issinglerow, t.whereclause, t.orderbyclause,
       (SELECT COUNT(*) FROM ad_field f JOIN ad_column c ON c.ad_column_id=f.ad_column_id
        WHERE f.ad_tab_id=t.ad_tab_id AND c.columnname='AbERP_ActivityAuditReview_ID') AS has_pk_field
FROM ad_tab t WHERE t.ad_tab_id=1000376;
