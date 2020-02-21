----------создание индексов для всех таблиц для колонки transactionID----------

--функция получает часть названия таблиц, и название колонки для которых нужно создать индексы, и создает их
create or replace function random_string11(tabname text, colname text) returns text as 
$$
declare
answr text;
tab_nam text;
col_name text;
  result text := '';
  curs2 CURSOR FOR SELECT  t.table_name, c.column_name
   FROM information_schema.TABLES t JOIN information_schema.COLUMNS c ON t.table_name::text = c.table_name::text
  WHERE t.table_schema::text = 'public'::text AND 
        t.table_catalog::name = current_database() AND 
        t.table_type::text = 'BASE TABLE'::text 
        and c.column_name=colname::text
        and t.table_name like tabname::text||'%'
        and t.table_name not in (select tablename from pg_indexes where tablename::text=t.table_name::text and indexdef like 'CREATE INDEX '||tabname::text||'%')
  ORDER BY t.table_name, c.ordinal_position;
  i integer := 0;
begin
	 OPEN curs2;
	 LOOP
		FETCH curs2 INTO tab_nam, col_name;
		IF NOT FOUND THEN EXIT;END IF;
		i:=i+1;
		answr:='create index '||tab_nam::text||i||' ON '||tab_nam::text||'('||colname::text||');';
		execute answr;
	 END LOOP;
	 CLOSE curs2;
	  result := 'ok';
		return result;
end;
$$ language plpgsql;

--блок, который передает часть названия таблиц и название колонки в функцию для создания индексов
do language plpgsql $$
declare
	res text;
begin
	select random_string11('pay_cheque_request_entity_','transactionid') into res;
	select random_string11('buy_cheque_request_entity_','transactionid') into res;
	select random_string11('error_notification_entity_','transactionid') into res;
	select random_string11('payment_cheque_entity_','data') into res;
	--select random_string11('...') into res
end
$$;