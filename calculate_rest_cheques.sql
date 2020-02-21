
--ф-ция получает дату в формате DD_MM_YYYY, для которых нужно пересчитать rest для спец счетов и сами спец счета

create or replace function rest_cheques(start_table text, acc_system text, acc_emiss text, acc_oper text, acc_rez text) returns text as 
$$
	declare
op bigint;
opid bigint;
acc text;
dtime bigint;
dep double precision;
withdr double precision;
rest double precision;
chq text;
------------------
curs refcursor;
	regoper bigint;
	restchq text:='';
	acc_sel text:='';
	chq_sum text:='';
begin

	OPEN curs FOR EXECUTE 'select * from(with tmp as(
				select pc.regoperationid, pc.operationtype,pc.account,pc.datetime, pc.deposit, pc.rest, pc.withdraw, pc.cheque::text from payment_cheque_register_entity_'||start_table||' pc 
				where pc.account in(select '||''''||acc_system||''''||'union select '||''''||acc_emiss||''''||'union select '||''''||acc_oper||''''||'union select '||''''||acc_rez||''''||') and pc.operationtype>0
				order by pc.account, pc.datetime, pc.operationtype, pc.regoperationid asc
				)select * from tmp) foo';


execute 'CREATE TEMP TABLE tmp_cheqs'||start_table||'(
regoperationid bigint,
restcheque text,
date bigint,
PRIMARY KEY (regoperationid, restcheque)
)ON COMMIT DROP
';
	 LOOP
		FETCH curs INTO  opid, op, acc, dtime, dep, rest, withdr, chq;
		IF NOT FOUND THEN EXIT;END IF;
		if acc_sel='' then
			acc_sel:=acc;
			regoper:=opid;
			execute 'insert into tmp_cheqs'||start_table||' values('||regoper||','||''''||chq::text||''''||','||dtime||')';
		ELSIF acc_sel=acc then
			if dep>=0.01 then
				execute 'insert into tmp_cheqs'||start_table||' select '||opid||', ch.restcheque::text, date from tmp_cheqs'||start_table||' ch where '||regoper||'=ch.regoperationid';
				execute 'insert into tmp_cheqs'||start_table||' values('||opid||','||''''||chq::text||''''||','||dtime||')';
				acc_sel:=acc;
				regoper:=opid;
				
			ELSIF withdr>=0.01 then
				execute 'insert into tmp_cheqs'||start_table||' select '||opid||', restcheque::text, date from tmp_cheqs'||start_table||' where '||regoper||' = regoperationid and restcheque::text <> '||''''||chq::text||'''';
				regoper:=opid;
			end if;
		ELSIF acc_sel<>acc then
			acc_sel:=acc;
			regoper:=opid;
			
			if dep>=0.01 then
				execute 'insert into tmp_cheqs'||start_table||' select '||opid||', ch.restcheque::text, date from tmp_cheqs'||start_table||' ch where '||regoper||'=ch.regoperationid';
				execute 'insert into tmp_cheqs'||start_table||' values('||opid||','||''''||chq::text||''''||','||dtime||')';
				acc_sel:=acc;
				regoper:=opid;
				
			ELSIF withdr>=0.01 then
				execute 'insert into tmp_cheqs'||start_table||' select '||opid||', restcheque::text, date from tmp_cheqs'||start_table||' where '||regoper||'=regoperationid and restcheque::text<>'||''''||chq::text||'''';
				regoper:=opid;
			end if;	
		end if;
		END LOOP;	

		execute 'update rest_cheques_entity_'||start_table||' SET date=t2.date from tmp_cheqs'||start_table||' t2 where rest_cheques_entity_'||start_table||'.regoperationid = t2.regoperationid and rest_cheques_entity_'||start_table||'.restcheque = t2.restcheque';
		execute 'insert into rest_cheques_entity_'||start_table||' select t2.regoperationid, t2.restcheque,t2.date from tmp_cheqs'||start_table||' t2 where (t2.regoperationid, t2.restcheque) not in (select b.regoperationid, b.restcheque from rest_cheques_entity_'||start_table||' b)';
		CLOSE curs;
	 return 'ok';
end
$$ language plpgsql;

--пример вызова. передаем дату и спецсчета
do language plpgsql $$
declare
	answr text;
	res text;
begin

	select rest_cheques('21_12_2015','CP143135798603','CP553148618463','CP606610000567','CP835244966709') into res;

end
$$;


------------------------------для тестирования расчетов---------------------------------
--вывод отсортированного реестра движения чеков (указываем верную payment_cheque_register_entity_21_12_2015)
with tmp as(
select pc.regoperationid, pc.operationtype,pc.account,pc.datetime, pc.deposit, pc.rest, pc.withdraw, pc.cheque from payment_cheque_register_entity_21_12_2015 pc 
where pc.account in(select accountnumber from special_payment_account_entity) and pc.operationtype>0
order by pc.account, pc.datetime, pc.operationtype, pc.regoperationid asc
)select * from tmp;

--вывод чеков из rest_cheques по конкретной операции (в запросе заменяем таблицы на свои и указываем номер операции)
select * from rest_cheques_entity_21_12_2015 where regoperationid in (select regoperationid from payment_cheque_register_entity_21_12_2015 where account in (select accountnumber from
special_payment_account_entity )) and regoperationid='1450691423201749764'