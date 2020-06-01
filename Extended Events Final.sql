IF EXISTS (SELECT * FROM  sys.configurations WHERE name = 'blocked process threshold (s)' AND value_in_use = 0)
	BEGIN
		IF EXISTS (SELECT * FROM  sys.configurations WHERE name = 'show advanced options' AND value_in_use = 0)
			BEGIN
				EXEC sys.sp_configure 'show advanced options' , 1;
				RECONFIGURE;
			END
		EXEC sys.sp_configure 'blocked process threshold (s)' , 5;
		RECONFIGURE;
	END

IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'SQLMonitoring_CompletedQueries')			IS NOT NULL DROP EVENT SESSION SQLMonitoring_CompletedQueries		  ON SERVER;
IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'SQLMonitoring_PageSplits')					IS NOT NULL DROP EVENT SESSION SQLMonitoring_PageSplits				  ON SERVER;
IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'Histogram_PageSplits')						IS NOT NULL DROP EVENT SESSION Histogram_PageSplits					  ON SERVER;

IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'SQLMonitoring_CorruptionAndConsistency')	IS NOT NULL DROP EVENT SESSION SQLMonitoring_CorruptionAndConsistency ON SERVER;
IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'SQLMonitoring_ObjectModifications')		IS NOT NULL DROP EVENT SESSION SQLMonitoring_ObjectModifications      ON SERVER;
IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'SQLMonitoring_DatabaseLevelEvents')		IS NOT NULL DROP EVENT SESSION SQLMonitoring_DatabaseLevelEvents      ON SERVER;
IF (SELECT TOP 1 1 FROM  sys.server_event_sessions WHERE name = 'SQLMonitoring_Locking')					IS NOT NULL DROP EVENT SESSION SQLMonitoring_Locking                  ON SERVER;

CREATE EVENT SESSION SQLMonitoring_CompletedQueries	      ON SERVER 
ADD EVENT sqlos.wait_info(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ([opcode]=(1) AND [duration]>(1000) AND ([wait_type]>(0) AND [wait_type]<(22) OR [wait_type]>(31) AND [wait_type]<(38) OR [wait_type]>(47) AND [wait_type]<(54) OR [wait_type]>(63) AND [wait_type]<(70) OR [wait_type]>(96) AND [wait_type]<(100) OR [wait_type]=(107) OR [wait_type]=(113) OR [wait_type]=(120) OR [wait_type]=(178) OR [wait_type]>(174) AND [wait_type]<(177) OR [wait_type]=(186) OR [wait_type]=(187) OR [wait_type]=(207) OR [wait_type]=(269) OR [wait_type]=(283) OR [wait_type]=(284)) AND [sqlserver].[session_id]>=(50))),
ADD EVENT sqlserver.additional_memory_grant(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([granted_memory_kb]>=(10000))),
ADD EVENT sqlserver.alter_table_update_data(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.attention(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([duration]>=(1000000) AND [sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.batch_hash_join_separate_hash_column(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.batch_hash_table_build_bailout(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.bitmap_disabled_warning(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.exchange_spill(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.execution_warning(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.expression_compile_stop_batch_processing(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.hash_spill_details(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.hash_warning(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([granted_memory_kb]>=(10000) AND ([workfile_physical_writes]>=(100) OR [worktable_physical_writes]>=(100)) AND [sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.latch_suspend_warning(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.lock_timeout_greater_than_0(SET collect_database_name=(1),collect_resource_description=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.long_io_detected(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.missing_column_statistics(SET collect_column_list=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text,sqlserver.username)
    WHERE (NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%staging%') AND [sqlserver].[database_name]<>N'tempdb' AND [sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.missing_join_predicate(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[is_system]=(0) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%redgate%') AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%intellisense%'))),
ADD EVENT sqlserver.optimizer_timeout(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.plan_affecting_convert(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[client_app_name]<>N'dbatools PowerShell module - dbatools.io' AND [sqlserver].[client_app_name]<>N'SQL Monitor - Monitoring' AND NOT [sqlserver].[like_i_sql_unicode_string]([expression],N'%mssqlsystemresource%') AND NOT [sqlserver].[like_i_sql_unicode_string]([expression],N'%TempDB%') AND NOT [sqlserver].[like_i_sql_unicode_string]([expression],N'%replica_server_name%') AND NOT [sqlserver].[like_i_sql_unicode_string]([expression],N'%HADR%') AND [sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.query_memory_grant_usage(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE (([granted_percent]<=(70) OR [granted_percent]>=(130)) AND ([granted_memory_kb]>=(10000) OR [used_memory_kb]>=(10000)))),
ADD EVENT sqlserver.sort_warning(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.username)
    WHERE (([used_memory_kb]>=(1000) OR [granted_memory_kb]>=(10000)) AND [worktable_physical_reads]>=(100) AND [sqlserver].[is_system]=(0))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlos.task_time,sqlserver.database_name,package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id)
    WHERE ([duration]>=(1000000) OR [cpu_time]>=(1000000))),	
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.username)
    WHERE (([duration]>=(1000000)) OR ([cpu_time]>=(1000000)))),
ADD EVENT sqlserver.unmatched_filtered_indexes(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.ring_buffer(SET max_events_limit=(5000),max_memory=(10240))
WITH (MAX_MEMORY=25600 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=120 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO

--CREATE EVENT SESSION SQLMonitoring_PageSplits ON SERVER 
--ADD EVENT sqlserver.page_split(
--    ACTION(sqlserver.session_id)),
--ADD EVENT sqlserver.sql_statement_completed(SET collect_statement=(1)
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.session_id)
--    WHERE ([duration]>=(1000000) AND [cpu_time]>=(1000000)))
--ADD TARGET package0.ring_buffer(SET max_memory=(25600))
--WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
--GO
CREATE EVENT SESSION Histogram_PageSplits ON SERVER 
ADD EVENT sqlserver.page_split(
ACTION(sqlserver.session_id,package0.collect_system_time))
ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.page_split',source=N'database_id',source_type=(0))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO


CREATE EVENT SESSION [SQLMonitoring_CorruptionAndConsistency] ON SERVER 
ADD EVENT sqlserver.constant_page_corruption_detected(
    ACTION(package0.collect_current_thread_id,package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.database_suspect_data_page(SET collect_database_name=(1)
    ACTION(package0.collect_current_thread_id,package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
--ADD EVENT sqlserver.dbcc_checkdb_error_reported(
--    ACTION(package0.collect_current_thread_id))
--	,
ADD EVENT sqlserver.error_reported(
    ACTION(package0.collect_current_thread_id,package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
	         WHERE (
                   ([severity] >= (17))
                   AND ([severity] <= (25))
               ))
ADD TARGET package0.ring_buffer(SET max_memory=(1024))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO


CREATE EVENT SESSION SQLMonitoring_Locking ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.lock_acquired(SET collect_database_name=(1),collect_resource_description=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
	WHERE ([duration]>=(1000000))),
ADD EVENT sqlserver.lock_cancel(SET collect_database_name=(1),collect_resource_description=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.lock_deadlock_chain(SET collect_database_name=(1),collect_resource_description=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.lock_escalation(SET collect_database_name=(1),collect_statement=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.locks_lock_waits(
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))--,
--ADD EVENT sqlserver.query_memory_grant_blocking(
--    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.ring_buffer(SET max_memory=(1024))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO

CREATE EVENT SESSION SQLMonitoring_ObjectModifications ON SERVER 
ADD EVENT sqlserver.object_altered(SET collect_database_name=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ((((([package0].[not_equal_uint64]([database_id],(2))) AND ([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'telemetry_xevents'))) AND (NOT ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%STAGING%')))) AND ([object_type]<>(21587))) AND ([ddl_phase]=(1)))),
    --WHERE ([package0].[not_equal_uint64]([database_id],(2)) AND [object_name]<>N'telemetry_xevents' AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%STAGING%'))),
ADD EVENT sqlserver.object_created(SET collect_database_name=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    --WHERE (((([package0].[not_equal_uint64]([database_id],(2))) AND ([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'telemetry_xevents'))) AND (NOT ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%STAGING%')))) AND ([object_type]<>(21587)))),
    WHERE ((((([package0].[not_equal_uint64]([database_id],(2))) AND ([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'telemetry_xevents'))) AND (NOT ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%STAGING%')))) AND ([object_type]<>(21587))) AND ([ddl_phase]=(1)))),
ADD EVENT sqlserver.object_deleted(SET collect_database_name=(1)
    ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ((((([package0].[not_equal_uint64]([database_id],(2))) AND ([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'telemetry_xevents'))) AND (NOT ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%STAGING%')))) AND ([object_type]<>(21587))) AND ([ddl_phase]=(1))))
    --WHERE ([package0].[not_equal_uint64]([database_id],(2)) AND [object_name]<>N'telemetry_xevents' AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'%STAGING%')))
ADD TARGET package0.ring_buffer(SET max_memory=(1024))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

GO

CREATE EVENT SESSION SQLMonitoring_DatabaseLevelEvents ON SERVER 
ADD EVENT sqlserver.database_attached					(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.database_created					(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.database_detached					(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
--ADD EVENT sqlserver.database_dropped,					(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD EVENT sqlserver.database_file_size_change			(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.database_started					(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.database_stopped					(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.databases_data_file_size_changed	(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.databases_log_file_size_changed		(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))		,
ADD EVENT sqlserver.databases_log_growth				(ACTION(package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.ring_buffer(SET max_memory=(1024))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

CREATE EVENT SESSION SQLMonitoring_PageSplits ON SERVER 
ADD EVENT sqlserver.page_split(
    ACTION(package0.collect_current_thread_id,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.session_id,sqlserver.sql_text)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)) AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[client_hostname],N'monitor-01') AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[client_hostname],N'monitor-03')))
ADD TARGET package0.ring_buffer(SET max_memory=(25600))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO



ALTER EVENT SESSION SQLMonitoring_CompletedQueries			 ON SERVER STATE  = START;
ALTER EVENT SESSION SQLMonitoring_PageSplits				 ON SERVER STATE  = START;
ALTER EVENT SESSION SQLMonitoring_CorruptionAndConsistency   ON SERVER STATE  = START;
ALTER EVENT SESSION SQLMonitoring_Locking				     ON SERVER STATE  = START;	


ALTER EVENT SESSION SQLMonitoring_ObjectModifications        ON SERVER STATE  = START;
ALTER EVENT SESSION SQLMonitoring_DatabaseLevelEvents        ON SERVER STATE  = START;
ALTER EVENT SESSION Histogram_PageSplits					 ON SERVER STATE  = START;
