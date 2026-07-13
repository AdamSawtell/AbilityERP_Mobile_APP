UPDATE aberp_shiftchange
SET isactive = 'Y',
    updated = NOW(),
    updatedby = 100
WHERE documentno = '1003753'
  AND isactive = 'N';

SELECT documentno, isactive, aberp_requestsubmitted, r_status_id, updated
FROM aberp_shiftchange WHERE documentno = '1003753';
