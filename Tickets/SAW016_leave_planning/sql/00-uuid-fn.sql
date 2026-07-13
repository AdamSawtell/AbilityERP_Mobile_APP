SELECT proname FROM pg_proc WHERE proname IN ('generate_uuid','uuid_generate_v4','get_uuid') LIMIT 10;
