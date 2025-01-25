-- dbo.license_procurement_model source

CREATE VIEW license_procurement_model AS
select ld.license_id,ld.feature_name as feature_name,ld.product_name as feature_description,
ld.version,ld.license_type,ld.quantity,ld.package_id,ld.is_token_based,ld.num_of_tokens,ld.vendor,ld.server_id,
lsd.server_name,lsd.license_manager_type,lss.server_status,lp.procurement_id,lp.asset_info,lp.dist_info,lp.components_info,
CAST(
        CASE
            WHEN lp.ts_ms >= lsd.ts_ms AND lp.ts_ms >= lss.ts_ms AND lp.ts_ms >= ld.ts_ms THEN lp.ts_ms
            WHEN lsd.ts_ms >= ld.ts_ms AND lsd.ts_ms >= lss.ts_ms AND lsd.ts_ms >= lp.ts_ms THEN lsd.ts_ms
            WHEN lss.ts_ms >= ld.ts_ms AND lss.ts_ms >= lsd.ts_ms AND lss.ts_ms >= lp.ts_ms THEN lss.ts_ms
            ELSE ld.ts_ms
        END AS DATETIME2
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

    -- dbo.process_model source

CREATE   view process_model as
select pdd.process_id,pdd.process_name,pdd.version,pft.host_name,hdd.host_id,pft.monitoring_id,max(CAST (psdt.ts_ms as datetime2)) as last_update_time,
(select tenant_id from license_fact_table where transaction_id = (SELECT MAX(transaction_id)FROM license_fact_table)) as tenant_id from process_fact_table pft
left join process_session_details_transaction psdt on pft.session_id = psdt.session_id
left join process_details_dimension pdd on psdt.process_id = pdd.process_id
left join host_details_dimension hdd on pft.host_name = hdd.host_name
where hdd.host_id is not null
group by pdd.process_id,pdd.process_name,pdd.version,pft.host_name,hdd.host_id,pft.monitoring_id,tenant_id;

-- dbo.vw_allocated_licenses source

CREATE   VIEW vw_allocated_licenses
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

-- dbo.vw_bottom_features source

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
    ld.feature_name; -- was changed from license_name  to feature_name by RG 19/082024;

-- dbo.vw_bottom_users source

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

    -- dbo.vw_calendar source

CREATE     view vw_calendar as SELECT		distinct
            [Date] as [date]
			,DATEPART(year,[Date]) AS [Year]
			,DATEPART(month,[Date]) AS [Month]
			,DATEPART(day,[Date]) AS [Day]
			,DATEPART(WEEKDAY, [Date]) AS DayoOfWeekNum
			,DATENAME(WEEKDAY, [Date]) AS DayoOfWeek
			,DATEPART(QUARTER, ([Date])) as [Quarter]
FROM		(
			SELECT
				(a.Number * 256) + b.Number AS N
			FROM
				(
					SELECT number
					FROM master..spt_values
					WHERE type = 'P' AND number <= 354
				) a (Number),
				(
					SELECT number
					FROM master..spt_values
					WHERE type = 'P' AND number <= 354
				) b (Number)
			) numbers
CROSS APPLY (SELECT DATEADD(day,N,'1950-1-1') AS [Date]) d;


-- dbo.vw_calendar_with_count source

CREATE    view vw_calendar_with_count as
select 
date_d  as date,
a.DayoOfWeek as DayoOfWeek,
a.Month as month ,
a.Quarter as quarter ,
a.Year as year,
ISNULL(b.num_of_licenses,0) as num_of_licenses,
ISNULL(c.user_id_count,0) as user_id_count,
ISNULL(d.denial_id_count,0) as denial_id_count
from 
 (select cldr.date,CONVERT (date, cldr.date) as date_d,cldr.DayoOfWeek, cldr.Month, cldr.Quarter, cldr.Year 
  from vw_calendar cldr) as a
LEFT JOIN
(  select 
	start_time_utc,
	sum(num_of_licenses) num_of_licenses 
	from (
	select CONVERT(date,lt1.start_time_utc) as start_time_utc, 
		lt1.num_of_licenses
	from license_transaction lt1
) a
group by start_time_utc
 ) as b
  ON b.start_time_utc =  date_d
LEFT JOIN
(select  u.start_date_utc, count(u.user_id) as user_id_count
   from(
   select distinct CONVERT (date,lt.start_time_utc) as start_date_utc,lft.user_id
     from      (select a.user_id, a.usage_id  from license_fact_table a) lft
        join  (select b.usage_id, start_time_utc from license_transaction b) lt
   	   on lft.usage_id = lt.usage_id
	  ) u 
	  group by u.start_date_utc
   ) as c
    ON c.start_date_utc =  a.date_d
LEFT JOIN   
  (select dd.denial_date, count(dd.denial_id) denial_id_count
	from (
			select CONVERT (date,ddd.denial_date) as denial_date, ddd.denial_id
			from denials_transaction ddd
     )dd
  group by dd.denial_date
   ) as d
      ON d.denial_date = a.date_d;



-- dbo.vw_compliance source

CREATE     view vw_compliance
as
select a.license_id as license_id,
b.feature_name as feature_name, -- was changed from license_name  to feature_name by RG 19/082024
a.rule_type as rule_type,
a.rule_value as rule_value,
c.user_id as user_id,
d.user_name as user_name,
d.department as department,
--coalesce(d.country,'') as country,
--coalesce(e.country_code,'')  as country_code,
--coalesce(e.region,'')  as region
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

-- dbo.vw_country source

CREATE   VIEW vw_country AS
SELECT CD.region,CD.country_code,UD.country,UD.user_name,UD.department,UD.default_group_id,UD.email,UD.is_enabled,UD.display_name,UD.ts_ms
FROM
user_details_dimension AS UD
LEFT JOIN
country_dimension AS CD ON CD.country = UD.country;

-- dbo.vw_denials source

CREATE       VIEW vw_denials as
select
iif((isnull(a.host_name, 'Not Available')) = '', 'Not Available', (isnull(a.host_name, 'Not Available'))) as workstation,
a.transaction_id,a.denial_id,
a.user_id,
a.host_name,
f.user_name,
f.first_name,
f.last_name,
b.feature_name,
b.denial_category, -- was added 12-12-2024
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
--LEFT JOIN license_details_dimension c ON b.license_id = c.license_id
LEFT JOIN license_details_dimension c ON b.feature_name = c.feature_name
LEFT JOIN license_server_dimension d ON a.server_id = d.server_id
LEFT JOIN license_server_host e ON a.server_id = e.server_id
LEFT JOIN user_details_dimension f ON a.user_id = f.user_id
LEFT JOIN group_details_dimension g ON f.default_group_id = g.group_id
where d.server_name NOT LIKE '%deleted%' and date_to_utc is null;

-- dbo.vw_denials_aggregation source

CREATE     VIEW vw_denials_aggregation as
select
* from denials_aggregation;

-- dbo.vw_denials_join source

CREATE    VIEW vw_denials_join as
select
a.transaction_id,a.denial_id,
a.project_id,a.server_id,
a.ts_ms,a.user_id,
b.denial_category,b.denial_date,b.denial_type,
iif((isnull(b.error_message, 'Not Available')) = '', 'Not Available', (isnull(b.error_message, 'Not Available'))) as error_message, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(c.product_name, 'Not Available')) = '', 'Not Available', (isnull(c.product_name, 'Not Available'))) as product_name, -- was changed from feature_name  to product_name by RG 19/082024 -- was changed by RG on 06/11/2024 to isnull + iif
b.license_id,
iif((isnull(cast(b.major_err as varchar(25)), 'Not Available')) = '', 'Not Available', (isnull(cast(b.major_err as varchar(25)), 'Not Available'))) as major_err, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(cast(b.minor_err as varchar(25)), 'Not Available')) = '', 'Not Available', (isnull(cast(b.minor_err as varchar(25)), 'Not Available'))) as minor_err, -- was changed by RG on 06/11/2024 to isnull + iif
b.num_of_licenses,
iif((isnull(b.status, 'Not Available')) = '', 'Not Available', (isnull(b.status, 'Not Available'))) as status, -- was changed by RG on 06/11/2024 to isnull + iif
f.default_group_id AS grp_id,
CAST(NULL AS int) AS denial_hour_in_day_utc,  -- Not Required***
b.denial_category AS category,
iif((isnull(cast(e.server_port as varchar(25)), 'Not Available')) = '', 'Not Available', (isnull(cast(e.server_port as varchar(25)), 'Not Available'))) as host_port, -- was changed by RG on 06/11/2024 to isnull + iif
b.denial_date AS date_utc,
DATEADD(hour, DATEDIFF(hour, 0, b.denial_date), 0) AS denial_hour_utc,
DATEADD(week, DATEDIFF(week, 0, b.denial_date), 0) AS denial_week_utc,
DATEADD(month, DATEDIFF(month, 0, b.denial_date), 0) AS denial_month_utc,
CAST(NULL AS datetime) AS denial_timestamp, -- Not Required till date
CAST(NULL AS datetime) AS user_timestamp, -- Not Required till date
CAST(NULL AS datetime) AS grp_timestamp, -- Not Required till date
CAST(NULL AS datetime) AS licsrv_timestamp, -- Not Required till date
iif((isnull(a.host_name, 'Not Available')) = '', 'Not Available', (isnull(a.host_name, 'Not Available'))) as workstation, -- Host Name of user-- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(b.vendor, 'Not Available')) = '', 'Not Available', (isnull(b.vendor, 'Not Available'))) as vendor, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(b.version, 'Not Available')) = '', 'Not Available', (isnull(b.version, 'Not Available'))) as version, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(b.license_type, 'Not Available')) = '', 'Not Available', (isnull(b.license_type, 'Not Available'))) as license_type, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(d.server_name, 'Not Available')) = '', 'Not Available', (isnull(d.server_name, 'Not Available'))) as licsrv_description, -- was changed by RG on 06/11/2024 to isnull + iif
CAST(NULL AS nvarchar(max)) AS licsrv_timezone,  -- Not Required till date
d.license_manager_type AS licsrv_licmanager,
d.is_token_enabled AS licsrv_istokenenabled,
f.country AS user_country,
f.mobile_phone AS user_mobile_phone,
iif((isnull(LOWER(f.user_name), 'Not Available')) ='', 'Not Available',(isnull(LOWER(f.user_name), 'Not Available')))  AS user_lower_user_name,-- was changed by RG on 05/11/2024 to coalese
iif((isnull(g.group_name, 'Not Available')) = '', 'Not Available', (isnull(g.group_name, 'Not Available'))) as grp_name, -- was changed by RG on 06/11/2024 to isnull + iif
g.is_user_group AS grp_is_user_group,
g.is_computer_group AS grp_is_computers_group,
f.display_name AS user_display_name,
f.phone_number AS user_phone_number,
f.description AS user_description,
f.office AS user_office,
f.is_enabled AS user_is_valid,
f.email AS user_email,
iif((isnull(b.additional_key, 'Not Available')) = '', 'Not Available', (isnull(b.additional_key, 'Not Available'))) as additional_key, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(e.host_name, 'Not Available')) = '', 'Not Available', (isnull(e.host_name, 'Not Available'))) as [host_name], --- Server Host Name  -- was changed by RG on 06/11/2024 to isnull + iif
CAST(NULL AS nvarchar(max)) AS series_no,  -- Not Required
iif((isnull(f.user_name, 'Not Available')) = '', 'Not Available', (isnull(f.user_name, 'Not Available'))) as user_name, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(f.first_name, 'Not Available')) = '', 'Not Available', (isnull(f.first_name, 'Not Available'))) as user_first_name, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(f.last_name, 'Not Available')) = '', 'Not Available', (isnull(f.last_name, 'Not Available'))) as user_last_name, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(b.feature_name, 'Not Available')) = '', 'Not Available', (isnull(b.feature_name, 'Not Available'))) as feature_name, -- was changed from license_name  to feature_name by RG 19/082024-- was changed by RG on 06/11/2024 to isnull + iif
h.project_name AS project_name,
i.region AS region,
f.department AS department
from
          denials_fact_table a
	 JOIN denials_transaction b ON a.denial_id = b.denial_id
LEFT JOIN license_details_dimension c ON b.license_id = c.license_id
LEFT JOIN license_server_dimension d ON a.server_id = d.server_id
LEFT JOIN license_server_host e ON a.server_id = e.server_id
LEFT JOIN user_details_dimension f ON a.user_id = f.user_id
LEFT JOIN group_details_dimension g ON f.default_group_id = g.group_id
LEFT JOIN project_details_dimension h ON a.project_id = h.project_id
LEFT JOIN country_dimension i ON i.country= f.country;

-- dbo.vw_denials_realtime_DQ source

CREATE      view vw_denials_realtime_DQ
as
select a.denial_id, a.denial_date,DATEPART(HOUR, a.denial_date) AS denial_hour_utc,
CONVERT(DATE, a.denial_date) AS denial_date_utc,
LDD.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
a.ts_ms from denials_transaction a
left join license_details_dimension LDD on a.license_id=LDD.license_id;

-- dbo.vw_dongle_monitoring source

-- dbo.vw_dongle_monitoring source

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
/*c.user_name AS user_name,
d.host_name AS host_name,*/
a.user_name AS user_name,
a.host_name AS host_name,
b.serial_no AS serial_number,
/*CAST(NULL AS nvarchar(max)) AS customer_id,
CAST(NULL AS nvarchar(max)) AS agent_status*/
a.customer_id AS customer_id,
a.agent_status AS agent_status,
a.ts_ms
from dongle_transaction a
JOIN dongle_details_dimension b ON a.serial_no = b.serial_no
/*JOIN process_fact_table e ON a.monitoring_id = e.monitoring_id
JOIN user_details_dimension c ON c.user_id = e.user_id
JOIN host_details_dimension d ON d.host_name = e.host_name*/
;

-- dbo.vw_license_allocation_transaction source

-- dbo.vw_license_allocation_transaction source

CREATE       VIEW vw_license_allocation_transaction
as
select
lat.allocation_id, lat.end_date_utc,lat.license_id,lat.start_date_utc,lat.user_id,
iif((isnull(ls.server_name, 'Not Available')) = '', 'Not Available', (isnull(ls.server_name, 'Not Available'))) as server_name, -- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(ld.vendor, 'Not Available')) = '', 'Not Available', (isnull(ld.vendor, 'Not Available'))) as vendor,-- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(ld.license_type, 'Not Available')) = '', 'Not Available', (isnull(ld.license_type, 'Not Available'))) as license_type,-- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(ld.version, 'Not Available')) = '', 'Not Available', (isnull(ld.version, 'Not Available'))) as Version_Name,-- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(ld.feature_name, 'Not Available')) = '', 'Not Available', (isnull(ld.feature_name, 'Not Available'))) as Feature_name,-- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(ld.product_name, 'Not Available')) = '', 'Not Available', (isnull(ld.product_name, 'Not Available'))) as Product_name, -- was changed from feature_name to product_name 19/08/2024 by RG-- was changed by RG on 06/11/2024 to isnull + iif
iif((isnull(ud.user_name, 'Not Available')) = '', 'Not Available', (isnull(ud.user_name, 'Not Available'))) as user_name,-- was changed by RG on 06/11/2024 to isnull + iif
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
    on ud.user_id = lat.user_id

left join (select a.project_id, a.project_name, lft.user_id
                from        license_fact_table lft
                right join  project_details_dimension a
                on a.project_id = lft.project_id
            ) pd
    on pd.user_id = lat.user_id;


-- dbo.vw_license_concurrent_measure source

CREATE     view vw_license_concurrent_measure
as
SELECT
ldd.license_id AS license_id,
iif((isnull(ldd.feature_name, 'Not Available')) = '', 'Not Available', (isnull(ldd.feature_name, 'Not Available'))) as feature_name, -- added by RG 11-11-2024 isnull + IIF
ldd.license_type,
iif((isnull(ldd.vendor, 'Not Available')) = '', 'Not Available', (isnull(ldd.vendor, 'Not Available'))) as vendor,-- added by RG 11-11-2024 isnull + IIF
ldd.product_name,
iif((isnull(ldd.version, 'Not Available')) = '', 'Not Available', (isnull(ldd.version, 'Not Available'))) as version,-- added by RG 11-11-2024 isnull + IIF
iif((isnull(ldd.additional_key, 'Not Available')) = '', 'Not Available', (isnull(ldd.additional_key, 'Not Available'))) as additional_key,-- added by RG 11-11-2024 isnull + IIF
iif((isnull(lsd.server_name, 'Not Available')) = '', 'Not Available', (isnull(lsd.server_name, 'Not Available'))) as server_name,-- added by RG 11-11-2024 isnull + IIF
CAST(COALESCE(lcm.date_utc, GETUTCDATE()) AS DATE) AS start_date_utc, -- casting to date
COALESCE(lcm.hour, 0) AS hour,
ldd.quantity AS quantity,
COALESCE(lcm.max_concurrent_usage, 0) AS max_concurrent_usage,
COALESCE(lcm.min_concurrent_usage, 0) AS min_concurrent_usage,
COALESCE(lcm.avg_concurrent_usage, 0) AS avg_concurrent_usage,
COALESCE(lcm.ts_ms, GETUTCDATE()) AS ts_ms,
CASE
WHEN ldd.quantity = 0 THEN 0  -- Avoid division by zero
--ELSE ROUND((COALESCE(lcm.max_concurrent_usage, 0)*100.0 / ldd.quantity),2)
else cast((COALESCE(lcm.max_concurrent_usage, 0)*100.0 / ldd.quantity) as decimal(10,2))
END AS usage_per -- calculating percentage
FROM
license_details_dimension ldd
LEFT JOIN
license_concurrent_measure lcm
ON
ldd.license_id = lcm.license_id
LEFT JOIN
license_server_dimension lsd ON ldd.server_id = lsd.server_id
where ldd.license_type <> 'unmanaged' AND ldd.quantity >0;

-- dbo.vw_license_concurrent_measure_pct source

-- dbo.vw_license_concurrent_measure_pct source

CREATE    view vw_license_concurrent_measure_pct
as
select
license_id,
feature_name, -- was changed from license_name  to feature_name by RG 19/082024
start_date_utc,
hour	,
num_concur_usages	,
Total_QTY	,
[%_of_total_number_of_licenses_from_quantity],
avg(uuuu.[%_of_total_number_of_licenses_from_quantity]) over (partition by uuuu.start_date_utc order by uuuu.start_date_utc) as 'avg_%_of_total_number_of_licenses_from_quantity',
--cast(avg(uuu.[%_of_total_number_of_licenses_from_quantity]) over (partition by uuu.license_name order by uuu.license_name) as varchar(10))+ ' %' as 'avg_%_of_total_number_of_licenses_from_quantity_str',
case when cast(avg(uuuu.[%_of_total_number_of_licenses_from_quantity]) over (partition by uuuu.start_date_utc order by uuuu.start_date_utc) as varchar(10)) < 0
     then 'unlimited'
	 else cast(avg(uuuu.[%_of_total_number_of_licenses_from_quantity]) over (partition by uuuu.start_date_utc order by uuuu.start_date_utc) as varchar(10)) +  ' %'
	 end as '%_of_total_number_of_licenses_from_quantity_str',ts_ms
from (
select distinct
license_id,
feature_name, -- was changed from license_name  to feature_name by RG 19/082024
start_date_utc,
hour,
tot_sum as num_concur_usages,
cast(sum(quantity) as int)  as Total_QTY,
[%_of_total_number_of_licenses_from_quantity],
max(ts_ms) as ts_ms
from(
select uu.*,
cast(round(uu.tot_sum/cast(uu.quantity as float),2)*100  as int)  '%_of_total_number_of_licenses_from_quantity'
from (
select
u.license_id,u.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
cast(u.start_time_utc as date) as start_date_utc, u.hour ,u.quantity,u.quantity_str,sum(u.tot) as tot_sum,max(u.ts_ms) as ts_ms
from(
select distinct
a.license_id,
b.feature_name,-- was changed from license_name  to feature_name by RG 19/082024
a.start_time_utc ,
datepart(hour,a.start_time_utc) [hour],
case when b.quantity = 0
     then 0.001
	 else b.quantity
	 end quantity,
case when cast(b.quantity as varchar(8)) = '-99'
      then 'UNLIMITED'
	  else cast(b.quantity as varchar(8))
	  end quantity_str,
--a.num_of_licenses,
sum(a.num_of_licenses) as tot,
max(a.ts_ms) as ts_ms
--a.usage_id
from      license_transaction a
 join license_details_dimension b
on a.license_id = b.license_id
group by
a.license_id,
b.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
a.start_time_utc,
datepart(hour,a.start_time_utc) ,
b.quantity--,
--a.num_of_licenses
) u
--where u.quantity != -99
group by
u.license_id,u.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
cast(u.start_time_utc as date), u.hour ,u.quantity, u.quantity_str
) uu
)uuu
--where uuu.license_name = 'MATLAB'
--and uuu.start_date_utc = '2023-11-22'
group by
license_id,
feature_name,-- was changed from license_name  to feature_name by RG 19/082024
start_date_utc,
hour,
tot_sum,
[%_of_total_number_of_licenses_from_quantity]
) uuuu
--order by uu.quantity;

-- dbo.vw_license_idle_time source

create view vw_license_idle_time as
select  c.license_id as feature_name, sum(c.idle_time) as idle_time ,max(c.ts_ms) as ts_ms
from
(select b.license_id, b.start_time_utc, b.end_time_utc,b.end_time_utc_calc,
b.idle_time,b.ts_ms
from
(select a.license_id, a.start_time_utc, a.end_time_utc,a.end_time_utc_calc,
DATEDIFF(MINUTE, a.end_time_utc_calc,a.start_time_utc ) AS idle_time,a.ts_ms
from (SELECT license_id, start_time_utc,end_time_utc,
       LAG(end_time_utc, 1) OVER(
       ORDER BY license_id,end_time_utc ASC) AS end_time_utc_calc,ts_ms
FROM license_transaction where end_time_utc is not null ) as a) as b
where b.idle_time  >= 5 ) as c
group by c.license_id;

-- dbo.vw_license_join source

CREATE     VIEW vw_license_join AS
SELECT
    a.usage_id,
    a.borrowed,
    a.duration,
    a.start_time_utc,
    a.end_time_utc,
    CAST(a.start_time_utc AS date) AS start_date_utc,
    a.idle_time,
	iif((isnull(j.host_ip, 'Not Available')) = '', 'Not Available', (isnull(j.host_ip, 'Not Available'))) AS remote_ip, -- was changed by RG on 06/11/2024 to isnull + iif
    a.num_of_licenses,
    a.license_id,
    a.group_id,
	iif((isnull(a.host_id, 'Not Available')) = 'NULLID', 'Not Available', (isnull(a.host_id, 'Not Available'))) AS host_id, -- was changed by RG on 06/11/2024 to isnull + iif
    a.project_id,
    a.server_id,
    a.ts_ms,
    a.user_id,
	iif((isnull(i.host_name, 'Not Available')) = '', 'Not Available', (isnull(i.host_name, 'Not Available'))) AS host_name, -- was changed by RG on 06/11/2024 to isnull + iif
    case when isnull(d.user_name,'Not Available') = ''
	     then 'Not Available'
		 else isnull(d.user_name,'Not Available')
		 end AS user_name, -- was changed by RG on 04/11/2024 to isnull
	iif((isnull(d.first_name, 'Not Available')) = '', 'Not Available', (isnull(d.first_name, 'Not Available'))) AS first_name, -- was changed by RG on 06/11/2024 to isnull + iif
	iif((isnull(d.last_name, 'Not Available')) = '', 'Not Available', (isnull(d.last_name, 'Not Available'))) AS last_name, -- was changed by RG on 06/11/2024 to isnull + iif
    d.display_name,
	iif((isnull(d.department, 'Not Available')) = '', 'Not Available', (isnull(d.department, 'Not Available'))) AS department, -- was changed by RG on 06/11/2024 to isnull + iif
	iif((isnull(d.email, 'Not Available')) = '', 'Not Available', (isnull(d.email, 'Not Available'))) AS email, -- was changed by RG on 06/11/2024 to isnull + iif
	iif((isnull(d.country, 'Not Available')) = '', 'Not Available', (isnull(d.country, 'Not Available'))) AS country, -- was changed by RG on 06/11/2024 to isnull + iif
    h.country_code,
    d.mobile_phone,
    c.license_id AS lic_inv_id,
	case when isnull(c.vendor, 'Not Available') = ''
	     then 'Not Available'
		 else isnull(c.vendor, 'Not Available')
		 end AS lic_inv_vendor, -- was changed by RG on 04/11/2024 to isnull
	case when isnull(c.feature_name,  'Not Available') = ''
	     then 'Not Available'
		 else isnull(c.feature_name,  'Not Available')
		 end AS feature_name, -- was changed by RG on 04/11/2024 to isnull
    c.quantity AS lic_inv_quantity,
    case when isnull(c.license_type, 'Not Available') = ''
	     then 'Not Available'
		 else isnull(c.license_type, 'Not Available')
		 end AS lic_inv_type, -- was changed by RG on 06/11/2024 to isnull
    iif((isnull(c.version, 'Not Available')) = '', 'Not Available', (isnull(c.version, 'Not Available'))) AS lic_inv_version, -- was changed by RG on 06/11/2024 to isnull
    c.is_token_based,
	iif((isnull(c.additional_key, 'Not Available')) = '', 'Not Available', (isnull(c.additional_key, 'Not Available'))) AS lic_inv_additional_key, -- was changed by RG on 06/11/2024 to isnull
    c.package_id AS fea_package_id,
    case when isnull(c.product_name, 'Not Available') = ''
	     then 'Not Available'
		 else isnull(c.product_name, 'Not Available')
		 end as product_name,
    case when isnull(e.project_name,'No Project') = ''
	     then 'Not Available'
		 else isnull(e.project_name,'No Project')
		 end as project_name, -- was changed by RG on 06/11/2024 to isnull
	iif((isnull(f.group_name, 'Not Available')) = '', 'Not Available', (isnull(f.group_name, 'Not Available'))) AS group_name, -- was changed by RG on 06/11/2024 to isnull + iif
	case when isnull(g.server_name, 'Not Available') = ''
	     then 'Not Available'
		 else isnull(g.server_name, 'Not Available')
		 end AS server_name,  -- was changed by RG on 04/11/2024 to isnull
    h.region,
    c.date_from_utc,
    c.date_to_utc,
    c.quantity,
    c.package_id,
    d.[source]
FROM
(
    SELECT
        a.usage_id,
        a.borrowed,
        a.duration,
        a.start_time_utc,
        a.end_time_utc,
        CAST(a.start_time_utc AS date) AS start_date_utc,
        a.idle_time,
        --a.remote_ip, -- Added remote_ip here in the inner query
        a.num_of_licenses,
        a.license_id AS license_id,
        b.group_id,
        b.host_id,
        b.project_id,
        b.server_id,
        b.tenant_id,
        b.ts_ms,
        b.user_id,
        a.license_id AS id
    FROM
         license_transaction AS a
    JOIN license_fact_table AS b
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
    ON h.country = d.country
LEFT JOIN license_server_host i
    ON a.server_id = i.server_id
LEFT JOIN host_details_dimension j
    ON a.host_id = j.host_name;

-- dbo.vw_license_procurement source

CREATE VIEW vw_license_procurement AS
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
    inner JOIN license_server_dimension ls ON ld.server_id = ls.server_id
--where ls.enabled=1 and ld.date_to_utc is null;

-- dbo.vw_license_realtime_DQ source

CREATE   view vw_license_realtime_DQ
as
select a.usage_id, a.start_time_utc,DATEPART(HOUR, a.start_time_utc) AS start_hour_utc,
CONVERT(DATE, a.start_time_utc) AS start_date_utc,a.end_time_utc,
LDD.feature_name,-- was changed from license_name  to feature_name by RG 19/082024
a.ts_ms from license_transaction a
left join license_details_dimension LDD on a.license_id=LDD.license_id;

-- dbo.vw_license_server_status source

-- dbo.vw_license_server_status source

CREATE     VIEW vw_license_server_status AS
SELECT
 LSS.transaction_id,
 LSS.server_id,
 iif(isnull(LSD.server_name, 'Not Available') =  '', 'Not Available', isnull(LSD.server_name, 'Not Available')) AS server_name, -- was changed by RG on 06/11/2024 to isnull + iif
 iif((isnull(LSD.status_description, 'Not Available')) = '', 'Not Available', (isnull(LSD.status_description, 'Not Available'))) as status_description,
 iif(isnull(LSD.license_manager_type, 'Not Available') =  '', 'Not Available', isnull(LSD.license_manager_type, 'Not Available')) AS license_manager_type, -- was changed by RG on 06/11/2024 to isnull + iif
 iif(isnull(LSS.host_name, 'Not Available') =  '', 'Not Available', isnull(LSS.host_name, 'Not Available')) AS host_name, -- was changed by RG on 06/11/2024 to isnull + iif
 LSS.server_port,
 iif(isnull(LSS.host_status, 'Not Available') =  '', 'Not Available', isnull(LSS.host_status, 'Not Available')) AS host_status, -- was changed by RG on 06/11/2024 to isnull + iif
 iif(isnull(LSS.server_status, 'Not Available') =  '', 'Not Available', isnull(LSS.server_status, 'Not Available')) AS server_status, -- was changed by RG on 06/11/2024 to isnull + iif
 LSS.update_date_utc,
 LSS.ts_ms
FROM license_server_status as LSS
LEFT JOIN license_server_dimension as LSD on LSD.server_id=LSS.server_id;

-- dbo.vw_license_time source

CREATE     VIEW vw_license_time
AS
SELECT
    LDD.date_from_utc,
    LDD.date_to_utc,
    LDD.feature_name,-- was changed from license_name  to feature_name by RG 19/082024
    LDD.license_id,
    LDD.ts_ms,

    CASE
        WHEN LDD.date_to_utc IS NULL THEN 9999
        WHEN LDD.date_to_utc >= GETUTCDATE() THEN DATEDIFF(HOUR, GETUTCDATE(), LDD.date_to_utc)
        ELSE 0
    END AS TimeLeft,

    CASE
        WHEN LDD.date_to_utc IS NULL THEN DATEDIFF(HOUR, LDD.date_from_utc, GETUTCDATE())
        WHEN LDD.date_to_utc >= GETUTCDATE() THEN DATEDIFF(HOUR, LDD.date_from_utc, GETUTCDATE())
        ELSE DATEDIFF(HOUR, LDD.date_from_utc, LDD.date_to_utc)
    END AS TimeFromStart

FROM
    license_details_dimension AS LDD;

-- dbo.vw_license_usage_percentage source

CREATE     VIEW vw_license_usage_percentage AS
select
uu.license_id,
uu.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
sum(num_of_licenses) as Total_Num_of_Times_License_Usages_During_LifeCycle_Period,
LDD2.quantity as Purchased_QTY,
round(sum(num_of_licenses)/sum(qty)*100,2) as Total_Percentage_Licenses_Used,
max(uu.ts_ms) as ts_ms
from (
select
u.license_id,
u.feature_name,-- was changed from license_name  to feature_name by RG 19/082024
u.start_time_utc,
u.end_time_utc,
cast(u.qty  as float) qty,
cast(u.num_of_licenses as float) as num_of_licenses,
u.ts_ms
from(
SELECT
    LDD.license_id,
    LDD.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
    LDD.quantity as qty,
	VLJ.num_of_licenses,
	VLJ.start_time_utc,
	VLJ.end_time_utc,
	VLJ.ts_ms
FROM
     license_details_dimension AS LDD
JOIN (select  a.license_id, num_of_licenses, start_time_utc, end_time_utc,
             usage_id, server_id,a.ts_ms
        from vw_license_join a
		) VLJ
   ON LDD.license_id = VLJ.license_id
    ) u

 ) uu
join (select a.license_id, a.quantity
        from license_details_dimension a) LDD2
	on uu.license_id = LDD2.license_id
group by uu.license_id,
uu.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
LDD2.quantity, qty;

-- dbo.vw_license_user_allocation_time_calculation source

create   view vw_license_user_allocation_time_calculation as
select a.license_id, DATEDIFF(HOUR,a.start_date_utc,(coalesce(a.end_date_utc,CURRENT_TIMESTAMP)) ) totalDuration,
case when a.end_date_utc is null
then 'No'
else 'Yes'
end as isExpired,
case when a.end_date_utc is null then
	DATEDIFF(HOUR,a.start_date_utc,CURRENT_TIMESTAMP)
else DATEDIFF(HOUR,a.start_date_utc,a.end_date_utc)
end as TimeUsed,
case when a.end_date_utc is null then
DATEDIFF(HOUR,CURRENT_TIMESTAMP,(coalesce(a.end_date_utc,CURRENT_TIMESTAMP)))
else
0
end as TimeLeft, a.ts_ms
from license_allocation_transaction as a;

-- dbo.vw_not_used_licenses source

CREATE   VIEW vw_not_used_licenses AS

SELECT
    ldd.license_id,
	ldd.date_from_utc,--- was added 12-12-2024
    IIF((ISNULL(ldd.feature_name, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.feature_name, 'Not Available'))) AS feature_name, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    ldd.product_name,
    IIF((ISNULL(ldd.vendor, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.vendor, 'Not Available'))) AS vendor, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    IIF((ISNULL(ldd.license_type, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.license_type, 'Not Available'))) AS license_type, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    IIF((ISNULL(ldd.version, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.version, 'Not Available'))) AS version, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    IIF((ISNULL(ldd.additional_key, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.additional_key, 'Not Available'))) AS additional_key, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    ldd.quantity,
    IIF((ISNULL(lsd.server_name, 'Not Available')) = '', 'Not Available', (ISNULL(lsd.server_name, 'Not Available'))) AS server_name, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    COUNT(lt.license_id) AS transaction_count
FROM
    license_details_dimension ldd
LEFT JOIN
    license_transaction lt ON ldd.license_id = lt.license_id
LEFT JOIN
    license_server_dimension lsd ON ldd.server_id = lsd.server_id
WHERE
    lt.license_id IS NULL
    AND ldd.date_to_utc IS NULL -- Adding the new condition here
GROUP BY
    ldd.license_id,
	ldd.date_from_utc,
    ldd.feature_name,
    ldd.product_name,
    ldd.vendor,
    ldd.license_type,
    ldd.version,
    ldd.additional_key,
    ldd.quantity,
    ldd.server_id,
    lsd.server_name;

-- dbo.vw_office_time_calculation source

CREATE view vw_office_time_calculation as
select o.*, case when isnull(u.user_name,'Not Available') = ''
	     then 'Not Available'
		 else isnull(u.user_name,'Not Available')
		 end AS user_name,
IIF((ISNULL(l.feature_name, 'Not Available')) = '', 'Not Available', (ISNULL(l.feature_name, 'Not Available'))) AS feature_name,cd.country
from
office_time_calculation as o
left join user_details_dimension as u
on o.user_id =u.user_id
left join license_details_dimension as l
on o.lic_id =l.license_id
left join country_dimension as cd
on o.country_code = cd.country_code;

-- dbo.vw_OfficeUtilizationHours_UTC source

CREATE                 view vw_OfficeUtilizationHours_UTC as


 /*query 9*/
select usage_id,duration,user_name,lic_inv_id,country,start_date_utc,
end_date_utc,start_time_utc,end_time_utc,shift_starttime_utc,
shift_endtime_utc,avg_daily_working_hours,duration_in_days,
start_date_name,end_date_name,if_startdate_weekend,
if_enddate_weekend,if_startdate_weekend_txt,if_enddate_weekend_txt,
if_weekend_in_the_range,
--uuuu.Office_Utilization_in_hours,
--OfficeUtilization_in_hours_new,
--iif((start_time_utc > shift_endtime_utc or end_time_utc<shift_starttime_utc and duration_in_days=2),0,avg_daily_working_hours) as ifff,--for testing purposes
case
/*duration = 2 and 3  days*/ /*OfficeUtilization_in_hours_new has startday and endday time calculation only */
/*1*/when uuuu.duration_in_days between  2 and 3
     and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0
     and  if_weekend_in_the_range = 0) -- when start and end date not in weekend and there is weekend not in the range
    then (uuuu.OfficeUtilization_in_hours_new
         + iif((duration_in_days=2 or (start_time_utc > shift_endtime_utc or end_time_utc<shift_starttime_utc and  duration_in_days=2)),0,avg_daily_working_hours))

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
     then uuuu.OfficeUtilization_in_hours_new - datediff(hour,start_time_utc,shift_endtime_utc) -- --subtract only particular hours of the weekend if startdate is weekend

/*5*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.start_time_utc < uuuu.shift_starttime_utc ) /*was added new conditions at  at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,shift_endtime_utc))--subtract only particular hours of the weekend if startdate is weekend

/*6*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.end_time_utc < uuuu.shift_endtime_utc ) /*was added new conditions at  at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,end_time_utc))--subtract only particular hours of the weekend if startdate is weekend

/*7*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) --when usage starts in weekend and ends in weekday
      and (uuuu.end_time_utc > uuuu.shift_endtime_utc ) /*was added new conditions at  at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,shift_endtime_utc))--subtract only particular hours of the weekend if startdate is weekend

/*8*/when uuuu.duration_in_days between  2 and 3
      and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1)--when usage starts in weekday and ends in weekend
      and end_time_utc < shift_endtime_utc /*was added new conditions at 09/08/2024*/
     then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,end_time_utc)) --subtract only particular hours of the weekend if enddate is weekend

/*9*/when uuuu.duration_in_days between  2 and 3
       and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1)--when usage starts in weekday and ends in weekend
       and end_time_utc > shift_endtime_utc /*was added new conditions at 09/08/2024*/
      then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,shift_endtime_utc)) --subtract only particular hours of the weekend if enddate is weekend

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
      then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,start_time_utc,shift_endtime_utc))

/*13*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) -- when usage starts in weekend and ends in weekday
       and (uuuu.start_time_utc < uuuu.shift_starttime_utc )
      then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,shift_endtime_utc))

/*14*/when uuuu.duration_in_days between 4 and 7
        and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1) -- when usage starts in weekday and ends in weekend
        and end_time_utc < shift_endtime_utc
      then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,end_time_utc))

/*15*/when uuuu.duration_in_days between 4 and 7
      and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1) -- when usage starts in weekday and ends in weekend
      and end_time_utc > shift_endtime_utc
     then (uuuu.OfficeUtilization_in_hours_new - datediff(hour,shift_starttime_utc,shift_endtime_utc))

/*16*/when uuuu.duration_in_days between 4 and 7
       and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 1) -- when usage starts in weekend and ends in weekend
      /*IIF1= if usage starts after shift finished, then 0, othewise if usage started before shift starts, then calculate entire shift hours, othewise calculate difference between start_time and shift_end_time*/
     /*IIF2= if usage finished before shift starts, then 0, othewise if usage ends after shift ends, then calculate difference between shift_starttime_utc and shift_endtime_utc, othewise calculate difference between shift_starttime_utc and end_time_utc*/
 then (uuuu.OfficeUtilization_in_hours_new - (IIF(start_time_utc > shift_endtime_utc, 0, IIF(start_time_utc< shift_starttime_utc,datediff(hour, shift_starttime_utc, shift_endtime_utc),datediff(hour, start_time_utc, shift_endtime_utc))) --if usage was after shift finished
	                                        + IIF(end_time_utc < shift_starttime_utc,0,IIF(end_time_utc > shift_endtime_utc,datediff(hour, shift_starttime_utc, shift_endtime_utc), datediff(hour, shift_starttime_utc, end_time_utc)))  --if usage was before shift started
		                                    + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1)
											  )
                                           )
 /*duration >= 8*/

/*17*/when uuuu.duration_in_days >= 8 
        and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 0) -- weekend in the interval
     then (uuuu.OfficeUtilization_in_hours_new - (avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7))))
/*18*/when uuuu.duration_in_days >= 8  
      and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 0) -- from weekend (subtract in-shift hours from first weekend) 
     then (uuuu.OfficeUtilization_in_hours_new - (IIF(start_time_utc > shift_endtime_utc, 0,datediff(hour,start_time_utc,shift_endtime_utc)) 
                                                   + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1))
											)
/*19*/when uuuu.duration_in_days >= 8  
       and (uuuu.if_startdate_weekend = 0 and uuuu.if_enddate_weekend = 1) -- to weekend(subtract in-shift hours from last weekend )
      then (uuuu.OfficeUtilization_in_hours_new - (IIF(end_time_utc < shift_starttime_utc, 0,datediff(hour,shift_starttime_utc,end_time_utc))--if usage was after shift finished
                                                        + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1))
												    )
/*20*/when uuuu.duration_in_days >= 8  
        and (uuuu.if_startdate_weekend = 1 and uuuu.if_enddate_weekend = 1) -- from weekend to weekend(subtract in-shift hours from 2 weekends )
    /*IIF1= if usage starts after shift finished, then 0, othewise if usage started before shift strats, then calculate entire shift hours, othewise calculate difference between start_time and shift_end_time*/
    /*IIF2= if usage finished before shift starts, then 0, othewise if usage ends after shift ends, then calculate difference between shift_starttime_utc and shift_endtime_utc, othewise calculate difference between shift_starttime_utc and end_time_utc*/
      then (uuuu.OfficeUtilization_in_hours_new - (IIF(start_time_utc > shift_endtime_utc, 0, IIF(start_time_utc< shift_starttime_utc,datediff(hour, shift_starttime_utc, shift_endtime_utc),datediff(hour, start_time_utc, shift_endtime_utc))) --if usage was after shift finished
	                                       + IIF(end_time_utc < shift_starttime_utc,0,IIF(end_time_utc > shift_endtime_utc,datediff(hour, shift_starttime_utc, shift_endtime_utc), datediff(hour, shift_starttime_utc, end_time_utc)))  --if usage was before shift started
	                                       + avg_daily_working_hours*(ceiling(cast(duration_in_days as numeric(18,1))/7)-1)
											  )
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
	 then datediff(second,start_time_utc, shift_endtime_utc)/3600.0  
   /*here duration =1 and usage was in weekend and weekday, lisence usage starts before the shift, but we calc weekday only usage of entire weekday shift*/
/*5*/when uuu.duration_in_days = 1 
	  and uuu.if_startdate_weekend = 0/*Friday in israel*/ and uuu.if_enddate_weekend = 1
	  and (start_time_utc < shift_starttime_utc) 
	then datediff(second,shift_starttime_utc, shift_endtime_utc)/3600.0  
/*here duration =1 and usage was in weekend and weekday, but we take weekday only usage*/
/*6*/when  uuu.duration_in_days = 1 
	  and uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
	  and (end_time_utc < shift_starttime_utc) /*lisence usage end before the shift starts*/
	 then 0  
/*here duration =1 and usage was in weekend and weekday, but we take weekday only usage*/
/*7*/when  uuu.duration_in_days = 1 
	  and uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
	  and (end_time_utc > shift_starttime_utc and end_time_utc > shift_endtime_utc) /*lisence usage ends after the shift starts and finished after shift ends*/
	then datediff(second,shift_starttime_utc, shift_endtime_utc)/3600.0  /*take only weekday usage*/	
/*8*/when  uuu.duration_in_days = 1 
	  and uuu.if_startdate_weekend = 1 and uuu.if_enddate_weekend = 0
	  and (end_time_utc > shift_starttime_utc and end_time_utc < shift_endtime_utc) /*lisence usage end after the shift starts and finished before shift ends*/
	 then datediff(second,shift_starttime_utc, end_time_utc)/3600.0  /*take only weekday usage*/
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
	 end as 'if_startdate_weekend',
case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','') and country !='N/A'
					  and end_date_name = 'Saturday'
     then 1
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen') 
					  and end_date_name = 'Friday' and country !='N/A'
	 then 1
	 when end_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen') 
	 then 1
	 else 0
	 end as 'if_enddate_weekend',

	 case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania') and country !='N/A'
					  and start_date_name = 'Saturday'
     then 'weekend'
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen') 
					  and start_date_name = 'Friday' and country !='N/A'
	 then 'weekend'
	 when start_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen')
	 then 'weekend'
	 else 'weekday'
	 end as 'if_startdate_weekend_txt',

case when country in ('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania') 
					  and end_date_name = 'Saturday'
     then 'weekend'
	 when country in('Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen') 
					  and end_date_name = 'Friday' and country !='N/A'
	 then 'weekend'
	 when end_date_name = 'Sunday' and country not in('Israel', 'Nepal', 'Algeria', 'Egypt','Bangladesh','Maldives','Mauritania','Iran', 'Afghanistan','Bahrain','Iraq', 'Jordan','Kuwait','Oman','Libya','Qatar','Saudi Arabia', 'Sudan','Syria','United Arab Emirate','Yemen') 
	 then 'weekend'
	 else 'weekday'
	 end as 'if_enddate_weekend_txt',
	 IIF(datediff(wk,u.start_date_utc,u.end_date_utc) >= 1, 1, 0) as if_weekend_in_the_range,/* sign = changed to >=, because */
u.Office_Utilization_in_sec,
u.Office_Utilization_in_min,
u.Office_Utilization_in_hours
from(                               /*query 5*/
select  usage_id,duration,user_name,lic_inv_id,	country,start_date_utc,	
start_date_utc_full,end_date_utc,end_date_utc_full,start_time_utc,end_time_utc,
shift_starttime_utc,shift_endtime_utc,avg_daily_working_hours,duration_in_days,
start_date_name,end_date_name,
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
	 then datediff(second,start_time_utc, end_time_utc) 

/*3*/when (start_date_utc = end_date_utc and start_time_utc < shift_starttime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57') -- in-day usage. usage start before shift and finished before shift starts
	 then 0	

/*4*/when (start_date_utc = end_date_utc and start_time_utc < shift_starttime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57') -- in-day usage. usage start before shift and finished before shift ended
	 then datediff(second,shift_starttime_utc, end_time_utc) 	

/*5*/when (start_date_utc = end_date_utc and start_time_utc < shift_starttime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57') -- in-day usage. usage start before shift and finished after shift ended
	 then datediff(second,shift_starttime_utc, shift_endtime_utc)
	 --usage was more then 1 day
/*6*/when (start_date_utc != end_date_utc  and start_time_utc > shift_endtime_utc and shift_starttime_utc < shift_endtime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57' ) -- more the 1 day usage. when usage start after shift ended and usage finished before shift start
     then 0

/*7*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57' )
     then (datediff(second, shift_starttime_utc,'23:59:57') + datediff(second, '00:00:01',shift_endtime_utc)) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first day before shift starts and usage was after shift ended in the last day from 00:00:00

/*8*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc  and end_time_utc != '23:59:57' ) 
     then (datediff(second, start_time_utc,'23:59:57') + datediff(second, '00:00:01',end_time_utc)) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first day after shift starts and usage was after shift ended in the last day from 00:00:00 

/*9*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57' ) 
     then (datediff(second, shift_starttime_utc,'23:59:57') + datediff(second, '00:00:01',shift_endtime_utc)) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first after shift starts and usage was before shift ended in the last day from 00:00:00 

/*10*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and shift_starttime_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57' ) 
     then (datediff(second, shift_starttime_utc,'23:59:57') + datediff(second, '00:00:01',shift_endtime_utc)) -- events when shift has duration like this(22:00 to 5:00); usage starts in the first before shift starts and usage was after shift ended in the last day from 00:00:00 

/*11*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57') 
	 then (datediff(second,shift_starttime_utc, shift_endtime_utc) + 0 )--when  usage was in the whole 1st day and no usage in the last day(usage was finished before last day shift was started) with duration > 1

/*12*/when (start_date_utc != end_date_utc  and start_time_utc > shift_endtime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57') 
	 then (datediff(second,shift_starttime_utc, end_time_utc))   --when in 1st day was no usage and usage was only in last date before shift ended

/*13*/when (start_date_utc != end_date_utc  and start_time_utc > shift_endtime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57') 
	 then (datediff(second,shift_starttime_utc, shift_endtime_utc))--when in 1st day was no usage and usage was only in last date after shift ended

/*14*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and end_time_utc < shift_starttime_utc and end_time_utc != '23:59:57') 
	 then datediff(second,start_time_utc, shift_endtime_utc) -- when usage was in the 1st after shift stared and no usage in the last day

/*15*/when (start_date_utc != end_date_utc and start_time_utc > shift_starttime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57')
	 then (datediff(second,start_time_utc, shift_endtime_utc) + datediff(second,shift_starttime_utc,shift_endtime_utc))-- when usage was starts after shift started and ends after shift ends(we calaculated first and last usage days) -> additional whole day will added further

/*16*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57')
     then datediff(second,shift_starttime_utc, shift_endtime_utc) +  datediff(second,shift_starttime_utc,end_time_utc) -- when usage was started before shift starts and ends before shift ends(we calaculated first and last usage days)
	                        /*!!!!   change beneath from start_time_utc to shift_starttime_utc in datediff 1 */
/*17*/when (start_date_utc != end_date_utc  and start_time_utc < shift_starttime_utc and end_time_utc > shift_endtime_utc and end_time_utc != '23:59:57')
     then datediff(second,shift_starttime_utc, shift_endtime_utc) + datediff(second,shift_starttime_utc,shift_endtime_utc)-- when usage was started before shift starts and ends after shift ends(we calaculated first and last usage days)	 

/*18*/when (start_date_utc != end_date_utc  and start_time_utc > shift_starttime_utc and end_time_utc < shift_endtime_utc and end_time_utc != '23:59:57')
     then datediff(second,start_time_utc, shift_endtime_utc) + datediff(second,shift_starttime_utc,end_time_utc)      -- when usage was started after shift starts and ends before shift ends(we calaculated first and last usage days)		 
	 else 0
	 end
	 as Office_Utilization_Hours_in_sec
from(                                      /*query 1*/
select distinct 
a.usage_id,
a.duration,
a.user_name,
a.lic_inv_id,
iif(isnull(a.country,'N/A') = '', 'N/A', isnull(a.country,'N/A')) country,
a.start_time_utc as start_date_utc_full,
a.start_date_utc,
isnull(a.end_time_utc, getdate()) as end_date_utc_full,
cast(isnull(a.end_time_utc, getdate()) as date) end_date_utc,
cast(a.start_time_utc as time(0)) start_time_utc,
COALESCE(cast(isnull(a.end_time_utc, getdate()) as time(0)),cast('23:59:57' AS TIME(0))) as end_time_utc,
isnull(b.shift_starttime_utc,'9:00:00') shift_starttime_utc,
isnull(b.shift_endtime_utc,'18:00:00') shift_endtime_utc,
isnull(b.avg_daily_working_hours,9) avg_daily_working_hours,
datediff(day,a.start_date_utc,cast(isnull(a.end_time_utc, getdate()) as date)) as duration_in_days,
DATENAME(WEEKDAY,a.start_date_utc) as start_date_name,
DATENAME(WEEKDAY,isnull(a.end_time_utc, getdate())) as end_date_name
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

;


/*
If I'm adding additional subquery, I get this error:Internal error: An expression services limit has been reached. 
 Please look for potentially complex expressions in your query, and try to simplify them.

Means, This issue occurs because SQL Server limits the number of identifiers 
and constants that can be contained in a single expression of a query. 
This limit is 65,535.
*/

;

-- dbo.vw_process_all source

create view  vw_process_all ---16032
as
select
pft.host_name, pft.monitoring_id, pft.session_id , pft.transaction_id, pft.user_id, pft.user_name,
psdt.shutdown_reason,psdt.process_id,psdt.customer_id,psdt.agent_status,psdt.session_start_time,
psdt.session_end_time,psdt.total_idle_time_in_min,psdt.session_duration_in_min,
pd.dll_name,pd.process_name, pd.[version]
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
               process_id,dll_name,process_name, [version]
             from process_details_dimension ) pd
    ON pd.process_id = psdt.process_id;

-- dbo.vw_procured_licenses source

CREATE   VIEW vw_procured_licenses AS
SELECT
	iif(isnull(ls.server_name, 'Not Available') =  '', 'Not Available', isnull(ls.server_name, 'Not Available')) AS server_name, -- was changed by RG on 06/11/2024 to isnull + iif
	iif(isnull(ld.vendor, 'Not Available') =  '', 'Not Available', isnull(ld.vendor, 'Not Available')) AS vendor, -- was changed by RG on 06/11/2024 to isnull + iif
	iif(isnull(ld.feature_name, 'Not Available') =  '', 'Not Available', isnull(ld.feature_name, 'Not Available')) AS feature_name, -- was changed by RG on 06/11/2024 to isnull + iif
	iif(isnull(ld.product_name, 'Not Available') =  '', 'Not Available', isnull(ld.product_name, 'Not Available')) AS product_name, -- was changed by RG on 06/11/2024 to isnull
	iif(isnull(ld.additional_key, 'Not Available') =  '', 'Not Available', isnull(ld.additional_key, 'Not Available')) AS additional_key, -- was changed by RG on 06/11/2024 to isnull
    lp.issued_date,
    lp.start_date,
    lp.expiration_date,
    lp.quantity,
	iif(isnull(ld.version, 'Not Available') =  '', 'Not Available', isnull(ld.version, 'Not Available')) AS version, -- was changed by RG on 06/11/2024 to isnull + iif
	iif(isnull(ld.license_type, 'Not Available') =  '', 'Not Available', isnull(ld.license_type, 'Not Available')) AS license_type, -- was changed by RG on 06/11/2024 to isnull + iif
	iif(isnull(lp.asset_info, 'Not Available') =  '', 'Not Available', isnull(lp.asset_info, 'Not Available')) AS asset_info, -- was changed by RG on 06/11/2024 to isnull + iif
    COUNT(DISTINCT lat.user_id) AS allocated,
    (lp.quantity - COUNT(DISTINCT lat.user_id)) AS total_available,
    CASE
        WHEN lp.quantity > 0 THEN
            (COUNT(DISTINCT lat.user_id) * 100.0 / lp.quantity)
        ELSE 0
    END AS util_percent
FROM
    license_details_dimension ld
    LEFT JOIN license_server_dimension ls
        ON ld.server_id = ls.server_id
    LEFT JOIN license_procurement_table lp
        ON ld.license_id = lp.license_id
    LEFT JOIN license_allocation_transaction lat
        ON ld.license_id = lat.license_id
GROUP BY
    ls.server_name, ld.vendor, ld.feature_name, ld.product_name,
    ld.additional_key, lp.issued_date, lp.start_date,
    lp.expiration_date, lp.quantity, ld.version, ld.license_type,
    lp.asset_info;

-- dbo.vw_project_data source

CREATE VIEW vw_project_data AS
SELECT
    ROW_NUMBER() OVER (ORDER BY a.project_id) AS row_number,
    CAST(NULL AS int) AS action,
    CAST(NULL AS int) AS allocate_time,
    a.priority AS priority,
    CASE
        WHEN a.priority = 0 THEN 'High'
        WHEN a.priority = 1 THEN 'Medium'
        WHEN a.priority = 2 THEN 'Low'
        ELSE 'Unknown'
    END AS priority_text,
    a.percent_done AS percent_done,
    a.source AS source,
    a.start_time_utc AS start_date_utc,
    a.end_time_utc AS end_date_utc,
    a.is_enabled AS is_enabled,
    CAST(NULL AS bit) AS user_is_default_project,
    CAST(NULL AS BIT) AS group_is_default_project,
    CAST(NULL AS nvarchar(max)) AS id,
    a.project_id AS project_id,
    a.project_name AS project_name,
    d.user_name AS user_name,
    c.group_id AS group_id,
    e.group_name,
    a.ts_ms
FROM
    project_details_dimension a
JOIN project_user_fact_table b ON a.project_id = b.project_id
JOIN project_group_fact_table c ON a.project_id = c.project_id
JOIN user_details_dimension d ON b.user_id = d.user_id
LEFT JOIN group_details_dimension e ON e.group_id = c.group_id;

-- dbo.vw_token_statistics source

CREATE   VIEW vw_token_statistics AS
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

-- dbo.vw_token_usage source

CREATE    VIEW vw_token_usage AS
SELECT
    TBT.usage_id,
    TBT.usage_date,
    TBT.number_of_tokens,
	LDD.quantity,
    TBT.license_id,
	LDD.feature_name, -- was changed from license_name  to feature_name by RG 19/082024
	LDD.product_name, -- was changed from feature_name  to product_name by RG 19/082024
	LDD.vendor,
    TBUF.user_id,
	UDD.user_name,
	UDD.first_name,
	UDD.last_name,
	UDD.email,
    TBUF.server_id,
	LSD.server_name,
	LSD.status_description,
	LDD.is_token_based,

    SUM(TBT.number_of_tokens) OVER (ORDER BY TBT.usage_date) AS cumulative_tokens_used,
    TBT.ts_ms
FROM
    token_based_transaction AS TBT
JOIN
    token_based_user_fact AS TBUF ON TBT.usage_id = TBUF.usage_id
LEFT JOIN user_details_dimension AS UDD ON TBUF.user_id = UDD.user_id
LEFT JOIN license_server_dimension AS LSD ON TBUF.server_id = LSD.server_id
LEFT JOIN license_details_dimension AS LDD ON TBT.license_id = LDD.license_id;

-- dbo.vw_touchpoint_details source

CREATE  VIEW vw_touchpoint_details AS
WITH CTE_Touchpoint AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY a.event_id ASC) AS row_number,
        a.event_type,
        a.event_date_time AS event_date_time,
        a.event_id AS id,
        a.user_name,
        a.host_name AS workstation,
        a.touchpoint_event_source,
        a.found_url,
        case when a.found_url like '%.com%'
        then
        SUBSTRING(a.found_url, CHARINDEX('://', a.found_url) + 3, CHARINDEX('.com', a.found_url) + 4 - CHARINDEX('://', a.found_url) - 3)
        else a.found_url end as website_type,
        case when found_url LIKE '%.com'
        then
        SUBSTRING(a.found_url,
        CHARINDEX('.', a.found_url) + 1,
        LEN(a.found_url) -
        CHARINDEX('.', REVERSE(a.found_url)) - CHARINDEX('.', a.found_url))
        else found_url end AS domain,
        a.page_title,
        a.event_type_desc,
        a.customer_id,
        a.user_id,
        a.ts_ms
    FROM
        touchpoint_transaction a

)
SELECT * FROM CTE_Touchpoint;




-- dbo.vw_not_used_licenses_cost source

CREATE   VIEW vw_not_used_licenses_cost AS
with cte1 as(
SELECT
    ldd.license_id,
	ldd.package_id,
	ldd.date_from_utc,--- was added 12-12-2024
    IIF((ISNULL(ldd.feature_name, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.feature_name, 'Not Available'))) AS feature_name, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    ldd.product_name,
    IIF((ISNULL(ldd.vendor, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.vendor, 'Not Available'))) AS vendor, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    IIF((ISNULL(ldd.license_type, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.license_type, 'Not Available'))) AS license_type, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    IIF((ISNULL(ldd.version, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.version, 'Not Available'))) AS version, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    IIF((ISNULL(ldd.additional_key, 'Not Available')) = '', 'Not Available', (ISNULL(ldd.additional_key, 'Not Available'))) AS additional_key, -- was changed by RG on 06/11/2024 to ISNULL + IIF
    ldd.quantity,
    IIF((ISNULL(lsd.server_name, 'Not Available')) = '', 'Not Available', (ISNULL(lsd.server_name, 'Not Available'))) AS server_name, -- was changed by RG on 06/11/2024 to ISNULL + IIF
	lt.start_time_utc,
	lt.end_time_utc,
	lt.usage_id,
    COUNT(lt.license_id) AS transaction_count,
	SUM(lt.num_of_licenses) as num_of_licenses
FROM
    license_details_dimension ldd
LEFT JOIN
    license_transaction lt ON ldd.license_id = lt.license_id
LEFT JOIN
    license_server_dimension lsd ON ldd.server_id = lsd.server_id
WHERE
    lt.license_id IS NULL
    AND ldd.date_to_utc IS NULL -- Adding the new condition here
GROUP BY
    ldd.license_id,
	ldd.package_id,
	ldd.date_from_utc,
    ldd.feature_name,
    ldd.product_name,
    ldd.vendor,
    ldd.license_type,
    ldd.version,
    ldd.additional_key,
    ldd.quantity,
    ldd.server_id,
    lsd.server_name,
	lt.start_time_utc,
	lt.end_time_utc,
	lt.usage_id
)
select plcmd.*,
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
coalesce(CAST(DATEDIFF(SECOND,
start_time_utc,
end_time_utc) AS BIGINT) / 3600.00,0.0) AS usage_time_hrs,
cast((( unit_cost * conversion_factor)/duration_value) as decimal(10,4)) AS hourly_cost
from procured_license_cost_mapping_dimension as plcmd
join cte1 as c
on plcmd.license_id =c.license_id
left join license_fact_table as lft
on c.usage_id = lft.usage_id
left join user_details_dimension as udd
on lft.user_id = udd.user_id

/*
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
coalesce(CAST(DATEDIFF(SECOND,
start_time_utc,
end_time_utc) AS BIGINT) / 3600.00,0.0) AS usage_time_hrs,
cast((( unit_cost * conversion_factor)/duration_value) as decimal(10,4)) AS hourly_cost
from procured_license_cost_mapping_dimension as plcmd
left join license_details_dimension as ldd
on plcmd.license_id = ldd.license_id
left join license_transaction as lt
on plcmd.license_id=lt.license_id
left join license_fact_table as lft
on lt.usage_id = lft.usage_id
left join user_details_dimension as udd
on lft.user_id = udd.user_id
*/;


-- dbo.vw_process_cost source

create view vw_process_cost as
select cmd.*,
process_name,
dll_name,
version,
host_name,
cast(((cost * conversion_factor)/duration_value) as decimal(10,4)) as hourly_cost,
cast(((cost * conversion_factor * 8760)/duration_value) as decimal(10,4)) as yearly_cost
from cost_mapping_dimension as cmd
left join process_details_dimension as pdd
on cmd.process_id = pdd.process_id
left join host_details_dimension as hdd
on cmd.host_id=hdd.host_id;


-- dbo.vw_used_licenses_cost source

CREATE   VIEW vw_used_licenses_cost AS
select plcmd.*,
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
coalesce(CAST(DATEDIFF(SECOND,
start_time_utc,
end_time_utc) AS BIGINT) / 3600.00,0.0) AS usage_time_hrs,
cast((( unit_cost * conversion_factor)/duration_value) as decimal(10,4)) AS hourly_cost
from procured_license_cost_mapping_dimension as plcmd
left join license_details_dimension as ldd
on plcmd.license_id = ldd.license_id
left join license_transaction as lt
on plcmd.license_id=lt.license_id
left join license_fact_table as lft
on lt.usage_id = lft.usage_id
left join user_details_dimension as udd
on lft.user_id = udd.user_id;


 