CREATE OR REPLACE VIEW license_procurement_model AS 
select ld.license_id,ld.feature_name as feature_name,ld.product_name as feature_description,
ld.version,ld.license_type,ld.quantity,ld.package_id,ld.is_token_based,ld.num_of_tokens,ld.vendor,ld.server_id,
lsd.server_name,lsd.license_manager_type,lss.server_status,lp.procurement_id,lp.asset_info,lp.dist_info,lp.components_info,
CAST(
        CASE
            WHEN lp.ts_ms >= lsd.ts_ms AND lp.ts_ms >= lss.ts_ms AND lp.ts_ms >= ld.ts_ms THEN lp.ts_ms
            WHEN lsd.ts_ms >= ld.ts_ms AND lsd.ts_ms >= lss.ts_ms AND lsd.ts_ms >= lp.ts_ms THEN lsd.ts_ms
            WHEN lss.ts_ms >= ld.ts_ms AND lss.ts_ms >= lsd.ts_ms AND lss.ts_ms >= lp.ts_ms THEN lss.ts_ms
            ELSE ld.ts_ms
        END AS timestamp
    ) AS last_update_time,
	(select tenant_id from license_fact_table where transaction_id = (SELECT MAX(transaction_id)FROM license_fact_table)) as tenant_id
from license_details_dimension ld 
left join license_procurement_table lp on ld.license_id = lp.license_id
left join license_server_dimension lsd on ld.server_id = lsd.server_id
LEFT JOIN
    (
        SELECT
            t1.server_id,
            t1.server_status,
            t1.ts_ms,
            t1.update_date_utc
        FROM
            license_server_status t1
        WHERE
            t1.update_date_utc = (
                SELECT MAX(t2.update_date_utc)
                FROM license_server_status t2
                WHERE t2.server_id = t1.server_id
            )
    ) lss ON lsd.server_id = lss.server_id;

    CREATE OR REPLACE VIEW process_model as 
select 
pdd.process_id,
pdd.process_name,
pdd.version,
pft.host_name,
hdd.host_id,
pft.monitoring_id,
max(CAST (psdt.ts_ms as timestamp)) as last_update_time,
(select tenant_id 
   from license_fact_table 
   where transaction_id = (SELECT MAX(transaction_id) FROM license_fact_table)) as tenant_id 
from 
          process_fact_table pft 
left join process_session_details_transaction psdt on pft.session_id = psdt.session_id 
left join process_details_dimension pdd on psdt.process_id = pdd.process_id
left join host_details_dimension hdd on pft.host_name = hdd.host_name
where hdd.host_id is not null
group by pdd.process_id,pdd.process_name,pdd.version,pft.host_name,hdd.host_id,pft.monitoring_id, tenant_id;


CREATE  VIEW vw_allocated_licenses
AS
select c.license_id,c.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
c.date_to_utc,d.ts_ms
from license_details_dimension as c 
JOIN
(
SELECT 
a.user_id AS user_alloc, 
b.user_id AS user_id, b.is_enabled, a.license_id,a.ts_ms
FROM     license_allocation_transaction  as a
JOIN
		 user_details_dimension as b
		 ON a.user_id = b.user_id
		 where b.is_enabled = '1'
) as d
ON c.license_id=d.license_id and c.date_to_utc is NULL;


CREATE     VIEW vw_bottom_features AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(lt.duration) ASC) AS row_number,
    ld.feature_name,-- was changed from license_name  to feature_name by RG 19/082024
    SUM(lt.duration)/60 AS total_duration_hrs,
    MAX(lt.ts_ms) AS ts_ms
FROM 
    license_transaction lt
    LEFT JOIN license_details_dimension ld ON lt.license_id = ld.license_id
GROUP BY 
    ld.feature_name; 

CREATE   VIEW vw_bottom_users AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(lt.duration) ASC) AS row_number,
    ud.user_name,
    ud.first_name,
    ud.last_name,
    SUM(lt.duration)/60 AS total_duration_hrs,
    MAX(lt.ts_ms) as ts_ms
FROM 
    license_transaction lt
    LEFT JOIN license_fact_table lft ON lt.usage_id = lft.usage_id
    LEFT JOIN user_details_dimension ud ON lft.user_id = ud.user_id
GROUP BY 
    ud.user_name,
    ud.first_name,
    ud.last_name;

CREATE   VIEW vw_calendar AS
SELECT 
       cast(datum AS timestamp) "Date",
	   EXTRACT(YEAR FROM datum) AS "Year",
	   EXTRACT(MONTH FROM datum) AS "Month",
	   EXTRACT(DAY FROM datum) AS "Day",
       EXTRACT(ISODOW FROM datum) AS "DayOfWeekNum",
       TO_CHAR(datum, 'TMDay')   AS "DayOfWeek",
	   EXTRACT(QUARTER FROM datum) AS "Quarter"	   
FROM (SELECT '1950-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 91400) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ;
CREATE OR REPLACE VIEW vw_calendar_with_count as
select
a."Date"  as "date",
a."DayOfWeek" as "DayoOfWeek",
a."Month" as "month" ,
a."Quarter" as "quarter" ,
a."Year" as "year",
COALESCE(b."num_of_licenses",0) as num_of_licenses,
COALESCE(c."user_id_count",0) as user_id_count,
COALESCE(d."denial_id_count",0) as denial_id_count
from (
select
     "Date",
      cast (cldr."Date" as date) as date_d,
      cldr."DayOfWeek", cldr."Month", cldr."Quarter", cldr."Year"
     from vw_calendar cldr
    ) as a
LEFT JOIN
(   select
start_time_utc,
sum(num_of_licenses) num_of_licenses
from (
select cast(lt1.start_time_utc as date) as start_time_utc,
lt1.num_of_licenses
from license_transaction lt1
) a
group by start_time_utc
) as b
  ON b.start_time_utc =a."Date"
LEFT JOIN
(  select  u.start_date_utc, count(u.user_id) as user_id_count
   from(
   select distinct cast(lt.start_time_utc as date) as start_date_utc,lft.user_id
     from     (select a.user_id, a.usage_id  from license_fact_table a) lft
        join  (select b.usage_id, start_time_utc from license_transaction b) lt
          on lft.usage_id = lt.usage_id
   ) u
 group by u.start_date_utc
) as c
    ON c."start_date_utc" =  a."Date"
LEFT JOIN
  (select cast("denial_date" as date) as denial_date, count("denial_id") denial_id_count
   from denials_transaction
   group by cast ("denial_date" as date)) as d
      ON d."denial_date" = a."Date";

CREATE VIEW vw_compliance as
select 
a.license_id as license_id,
b.feature_name as feature_name, -- was changed from license_name  to feature_name by RG 19/082024
a.rule_type as rule_type,
a.rule_value as rule_value,
c.user_id as user_id,
d.user_name as user_name,
d.department as department,
d.country as country,
e.country_code  as country_code,
e.region  as region,
case when (a.rule_value = 'Global' or d.country = 'Global')
   then 'Compliant'
   when ( a.rule_value is null or d.country is null or d.country ='') 
   then 'Missing Data'
   when a.rule_value = d.country
   then 'Compliant'
   when a.rule_value <> d.country 
   then
       case 
	   when a.rule_value = e.region 
	   then 'Compliant'
	   else
	      'Non Compliant'
	end 
end as com_noncom_status,
b.ts_ms
from 
location_dimension as a 
JOIN license_details_dimension b
ON a.license_id = b.license_id
JOIN license_allocation_transaction c
ON a.license_id  = c.license_id
JOIN user_details_dimension d
ON c.user_id = d.user_id
LEFT JOIN country_dimension e 
ON coalesce(e.country,'NA') = coalesce(d.country,'NA');

CREATE   VIEW vw_country AS 
SELECT 
CD.region,CD.country_code,UD.country,UD.user_name,
UD.department,UD.default_group_id,UD.email,UD.is_enabled,UD.display_name,
UD.ts_ms
FROM 
user_details_dimension AS UD
LEFT JOIN 
country_dimension AS CD ON CD.country = UD.country;

CREATE OR REPLACE  VIEW vw_denials as
select
COALESCE(NULLIF(a.host_name, ''), 'Not Available')  AS workstation,
a.transaction_id,a.denial_id,
a.user_id,
a.host_name,
f.user_name,
f.first_name,
f.last_name,
b.feature_name,
b.num_of_licenses,
b.denial_date,
b.major_err, 
b.minor_err,
b.error_message,
b.version,
b.vendor,
b.license_type,
b.additional_key,
b.status,
g.group_name as grp_name,
c.date_to_utc,
d.server_name as licsrv_description,
e.server_port
from
          denials_fact_table a
	 JOIN denials_transaction b ON a.denial_id = b.denial_id

LEFT JOIN license_details_dimension c ON b.feature_name = c.feature_name
LEFT JOIN license_server_dimension d ON a.server_id = d.server_id
LEFT JOIN license_server_host e ON a.server_id = e.server_id
LEFT JOIN user_details_dimension f ON a.user_id = f.user_id
LEFT JOIN group_details_dimension g ON f.default_group_id = g.group_id
where d.server_name NOT LIKE '%deleted%' and date_to_utc is null;

CREATE  OR REPLACE VIEW vw_denials_join as
select 
a.transaction_id,a.denial_id,
a.project_id,a.server_id,
a.ts_ms,a.user_id,
b.denial_category,b.denial_date,b.denial_type,
COALESCE(NULLIF(b.error_message, ''), 'Not Available')  AS error_message,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(b.product_name, ''), 'Not Available')  AS product_name,-- was changed by RG on 20/11/2024 to coalese + NULLIF + -- was changed from feature_name  to product_name by RG 19/082024
b.license_id,
COALESCE(NULLIF(b.major_err::TEXT, ''), 'Not Available')  AS major_err,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(b.minor_err::TEXT, ''), 'Not Available')  AS minor_err,-- was changed by RG on 07/11/2024 to coalese + NULLIF
b.num_of_licenses,
COALESCE(NULLIF(b.status, ''), 'Not Available')  AS status,-- was changed by RG on 07/11/2024 to coalese + NULLIF
f.default_group_id AS grp_id,
CAST(NULL AS int) AS denial_hour_in_day_utc,  -- Not Required***
b.denial_category AS category,
COALESCE(NULLIF(e.server_port::TEXT, ''), 'Not Available')  AS host_port,-- was changed by RG on 07/11/2024 to coalese + NULLIF
b.denial_date AS date_utc,
date_trunc('hour', b.denial_date::timestamp) AS denial_hour_utc,
date_trunc('week', b.denial_date::timestamp) AS denial_week_utc,
date_trunc('month',b.denial_date::timestamp) AS denial_month_utc,
CAST(NULL AS timestamp) AS denial_timestamp, -- Not Required till date
CAST(NULL AS timestamp) AS user_timestamp, -- Not Required till date
CAST(NULL AS timestamp) AS grp_timestamp, -- Not Required till date
CAST(NULL AS timestamp) AS licsrv_timestamp, -- Not Required till date
COALESCE(NULLIF(a.host_name, ''), 'Not Available')  AS workstation, -- Host Name of user-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(b.vendor, ''), 'Not Available')  AS vendor,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(b.version, ''), 'Not Available')  AS version,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(b.license_type, ''), 'Not Available')  AS license_type,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(d.server_name, ''), 'Not Available')  AS licsrv_description,-- was changed by RG on 07/11/2024 to coalese + NULLIF
CAST(NULL AS CHARACTER VARYING(1000)) AS licsrv_timezone,  -- Not Required till date
d.license_manager_type AS licsrv_licmanager,
d.is_token_enabled AS licsrv_istokenenabled,
f.country AS user_country,
f.mobile_phone AS user_mobile_phone,
COALESCE(NULLIF(LOWER(f.user_name), ''), 'Not Available')  AS user_lower_user_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(g.group_name, ''), 'Not Available')  AS grp_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
g.is_user_group AS grp_is_user_group,
g.is_computer_group AS grp_is_computers_group,
f.display_name AS user_display_name,
f.phone_number AS user_phone_number,
f.description AS user_description,
f.office AS user_office,
f.is_enabled AS user_is_valid,
f.email AS user_email,
COALESCE(NULLIF(b.additional_key, ''), 'Not Available')  AS additional_key,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(e.host_name, ''), 'Not Available')  AS host_name,-- --- Server Host Name  was changed by RG on 07/11/2024 to coalese + NULLIF
CAST(NULL AS CHARACTER VARYING(1000)) AS series_no,  -- Not Required
COALESCE(f.user_name,'Not Available') AS user_name, -- was changed by RG on 05/11/2024 to coalese
COALESCE(NULLIF(f.first_name, ''), 'Not Available')  AS user_first_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(f.last_name, ''), 'Not Available')  AS user_last_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(b.feature_name, ''), 'Not Available')  AS feature_name,-- -- was changed from license_name  to feature_name by RG 19/08/2024 + was changed by RG on 07/11/2024 to coalese + NULLIF
h.project_name AS project_name,
i.region AS region,
f.department AS department
from 
          denials_fact_table a 
	 JOIN denials_transaction b ON a.denial_id = b.denial_id
--LEFT JOIN license_details_dimension c ON b.license_id = c.license_id
LEFT JOIN license_server_dimension d ON a.server_id = d.server_id
LEFT JOIN license_server_host e ON a.server_id = e.server_id
LEFT JOIN user_details_dimension f ON a.user_id = f.user_id
LEFT JOIN group_details_dimension g ON f.default_group_id = g.group_id
LEFT JOIN project_details_dimension h ON a.project_id = h.project_id
LEFT JOIN country_dimension i ON i.country= f.country
;

CREATE VIEW vw_denials_realtime_DQ
as
select 
a.denial_id, a.denial_date,
EXTRACT(hour from  a.denial_date) AS denial_hour_utc,
cast(a.denial_date as DATE) AS denial_date_utc,
LDD.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
a.ts_ms from denials_transaction a
left join license_details_dimension LDD on a.license_id=LDD.license_id;


 CREATE   VIEW vw_dongle_monitoring AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY a.monitoring_id) AS row_number,
    CAST(NULL AS int) AS agent_status_id,
    a.device_connected_date_time,
    a.last_update_date_time,
    a.device_disconnected_date_time,
    CAST(b.blacklisted_when_connected_or_disconnected AS char) AS blacklisted_when_connected_or_disconnected,
    a.monitoring_id,
    b.device_id AS device_identifier,
b.device_name AS device_name,
b.device_description AS device_description,
b.manufacturer AS manufacturer,
a.user_name AS user_name,
a.host_name AS host_name,
b.serial_no AS serial_number,
a.customer_id AS customer_id,
a.agent_status AS agent_status,
a.ts_ms
from dongle_transaction a
JOIN dongle_details_dimension b ON a.serial_no = b.serial_no;

CREATE OR REPLACE VIEW vw_license_allocation_transaction
as 
select 
lat.allocation_id, lat.end_date_utc,lat.license_id,lat.start_date_utc,lat.user_id,
COALESCE(NULLIF(ls.server_name, ''), 'Not Available')  AS server_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(ld.vendor, ''), 'Not Available')  AS vendor,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(ld.license_type, ''), 'Not Available')  AS license_type,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(ld.version, ''), 'Not Available')  AS Version_Name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(ld.feature_name, ''), 'Not Available')  AS Feature_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
COALESCE(NULLIF(ld.product_name, ''), 'Not Available')  AS Product_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF-- was changed from feature_name to product_name 19/08/2024 
COALESCE(NULLIF(ud.user_name, ''), 'Not Available')  AS user_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
lat.ts_ms
from 
     license_allocation_transaction lat
left join(select a.license_id, a.license_type, a.version, a.server_id, 
          a.product_name,--was added by RG 19/08/2024
          a.feature_name, -- was changed from lincense_name to feature_name 19/08/2024 by RG
		  a.vendor
            from license_details_dimension a
		 ) ld
	on lat.license_id = ld.license_id
left join (select a.server_id, a.server_name, a.vendor
             from license_server_dimension a
          ) ls
  on ld.server_id = ls.server_id
left join (select a.user_id, a.user_name
             from user_details_dimension a
		   ) ud
    on ud.user_id = lat.user_id;

-- vw_license_concurrent_measure source

CREATE OR REPLACE VIEW vw_license_concurrent_measure
AS SELECT ldd.license_id,
    COALESCE(NULLIF(ldd.feature_name::text, ''::text), 'Not Available'::text) AS feature_name,
    ldd.license_type,
    COALESCE(NULLIF(ldd.vendor::text, ''::text), 'Not Available'::text) AS vendor,
    COALESCE(lcm.date_utc::timestamp without time zone, (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text))::date AS start_date_utc,
    ldd.product_name,
    COALESCE(NULLIF(ldd.version::text, ''::text), 'Not Available'::text) AS version,
    COALESCE(NULLIF(ldd.additional_key::text, ''::text), 'Not Available'::text) AS additional_key,
    COALESCE(NULLIF(lsd.server_name::text, ''::text), 'Not Available'::text) AS server_name,
    COALESCE(lcm.hour, 0) AS hour,
    ldd.quantity,
    COALESCE(lcm.max_concurrent_usage, 0::bigint) AS max_concurrent_usage,
    COALESCE(lcm.min_concurrent_usage, 0::bigint) AS min_concurrent_usage,
    COALESCE(lcm.avg_concurrent_usage, 0::double precision) AS avg_concurrent_usage,
    COALESCE(lcm.ts_ms, (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text)) AS ts_ms,
        CASE
            WHEN ldd.quantity = 0 THEN 0::numeric
            ELSE round(COALESCE(lcm.max_concurrent_usage, 0::bigint)::numeric * 100.0 / ldd.quantity::numeric, 2)
        END AS usage_per
   FROM license_details_dimension ldd
     LEFT JOIN license_concurrent_measure lcm ON ldd.license_id = lcm.license_id
     LEFT JOIN license_server_dimension lsd ON ldd.server_id = lsd.server_id
  WHERE ldd.license_type::text <> 'unmanaged'::text AND ldd.quantity > 0;


CREATE  VIEW vw_license_concurrent_measure_pct
as
select
license_id,
feature_name, 
start_date_utc,	
hour	,
num_concur_usages	,
Total_QTY	,
"%_of_total_number_of_licenses_from_quantity",
cast(avg(uuuu."%_of_total_number_of_licenses_from_quantity") over (partition by uuuu.start_date_utc order by uuuu.start_date_utc) as int) as "avg_%_of_total_number_of_licenses_from_quantity",
case when cast(cast(avg(uuuu."%_of_total_number_of_licenses_from_quantity") over (partition by uuuu.start_date_utc order by uuuu.start_date_utc) as int) as varchar(10)) < '0' 
     then 'unlimited'
	 else cast(cast(avg(uuuu."%_of_total_number_of_licenses_from_quantity") over (partition by uuuu.start_date_utc order by uuuu.start_date_utc)as int) as varchar(10)) ||  ' %' 
	 end as "%_of_total_number_of_licenses_from_quantity_str",
ts_ms
from (
select distinct 
license_id,
feature_name, 	
start_date_utc,	
hour,	
tot_sum as num_concur_usages,
cast(sum(quantity) as int)  as Total_QTY,
"%_of_total_number_of_licenses_from_quantity",
max(ts_ms) as ts_ms
from(
	select uu.*,
	cast(ROUND(cast(uu.tot_sum/cast(uu.quantity as float) as numeric),2)*100  as int)  as  "%_of_total_number_of_licenses_from_quantity"
     from (
			select 
			u.license_id,u.feature_name, 
			cast(u.start_time_utc as date) as start_date_utc, 
			u.hour ,
			u.quantity,
			u.quantity_str,
			sum(u.tot) as tot_sum,
			max(u.ts_ms) as ts_ms
			from(
			select distinct  
			a.license_id, 
			b.feature_name,	
			a.start_time_utc ,
			EXTRACT(hour from a.start_time_utc) as "hour", 
			case when b.quantity = 0
				 then 0.001
				 else b.quantity
				 end quantity,
			case when cast(b.quantity as varchar(8)) = '-99'
				  then 'UNLIMITED'
				  else cast(b.quantity as varchar(8)) 
				  end quantity_str,
			sum(a.num_of_licenses) as tot,
			max(a.ts_ms) as ts_ms
			from      
				  license_transaction a
			 join license_details_dimension b
			on a.license_id = b.license_id
			group by 
			a.license_id, 
			b.feature_name, 	
			a.start_time_utc,
			EXTRACT(hour from a.start_time_utc) , 
			b.quantity
			) u 
			group by 
			u.license_id,u.feature_name, 
			cast(u.start_time_utc as date), u.hour ,u.quantity, u.quantity_str
		) uu
    )uuu
group by 
license_id,
feature_name,	
start_date_utc,	
hour,
tot_sum,
"%_of_total_number_of_licenses_from_quantity"
) uuuu
;

CREATE VIEW vw_license_idle_time as 
select  
c.license_id as feature_name, 
sum(c.idle_time) as idle_time ,
max(c.ts_ms) as ts_ms
from
(select b.license_id, b.start_time_utc, b.end_time_utc,b.end_time_utc_calc, 
b.idle_time,b.ts_ms
from (
	     select a.license_id, 
	            a.start_time_utc, 
	            a.end_time_utc,
	            a.end_time_utc_calc, 
	            EXTRACT(MINUTE from max(a.start_time_utc) - min(a.end_time_utc_calc)) AS idle_time,
	            a.ts_ms 
		      from (
				    SELECT license_id, start_time_utc,end_time_utc,
			           LAG(end_time_utc, 1) OVER(ORDER BY license_id,end_time_utc ASC) AS end_time_utc_calc,
				       ts_ms
		              FROM license_transaction 
				       where end_time_utc is not null 
			         ) as a
	           group by 
	            a.license_id, 
	            a.start_time_utc, 
	            a.end_time_utc,
	            a.end_time_utc_calc,
	            a.ts_ms
        ) as b
		where b.idle_time  >= 5 
     ) as c
group by c.license_id
;

CREATE OR REPLACE VIEW vw_license_join as
select 
    a.usage_id,a.borrowed,
	a.duration,
	a.start_time_utc,
	a.end_time_utc,
	cast(a.start_time_utc as date) as start_date_utc,
    a.idle_time,
	COALESCE(NULLIF(j.host_ip, ''), 'Not Available') AS remote_ip,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	a.num_of_licenses,
	a.license_id,
	a.group_id,
	COALESCE(NULLIF(a.host_id, 'NULLID'), 'Not Available') AS host_id,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	a.project_id,a.server_id,
	a.ts_ms,
	a.user_id,
    COALESCE(NULLIF(i.host_name, ''), 'Not Available')  AS host_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
    COALESCE(NULLIF(d.user_name, ''), 'Not Available')  AS user_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(d.first_name, ''), 'Not Available') AS first_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(d.last_name, ''), 'Not Available')  AS last_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
    d.display_name,
	COALESCE(NULLIF(d.department, ''), 'Not Available') AS department,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(d.email, ''), 'Not Available')      AS email,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(d.country, ''), 'Not Available')    AS country,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	h.country_code,
    d.mobile_phone,
    c.license_id AS lic_inv_id,   --- License_id   from license_details_dimention table(c)
    COALESCE(NULLIF(c.vendor, ''), 'Not Available') AS lic_inv_vendor, -- was changed by RG on 07/11/2024 to coalese + NULLIF
    COALESCE(NULLIF(c.feature_name, ''), 'Not Available')  AS feature_name, -- -- was changed from license_name  to feature_name by RG 21/082024  + was changed by RG on 07/11/2024 to coalese + NULLIF
	c.quantity AS lic_inv_quantity,     -- quantity table B
	COALESCE(NULLIF(c.license_type, ''), 'Not Available') AS lic_inv_type, -- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(c.version, ''), 'Not Available') AS lic_inv_version, -- was changed by RG on 07/11/2024 to coalese + NULLIF
    c.is_token_based,
	COALESCE(NULLIF(c.additional_key, ''), 'Not Available') AS lic_inv_additional_key, -- was changed by RG on 07/11/2024 to coalese + NULLIF
    c.package_id AS fea_package_id,   --- package_id  table B   --not to remove. appear in powerbi
	COALESCE(NULLIF(c.product_name, ''), 'Not Available') AS product_name,--  was changed from feature_name  to product_name table B-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(e.project_name, ''), 'No Project')    AS project_name, -- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(f.group_name, ''), 'Not Available')   AS group_name, -- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(g.server_name, ''), 'Not Available')  AS server_name, -- was changed by RG on 07/11/2024 to coalese + NULLIF
	h.region AS region,
	c.date_from_utc AS date_from_utc,
	c.date_to_utc AS date_to_utc,
	c.quantity,
	c.package_id,
	d."source"
from(
select 
a.usage_id,a.borrowed,a.duration,a.start_time_utc,a.end_time_utc,cast(a.start_time_utc as date) as start_date_utc,
a.idle_time,a.remote_ip,a.num_of_licenses,a.license_id as license_id,
b.group_id,b.host_id,b.project_id,b.server_id,b.tenant_id,b.ts_ms,b.user_id,
a.license_id AS id
FROM   (select a.usage_id,a.borrowed,a.duration,a.start_time_utc,a.end_time_utc,a.remote_ip,
               a.idle_time,a.license_id,a.num_of_licenses, cast(a.start_time_utc as date) start_date_utc
         from license_transaction AS a
		 ) a
     JOIN  (select b.usage_id,b.group_id,b.host_id,b.project_id,b.server_id,b.tenant_id,b.ts_ms,b.user_id, cast(b.ts_ms as date) ts_ms_date
	        from license_fact_table b )AS b 
	ON a.usage_id = b.usage_id
	) a 
LEFT JOIN license_details_dimension AS c 
   ON a.id = c.license_id  
LEFT JOIN user_details_dimension AS d 
   ON a.user_id = d.user_id  
LEFT JOIN project_details_dimension e 
  ON e.project_id = a.project_id 
LEFT JOIN group_details_dimension f 
  ON f.group_id = a.group_id 
LEFT JOIN license_server_dimension g 
  ON g.server_id = a.server_id 
LEFT JOIN country_dimension h 
  ON h.country= d.country
LEFT JOIN license_server_host i
    ON a.server_id = i.server_id
LEFT JOIN host_details_dimension j
    ON a.host_id = j.host_name;

CREATE OR REPLACE VIEW vw_license_procurement AS						   
SELECT distinct
	ls.server_name,
	ld.vendor,
	ld.feature_name, 
	ld.product_name, 
	ld.additional_key, 
    lp.issued_date,
    lp.start_date,
    lp.expiration_date,
    lp.quantity,
	ld.version,
	ld.license_type,
	lp.asset_info    
FROM
	license_procurement_table lp
	inner JOIN license_details_dimension ld ON ld.license_id = lp.license_id
    inner JOIN license_server_dimension ls ON ld.server_id = ls.server_id;

CREATE VIEW vw_license_realtime_DQ
as
select 
a.usage_id, 
a.start_time_utc,
EXTRACT(hour from a.start_time_utc) AS start_hour_utc,
cast(a.start_time_utc as date) AS start_date_utc,
a.end_time_utc,
LDD.feature_name,
a.ts_ms 
from license_transaction a
left join license_details_dimension LDD 
on a.license_id=LDD.license_id
;
CREATE OR REPLACE VIEW vw_license_server_status AS 
SELECT LSS.transaction_id,
 LSS.server_id,
 COALESCE(NULLIF(LSD.server_name::TEXT, ''), 'Not Available')  AS server_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
 COALESCE(NULLIF(LSD.status_description::TEXT, ''), 'Not Available')  AS status_description,-- was changed by RG on 06/12/2024 to coalese + NULLIF
 COALESCE(NULLIF(LSD.license_manager_type, ''), 'Not Available')  AS license_manager_type,-- was changed by RG on 07/11/2024 to coalese + NULLIF
 COALESCE(NULLIF(LSS.host_name, ''), 'Not Available')  AS host_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
 LSS.server_port,
 COALESCE(NULLIF(LSS.host_status, ''), 'Not Available')  AS host_status,-- was changed by RG on 07/11/2024 to coalese + NULLIF
 COALESCE(NULLIF(LSS.server_status, ''), 'Not Available')  AS server_status,-- was changed by RG on 07/11/2024 to coalese + NULLIF
 LSS.update_date_utc,
 LSS.ts_ms
FROM license_server_status as LSS
LEFT JOIN license_server_dimension as LSD 
on LSD.server_id=LSS.server_id;

CREATE  VIEW vw_license_time
AS
SELECT 
    LDD.date_from_utc,
    LDD.date_to_utc,
    LDD.feature_name,
    LDD.license_id,
    LDD.ts_ms,   
    CAST(CASE 
        WHEN LDD.date_to_utc IS NULL THEN 9999
        WHEN LDD.date_to_utc >= now() 
		THEN EXTRACT(EPOCH from LDD.date_to_utc - now())/3600.0
        ELSE 0
    END as numeric(18,0)) AS TimeLeft,
    cast(CASE 
        WHEN LDD.date_to_utc IS NULL 
		THEN EXTRACT(EPOCH from now() - LDD.date_from_utc)/3600.0
        WHEN LDD.date_to_utc >= now() 
		THEN EXTRACT(EPOCH from LDD.date_to_utc - now())/3600.0
        ELSE EXTRACT(EPOCH from LDD.date_to_utc -  LDD.date_from_utc)/3600.0
    END as numeric(18,0)) AS TimeFromStart

FROM 
    license_details_dimension AS LDD;
	
	
	
-- select now() at time zone 'utc';
-- SELECT now() + '1 hour'::interval

-- select EXTRACT(HOUR from (now() + '1 hour'::interval) - now())

-- select current_timestamp at time zone 'utc';

-- vw_license_usage_percentage source

CREATE OR REPLACE VIEW vw_license_usage_percentage
AS SELECT license_id,
    feature_name,
    sum(num_of_licenses) AS total_num_of_times_license_usages_during_lifecycle_period,
    qty AS purchased_qty,
    round((sum(num_of_licenses) / sum(qty) * 100.0::double precision)::numeric, 2) AS total_percentage_licenses_used,
    max(start_time_utc) AS start_time_utc,
    max(ts_ms) AS ts_ms
   FROM ( SELECT u.license_id,
            u.feature_name,
            u.start_time_utc,
            u.end_time_utc,
            u.qty::double precision AS qty,
            u.num_of_licenses::double precision AS num_of_licenses,
            u.ts_ms
           FROM ( SELECT b.license_id,
                    b.feature_name,
                    b.quantity AS qty,
                    a.num_of_licenses,
                    a.start_time_utc,
                    a.end_time_utc,
                    a.ts_ms
                   FROM license_transaction a
                     JOIN license_details_dimension b ON a.license_id = b.license_id) u) uu
  GROUP BY qty, feature_name, license_id;
  
create or replace  view vw_license_user_allocation_time_calculation as
select a.license_id, 
EXTRACT(HOUR from (coalesce(a.end_date_utc,CURRENT_TIMESTAMP)- a.start_date_utc) ) totalDuration,
case when a.end_date_utc is null
then 'No' 
else 'Yes' 
end as isExpired,
case when a.end_date_utc is null 
then EXTRACT(HOUR from CURRENT_TIMESTAMP- a.start_date_utc) 
else EXTRACT(HOUR from a.end_date_utc - a.start_date_utc)
end as TimeUsed,
case when a.end_date_utc is null then
EXTRACT(HOUR from (coalesce(a.end_date_utc,CURRENT_TIMESTAMP)- CURRENT_TIMESTAMP)) 
else
0 
end as TimeLeft, a.ts_ms
from license_allocation_transaction as a;
CREATE OR REPLACE  VIEW vw_not_used_licenses AS

SELECT ldd.license_id,
	COALESCE(NULLIF(ldd.feature_name, ''), 'Not Available')  AS feature_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
    ldd.product_name,
	COALESCE(NULLIF(ldd.license_type, ''), 'Not Available')  AS license_type,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(ldd.vendor, ''), 'Not Available')  AS vendor,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(ldd.version, ''), 'Not Available')  AS version,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(ldd.additional_key, ''), 'Not Available')  AS additional_key,-- was changed by RG on 07/11/2024 to coalese + NULLIF
	COALESCE(NULLIF(lsd.server_name, ''), 'Not Available')  AS server_name,-- was changed by RG on 07/11/2024 to coalese + NULLIF
    COUNT(lt.license_id) AS transaction_count
FROM license_details_dimension ldd
LEFT JOIN license_transaction lt
    ON ldd.license_id = lt.license_id
LEFT JOIN 
    license_server_dimension lsd ON ldd.server_id = lsd.server_id
WHERE lt.license_id IS NULL---30460
  AND ldd.date_to_utc IS NULL -- Adding the new condition here 05-12-2024
group by 
ldd.license_id,
    ldd.feature_name,
    ldd.product_name,
    ldd.vendor,
    ldd.license_type,
    ldd.version,
    ldd.additional_key,
	lsd.server_name;
		
/*Explanation:
We perform a LEFT JOIN between the license_details_dimension (ldd) and license_transaction (lt) tables 
based on the license_id column.
The WHERE lt.license_id IS NULL clause ensures that only the records from license_details_dimension 
that do not have a corresponding entry in the license_transaction table are returned.
This will give you the licenses that exist in license_details_dimension 
but are not present in license_transaction.
*/
CREATE OR REPLACE VIEW vw_OfficeUtilizationHours_UTC as 

select usage_id,duration,user_name,lic_inv_id,country,start_date_utc,
end_date_utc,start_time_utc,end_time_utc,shift_starttime_utc,
shift_endtime_utc,avg_daily_working_hours,duration_in_days,
start_date_name,end_date_name,if_startdate_weekend,
if_enddate_weekend,if_startdate_weekend_txt,if_enddate_weekend_txt,
if_weekend_in_the_range,
case 
/*duration = 2 and 3  days*/ /*OfficeUtilization_in_hours_new has startday and endday time calculation only */
/*1*/when uuuu.duration_in_days between  2 and 3 
     and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0  
     and  if_weekend_in_the_range = 0) -- when start and end date not in weekend and there is weekend not in the range
    then (uuuu.OfficeUtilization_in_hours_new 
         + case when (duration_in_days=2 or (start_time_utc > shift_endtime_utc or end_time_utc<shift_starttime_utc and duration_in_days=2))
                then 0
		        else avg_daily_working_hours
	            end
		 )
/*2*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0
      and  if_weekend_in_the_range = 1) --when start and end date not in weekend and there is weekend in the range
     then (uuuu.OfficeUtilization_in_hours_new - avg_daily_working_hours)/**/

/*3*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.start_time_utc > uuuu.shift_endtime_utc)
     then uuuu.OfficeUtilization_in_hours_new

/*4*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.start_time_utc > uuuu.shift_starttime_utc) /*was added new conditions at  at 09/08/2024*/
     then uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from shift_endtime_utc - start_time_utc) -- --subtract only particular hours of the weekend if startdate is weekend

/*5*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.start_time_utc < uuuu.shift_starttime_utc ) /*was added new conditions at  at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from shift_endtime_utc - shift_starttime_utc))--subtract only particular hours of the weekend if startdate is weekend

/*6*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.end_time_utc < uuuu.shift_endtime_utc ) /*was added new conditions at  at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from end_time_utc - shift_starttime_utc))--subtract only particular hours of the weekend if startdate is weekend

/*7*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.end_time_utc > uuuu.shift_endtime_utc ) /*was added new conditions at  at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from shift_endtime_utc - shift_starttime_utc))--subtract only particular hours of the weekend if startdate is weekend

/*8*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1)--when usage starts in weekday and ends in weekend
      and end_time_utc < shift_endtime_utc /*was added new conditions at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from end_time_utc - shift_starttime_utc)) --subtract only particular hours of the weekend if enddate is weekend

/*9*/when uuuu.duration_in_days between  2 and 3
       and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1)--when usage starts in weekday and ends in weekend
       and end_time_utc > shift_endtime_utc /*was added new conditions at 09/08/2024*/
      then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from shift_endtime_utc - shift_starttime_utc)) --subtract only particular hours of the weekend if enddate is weekend

 /* duration =>= 4 or duration < 8*/
/*10*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0) -- when usage start and end days are not weekends
       and  if_weekend_in_the_range = 0 -- weekend not in the interval
      then (uuuu.OfficeUtilization_in_hours_new + avg_daily_working_hours)

/*11*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0) -- when usage start and end days are not weekends
       and  if_weekend_in_the_range = 1 -- weekend in the interval
      then (uuuu.OfficeUtilization_in_hours_new - avg_daily_working_hours)

/*12*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) -- when usage starts in weekend and ends in weekday
       and (uuuu.start_time_utc > uuuu.shift_starttime_utc )
      then (uuuu.OfficeUtilization_in_hours_new - extract(hour from shift_endtime_utc - start_time_utc))

/*13*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) -- when usage starts in weekend and ends in weekday
       and (uuuu.start_time_utc < uuuu.shift_starttime_utc )
      then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from shift_endtime_utc - shift_starttime_utc))

/*14*/when uuuu.duration_in_days between 4 and 7
        and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1) -- when usage starts in weekday and ends in weekend
        and end_time_utc < shift_endtime_utc
      then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from end_time_utc - shift_starttime_utc))

/*15*/when uuuu.duration_in_days between 4 and 7
      and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1) -- when usage starts in weekday and ends in weekend
      and end_time_utc > shift_endtime_utc
     then (uuuu.OfficeUtilization_in_hours_new - EXTRACT(hour from shift_endtime_utc - shift_starttime_utc))

/*16*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 1) -- when usage starts in weekend and ends in weekend
      /*IIF1= if usage starts after shift finished, then 0, othewise if usage started before shift starts, then calculate entire shift hours, othewise calculate difference between start_time and shift_end_time*/
     /*IIF2= if usage finished before shift starts, then 0, othewise if usage ends after shift ends, then calculate difference between shift_starttime_utc and shift_endtime_utc, othewise calculate difference between shift_starttime_utc and end_time_utc*/
 then (uuuu.OfficeUtilization_in_hours_new - ((case when start_time_utc > shift_endtime_utc
											       then 0
											       else (case when start_time_utc< shift_starttime_utc
														      then extract(hour from  shift_endtime_utc - shift_starttime_utc)
														      else extract(hour from  shift_endtime_utc - start_time_utc)
														      end)
											       end)--if usage was after shift finished
												+ (case when end_time_utc < shift_starttime_utc
														then 0
														else (case when end_time_utc > shift_endtime_utc
																   then extract(hour from shift_endtime_utc - shift_starttime_utc)
																   else extract(hour from end_time_utc - shift_starttime_utc)
																   end)
														end )  --if usage was before shift started
												+ avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1)
											  )
                                           )
 /*duration >= 8*/

/*17*/when uuuu.duration_in_days >= 8
        and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0) -- weekend in the interval
     then (uuuu.OfficeUtilization_in_hours_new - (avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7))))
/*18*/when uuuu.duration_in_days >= 8
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) -- from weekend (subtract in-shift hours from first weekend)
     then (uuuu.OfficeUtilization_in_hours_new - (case when start_time_utc > shift_endtime_utc
												       then  0
												       else EXTRACT(hour from shift_endtime_utc - start_time_utc)
												       end )
                                                      + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1)
		  )

/*19*/when uuuu.duration_in_days >= 8
       and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1) -- to weekend(subtract in-shift hours from last weekend )
      then (uuuu.OfficeUtilization_in_hours_new - (case when end_time_utc < shift_starttime_utc
												        then 0
												        else EXTRACT(hour from end_time_utc - shift_starttime_utc)
												        end )--if usage was after shift finished
                                                        + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1)
		   )

/*20*/when uuuu.duration_in_days >= 8
        and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 1) -- from weekend to weekend(subtract in-shift hours from 2 weekends )
    /*case 1= if usage starts after shift finished, then 0, othewise if usage started before shift strats, then calculate entire shift hours, othewise calculate difference between start_time and shift_end_time*/
    /*case 2= if usage finished before shift starts, then 0, othewise if usage ends after shift ends, then calculate difference between shift_starttime_utc and shift_endtime_utc, othewise calculate difference between shift_starttime_utc and end_time_utc*/
      then (uuuu.OfficeUtilization_in_hours_new - (case when start_time_utc > shift_endtime_utc --case 1
												        then 0
												        else (case when start_time_utc< shift_starttime_utc
												             then EXTRACT(hour from  shift_endtime_utc - shift_starttime_utc)
												             else EXTRACT(hour from shift_endtime_utc - start_time_utc)
												             end)
												        end)
													   --if usage was after shift finished
	                                             + (case  when end_time_utc < shift_starttime_utc  --case 2
			                                              then 0
			                                              else (case when end_time_utc > shift_endtime_utc
			                                                         then EXTRACT(hour from  shift_endtime_utc - shift_starttime_utc)
		                                                             else EXTRACT(hour from  end_time_utc - shift_starttime_utc)
														         end )
											           end )--if usage was before shift started

                                                  + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1)
											  )
       else uuuu.OfficeUtilization_in_hours_new
       end OfficeUtilization_in_hours_new1
from (                               /*query 8*/
select usage_id,duration,user_name,lic_inv_id,country,start_date_utc,
end_date_utc,start_time_utc,end_time_utc,shift_starttime_utc,
shift_endtime_utc,avg_daily_working_hours,duration_in_days,
start_date_name,end_date_name,if_startdate_weekend,if_startdate_weekend_txt,if_enddate_weekend_txt,
if_weekend_in_the_range,
if_enddate_weekend,Office_Utilization_in_sec,Office_Utilization_in_min,
Office_Utilization_in_hours,
case
   /*where no usage during shifts*/
/*1*/when uuu.Office_Utilization_in_hours = 0
     then 0
      /*here duration =0 and usage was in weekend only*/
/*2*/when uuu.duration_in_days = 0
	   and uuu.if_startdate_weekend =1 and uuu.if_enddate_weekend = 1
     then 0
	 /*here duration = 1, weekday was no usage, only on weekend was usage*/
/*3*/when uuu.duration_in_days = 1
	  and uuu.if_startdate_weekend = 0/*Friday in israel*/ and uuu.if_enddate_weekend = 1/*Saturday in Israel*/
	  and start_time_utc > shift_endtime_utc
	  then 0
     /*here duration = 1, usage was weekday and weekend, lisence usage starts in the shift, calc only weekday usage*/
/*4*/when uuu.duration_in_days = 1
	   and uuu.if_startdate_weekend = 0/*Friday in israel*/ and uuu.if_enddate_weekend = 1/*Saturday in Israel*/
	   and (start_time_utc > shift_starttime_utc)
	 then EXTRACT(second from shift_endtime_utc - start_time_utc)/3600.0
   /*here duration =1 and usage was in weekend and weekday, lisence usage starts before the shift, but we calc weekday only usage of entire weekday shift*/
/*5*/when uuu.duration_in_days = 1
	  and uuu.if_startdate_weekend = 0/*Friday in israel*/ and uuu.if_enddate_weekend = 1
	  and (start_time_utc < shift_starttime_utc)
	then EXTRACT(second from shift_endtime_utc - shift_starttime_utc)/3600.0
/*here duration =1 and usage was in weekend and weekday, but we take weekday only usage*/
/*6*/when  uuu.duration_in_days = 1
	  and uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
	  and (end_time_utc < shift_starttime_utc) /*lisence usage end before the shift starts*/
	 then 0
/*here duration =1 and usage was in weekend and weekday, but we take weekday only usage*/
/*7*/when  uuu.duration_in_days = 1
	  and uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
	  and (end_time_utc > shift_starttime_utc and end_time_utc > shift_endtime_utc) /*lisence usage ends after the shift starts and finished after shift ends*/
	then EXTRACT(second from shift_endtime_utc - shift_starttime_utc)/3600.0  /*take only weekday usage*/
/*8*/when  uuu.duration_in_days = 1
	  and uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
	  and (end_time_utc > shift_starttime_utc and end_time_utc < shift_endtime_utc) /*lisence usage end after the shift starts and finished before shift ends*/
	 then EXTRACT(second from end_time_utc - shift_starttime_utc)/3600.0  /*take only weekday usage*/
/*9*/when uuu.duration_in_days = 1 /*first day is not relevant  for calc. It is weekend. Only second day is good for calc*/
	     and (uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
		 and (end_time_utc < shift_starttime_utc))
	  then 0
	  else uuu.Office_Utilization_in_hours
	 end as OfficeUtilization_in_hours_new /*result for margins values calculations. Without adding in the entire shifts in the interval*/
from (                                  /*query 7*/
--here we start to recognize and try to remove weekend from the resultset
select usage_id,duration,user_name,lic_inv_id,	country,start_date_utc,
end_date_utc,start_time_utc,end_time_utc,shift_starttime_utc,
shift_endtime_utc,avg_daily_working_hours,duration_in_days,
start_date_name,end_date_name,if_startdate_weekend,if_enddate_weekend,
if_startdate_weekend_txt,if_enddate_weekend_txt,
if_weekend_in_the_range,
Office_Utilization_in_sec,Office_Utilization_in_min,Office_Utilization_in_hours
from(                                         /*query 6*/
select
usage_id,
duration,
user_name,
lic_inv_id,
country	,
start_date_utc,
end_date_utc,
start_time_utc,
end_time_utc,
shift_starttime_utc	,
shift_endtime_utc,
avg_daily_working_hours,
duration_in_days,
start_date_name,
end_date_name,
case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania') and country !='N/A'
					  and start_date_name = 'Saturday'
     then 1
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
					  and start_date_name = 'Friday' and country !='N/A'
	 then 1
	 when start_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
	 then 1
	 else 0
	 end as if_startdate_weekend,
case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','') and country !='N/A'
					  and end_date_name = 'Saturday'
     then 1
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
					  and end_date_name = 'Friday' and country !='N/A'
	 then 1
	 when end_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
	 then 1
	 else 0
	 end as if_enddate_weekend,

	 case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania') and country !='N/A'
					  and start_date_name = 'Saturday'
     then 'weekend'
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
					  and start_date_name = 'Friday' and country !='N/A'
	 then 'weekend'
	 when start_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
	 then 'weekend'
	 else 'weekday'
	 end as if_startdate_weekend_txt,

case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania')
					  and end_date_name = 'Saturday'
     then 'weekend'
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
					  and end_date_name = 'Friday' and country !='N/A'
	 then 'weekend'
	 when end_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
	 then 'weekend'
	 else 'weekday'
	 end as if_enddate_weekend_txt,
case when weeks_number >= 1 then 1 else 0 end as if_weekend_in_the_range,
u.Office_Utilization_in_sec,
u.Office_Utilization_in_min,
u.Office_Utilization_in_hours
from(                               /*query 5*/
select  usage_id,duration,user_name,lic_inv_id,	country,start_date_utc,
start_date_utc_full,end_date_utc,end_date_utc_full,start_time_utc,end_time_utc,
shift_starttime_utc,shift_endtime_utc,avg_daily_working_hours,duration_in_days,
start_date_name,end_date_name,
EXTRACT(day FROM end_date_utc_full - start_date_utc_full)/ 7::int as weeks_number,
Office_Utilization_in_sec,Office_Utilization_in_min,Office_Utilization_in_hours
from (                                  /*query 4*/
select  usage_id,duration,user_name,lic_inv_id,country,start_date_utc,
start_date_utc_full,end_date_utc,end_date_utc_full,start_time_utc,
end_time_utc,shift_starttime_utc,shift_endtime_utc,avg_daily_working_hours,
duration_in_days,start_date_name,end_date_name,Office_Utilization_in_sec,
Office_Utilization_in_sec /60.0 as Office_Utilization_in_min,
Office_Utilization_in_sec / 3600.0 as Office_Utilization_in_hours
from (                                 /*query 3*/
select
usage_id,
duration,
user_name,
lic_inv_id,
country	,
start_date_utc,
start_date_utc_full,
end_date_utc,
end_date_utc_full,
start_time_utc,
end_time_utc,
shift_starttime_utc	,
shift_endtime_utc,
avg_daily_working_hours,
duration_in_days,
start_date_name,
end_date_name,
/*here should be calculated entire office utilization usage also when the usage duration was 2 days and more */
cast((case
	 when duration_in_days > 1 --and(uu.start_time_utc >= uu.shift_starttime_utc and uu.end_time_utc < uu.shift_starttime_utc)
     then uu.Office_Utilization_Hours_in_sec + (duration_in_days-1) * avg_daily_working_hours * 3600.0 /* changed from -2 to -1  09.08.2024*/
	 else uu.Office_Utilization_Hours_in_sec
	 end ) as numeric(18,0))
	 as Office_Utilization_in_sec
from(                                     /*query 2*/
/*here calculates office utilization usage at the first day(if it was) and at the lastday (if it was)*/
select
usage_id,
duration,
user_name,
lic_inv_id,
country	,
start_date_utc_full,
start_date_utc,
end_date_utc_full,
end_date_utc,
start_time_utc,
end_time_utc,
shift_starttime_utc	,
shift_endtime_utc,
avg_daily_working_hours,
duration_in_days,
start_date_name,
end_date_name,
/*in seconds*/
case
/*1*/when (start_date_utc = end_date_utc and start_time_utc > shift_endtime_utc and end_time_utc < shift_starttime_utc) --in-day usage. when usage start after shift ended and usage finished before shift start
	 then 0
/*2*/when (start_date_utc = end_date_utc and start_time_utc >= shift_starttime_utc and end_time_utc <= shift_endtime_utc and end_time_utc != '23:59:57') -- in-day usage. usage was during the shift
	 then EXTRACT(second from end_time_utc - start_time_utc)

/*3*/when (start_date_utc = end_date_utc and start_time_utc < shift_starttime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57') -- in-day usage. usage start before shift and finished before shift starts
	 then 0

/*4*/when (start_date_utc = end_date_utc and start_time_utc < shift_starttime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57') -- in-day usage. usage start before shift and finished before shift ended
	 then EXTRACT(second from end_time_utc - shift_starttime_utc)

/*5*/when (start_date_utc = end_date_utc and start_time_utc < shift_starttime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57') -- in-day usage. usage start before shift and finished after shift ended
	 then EXTRACT(second from shift_endtime_utc - shift_starttime_utc)
	 --usage was more then 1 day
/*6*/when (start_date_utc != end_date_utc  and start_time_utc > shift_endtime_utc and shift_starttime_utc < shift_endtime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57' ) -- more the 1 day usage. when usage start after shift ended and usage finished before shift start
     then 0

/*7*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57' )
     then (EXTRACT(second from '23:59:57' - shift_starttime_utc) + EXTRACT(second from shift_endtime_utc - '00:00:01')) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first day before shift starts and usage was after shift ended in the last day from 00:00:00

/*8*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc  and end_time_utc != '23:59:57' )
     then (EXTRACT(second from '23:59:57' - start_time_utc) + EXTRACT(second from  end_time_utc - '00:00:01')) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first day after shift starts and usage was after shift ended in the last day from 00:00:00

/*9*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57' )
     then (EXTRACT(second from '23:59:57' - shift_starttime_utc) + EXTRACT(second from shift_endtime_utc - '00:00:01')) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first after shift starts and usage was before shift ended in the last day from 00:00:00

/*10*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57' )
     then (EXTRACT(second from '23:59:57' - shift_starttime_utc) + EXTRACT(second from shift_endtime_utc - '00:00:01')) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first before shift starts and usage was after shift ended in the last day from 00:00:00

/*11*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57')
	 then (EXTRACT(second from shift_endtime_utc - shift_starttime_utc) + 0 )--when  usage was in the whole 1st day and no usage in the last day(usage was finished before last day shift was started) with duration > 1

/*12*/when (start_date_utc != end_date_utc  and start_time_utc > shift_endtime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57')
	 then (EXTRACT(second from end_time_utc - shift_starttime_utc))   --when in 1st day was no usage and usage was only in last date before shift ended

/*13*/when (start_date_utc != end_date_utc  and start_time_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57')
	 then (EXTRACT(second from shift_endtime_utc - shift_starttime_utc))--when in 1st day was no usage and usage was only in last date after shift ended

/*14*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57')
	 then EXTRACT(second from shift_endtime_utc - start_time_utc) -- when usage was in the 1st after shift stared and no usage in the last day

/*15*/when (start_date_utc != end_date_utc and start_time_utc > shift_starttime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57')
	 then (EXTRACT(second from shift_endtime_utc - start_time_utc) + EXTRACT(second from shift_endtime_utc - shift_starttime_utc))-- when usage was starts after shift started and ends after shift ends(we calaculated first and last usage days) -> additional whole day will added further

/*16*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57')
     then EXTRACT(second from shift_endtime_utc - shift_starttime_utc) +  EXTRACT(second from end_time_utc - shift_starttime_utc) -- when usage was started before shift starts and ends before shift ends(we calaculated first and last usage days)
	                        /*!!!!   change beneath from start_time_utc to shift_starttime_utc in datediff 1 */
/*17*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57')
     then EXTRACT(second from shift_endtime_utc - shift_starttime_utc) + EXTRACT(second from shift_endtime_utc - shift_starttime_utc)-- when usage was started before shift starts and ends after shift ends(we calaculated first and last usage days)

/*18*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57')
     then EXTRACT(second from shift_endtime_utc - start_time_utc) + EXTRACT(second from end_time_utc - shift_starttime_utc)      -- when usage was started after shift starts and ends before shift ends(we calaculated first and last usage days)
	 else 0
	 end
	 as Office_Utilization_Hours_in_sec
from(                                      /*query 1*/
select distinct
a.usage_id,
a.duration,
a.user_name,
a.lic_inv_id,
case when coalesce(a.country,'N/A') = '' then 'N/A' else coalesce(a.country,'N/A') end as country,
a.start_time_utc as start_date_utc_full,
a.start_date_utc,
coalesce(a.end_time_utc, now()) as end_date_utc_full,
cast(coalesce(a.end_time_utc, now()) as date) end_date_utc,
cast(a.start_time_utc as time(0)) start_time_utc,
COALESCE(cast(coalesce(a.end_time_utc, now()) as time(0)),cast('23:59:57' AS TIME(0))) as end_time_utc,
coalesce(b.shift_starttime_utc,'9:00:00') shift_starttime_utc,
coalesce(b.shift_endtime_utc,'18:00:00') shift_endtime_utc,
coalesce(b.avg_daily_working_hours,9) avg_daily_working_hours,
EXTRACT(day from coalesce(a.end_time_utc, cast(now() as date)) -a.start_date_utc) as duration_in_days,
TO_CHAR(a.start_date_utc, 'TMDay') as start_date_name,
TO_CHAR(coalesce(a.end_time_utc, now()), 'TMDay') as end_date_name
from vw_license_join a
left join utc_workinghours_dimension b
on a.country_code = b.country_code
)u
) uu
) uuu
)  a 
) u
) uu
) uuu
) uuuu
--where uuuu.usage_id = 7
;

--select cast('23:59:57' AS TIME(0));

create  or replace view  vw_process_all 
as
select 
pft.host_name, pft.monitoring_id, pft.session_id , pft.transaction_id, pft.user_id, pft.user_name,
psdt.shutdown_reason,psdt.process_id,psdt.customer_id,psdt.agent_status,psdt.session_start_time,
psdt.session_end_time,psdt.total_idle_time_in_min,psdt.session_duration_in_min,
pd.dll_name,pd.process_name, pd."version"
 from (select  pft.*, ud.user_name
         from     process_fact_table pft
         left join user_details_dimension ud
             on pft.user_id = ud.user_id
		) pft  --- 16032
LEFT JOIN (SELECT
				  session_id
				, shutdown_reason
				, process_id
				, customer_id
				, agent_status
				, session_start_time
				, session_end_time
				, total_idle_time_in_min
				, session_duration_in_min
				,ts_ms
				FROM
				  process_session_details_transaction
			) psdt
     on pft.session_id = psdt.session_id

LEFT JOIN (select 
               process_id,dll_name,process_name, "version"
             from process_details_dimension ) pd
    ON pd.process_id = psdt.process_id;

-- vw_procured_licenses source

CREATE OR REPLACE VIEW vw_procured_licenses
AS SELECT COALESCE(NULLIF(ls.server_name::text, ''::text), 'Not Available'::text) AS server_name,
    COALESCE(NULLIF(ld.vendor::text, ''::text), 'Not Available'::text) AS vendor,
    COALESCE(NULLIF(ld.feature_name::text, ''::text), 'Not Available'::text) AS feature_name,
    COALESCE(NULLIF(ld.product_name::text, ''::text), 'Not Available'::text) AS product_name,
    COALESCE(NULLIF(ld.additional_key::text, ''::text), 'Not Available'::text) AS additional_key,
    lp.issued_date,
    lp.start_date,
    lp.expiration_date,
    lp.quantity,
    COALESCE(NULLIF(ld.version::text, ''::text), 'Not Available'::text) AS version,
    COALESCE(NULLIF(ld.license_type::text, ''::text), 'Not Available'::text) AS license_type,
    COALESCE(NULLIF(lp.asset_info::text, ''::text), 'Not Available'::text) AS asset_info,
    count(DISTINCT lat.user_id) AS allocated,
    lp.quantity - count(DISTINCT lat.user_id) AS total_available,
        CASE
            WHEN lp.quantity > 0 THEN count(DISTINCT lat.user_id)::numeric * 100.0 / lp.quantity::numeric
            ELSE 0::numeric
        END AS util_percent
   FROM license_details_dimension ld
     LEFT JOIN license_server_dimension ls ON ld.server_id = ls.server_id
     LEFT JOIN license_procurement_table lp ON ld.license_id = lp.license_id
     LEFT JOIN license_allocation_transaction lat ON ld.license_id = lat.license_id
  GROUP BY ls.server_name, ld.vendor, ld.feature_name, ld.product_name, ld.additional_key, lp.issued_date, lp.start_date, lp.expiration_date, lp.quantity, ld.version, ld.license_type, lp.asset_info;

CREATE OR REPLACE  VIEW vw_project_data AS
select ROW_NUMBER() OVER (ORDER BY a.project_id) AS row_number,
CAST(NULL AS int)  AS action,
CAST(NULL AS int)  AS allocate_time,
a.priority AS priority,
CASE 
	WHEN a.priority = '0' THEN 'High'
	WHEN a.priority = '1' THEN 'Medium'
	WHEN a.priority = '2' THEN 'Low'
	ELSE 'Unknown'
END AS priority_text,
a.percent_done AS percent_done,
a.source AS source,
a.start_time_utc AS start_date_utc,
a.end_time_utc AS end_date_utc,
a.is_enabled AS is_enabled,
CAST(NULL AS bit)  AS user_is_default_project,
CAST(NULL AS BIT) AS group_is_default_project,
CAST(NULL AS varchar(1000)) AS id,
a.project_id AS project_id,
a.project_name AS project_name,
d.user_name AS user_name,
c.group_id AS group_id,
e.group_name,
a.ts_ms
from
     project_details_dimension a
JOIN project_user_fact_table b ON a.project_id = b.project_id
JOIN project_group_fact_table c ON a.project_id = c.project_id
JOIN user_details_dimension d ON b.user_id= d.user_id
LEFT JOIN group_details_dimension e ON e.group_id = c.group_id;


CREATE OR REPLACE  VIEW vw_token_statistics AS 
SELECT
ROW_NUMBER() OVER (ORDER BY TBSD.stats_id) AS transaction_id,
TBSD.stats_id,
TBSD.team_id,
TBSD.name AS team_name,
TBSD.available,
TBSD.consumed,
TBSD.total_quantity,
TBSD.server_id,
LSD.server_name,
LSD.vendor,
LSD.license_manager_type,
LSD.status_description,
TBSD.ts_ms

FROM token_based_statistics_dimension AS TBSD
LEFT JOIN license_server_dimension AS LSD ON TBSD.server_id = LSD.server_id;

CREATE OR REPLACE VIEW vw_token_usage AS
SELECT 
    TBT.usage_id,
    TBT.usage_date,
    TBT.number_of_tokens,
	LDD.quantity,
    TBT.license_id,
	LDD.feature_name, 
	LDD.product_name, 
	LDD.vendor,
    TBUF.user_id,
	UDD.user_name,
	UDD.first_name,
	UDD.last_name,
	UDD.email,
    TBUF.server_id,
	LSD.server_name,
	LSD.status_description,
    SUM(TBT.number_of_tokens) OVER (ORDER BY TBT.usage_date) AS cumulative_tokens_used,
    TBT.ts_ms
FROM 
    token_based_transaction AS TBT
JOIN 
    token_based_user_fact AS TBUF ON TBT.usage_id = TBUF.usage_id
LEFT JOIN user_details_dimension AS UDD ON TBUF.user_id = UDD.user_id
LEFT JOIN license_server_dimension AS LSD ON TBUF.server_id = LSD.server_id
LEFT JOIN license_details_dimension AS LDD ON TBT.license_id = LDD.license_id;









-- vw_touchpoint_details source

CREATE OR REPLACE VIEW vw_touchpoint_details
AS WITH cte_touchpoint AS (
         SELECT row_number() OVER (ORDER BY a.event_id) AS row_number,
            a.event_type,
            a.event_date_time,
            a.event_id AS id,
            a.user_name,
            a.host_name AS workstation,
            a.touchpoint_event_source,
            a.found_url,
            split_part(a.found_url, '/'::text, 3) AS website,
            "substring"(a.found_url, strpos(a.found_url, '//'::text) + 2, length(a.found_url)) AS domain,
            a.page_title,
            a.event_type_desc,
            a.customer_id,
            a.user_id,
            a.ts_ms
           FROM touchpoint_transaction a
          WHERE a.found_url ~~ '%.com'::text
        )
 SELECT row_number,
    event_type,
    event_date_time,
    id,
    user_name,
    workstation,
    touchpoint_event_source,
    found_url,
    website,
    domain,
    page_title,
    event_type_desc,
    customer_id,
    user_id,
    ts_ms
   FROM cte_touchpoint;

-- vw_used_licenses_cost source

CREATE OR REPLACE VIEW vw_used_licenses_cost
AS SELECT plcmd.cost_id,
    plcmd.license_id,
    plcmd.unit_cost,
    plcmd.purchase_currency,
    plcmd.conversion_factor,
    plcmd.procurement_country_code,
    plcmd.duration_value,
    plcmd.duration_unit,
    plcmd.ts_ms,
    ldd.date_from_utc,
    ldd.date_to_utc,
    ldd.feature_name,
    ldd.license_type,
    ldd.product_name,
    ldd.vendor,
    ldd.package_id,
    udd.user_name,
    ldd.quantity,
    lt.start_time_utc,
    lt.end_time_utc,
    lt.num_of_licenses,
    COALESCE(EXTRACT(epoch FROM lt.end_time_utc - lt.start_time_utc) / 3600.00, 0.0) AS usage_time_hrs,
    (plcmd.unit_cost * plcmd.conversion_factor / plcmd.duration_value::double precision)::numeric(10,4) AS hourly_cost
   FROM procured_license_cost_mapping_dimension plcmd
     LEFT JOIN license_details_dimension ldd ON plcmd.license_id = ldd.license_id
     LEFT JOIN license_transaction lt ON plcmd.license_id = lt.license_id
     LEFT JOIN license_fact_table lft ON lt.usage_id = lft.usage_id
     LEFT JOIN user_details_dimension udd ON lft.user_id::text = udd.user_id::text;

-- vw_process_cost source

CREATE OR REPLACE VIEW vw_process_cost
AS SELECT cmd.cost_id,
    cmd.process_id,
    cmd.host_id,
    cmd.cost,
    cmd.currency,
    cmd.conversion_factor,
    cmd.country_code,
    cmd.duration_value,
    cmd.duration_unit,
    cmd.ts_ms,
    pdd.process_name,
    pdd.dll_name,
    pdd.version,
    hdd.host_name,
    (cmd.cost * cmd.conversion_factor / cmd.duration_value::double precision)::numeric(10,4) AS hourly_cost,
    (cmd.cost * cmd.conversion_factor * 8760::double precision / cmd.duration_value::double precision)::numeric(10,4) AS yearly_cost
   FROM cost_mapping_dimension cmd
     LEFT JOIN process_details_dimension pdd ON cmd.process_id::text = pdd.process_id::text
     LEFT JOIN host_details_dimension hdd ON cmd.host_id::text = hdd.host_id::text;

-- vw_office_time_calculation source

CREATE OR REPLACE VIEW vw_office_time_calculation
AS SELECT o.usage_id,
    o.duration_in_days,
    o.user_id,
    o.lic_id,
    o.start_time_utc,
    o.end_time_utc,
    o.start_date_name,
    o.end_date_name,
    o.if_startdate_weekend,
    o.if_enddate_weekend,
    o.num_weekend_in_range,
    o.country_code,
    o.time_zone,
    o.utc_offset,
    o.utc_diff,
    o.shift_starttime,
    o.shift_endtime,
    o.shift_starttime_utc,
    o.shift_endtime_utc,
    o.avg_daily_working_hours,
    o.utilization_time,
    o.ts_ms,
        CASE
            WHEN COALESCE(u.user_name, 'Not Available'::character varying)::text = ''::text THEN 'Not Available'::character varying
            ELSE COALESCE(u.user_name, 'Not Available'::character varying)
        END AS user_name,
    COALESCE(NULLIF(l.feature_name::text, ''::text), 'Not Available'::text) AS feature_name,
    cd.country
   FROM office_time_calculation o
     LEFT JOIN user_details_dimension u ON o.user_id::text = u.user_id::text
     LEFT JOIN license_details_dimension l ON o.lic_id = l.license_id
     LEFT JOIN country_dimension cd ON o.country_code::text = cd.country_code::text;

-- vw_not_used_licenses_cost source

CREATE OR REPLACE VIEW vw_not_used_licenses_cost
AS WITH cte1 AS (
         SELECT ldd.license_id,
            ldd.package_id,
            ldd.date_from_utc,
            COALESCE(NULLIF(ldd.feature_name::text, ''::text), 'Not Available'::text) AS feature_name,
            ldd.product_name,
            COALESCE(NULLIF(ldd.vendor::text, ''::text), 'Not Available'::text) AS vendor,
            COALESCE(NULLIF(ldd.license_type::text, ''::text), 'Not Available'::text) AS license_type,
            COALESCE(NULLIF(ldd.version::text, ''::text), 'Not Available'::text) AS version,
            COALESCE(NULLIF(ldd.additional_key::text, ''::text), 'Not Available'::text) AS additional_key,
            ldd.quantity,
            COALESCE(NULLIF(lsd.server_name::text, ''::text), 'Not Available'::text) AS server_name,
            lt.start_time_utc,
            lt.end_time_utc,
            lt.usage_id,
            count(lt.license_id) AS transaction_count,
            sum(lt.num_of_licenses) AS num_of_licenses
           FROM license_details_dimension ldd
             LEFT JOIN license_transaction lt ON ldd.license_id = lt.license_id
             LEFT JOIN license_server_dimension lsd ON ldd.server_id = lsd.server_id
          WHERE lt.license_id IS NULL AND ldd.date_to_utc IS NULL
          GROUP BY ldd.license_id, ldd.package_id, ldd.date_from_utc, ldd.feature_name, ldd.product_name, ldd.vendor, ldd.license_type, ldd.version, ldd.additional_key, ldd.quantity, ldd.server_id, lsd.server_name, lt.start_time_utc, lt.end_time_utc, lt.usage_id
        )
 SELECT plcmd.cost_id,
    plcmd.license_id,
    plcmd.unit_cost,
    plcmd.purchase_currency,
    plcmd.conversion_factor,
    plcmd.procurement_country_code,
    plcmd.duration_value,
    plcmd.duration_unit,
    plcmd.ts_ms,
    c.package_id,
    c.date_from_utc,
    c.feature_name,
    c.product_name,
    c.vendor,
    c.license_type,
    c.version,
    c.additional_key,
    c.quantity,
    c.server_name,
    c.transaction_count,
    c.num_of_licenses,
    c.start_time_utc,
    c.end_time_utc,
    udd.user_name,
    COALESCE(EXTRACT(epoch FROM c.end_time_utc - c.start_time_utc) / 3600.00, 0.0) AS usage_time_hrs,
    (plcmd.unit_cost * plcmd.conversion_factor / plcmd.duration_value::double precision)::numeric(10,4) AS hourly_cost
   FROM procured_license_cost_mapping_dimension plcmd
     JOIN cte1 c ON plcmd.license_id = c.license_id
     LEFT JOIN license_fact_table lft ON c.usage_id = lft.usage_id
     LEFT JOIN user_details_dimension udd ON lft.user_id::text = udd.user_id::text;

















