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
    final_statement := 'CREATE TEMPORARY TABLE ' || schema.schema_name || '_temptable AS '
      || 'SELECT ' 
      || 'CAST(''' || schema.schema_name || ''' AS text) AS schema_name, '
      || 'q.* FROM ('
	    || raw_query
	    || ') AS q';
    EXECUTE final_statement;
  END LOOP;

  FOREACH name IN ARRAY schema_names
  LOOP
    temptable_select := 'SELECT * FROM ' || name || '_temptable';
    temptable_selects := array_append(temptable_selects, temptable_select);
  END LOOP;
  final_statement := 'CREATE TEMPORARY TABLE temptable AS ' 
    || array_to_string(temptable_selects, ' UNION ALL ')
    || ' ORDER BY schema_name';
  EXECUTE final_statement;
  RETURN 0;
END;$$ LANGUAGE plpgsql;

-- example usage
select for_all_schema('SELECT * FROM badge_types LIMIT 10'); select * from temptable;

-- PERFORM for any statements that don't return anything
-- can to cast results




