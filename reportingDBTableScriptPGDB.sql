
CREATE TABLE public.cost_mapping_dimension (
	cost_id bigserial NOT NULL,
	process_id varchar(64) NULL,
	host_id varchar(64) NULL,
	"cost" float8 NULL,
	currency varchar(7) NULL,
	conversion_factor float8 NULL,
	country_code varchar(3) NULL,
	duration_value int4 NULL,
	duration_unit varchar(8) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT cost_mapping_dimension_pkey PRIMARY KEY (cost_id)
);

CREATE TABLE public.country_dimension (
	country_code varchar(3) NULL,
	country varchar(255) NULL,
	region varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL
);

CREATE TABLE public.denial_data_realtime_table (
	rn bigserial NOT NULL,
	denial_date timestamp NULL,
	denial_date1 date NULL,
	denial_id int4 NULL,
	feature_name varchar(255) NULL,
	user_name varchar(1000) NULL,
	host_name varchar(255) NULL,
	server_name varchar(1000) NULL,
	current_datetime timestamp NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT denial_data_realtime_table_pkey1 PRIMARY KEY (rn)
);

CREATE TABLE public.denials_aggregation (
	binning_time timestamp NULL,
	unique_uid_count int8 NOT NULL,
	unique_licenseid_count int8 NOT NULL,
	unique_uid text NULL,
	unique_licenseid text NULL,
	ts_ms timestamp NULL
);

CREATE TABLE public.denials_count (
	feature_name varchar(100) NULL,
	interval_start timestamp NULL,
	interval_end timestamp NULL,
	denials_count int4 NULL
);

CREATE TABLE public.denials_data_realtime (
	rn int8 DEFAULT nextval('denial_data_realtime_table_rn_seq'::regclass) NOT NULL,
	denial_date timestamp NULL,
	denial_date1 date NULL,
	denial_id int4 NULL,
	feature_name varchar(255) NULL,
	user_name varchar(1000) NULL,
	host_name varchar(255) NULL,
	server_name varchar(1000) NULL,
	current_datetime timestamp NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT denial_data_realtime_table_pkey PRIMARY KEY (rn)
);
CREATE TABLE public.denials_fact_table (
	transaction_id bigserial NOT NULL,
	denial_id int4 NULL,
	server_id int4 NULL,
	user_id varchar(30) NULL,
	project_id varchar(30) NULL,
	host_name varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT denials_fact_table_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.denials_transaction (
	denial_id int4 NOT NULL,
	status varchar(255) NULL,
	num_of_licenses int4 NULL,
	denial_date timestamp NULL,
	error_message text NULL,
	license_id int4 NULL,
	feature_name varchar(255) NULL,
	major_err int4 NULL,
	minor_err int4 NULL,
	denial_type varchar(255) NULL,
	denial_category varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	product_name varchar(1000) NULL,
	vendor varchar(255) NULL,
	"version" varchar(255) NULL,
	license_type varchar(255) NULL,
	additional_key varchar(1000) NULL,
	CONSTRAINT denials_transaction_pkey PRIMARY KEY (denial_id)
);

CREATE TABLE public.denials_transaction_hist (
	transaction_id bigserial NOT NULL,
	denial_id int4 NULL,
	status varchar(255) NULL,
	num_of_licenses int4 NULL,
	denial_date timestamp NULL,
	error_message text NULL,
	license_id int4 NULL,
	feature_name varchar(255) NULL,
	major_err int4 NULL,
	minor_err int4 NULL,
	denial_type varchar(255) NULL,
	denial_category varchar(255) NULL,
	ops bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	product_name varchar(1000) NULL,
	vendor varchar(255) NULL,
	"version" varchar(255) NULL,
	license_type varchar(255) NULL,
	additional_key varchar(1000) NULL,
	CONSTRAINT denials_transaction_hist_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.dongle_details_dimension (
	serial_no varchar(255) NOT NULL,
	device_id varchar(255) NULL,
	manufacturer text NULL,
	device_name text NULL,
	blacklisted_when_connected_or_disconnected varchar(2) NULL,
	device_description text NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT dongle_details_dimension_pkey PRIMARY KEY (serial_no)
);
CREATE TABLE public.dongle_transaction (
	monitoring_id bigserial NOT NULL,
	device_connected_date_time timestamp NULL,
	device_disconnected_date_time timestamp NULL,
	last_update_date_time timestamp NULL,
	serial_no varchar(255) NULL,
	user_name varchar(1000) NULL,
	host_name varchar(255) NULL,
	agent_status int4 NULL,
	customer_id varchar(200) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT dongle_transaction_pkey PRIMARY KEY (monitoring_id)
);
CREATE TABLE public.error_log_table (
	error_type text NULL,
	error_msg text NULL,
	criticality int4 NOT NULL,
	"timestamp" timestamp NULL
);
CREATE TABLE public.group_details_dimension (
	tenant_id varchar(200) NULL,
	group_id varchar(30) NOT NULL,
	group_name varchar(1000) NULL,
	unified_group_name varchar(1000) NULL,
	is_enabled bpchar(1) NULL,
	"source" varchar(255) NULL,
	is_user_group int4 NULL,
	default_project_id varchar(30) NULL,
	is_computer_group int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT group_details_dimension_pkey PRIMARY KEY (group_id)
);
CREATE TABLE public.group_host_fact_table (
	group_host_id bigserial NOT NULL,
	group_id varchar(30) NULL,
	host_id varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT group_host_fact_table_pkey PRIMARY KEY (group_host_id)
);
CREATE TABLE public.group_to_group_fact_table (
	group_to_group_id bigserial NOT NULL,
	group_id varchar(30) NULL,
	parent_group_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT group_to_group_fact_table_pkey PRIMARY KEY (group_to_group_id)
);
CREATE TABLE public.group_user_fact_table (
	group_user_id bigserial NOT NULL,
	group_id varchar(30) NULL,
	user_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT group_user_fact_table_pkey PRIMARY KEY (group_user_id)
);
CREATE TABLE public.host_details_dimension (
	host_id varchar(255) NOT NULL,
	tenant_id varchar(200) NULL,
	host_name varchar(255) NULL,
	host_ip varchar(255) NULL,
	host_port int4 NULL,
	host_source varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT host_details_dimension_pkey PRIMARY KEY (host_id)
);
CREATE TABLE public.idle_license_transaction (
	transaction_id bigserial NOT NULL,
	usage_id int4 NULL,
	idle_start_time_utc timestamp NULL,
	idle_end_time_utc timestamp NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT idle_license_transaction_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.license_allocation_transaction (
	allocation_id int4 NOT NULL,
	start_date_utc timestamp NULL,
	end_date_utc timestamp NULL,
	license_id int4 NULL,
	server_id int4 NULL,
	user_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_allocation_transaction_pkey PRIMARY KEY (allocation_id)
);
CREATE TABLE public.license_concurrent_measure (
	transaction_id bigserial NOT NULL,
	license_id int4 NULL,
	date_utc date NULL,
	"hour" int4 NULL,
	min_concurrent_usage int8 NULL,
	max_concurrent_usage int8 NULL,
	avg_concurrent_usage float8 NULL,
	ts_ms timestamp NULL,
	CONSTRAINT license_concurrent_measure_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.license_details_dimension (
	license_id int4 NOT NULL,
	server_id int4 NULL,
	package_id int4 NULL,
	feature_name varchar(255) NULL,
	product_name varchar(1000) NULL,
	vendor varchar(255) NULL,
	date_from_utc timestamp NULL,
	date_to_utc timestamp NULL,
	license_type varchar(255) NULL,
	"version" varchar(255) NULL,
	additional_key varchar(1000) NULL,
	is_token_based bpchar(1) NULL,
	num_of_tokens int4 NULL,
	quantity int4 NULL,
	overdraft int4 NULL,
	base_quantity int4 NULL,
	dup_group varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_details_dimension_pkey PRIMARY KEY (license_id)
);
CREATE TABLE public.license_fact_table (
	transaction_id bigserial NOT NULL,
	usage_id int4 NULL,
	tenant_id varchar(200) NULL,
	host_id varchar(255) NULL,
	user_id varchar(30) NULL,
	group_id varchar(30) NULL,
	project_id varchar(30) NULL,
	server_id int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_fact_table_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.license_procurement_table (
	procurement_id int4 NOT NULL,
	license_id int4 NULL,
	"policy" varchar(255) NULL,
	issued_date timestamp NULL,
	start_date timestamp NULL,
	expiration_date timestamp NULL,
	date_from_utc timestamp NULL,
	date_to_utc timestamp NULL,
	quantity int4 NULL,
	vendor_info varchar(1000) NULL,
	issuer varchar(255) NULL,
	borrow int4 NULL,
	overdraft int4 NULL,
	components_info text NULL,
	asset_info varchar(255) NULL,
	dist_info varchar(255) NULL,
	user_info varchar(255) NULL,
	status varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_procurement_table_pkey PRIMARY KEY (procurement_id)
);
CREATE TABLE public.license_quantity_table (
	quantity_id int4 NOT NULL,
	license_id int4 NULL,
	date_from_utc timestamp NULL,
	date_to_utc timestamp NULL,
	quantity int4 NULL,
	actual_quantity int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_quantity_table_pkey PRIMARY KEY (quantity_id)
);
CREATE TABLE public.license_server_dimension (
	server_id int4 NOT NULL,
	server_name varchar(1000) NULL,
	vendor varchar(1000) NULL,
	status_description varchar(1000) NULL,
	status_date_utc timestamp NULL,
	enabled bpchar(1) NULL,
	licenses_valid_until timestamp NULL,
	license_manager_type varchar(1000) NULL,
	is_token_enabled bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_server_dimension_pkey PRIMARY KEY (server_id)
);
CREATE TABLE public.license_server_host (
	transaction_id bigserial NOT NULL,
	server_id int4 NULL,
	host_name varchar(255) NULL,
	server_port int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_server_host_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.license_server_status (
	transaction_id bigserial NOT NULL,
	server_id int4 NULL,
	host_name varchar(255) NULL,
	server_port int4 NULL,
	host_status varchar(255) NULL,
	server_status varchar(255) NULL,
	update_date_utc timestamp NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_server_status_table_pkey1 PRIMARY KEY (transaction_id)
);
CREATE TABLE public.license_transaction (
	usage_id int4 NOT NULL,
	license_id int4 NULL,
	start_time_utc timestamp NULL,
	end_time_utc timestamp NULL,
	duration float8 NULL,
	borrowed int4 NULL,
	num_of_licenses int4 NULL,
	idle_time float8 NULL,
	remote_ip varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	client_license_version varchar(100) NULL,
	handle int4 NULL,
	linger_time int4 NULL,
	linger_due_date varchar(100) NULL,
	CONSTRAINT license_transaction_pkey PRIMARY KEY (usage_id)
);
CREATE TABLE public.license_transaction_hist (
	transaction_id bigserial NOT NULL,
	usage_id int4 NULL,
	license_id int4 NULL,
	start_time_utc timestamp NULL,
	end_time_utc timestamp NULL,
	duration float8 NULL,
	borrowed int4 NULL,
	num_of_licenses int4 NULL,
	idle_time float8 NULL,
	remote_ip varchar(255) NULL,
	ops bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	client_license_version varchar(100) NULL,
	handle int4 NULL,
	linger_time int4 NULL,
	linger_due_date varchar(100) NULL,
	CONSTRAINT license_transaction_hist_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.license_usage_data_realtime (
	rn bigserial NOT NULL,
	license_id int4 NULL,
	start_time_utc timestamp NULL,
	start_date_utc date NULL,
	end_time_utc timestamp NULL,
	feature_name varchar(255) NULL,
	user_name varchar(1000) NULL,
	host_name varchar(255) NULL,
	server_name varchar(1000) NULL,
	current_datetime timestamp NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT license_usage_data_realtime_pkey PRIMARY KEY (rn)
);

CREATE TABLE public.location_dimension (
	license_id int4 NULL,
	rule_type int4 NULL,
	rule_value varchar(10) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL
);

CREATE TABLE public.office_time_calculation (
	usage_id int8 NOT NULL,
	duration_in_days int4 NULL,
	user_id varchar(255) NULL,
	lic_id int4 NULL,
	start_time_utc timestamp NULL,
	end_time_utc timestamp NULL,
	start_date_name varchar(50) NULL,
	end_date_name varchar(50) NULL,
	if_startdate_weekend bool NULL,
	if_enddate_weekend bool NULL,
	num_weekend_in_range int4 NULL,
	country_code varchar(10) NULL,
	time_zone text NULL,
	utc_offset varchar(10) NULL,
	utc_diff varchar(10) NULL,
	shift_starttime varchar(10) NULL,
	shift_endtime varchar(10) NULL,
	shift_starttime_utc varchar(10) NULL,
	shift_endtime_utc varchar(10) NULL,
	avg_daily_working_hours float8 NULL,
	utilization_time float8 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT office_time_calculation_pkey PRIMARY KEY (usage_id)
);

CREATE TABLE public.process_details_dimension (
	process_id varchar(64) NOT NULL,
	dll_name varchar(255) NULL,
	process_name varchar(255) NULL,
	"version" varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT process_details_dimension_pkey PRIMARY KEY (process_id)
);

CREATE TABLE public.process_fact_table (
	transaction_id bigserial NOT NULL,
	user_id varchar(30) NULL,
	session_id varchar(30) NULL,
	monitoring_id int4 NULL,
	host_name varchar(255) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT process_fact_table_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.process_session_details_transaction (
	session_id varchar(30) NOT NULL,
	process_id varchar(64) NULL,
	session_duration_in_min float8 NULL,
	session_end_time timestamp NULL,
	session_start_time timestamp NULL,
	total_idle_time_in_min float8 NULL,
	shutdown_reason varchar(10) NULL,
	customer_id varchar(200) NULL,
	agent_status int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT process_session_details_transaction_pkey PRIMARY KEY (session_id)
);

CREATE TABLE public.process_session_details_transaction_hist (
	transaction_id bigserial NOT NULL,
	session_id varchar(30) NULL,
	process_id varchar(64) NULL,
	session_duration_in_min float8 NULL,
	session_end_time timestamp NULL,
	session_start_time timestamp NULL,
	total_idle_time_in_min float8 NULL,
	shutdown_reason varchar(10) NULL,
	customer_id varchar(200) NULL,
	agent_status int4 NULL,
	ops bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT process_session_details_transaction_hist_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.procured_license_cost_mapping_dimension (
	cost_id bigserial NOT NULL,
	license_id int4 NULL,
	unit_cost float8 NULL,
	purchase_currency varchar(7) NULL,
	conversion_factor float8 NULL,
	procurement_country_code varchar(3) NULL,
	duration_value int4 NULL,
	duration_unit varchar(8) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT procured_license_cost_mapping_dimension_pkey PRIMARY KEY (cost_id)
);

CREATE TABLE public.project_details_dimension (
	project_id varchar(30) NOT NULL,
	project_name varchar(1000) NULL,
	start_time_utc timestamp NULL,
	end_time_utc timestamp NULL,
	priority varchar(10) NULL,
	percent_done int4 NULL,
	"source" varchar(255) NULL,
	is_enabled bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT project_details_dimension_pkey PRIMARY KEY (project_id)
);

CREATE TABLE public.project_group_fact_table (
	transaction_id bigserial NOT NULL,
	group_id varchar(30) NULL,
	project_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT project_group_fact_table_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.project_parent_fact_table (
	transaction_id bigserial NOT NULL,
	parent_id varchar(30) NULL,
	project_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT project_parent_fact_table_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.project_usage (
	usage_id varchar(30) NOT NULL,
	start_date_utc timestamp NULL,
	end_date_utc timestamp NULL,
	workstation varchar(1000) NULL,
	user_name varchar(1000) NULL,
	user_id varchar(30) NULL,
	project_id varchar(30) NULL,
	tenant_id varchar(200) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT project_usage_pkey PRIMARY KEY (usage_id)
);
CREATE TABLE public.project_user_fact_table (
	transaction_id bigserial NOT NULL,
	user_id varchar(30) NULL,
	project_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT project_user_fact_table_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.token_based_statistics_dimension (
	stats_id int4 NOT NULL,
	"name" varchar(1000) NULL,
	consumed int4 NULL,
	available int4 NULL,
	team_id varchar(100) NULL,
	total_quantity int4 NULL,
	server_id int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT token_based_statistics_dimension_pkey PRIMARY KEY (stats_id)
);
CREATE TABLE public.token_based_transaction (
	usage_id int4 NOT NULL,
	usage_date timestamp NULL,
	number_of_tokens int4 NULL,
	license_id int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT token_based_transaction_pkey PRIMARY KEY (usage_id)
);
CREATE TABLE public.token_based_transaction_hist (
	transaction_id bigserial NOT NULL,
	usage_id int4 NULL,
	usage_date timestamp NULL,
	number_of_tokens int4 NULL,
	license_id int4 NULL,
	ops bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT token_based_transaction_hist_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.token_based_user_fact (
	transaction_id bigserial NOT NULL,
	user_id varchar(30) NULL,
	server_id int4 NULL,
	usage_id int4 NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT token_based_user_fact_pkey PRIMARY KEY (transaction_id)
);
CREATE TABLE public.touchpoint_transaction (
	event_id varchar(30) NOT NULL,
	event_date_time timestamp NULL,
	event_type int4 NULL,
	event_type_desc text NULL,
	found_url text NULL,
	host_name varchar(255) NULL,
	page_title text NULL,
	touchpoint_event_source text NULL,
	user_name varchar(1000) NULL,
	customer_id varchar(200) NULL,
	user_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT touchpoint_transaction_pkey PRIMARY KEY (event_id)
);
CREATE TABLE public.touchpoint_transaction_hist (
	transaction_id bigserial NOT NULL,
	event_id varchar(30) NULL,
	event_date_time timestamp NULL,
	event_type int4 NULL,
	event_type_desc text NULL,
	found_url text NULL,
	host_name varchar(255) NULL,
	page_title text NULL,
	touchpoint_event_source text NULL,
	user_name varchar(1000) NULL,
	customer_id varchar(200) NULL,
	user_id varchar(30) NULL,
	ops bpchar(1) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT touchpoint_transaction_hist_pkey PRIMARY KEY (transaction_id)
);

CREATE TABLE public.user_details_dimension (
	tenant_id varchar(200) NULL,
	user_id varchar(30) NOT NULL,
	user_name varchar(1000) NULL,
	unified_user_name varchar(2000) NULL,
	first_name varchar(1000) NULL,
	last_name varchar(1000) NULL,
	display_name varchar(2000) NULL,
	title varchar(1000) NULL,
	department varchar(1000) NULL,
	phone_number varchar(255) NULL,
	description varchar(1000) NULL,
	office varchar(1000) NULL,
	is_enabled bpchar(1) NULL,
	email varchar(2000) NULL,
	"password" varchar(255) NULL,
	"source" varchar(255) NULL,
	country varchar(1000) NULL,
	mobile_phone varchar(255) NULL,
	default_group_id varchar(30) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL,
	CONSTRAINT user_details_dimension_pkey PRIMARY KEY (user_id)
);
CREATE TABLE public.utc_workinghours_dimension (
	country_code varchar(3) NULL,
	country_name varchar(255) NULL,
	time_zone text NULL,
	utc_offset varchar(25) NULL,
	utc_diff varchar(25) NULL,
	shift_starttime time(0) NULL,
	avg_daily_working_hours int4 NULL,
	shift_endtime time(0) NULL,
	shift_starttime_utc time(0) NULL,
	shift_endtime_utc time(0) NULL,
	ts_ms timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) NULL
);





