--функция генерации уникального transactionId
create or replace function random_string1(length integer) returns text as 
$$
declare
  chars text[] := '{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,g,D,A,O,L}';
  result text := '';
  i integer := 0;
  i2 integer:=0;
begin
  if length < 0 then
    raise exception 'Given length cannot be less than 0';
  end if;
  for i in 1..length loop
    result := result || chars[1+random()*(array_length(chars, 1)-1)];
  end loop;
  return result;
end;
$$ language plpgsql;


drop table IF EXISTS tab1;

--генерация остальных данных
create table tab1 as(
select random_string1(32)::text as "transactionId",to_char((current_timestamp + (cast(round(random()*(100)+1) AS varchar) || ' minute')::interval+ (cast(round(random()*(50)+1) AS varchar) || ' secs')::interval),'DD.MM.YYYY HH24:MI:SS') as "clientTime"
,to_char((current_timestamp + (cast(round(random()*(100)+201) AS varchar) || ' minute')::interval+ (cast(round(random()*(50)+51) AS varchar) || ' secs')::interval),'DD.MM.YYYY HH24:MI:SS') as "serverTime",
round((random()*(20000)+10)::numeric,2) as "amount",
'810'::text as "currency"
,round(random()*(10)+10) as "pointId"
,'138860177375'::text as "аgentId"--это walletid юр. лица с reg_type=3(эмитент) или reg_type=7(платежный агент)
, round(random()*(1)+1) as "category"
,round(random()*(29)+1) as "providerId"
from generate_series(1,1000)--количество сгенерированных строк
)

--альтернативный вариант - генерация остальных данных с указанием конкретной даты
create table tab1 as(
	select random_string1(32)::text as "transactionId",
	to_char(to_timestamp(
		'10.01.2016','DD.MM.YYYY'--дата отчета
			) + INTERVAL '1 hour' * round(random() * 20) + INTERVAL '1 minute' * round(random() * 60) + 
		INTERVAL '1 second' * round(random() * 60),'DD.MM.YYYY HH24:MI:SS') as "clientTime"
	,to_char(to_timestamp(
		'10.01.2016','DD.MM.YYYY'--дата отчета
			) + INTERVAL '1 hour' * round(random() * 20) + INTERVAL '1 minute' * round(random() * 60) + 
		INTERVAL '1 second' * round(random() * 60),'DD.MM.YYYY HH24:MI:SS')  as "serverTime",
	round((random()*(2000)+10)::numeric,2) as "amount",
	'810'::text as "currency"
	,round(random()*(10)+10) as "pointId"
,'138860177375'::text as "аgentId"--или reg_type=3(эмитент) или reg_type=7(платежный агент)
	, round(random()*(1)+1) as "category"
	,round(random()*(29)+1) as "providerId"
from generate_series(1,1000)--количество сгенерированных строк
)



--запись данных в файл на покупку
Copy (
select 'transactionId'||';'||'clientTime'||';'||'serverTime'||';'||'amount'||';'||'currency'||';'||'pointId'||';'||'аgentId'||';'||'category' union all
select "transactionId"||';'||"clientTime"||';'||"serverTime"||';'||"amount"||';'||"currency"||';'||"pointId"||';'||"аgentId"||';'||CASE when ((amount)<=15000.00) then '1'else '2' end from tab1 union all
select '1002'::text--кол-во строк+2
)
To 'C:\test1.csv' With CSV;

--запись данных в файл на оплату
Copy (
select 'transactionId'||';'||'serverTime'||';'||'paymentTime'||';'||'providerId'||';'||'providerName'||';'||'amount'::text||';'||'currency'||';'||'pointId'||';'||'аgentId'||';'||'category' union all
select "transactionId"||';'|| "serverTime"||';'||to_char(to_timestamp("serverTime", 'DD:MM:YYYY HH24:MI:SS')+ INTERVAL '1 minute' * round(random() * 60) + 
		INTERVAL '1 second' * round(random() * 60 +1),'DD.MM.YYYY HH24:MI:SS')
||';'||"providerId"::text||';'||
case "providerId" 
when 1 then 'Мегафон'
when 2 then 'МТС'
when 3 then 'СкайНет'
when 4 then 'ВёстКолл'
when 5 then 'Билайн'
when 6 then 'Нью Линк (НВ Линк)'
when 7 then 'Эт-Хоум'
when 8 then 'Дом.RU'
when 9 then 'Интерзет'
when 10 then 'Обит'
when 11 then 'Сумма Телеком'
when 12 then 'Ростелеком Docsis'
when 13 then 'WebPlus'
when 14 then 'АКАДО'
when 15 then 'Prometey Home'
when 16 then 'NEWlink'
when 17 then 'FasterNet'
when 18 then 'NETBYNET'
when 19 then 'ЁТ ХОУМ (+Парголово)'
when 20 then 'Well-Telecom'
when 21 then 'ВестКолл'
when 22 then 'РТС Онлайн'
when 23 then 'TiERA'
when 24 then 'Невалинк'
when 25 then 'Интеграл-Сервис'
when 26 then 'Доминанта'
when 27 then 'Web-Media'
when 28 then 'Твое ТВ (КТВ)'
when 29 then 'Sertolovo'
else 'Сестрорецкое кабельное телевидение (КТВ)' end
||';'||
 "amount" ||';'||"currency" ||';'||"pointId" ||';'||"аgentId" ||';'||CASE when ((amount)<=15000.00) then '1'else '2' end from tab1 union all
 select '1002'::text--кол-во строк+2
 )
To 'C:\test2.csv' With CSV;

--реестр уведомлений об ошибочных платежах
Copy (
select 'transactionId'||';'||'serverTime'||';'||'notificationTime'||';'||'amount'::text||';'||'currency'||';'||'аgentId'||';'||'category' union all
select "transactionId"||';'|| "serverTime"||';'||to_char(to_timestamp("serverTime", 'DD:MM:YYYY HH24:MI:SS')+ (cast(round(random()*(100)+100) AS varchar) || ' minute')::interval+(cast(round(random()*(51)+1) AS varchar) || ' secs')::interval,'DD.MM.YYYY HH24:MM:SS')||';'|| "amount" ||';'||"currency" ||';'||"аgentId"||';'||CASE when ((amount)<=15000.00) then '1'else '2' end from tab1 union all
 select '1002'::text
 )
To 'C:\test3.csv' With CSV
