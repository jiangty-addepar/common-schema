--
-- Evaluates the queries generated by a given query.
-- Given query is expected to be a SQL generating query. That is, it is expected to produce,
-- when invoked, a single text column consisting of SQL queries (one query per row).
-- The eval() procedure will invoke said query, and then invoke (evaluate) any of the resulting queries.
-- Invoker of this procedure must have the CREATE TEMPORARY TABLES privilege, as well as any privilege 
-- required for evaluating implied queries.
-- 
-- This procedure calls upon exec(), which means it will:
-- - skip executing empty queries (whitespace only)
-- - Avoid executing queries when @common_schema_dryrun is set (queries merely printed)
-- - Include verbose message when @common_schema_verbose is set
-- - Set @common_schema_rowcount to reflect the last executed query's ROW_COUNT(). 
--
-- Example:
--
-- CALL eval('select concat(\'KILL \',id) from information_schema.processlist where user=\'unwanted\'');
--

DELIMITER $$

DROP PROCEDURE IF EXISTS eval $$
CREATE PROCEDURE eval(sql_query TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Evaluates queries resulting from given query'

begin
  DROP TEMPORARY TABLE IF EXISTS _tmp_eval_queries;
  CREATE TEMPORARY TABLE _tmp_eval_queries (query TEXT CHARSET utf8);
  set @q := CONCAT('INSERT INTO _tmp_eval_queries ', sql_query);  
  PREPARE st FROM @q;
  EXECUTE st;
  DEALLOCATE PREPARE st;
  
  begin	
	declare current_query TEXT CHARSET utf8 DEFAULT NULL;
    declare done INT DEFAULT 0;
    declare eval_cursor cursor for SELECT query FROM _tmp_eval_queries;
    declare continue handler for NOT FOUND SET done = 1;
    
    open eval_cursor;
    read_loop: loop
      fetch eval_cursor into current_query;
      if done then
        leave read_loop;
      end if;
      set @execute_query := current_query;
	  call exec_single(@execute_query);
    end loop;

    close eval_cursor;
  end;
  
  DROP TEMPORARY TABLE IF EXISTS _tmp_eval_queries;
end $$

DELIMITER ;
