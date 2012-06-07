SET @s := '
  update test_cs.test_split set nval = 0;
  split(test_cs.test_split: update test_cs.test_split set nval = nval + 1 where id % 100 = 0)
  {
    select @query_script_split_step_index, @query_script_split_rowcount, @query_script_split_total_rowcount;
  }
  ';
call run(@s);

