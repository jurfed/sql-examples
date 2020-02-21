--calculate saldo, saldoprevious for payments_account_operation only with special accounts

--ф-ция получает дату в формате DD_MM_YYYY, для которых нужно пересчитать saldo для спец счетов и сами спец счета
create or replace function payment_saldo(start_table text, acc_system text, acc_emiss text, acc_oper text, acc_rez text) returns text as 
$$
declare
answr text;
op bigint;
acc text;
ot text;
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
			select row_number() over(order by accountnumber, datetime, operationtype1, operationid asc)num, operationid, accountnumber, datetime, depositamount, saldo, saldoprevious, withdrawamount from(
			select pc.operationid, case pc.operationtype
			when 1 then 1
			when 8 then 2
			when 9 then 3
			when 2 then 4
			when 10 then 5
			when 11 then 6
			when 4 then 7
			when 5 then 8
			when 6 then 9
			when 7 then 10
			when 8 then 11
			when -1 then 12
			when -2 then 13
			when -3 then 14
			when -4 then 15
			when -5 then 16
			when -6 then 17
			when -7 then 18
			when -8 then 19
			when -9 then 20
			when -10 then 21
			when -11 then 22
			when -12 then 23
			when -13 then 24
			end operationtype1,
			pc.accountnumber,pc.datetime, pc.depositamount, pc.saldo, pc.saldoprevious, pc.withdrawamount 
			from payment_account_operation_entity_'||start_table||' pc 
			where pc.accountnumber in(select '||''''||acc_system||''''||'union select '||''''||acc_emiss||''''||'union select '||''''||acc_oper||''''||'union select '||''''||acc_rez||''''||')
			order by pc.accountnumber, pc.datetime, operationtype1, pc.operationid asc) tmp
			), tmp2 as(
				select operationid from tmp where (num, accountnumber) in 
					(
						select min(num), accountnumber from tmp group by accountnumber
					)
			)
			update payment_account_operation_entity_'||start_table||' set saldo=depositamount, saldoprevious=withdrawamount where operationid in(select * from tmp2)';
	execute answr;
	OPEN curs FOR EXECUTE 'select pc.operationid, case pc.operationtype
				when 1 then 1
				when 8 then 2
				when 9 then 3
				when 2 then 4
				when 10 then 5
				when 11 then 6
				when 4 then 7
				when 5 then 8
				when 6 then 9
				when 7 then 10
				when 8 then 11
				when -1 then 12
				when -2 then 13
				when -3 then 14
				when -4 then 15
				when -5 then 16
				when -6 then 17
				when -7 then 18
				when -8 then 19
				when -9 then 20
				when -10 then 21
				when -11 then 22
				when -12 then 23
				when -13 then 24
				end operationtype1,
				pc.accountnumber,pc.datetime, pc.depositamount, pc.saldo, pc.saldoprevious, pc.withdrawamount 
				from payment_account_operation_entity_'||start_table||' pc 
				where pc.accountnumber in(select '||''''||acc_system||''''||'union select '||''''||acc_emiss||''''||'union select '||''''||acc_oper||''''||'union select '||''''||acc_rez||''''||')
				order by pc.accountnumber, pc.datetime, operationtype1, pc.operationid asc';
	 LOOP
		FETCH curs INTO op, ot, acc, dtime,dep, sal, salprev, withdr;
		IF NOT FOUND THEN EXIT;END IF;
		if i=0 then
			acc_sel:=acc;
			sum_saldo1:=dep;
			saldoprevious1:=dep;
		end if;

		if i<>0 then
			if acc_sel=acc then
				execute 'update payment_account_operation_entity_'||start_table||' set saldoprevious=round('||saldoprevious1::numeric||',2), saldo=round('||sum_saldo1::numeric||'+coalesce(depositamount::numeric,0.0)-coalesce(withdrawamount::numeric,0.0),2) where operationid='||op;
				sum_saldo1:=sum_saldo1+coalesce(dep,0.0)-coalesce(withdr,0.0);
				saldoprevious1:=sum_saldo1;			
				acc_sel:=acc;
			else 
				acc_sel:=acc;
				sum_saldo1:=dep;
				saldoprevious1:=dep;
			end if;
			
		end if;
		
		i:=i+1;
	 END LOOP;
	 CLOSE curs;
	 result := 'ok';
	 return result;
end;
$$ language plpgsql;

--пример вызова:
do language plpgsql $$
declare
	answr text;
	res text;
begin

	select payment_saldo('17_12_2015','CP182751874319','CP540840170738','CP698787901267','CP709890968413') into res;

end
$$;

---------сортировка
select pc.operationid, case pc.operationtype
when 1 then 1
when 8 then 2
when 9 then 3
when 2 then 4
when 10 then 5
when 11 then 6
when 4 then 7
when 5 then 8
when 6 then 9
when 7 then 10
when 8 then 11
when -1 then 12
when -2 then 13
when -3 then 14
when -4 then 15
when -5 then 16
when -6 then 17
when -7 then 18
when -8 then 19
when -9 then 20
when -10 then 21
when -11 then 22
when -12 then 23
when -13 then 24
end operationtype1,
pc.accountnumber,pc.datetime, pc.depositamount, pc.saldo, pc.saldoprevious, pc.withdrawamount 
from payment_account_operation_entity_17_12_2015 pc 
where pc.accountnumber in(select accountnumber from special_payment_account_entity)
order by pc.accountnumber, pc.datetime, operationtype1, pc.operationid asc