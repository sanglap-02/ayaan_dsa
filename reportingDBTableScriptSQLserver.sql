
CREATE TABLE cost_mapping_dimension (
	cost_id bigint IDENTITY(1,1) NOT NULL,
	process_id varchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_id varchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cost float NULL,
	currency varchar(7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	conversion_factor float NULL,
	country_code varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	duration_value int NULL,
	duration_unit varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__cost_map__9C2BDCCFED7EF782 PRIMARY KEY (cost_id)
);
GO

CREATE TABLE country_dimension (
	country_code varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	country nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	region nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL
);
GO

CREATE TABLE denials_aggregation (
	binning_time datetime NULL,
	unique_uid_count bigint NOT NULL,
	unique_licenseid_count bigint NOT NULL,
	unique_uid nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	unique_licenseid nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 NULL
);

GO

CREATE TABLE denials_count (
	feature_name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	interval_start datetime NULL,
	interval_end datetime NULL,
	denials_count int NULL
);
GO

CREATE TABLE denials_data_realtime (
	rn bigint IDENTITY(1,1) NOT NULL,
	denial_date datetime2 NULL,
	denial_date1 date NULL,
	denial_id int NULL,
	feature_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	current_datetime datetime2 NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__denials___3214330AF2B6355B PRIMARY KEY (rn)
);
GO

CREATE TABLE denials_fact_table (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	denial_id int NULL,
	server_id int NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__denials___85C600AFEEF38766 PRIMARY KEY (transaction_id)
);
GO

CREATE TABLE denials_transaction (
	denial_id int NOT NULL,
	status nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	num_of_licenses int NULL,
	denial_date datetime2 NULL,
	error_message nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	license_id int NULL,
	feature_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	major_err int NULL,
	minor_err int NULL,
	denial_type nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	denial_category nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	product_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	vendor nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	version nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	license_type nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	additional_key nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__denials___AE0D3BAD02427350 PRIMARY KEY (denial_id)
);

GO

CREATE TABLE denials_transaction_hist (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	denial_id int NULL,
	status nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	num_of_licenses int NULL,
	denial_date datetime2 NULL,
	error_message nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	license_id int NULL,
	feature_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	major_err int NULL,
	minor_err int NULL,
	denial_type nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	denial_category nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ops char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	product_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	vendor nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	version nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	license_type nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	additional_key nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__denials___85C600AF2392A533 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE dongle_details_dimension (
	serial_no nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	device_id nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	manufacturer nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	device_name nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	blacklisted_when_connected_or_disconnected nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	device_description nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__dongle_d__E5458193D33F531B PRIMARY KEY (serial_no)
);
GO


CREATE TABLE dongle_transaction (
	monitoring_id bigint IDENTITY(1,1) NOT NULL,
	device_connected_date_time datetime2 NULL,
	device_disconnected_date_time datetime2 NULL,
	last_update_date_time datetime2 NULL,
	serial_no nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	agent_status int NULL,
	customer_id varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__dongle_t__68F3D4A2EF617128 PRIMARY KEY (monitoring_id)
);
GO


CREATE TABLE group_details_dimension (
	tenant_id nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	group_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	unified_group_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_enabled char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[source] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_user_group int NULL,
	default_project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_computer_group int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__group_de__D57795A0CB646E66 PRIMARY KEY (group_id)
);
GO


CREATE TABLE group_host_fact_table (
	group_host_id bigint IDENTITY(1,1) NOT NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_id varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__group_ho__D17B70ED611F9BA4 PRIMARY KEY (group_host_id)
);
GO


CREATE TABLE group_to_group_fact_table (
	group_to_group_id bigint IDENTITY(1,1) NOT NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	parent_group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__group_to__C78FFCAF46725C05 PRIMARY KEY (group_to_group_id)
);
GO


CREATE TABLE group_user_fact_table (
	group_user_id bigint IDENTITY(1,1) NOT NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__group_us__195466964EF46A26 PRIMARY KEY (group_user_id)
);
GO


CREATE TABLE host_details_dimension (
	tenant_id nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_id varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_ip nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_port int NULL,
	host_source nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__host_det__A397C7AE13140170 PRIMARY KEY (host_id)
);

GO


CREATE TABLE idle_license_transaction (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	usage_id int NULL,
	idle_start_time_utc datetime2 NULL,
	idle_end_time_utc datetime2 NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__idle_lic__85C600AFA12EAF96 PRIMARY KEY (transaction_id)
);

GO


CREATE TABLE license_allocation_transaction (
	allocation_id int NOT NULL,
	start_date_utc datetime2 NULL,
	end_date_utc datetime2 NULL,
	license_id int NULL,
	server_id int NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___5DFAFF307E3D804D PRIMARY KEY (allocation_id)
);
GO


CREATE TABLE license_concurrent_measure (
	transaction_id bigint NOT NULL,
	license_id int NULL,
	date_utc date NULL,
	[hour] int NULL,
	min_concurrent_usage bigint NULL,
	max_concurrent_usage bigint NULL,
	avg_concurrent_usage float NULL,
	ts_ms datetime2 NULL,
	CONSTRAINT PK__license___85C600AF8F319017 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE license_details_dimension (
	license_id int NOT NULL,
	server_id int NULL,
	package_id int NULL,
	feature_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	product_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	vendor nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	date_from_utc datetime2 NULL,
	date_to_utc datetime2 NULL,
	license_type nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	version nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	additional_key nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_token_based char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	num_of_tokens int NULL,
	quantity int NULL,
	overdraft int NULL,
	base_quantity int NULL,
	dup_group nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___BBBB75781E68483F PRIMARY KEY (license_id)
);
GO


CREATE TABLE license_fact_table (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	usage_id int NULL,
	tenant_id nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_id varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_id int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___85C600AF39981D76 PRIMARY KEY (transaction_id)
);
 CREATE NONCLUSTERED INDEX IX_license_fact_table_usage_id_INC ON dbo.license_fact_table (  usage_id ASC  )  
	 INCLUDE ( group_id , host_id , project_id , server_id , tenant_id , ts_ms , user_id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
GO

CREATE TABLE license_join_table (
	usage_id int NOT NULL,
	borrowed int NULL,
	duration float NULL,
	start_time_utc datetime2 NULL,
	end_time_utc datetime2 NULL,
	start_date_utc date NULL,
	idle_time float NULL,
	num_of_licenses int NULL,
	license_id int NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_id int NULL,
	ts_ms datetime2 NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	first_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	last_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	display_name nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	department nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	email nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	country nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	country_code varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	mobile_phone nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	lic_inv_id int NULL,
	lic_inv_vendor nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	feature_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	lic_inv_quantity int NULL,
	lic_inv_type nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	lic_inv_version nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_token_based char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	lic_inv_additional_key nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	fea_package_id int NULL,
	product_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	group_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	region nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	date_from_utc datetime2 NULL,
	date_to_utc datetime2 NULL,
	quantity int NULL,
	package_id int NULL,
	[source] nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);
GO

CREATE TABLE license_procurement_table (
	procurement_id int NOT NULL,
	license_id int NULL,
	policy nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	issued_date datetime2 NULL,
	start_date datetime2 NULL,
	expiration_date datetime2 NULL,
	date_from_utc datetime2 NULL,
	date_to_utc datetime2 NULL,
	quantity int NULL,
	vendor_info nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	issuer nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	borrow int NULL,
	overdraft int NULL,
	components_info nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	asset_info nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	dist_info nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_info nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___C51250D2265360BC PRIMARY KEY (procurement_id)
);
GO

CREATE TABLE license_quantity_table (
	quantity_id int NOT NULL,
	license_id int NULL,
	date_from_utc datetime2 NULL,
	date_to_utc datetime2 NULL,
	quantity int NULL,
	actual_quantity int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___6D8587FF7F409D93 PRIMARY KEY (quantity_id)
);
GO

CREATE TABLE license_server_dimension (
	server_id int NOT NULL,
	server_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	vendor nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_description nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_date_utc datetime2 NULL,
	enabled char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	licenses_valid_until datetime2 NULL,
	license_manager_type nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_token_enabled char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___ED5B5C580BFBE812 PRIMARY KEY (server_id)
);
GO

CREATE TABLE license_server_host (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	server_id int NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_port int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___85C600AF4B284E6D PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE license_server_status (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	server_id int NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_port int NULL,
	host_status nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_status nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	update_date_utc datetime2 NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___85C600AFA13E3AE8 PRIMARY KEY (transaction_id)
);
GO

CREATE TABLE license_transaction (
	usage_id int NOT NULL,
	license_id int NULL,
	start_time_utc datetime2 NULL,
	end_time_utc datetime2 NULL,
	duration float NULL,
	borrowed int NULL,
	num_of_licenses int NULL,
	idle_time float NULL,
	remote_ip nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	client_license_version nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	handle int NULL,
	linger_time int NULL,
	linger_due_date nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__license___B6B13A0214234050 PRIMARY KEY (usage_id)
);
 CREATE NONCLUSTERED INDEX IX_license_transaction_start_time_utc_INC ON dbo.license_transaction (  start_time_utc ASC  )  
	 INCLUDE ( borrowed , duration , end_time_utc , idle_time , license_id , num_of_licenses , remote_ip , ts_ms ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
GO

CREATE TABLE license_transaction_hist (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	usage_id int NULL,
	license_id int NULL,
	start_time_utc datetime2 NULL,
	end_time_utc datetime2 NULL,
	duration float NULL,
	borrowed int NULL,
	num_of_licenses int NULL,
	idle_time float NULL,
	remote_ip nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ops char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	client_license_version nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	handle int NULL,
	linger_time int NULL,
	linger_due_date nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__license___85C600AFD6041B94 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE license_usage_data_realtime (
	rn bigint IDENTITY(1,1) NOT NULL,
	license_id int NULL,
	start_time_utc datetime2 NULL,
	start_date_utc date NULL,
	end_time_utc datetime2 NULL,
	feature_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	current_datetime datetime2 NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__license___3214330AFB2BF10B PRIMARY KEY (rn)
);
GO


CREATE TABLE location_dimension (
	license_id int NULL,
	rule_type int NULL,
	rule_value nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL
);
GO


CREATE TABLE office_time_calculation (
	usage_id bigint NOT NULL,
	duration_in_days int NULL,
	user_id nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	lic_id int NULL,
	start_time_utc datetime NULL,
	end_time_utc datetime NULL,
	start_date_name nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	end_date_name nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	if_startdate_weekend bit NULL,
	if_enddate_weekend bit NULL,
	num_weekend_in_range int NULL,
	country_code nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	time_zone nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	utc_offset nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	utc_diff nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	shift_starttime nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	shift_endtime nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	shift_starttime_utc nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	shift_endtime_utc nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	avg_daily_working_hours float NULL,
	utilization_time float NULL,
	ts_ms datetime NULL,
	CONSTRAINT PK_office_time_calculation PRIMARY KEY (usage_id)
);
GO

CREATE TABLE process_details_dimension (
	process_id varchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	dll_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	process_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	version nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__process___9446C3E19AE8EB99 PRIMARY KEY (process_id)
);
GO


CREATE TABLE process_fact_table (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	session_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	monitoring_id int NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__process___85C600AF7EB87CD7 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE process_session_details_transaction (
	session_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	process_id varchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	session_duration_in_min float NULL,
	session_end_time datetime2 NULL,
	session_start_time datetime2 NULL,
	total_idle_time_in_min float NULL,
	shutdown_reason nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	customer_id varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	agent_status int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__process___69B13FDCE9ABF148 PRIMARY KEY (session_id)
);
GO


CREATE TABLE process_session_details_transaction_hist (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	session_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	process_id varchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	session_duration_in_min float NULL,
	session_end_time datetime2 NULL,
	session_start_time datetime2 NULL,
	total_idle_time_in_min float NULL,
	shutdown_reason nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	customer_id varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	agent_status int NULL,
	ops char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__process___85C600AF887CF295 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE procured_license_cost_mapping_dimension (
	cost_id bigint IDENTITY(1,1) NOT NULL,
	license_id int NULL,
	unit_cost float NULL,
	purchase_currency nvarchar(7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	conversion_factor float NULL,
	procurement_country_code varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	duration_value int NULL,
	duration_unit varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__procured__9C2BDCCF37597702 PRIMARY KEY (cost_id)
);
GO


CREATE TABLE project_details_dimension (
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	project_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	start_time_utc datetime2 NULL,
	end_time_utc datetime2 NULL,
	priority nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	percent_done int NULL,
	[source] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_enabled char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__project___BC799E1F30A4DAF5 PRIMARY KEY (project_id)
);
GO


CREATE TABLE project_group_fact_table (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__project___85C600AFC4D6294B PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE project_parent_fact_table (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	parent_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__project___85C600AF4B16A9BE PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE project_usage (
	usage_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	start_date_utc datetime2 NULL,
	end_date_utc datetime2 NULL,
	workstation nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	tenant_id nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__project___B6B13A023196E062 PRIMARY KEY (usage_id)
);
GO


CREATE TABLE project_user_fact_table (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	project_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__project___85C600AFCC1AC4B6 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE token_based_statistics_dimension (
	stats_id int NOT NULL,
	name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	consumed int NULL,
	available int NULL,
	team_id varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	total_quantity int NULL,
	server_id int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__token_ba__03C4F07424C06EF9 PRIMARY KEY (stats_id)
);
GO


CREATE TABLE token_based_transaction (
	usage_id int NOT NULL,
	usage_date datetime2 NULL,
	number_of_tokens int NULL,
	license_id int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__token_ba__B6B13A029FED0A78 PRIMARY KEY (usage_id)
);
GO


CREATE TABLE token_based_transaction_hist (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	usage_id int NULL,
	usage_date datetime2 NULL,
	number_of_tokens int NULL,
	license_id int NULL,
	ops char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__token_ba__85C600AF67118343 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE token_based_user_fact (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	server_id int NULL,
	usage_id int NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__token_ba__85C600AF8027FE26 PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE touchpoint_transaction (
	event_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	event_date_time datetime2 NULL,
	event_type int NULL,
	event_type_desc nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	found_url nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	page_title nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	touchpoint_event_source nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	customer_id varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__touchpoi__2370F72759080225 PRIMARY KEY (event_id)
);
GO


CREATE TABLE touchpoint_transaction_hist (
	transaction_id bigint IDENTITY(1,1) NOT NULL,
	event_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	event_date_time datetime2 NULL,
	event_type int NULL,
	event_type_desc nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	found_url nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	host_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	page_title nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	touchpoint_event_source nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	customer_id varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ops char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__touchpoi__85C600AF216316AD PRIMARY KEY (transaction_id)
);
GO


CREATE TABLE user_details_dimension (
	tenant_id nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	user_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	user_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	unified_user_name nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	first_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	last_name nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	display_name nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	title nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	department nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	phone_number nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	description nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	office nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	is_enabled char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	email nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	password nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[source] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	country nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	mobile_phone nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	default_group_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL,
	CONSTRAINT PK__user_det__B9BE370FC8B50D52 PRIMARY KEY (user_id)
);
GO


CREATE TABLE utc_workinghours_dimension (
	country_code varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	country_name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	time_zone nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	utc_offset nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	utc_diff nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	shift_starttime time(0) NULL,
	avg_daily_working_hours int NULL,
	shift_endtime time(0) NULL,
	shift_starttime_utc time(0) NULL,
	shift_endtime_utc time(0) NULL,
	ts_ms datetime2 DEFAULT getutcdate() NULL
);

