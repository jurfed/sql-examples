with tmp as(
select distinct b.chequeid, b.operationuid, c.transactionid, c.requestdate from payment_cheque_entity_12_01_2016 a join payment_account_operation_entity_12_01_2016 b on (a.chequeid=b.chequeid)
join buy_cheque_request_entity_12_01_2016 c on (b.operationuid=c.operationuid)
)update payment_cheque_entity_12_01_2016 set chequeid=t2.transactionid from tmp t2 where  payment_cheque_entity_12_01_2016.chequeid=t2.chequeid;

with tmp as(
select distinct b.chequeid, b.operationuid, c.transactionid, c.requestdate from payment_cheque_register_entity_12_01_2016 a join payment_account_operation_entity_12_01_2016 b on (a.cheque=b.chequeid)
join buy_cheque_request_entity_12_01_2016 c on (b.operationuid=c.operationuid)
)update payment_cheque_register_entity_12_01_2016 set cheque=t2.transactionid from tmp t2 where  payment_cheque_register_entity_12_01_2016.cheque=t2.chequeid;

with tmp as(
select distinct b.chequeid, b.operationuid, c.transactionid, c.requestdate from payment_operation_entity_12_01_2016 a join payment_account_operation_entity_12_01_2016 b on (a.transfercheque=b.chequeid)
join buy_cheque_request_entity_12_01_2016 c on (b.operationuid=c.operationuid)
)update payment_operation_entity_12_01_2016 set transfercheque=t2.transactionid from tmp t2 where  payment_operation_entity_12_01_2016.transfercheque=t2.chequeid;

with tmp as(
select distinct b.chequeid, b.operationuid, c.transactionid, c.requestdate from payment_account_operation_entity_12_01_2016 b
join buy_cheque_request_entity_12_01_2016 c on (b.operationuid=c.operationuid)
)update payment_account_operation_entity_12_01_2016 set chequeid=t2.transactionid from tmp t2 where  payment_account_operation_entity_12_01_2016.chequeid=t2.chequeid;

update payment_account_operation_entity_12_01_2016 set saldo=depositamount, saldoprevious=0 where depositamount>=0.01;
update payment_account_operation_entity_12_01_2016 set saldo=0, saldoprevious=withdrawamount where withdrawamount>=0.01;

update payment_cheque_register_entity_12_01_2016 set rest=deposit where operationtype>0;

do language plpgsql $$
declare
	res int;
begin
	SELECT  count(*)
	FROM information_schema.TABLES t JOIN information_schema.COLUMNS c ON t.table_name::text = c.table_name::text
	WHERE t.table_schema::text = 'public'::text AND 
         c.column_name='date'
         AND t.table_name like 'rest_cheques_entity_16_01_2016' into res;
		if res=0 then
			 execute 'ALTER TABLE rest_cheques_entity_16_01_2016 ADD COLUMN date bigint;';
			 execute 'insert into rest_cheques_entity_16_01_2016(regoperationid,restcheque, date) select regoperationid, cheque, datetime from payment_cheque_register_entity_16_01_2016
			 where operationtype>0 and deposit>=0.01;';
		end if;
end
$$;