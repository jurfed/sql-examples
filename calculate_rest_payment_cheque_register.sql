--calculate rest, for payment_cheque_rest only with special accounts

--ф-ция получает дату в формате DD_MM_YYYY, для которых нужно пересчитать rest для спец счетов и сами спец счета

create or replace function payment_cheque_rest(start_table text, acc_system text, acc_emiss text, acc_oper text, acc_rez text) returns text as 
$$
declare
answr text;
op bigint;
opid bigint;
acc text;
dtime bigint;
dep double precision;
withdr double precision;
sal double precision;
salprev double precision;
-----------------------------
acc_sel text;
saldoprevious1 double precision;
sum_saldo1 double precision='0.0';
cnt int:=0;
 result text := '';
	curs refcursor;
  i integer := 0;
begin	 
	answr='with tmp as (
			SELECT row_number() over(ORDER BY pc.account, pc.datetime, pc.operationtype, pc.regoperationid) num,
			pc.regoperationid, pc.operationtype,pc.account,pc.datetime, pc.deposit, pc.rest, pc.withdraw
			FROM payment_cheque_register_entity_'||start_table||' pc where account in(select '||''''||acc_system||''''||'union select '||''''||acc_emiss||''''||'union select '||''''||acc_oper||''''||'union select '||''''||acc_rez||''''||') and operationtype>0
		), tmp2 as(
			select regoperationid from tmp where (num, account) in 
			(
				select min(num), account from tmp group by account
			)
		) update payment_cheque_register_entity_'||start_table||' set rest=deposit where regoperationid in(select * from tmp2)';

	execute answr;
	
	OPEN curs FOR EXECUTE 'select pc.regoperationid, pc.operationtype,pc.account,pc.datetime, pc.deposit, pc.rest, pc.withdraw from payment_cheque_register_entity_'||start_table||' pc 
				where pc.account in(select '||''''||acc_system||''''||'union select '||''''||acc_emiss||''''||'union select '||''''||acc_oper||''''||'union select '||''''||acc_rez||''''||') and pc.operationtype>0
				order by pc.account, pc.datetime, pc.operationtype, pc.regoperationid asc';
	 LOOP
		FETCH curs INTO  opid, op, acc, dtime, dep, sal, withdr;
		IF NOT FOUND THEN EXIT;END IF;
		if i=0 then
			acc_sel:=acc;
			sum_saldo1:=dep;
		end if;

		if i<>0 then
			if acc_sel=acc then
				execute 'update payment_cheque_register_entity_'||start_table||' set rest= round('||sum_saldo1::numeric||'+coalesce(deposit::numeric,0.0)-coalesce(withdraw::numeric,0.0),2) where regoperationid='||opid;
				sum_saldo1:=sum_saldo1+coalesce(dep,0.0)-coalesce(withdr,0.0);			
				acc_sel:=acc;
			else 
				acc_sel:=acc;
				sum_saldo1:=dep;
			end if;
			
		end if;
		
		i:=i+1;
	 END LOOP;
	 CLOSE curs;
	 result := 'ok';
	 return result;
end;
$$ language plpgsql;

--пример вызова
do language plpgsql $$
declare
	answr text;
	res text;
begin

	select payment_cheque_rest('17_12_2015','CP182751874319','CP540840170738','CP698787901267','CP709890968413') into res;

end
$$;

--верная сортировка записей
select pc.regoperationid, pc.operationtype,pc.account,pc.datetime, pc.deposit, pc.rest, pc.withdraw from payment_cheque_register_entity_17_12_2015 pc 
where pc.account in(select accountnumber from special_payment_account_entity) and pc.operationtype>0
order by pc.account, pc.datetime, pc.operationtype, pc.regoperationid asc