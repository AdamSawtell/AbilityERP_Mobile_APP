SET search_path TO adempiere;
SELECT s.name, COUNT(d.*) AS lines
FROM aberp_skip_dates s
LEFT JOIN aberp_dates d ON d.aberp_skip_dates_id = s.aberp_skip_dates_id
WHERE s.name IN ('SAW015 UAT Copy Test', 'Public Holidays 2025+2026')
GROUP BY s.name
ORDER BY s.name;

-- Independent IDs: no shared aberp_dates_id between source and target
SELECT COUNT(*) AS overlapping_ids
FROM aberp_dates t
JOIN aberp_dates s ON s.aberp_dates_id = t.aberp_dates_id
JOIN aberp_skip_dates ts ON ts.aberp_skip_dates_id = t.aberp_skip_dates_id AND ts.name = 'SAW015 UAT Copy Test'
JOIN aberp_skip_dates ss ON ss.aberp_skip_dates_id = s.aberp_skip_dates_id AND ss.name = 'Public Holidays 2025+2026';
