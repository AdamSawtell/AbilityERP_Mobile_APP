SELECT u.ad_user_id, u.name, u.email, u.value, u.c_bpartner_id
FROM ad_user u
JOIN ad_user_roles ur ON ur.ad_user_id = u.ad_user_id
JOIN ad_role r ON r.ad_role_id = ur.ad_role_id
WHERE r.name = 'Support Worker'
  AND u.isactive = 'Y'
  AND ur.isactive = 'Y'
LIMIT 10;
