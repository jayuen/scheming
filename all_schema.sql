CREATE OR REPLACE FUNCTION for_all_schema(raw_query text) RETURNS integer AS $$
DECLARE 
  final_statement text;
  all_schema_query text;
  schema RECORD;
  schema_names text[];
  name text;

  temptable_select text;
  temptable_selects text[];
BEGIN
  -- kill temp tables
  DISCARD TEMP;

  -- get all the schemas
  FOR schema IN SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'public' OR schema_name LIKE 'account_%'
  LOOP
    schema_names := array_append(schema_names, CAST(schema.schema_name AS text));
    all_schema_query := raw_query;
    final_statement := 'CREATE TEMPORARY TABLE ' || schema.schema_name || '_temptable AS '
	|| 'SELECT q.* FROM ('
	|| all_schema_query
	|| ') AS q';
    EXECUTE final_statement;
  END LOOP;

  FOREACH name IN ARRAY schema_names
  LOOP
    temptable_select := 'SELECT * FROM ' || name || '_temptable';
    RAISE NOTICE 'statement: %', temptable_select;
    temptable_selects := array_append(temptable_selects, temptable_select);
  END LOOP;
  final_statement := 'CREATE TEMPORARY TABLE temptable AS ' || array_to_string(temptable_selects, ' UNION ALL ');
  EXECUTE final_statement;
  RETURN 0;
END;$$ LANGUAGE plpgsql;

select for_all_schema('SELECT * FROM badge_types LIMIT 10'); select * from temptable;

--CREATE TEMPORARY TABLE tempy AS SELECT * FROM public_temptable UNION ALL SELECT * FROM public_temptable;
--SELECT * FROM tempy;

-- PERFORM for any statements that don't return anything
-- can to cast results




