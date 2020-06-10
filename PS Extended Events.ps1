Import-Module SQLServerMonitoringGeneral
function Write-SQLMonitoringErrors 
    {
        
        [CmdletBinding(DefaultParameterSetName = "Default")]
        
        param 
            (
                 [string[]]$ErrorDateTime        = (get-date)
                ,[string[]]$FunctionName         = ""
                ,[string[]]$Iteration            = "" 
                ,[string[]]$ErrorVariable        = ""
                ,[string[]]$WarningVariable      = ""
            )
            
            $MonitoringServerDetails = Get-MonitoringServer
            $TargetServerInstance    = $MonitoringServerDetails['ServerInstance']
            $TargetDatabase          = "DatabaseMonitoring"
            $TargetSchema            = "Errors"
            $TargetTable             = "Errors"
            $ErrorLoggingData        = $DateTime | Select-Object @{N='ErrorDateTime';E={$_.ErrorDateTime}} `
            , @{N='FunctionName';E={$FunctionName}} `
            , @{N='Iteration';E={$Iteration}} `
            , @{N='ErrorVariable';E={$ErrorVariable}} `
            , @{N='WarningVariable';E={$WarningVariable}} 

            $ErrorLoggingData | Write-DbaDataTable -SqlInstance $TargetServerInstance -Database $TargetDatabase -Schema $TargetSchema -Table $TargetTable -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            
            Remove-Variable MonitoringServerDetails
            Remove-Variable TargetServerInstance
            Remove-Variable TargetDatabase
            Remove-Variable TargetSchema
            Remove-Variable TargetTable
            Remove-Variable ErrorLoggingData
            Remove-Variable ErrorLoggingData
    }
    function write-SQLMonitoringExtendedEventsDataXML
    {
        $MonitoringServerDetails = Get-MonitoringServer
        $TargetServerInstance    = $MonitoringServerDetails['ServerInstance']
        $TargetDatabase          = $MonitoringServerDetails['DatabaseName']
        $TargetSchema            = "Staging" 
        $TargetTable             = "EventQueue"
        $SQLList = Get-SQLServerList -InstanceRole PROD -InstanceType 'BUSINESS CRITICAL' | Where-Object {$_.SQLInstance -eq "Rep-01"}
        $SQLQuery = "
        /*
            Strange optimzation, it seems to be quicker to return from a temp table than 
        */
            IF OBJECT_ID('TempDB..#EventData','U') IS NOT NULL DROP TABLE #EventData;
            SELECT
                @@SERVERNAME SQLInstance            
                ,SYSDATETIME() CollectionDateTime     
                ,DxS.name EventSession
                ,DxSt.target_name EventSessionType			
                ,CAST(DXst.target_data AS XML) EventSessionXML      
                ,CHECKSUM(CAST(@@SERVERNAME AS VARCHAR(255)) + DxSt.target_name + DXst.target_data) EventSessionChecksum	
                ,0 isInprogress         
            INTO
                #EventData
            FROM
                sys.dm_xe_sessions DxS
            JOIN
                sys.dm_xe_session_targets DxSt
            ON
                DxS.address = DxSt.event_session_address
            WHERE   
                DxSt.target_name 
            IN  (
                    'ring_buffer'
                    ,'histogram'
                )
            AND
                DxS.name LIKE 'SQLMonitoring_%';
            SELECT 
                SQLInstance            
                ,CollectionDateTime     
                ,EventSession
                ,EventSessionType			
                ,EventSessionXML      
                ,EventSessionChecksum 
                ,0 isInprogress 
            FROM  
                #EventData;
        "
        get-date
        $Output = 
        foreach ($Inst in $SQLList)
            {
                Invoke-DbaQuery -SqlInstance $Inst.SQLInstance -Query $SQLQuery 
            }
            get-date    
        $Output | Write-DbaDataTable -SqlInstance $TargetServerInstance -Database $TargetDatabase -Schema $TargetSchema -Table  $TargetTable -FireTriggers
        get-date
    }

FUNCTION Get-SQLMonitoringEventSessionData
    {  
        [CmdletBinding(DefaultParameterSetName = "Default")]
        param 
            (
                  [Parameter(Mandatory=$TRUE)][STRING]  $SessionName
                 ,[Parameter(Mandatory=$TRUE)][STRING]  $Inst
                 ,[Parameter(Mandatory=$TRUE)][STRING]  $FunctionName
                 ,[Parameter(Mandatory=$TRUE)][INT]     $TimeAway                 
            )        
        #$FunctionName            = (Get-PSCallStack)[0].FunctionName
        $LoopErrorVariable       = ""   
        $LoopWarningVariable     = ""           
        $ExtendedEventsOutput    =
            try 
                {
                    Get-DbaXESession -SqlInstance $Inst -Session $SessionName -ErrorVariable $LoopErrorVariable -WarningVariable $LoopWarningVariable -ErrorAction SilentlyContinue `
                    -WarningAction SilentlyContinue  | Read-DbaXEFile -ErrorVariable $LoopErrorVariable -WarningVariable $LoopWarningVariable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue `
                    | Where-Object {$_TimeStamp -ge (Get-Date).ToLocalTime().AddMinutes(-$TimeAway)}
                }
            catch 
                {
                    Write-SQLMonitoringErrors -ErrorDateTime (get-date) -FunctionName $FunctionName -Iteration "Loop Block" -ErrorVariable $LoopErrorVariable WarningVariable $LoopWarningVariable
                }
        return $ExtendedEventsOutput          
        Remove-Variable LoopErrorVariable
        Remove-Variable LoopWarningVariable
        Remove-Variable ExtendedEventsOutput
        Remove-Variable SessionName
        Remove-Variable TimeAway
    }
function write-SQLMonitoringEventSessionData 
    {
        [CmdletBinding(DefaultParameterSetName = "Default")]
        param 
            (
                 [Parameter(Mandatory=$TRUE)][STRING]  $SessionName
                ,[Parameter(Mandatory=$TRUE)][ARRAY]   $EventSessionOutput 
                ,[Parameter(Mandatory=$TRUE)][STRING]  $FunctionName
            )
        $MonitoringServerDetails = Get-MonitoringServer
        $TargetServerInstance    = $MonitoringServerDetails['ServerInstance']
        $TargetDatabase          = $MonitoringServerDetails['DatabaseName']
        $TargetSchema            = "Staging"
        $TargetTable             = $SessionName
        $WriteErrorVariable      = ""   
        $WriteWarningVariable    = ""
        try 
            {
                $EventSessionOutput| Write-DbaDataTable -SqlInstance $TargetServerInstance -Database $TargetDatabase -Schema $TargetSchema -Table $TargetTable `
                -ErrorVariable $WriteErrorVariable -WarningVariable $WriteWarningVariable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue 
            }
        catch 
            {
                Write-SQLMonitoringErrors -ErrorDateTime (get-date) -FunctionName $FunctionName -Iteration "Write Table" -ErrorVariable $WriteErrorVariable WarningVariable $WriteWarningVariable
            }
        Remove-Variable SessionName
        Remove-Variable EventSessionOutput
        Remove-Variable MonitoringServerDetails 
        Remove-Variable TargetServerInstance    
        Remove-Variable TargetDatabase          
        Remove-Variable TargetSchema            
        Remove-Variable TargetTable             
        Remove-Variable WriteErrorVariable      
        Remove-Variable WriteWarningVariable    
    }
FUNCTION write-SQLMonitoringExtendedEventsData_CompletedQueries
    {
        $EESessionName              = "SQLMonitoring_CompletedQueries"
        $SQLInstances               = (Get-SQLServerList -InstanceType PROD -InstanceRole ALL).SQLInstance
        $FunctionName               = (Get-PSCallStack)[0].FunctionName
        $EEOutput                   = 
        foreach ($Inst in $SQLInstances)
            {
                Get-SQLMonitoringEventSessionData -SessionName $EESessionName -Inst $Inst -TimeAway 10 -FunctionName $FunctionName | `
                Select-Object @{N='EventName';E={$_.name}},@{N='DateTimestamp';E={$_.timestamp}},@{N='CollectSystemTime';E={$_.collect_system_time}},@{N='SQLInstance';E={$Inst}} `
                ,@{N='ImportDateTime';E={get-date}},@{N='SessionID';E={$_.session_id}},@{N='DatabaseName';E={$_.database_name}},@{N='ClientAppName';E={$_.client_app_name}} `
                ,@{N='ClientHostname';E={$_.client_hostname}},@{N='UnmatchedDatabaseName';E={$_.unmatched_database_name}},@{N='UnmatchedIndexName';E={$_.unmatched_index_name}} `
                ,@{N='UnmatchedSchemaName';E={$_.unmatched_schema_name}},@{N='UnmatchedTableName';E={$_.unmatched_table_name}},@{N='Username';E={$_.username}},@{N='CompileTime';E={$_.compile_time}} `
                ,@{N='SignalDuration';E={$_.signal_duration}},@{N='CpuTime';E={$_.cpu_time}},@{N='TaskTime';E={$_.task_time}},@{N='Dop';E={$_.dop}},@{N='Duration';E={$_.duration}} `
                ,@{N='WorktablePhysicalReads';E={$_.worktable_physical_reads}},@{N='WorktablePhysicalWrites';E={$_.worktable_physical_writes}},@{N='PhysicalReads';E={$_.physical_reads}} `
                ,@{N='LogicalReads';E={$_.logical_reads}},@{N='Writes';E={$_.writes}},@{N='GrantedMemoryKb';E={$_.granted_memory_kb}},@{N='UsedMemoryKb';E={$_.used_memory_kb}} `
                ,@{N='ActualRowCount';E={$_.actual_row_count}},@{N='LastRowCount';E={$_.last_row_count}},@{N='LineNumber';E={$_.line_number}},@{N='Offset';E={$_.offset}} `
                ,@{N='OffsetEnd';E={$_.offset_end}},@{N='Opcode';E={$_.opcode}},@{N='OptimizerTimeoutTaskNumber';E={$_.optimizer_timeout_task_number}} `
                ,@{N='ParameterizedPlanHandle';E={$_.parameterized_plan_handle}},@{N='PlanHandle';E={$_.plan_handle}},@{N='QueryHash';E={$_.query_hash}} `
                ,@{N='QueryPlanHash';E={$_.query_plan_hash}},@{N='RequestID';E={$_.request_id}},@{N='ThreadID';E={$_.thread_id}},@{N='QueryOperationNodeID';E={$_.query_operation_node_id}} `
                ,@{N='Result';E={$_.result}},@{N='RowCountNumber';E={$_.row_count}} ,@{N='SortWarningType';E={$_.sort_warning_type}},@{N='ConvertIssue';E={$_.convert_issue}},@{N='SQLText';E={$_.sql_text}} `
                ,@{N='SQLStatement';E={$_.statement}},@{N='BatchText';E={$_.batch_text}},@{N='Expression';E={$_.expression}},@{N='TimeoutType';E={$_.timeout_type}},@{N='WaitResource';E={$_.wait_resource}} `
                ,@{N='WaitType';E={$_.wait_type}},@{N='AttachActivityID';E={$_.attach_activity_id}},@{N='AttachActivityIDXfer';E={$_.attach_activity_id_xfer}},@{N='isInProgress';E={0}}
            }
        write-SQLMonitoringEventSessionData -SessionName $EESessionName -EventSessionOutput $EEOutput -FunctionName $FunctionName
        Remove-Variable EESessionName
        Remove-Variable SQLInstances
        Remove-Variable FunctionName               
        Remove-Variable EEOutput                   
    }  
FUNCTION write-SQLMonitoringExtendedEventsData_CorruptionAndConsistency
    {
        $EESessionName              = "SQLMonitoring_CorruptionAndConsistency"
        $SQLInstances               = (Get-SQLServerList -InstanceType PROD -InstanceRole ALL).SQLInstance
        $FunctionName               = (Get-PSCallStack)[0].FunctionName
        $EEOutput                   = 
        foreach ($Inst in $SQLInstances)
            {
                Get-SQLMonitoringEventSessionData -SessionName $EESessionName -Inst $Inst -TimeAway 10 -FunctionName $FunctionName | `
                Select-Object @{N='EventName';E={$_.name}},@{N='DateTimestamp';E={$_.timestamp}},@{N='CollectSystemTime';E={$_.collect_system_time}},@{N='SQLInstance';E={$Inst}},@{N='ImportDateTime';E={get-date}} `
                ,@{N='SessionID';E={$_.session_id}},@{N='DatabaseName';E={$_.database_name}},@{N='ClientAppName';E={$_.client_app_name}},@{N='ClientHostname';E={$_.client_hostname}},@{N='Username';E={$_.username}} `
                ,@{N='TaskTime';E={$_.task_time}},@{N='Category';E={$_.category}},@{N='Destination';E={$_.destination}},@{N='ErrorNumber';E={$_.error_number}},@{N='IsIntercepted';E={$_.is_intercepted}},@{N='Message';E={$_.message}} `
                ,@{N='PlanHandle';E={$_.plan_handle}},@{N='QueryHash';E={$_.query_hash}},@{N='Severity';E={$_.severity}},@{N='SqlText';E={$_.sql_text}},@{N='State';E={$_.state}},@{N='UserDefined';E={$_.user_defined}} `
                ,@{N='AttachActivityID';E={$_.attach_activity_id}},@{N='AttachActivityIDXfer';E={$_.attach_activity_id_xfer}},@{N='isInProgress';E={0}}
            }
        write-SQLMonitoringEventSessionData -SessionName $EESessionName -EventSessionOutput $EEOutput -FunctionName $FunctionName
        Remove-Variable EESessionName
        Remove-Variable SQLInstances
        Remove-Variable FunctionName               
        Remove-Variable EEOutput                   
    }
FUNCTION write-SQLMonitoringExtendedEventsData_Locking
    {
        $EESessionName              = "SQLMonitoring_Locking"
        $SQLInstances               = (Get-SQLServerList -InstanceType PROD -InstanceRole ALL).SQLInstance
        $FunctionName               = (Get-PSCallStack)[0].FunctionName
        $EEOutput                   = 
        foreach ($Inst in $SQLInstances)
            {
                Get-SQLMonitoringEventSessionData -SessionName $EESessionName -Inst $Inst -TimeAway 10 -FunctionName $FunctionName | `
                Select-Object  @{N='EventName';E={$_.name}},@{N='DateTimestamp';E={$_.timestamp}},@{N='CollectSystemTime';E={$_.collect_system_time}},@{N='SQLInstance';E={$Inst.SQLInstance}},@{N='ImportDateTime';E={get-date}} `
                ,@{N='SessionID';E={$_.session_id}},@{N='TransactionID';E={$_.transaction_id}},@{N='DatabaseName';E={$_.database_name}},@{N='DatabaseID';E={$_.database_id}},@{N='ObjectID';E={$_.object_id}},@{N='HobtID';E={$_.hobt_id}} `
                ,@{N='ClientAppName';E={$_.client_app_name}},@{N='ClientHostname';E={$_.client_hostname}},@{N='Username';E={$_.username}},@{N='TaskTime';E={$_.task_time}},@{N='Increment';E={$_.increment}},@{N='LockType';E={$_.lock_type}} `
                ,@{N='LockspaceNestID';E={$_.lockspace_nest_id}},@{N='LockspaceSubID';E={$_.lockspace_sub_id}},@{N='LockspaceWorkspaceID';E={$_.lockspace_workspace_id}},@{N='Mode';E={$_.mode}},@{N='Count';E={$_.count}} `
                ,@{N='EscalatedLockCount';E={$_.escalated_lock_count}},@{N='EscalationCause';E={$_.escalation_cause}},@{N='HobtLockCount';E={$_.hobt_lock_count}},@{N='OwnerType';E={$_.owner_type}},@{N='PlanHandle';E={$_.plan_handle}} `
                ,@{N='QueryHash';E={$_.query_hash}},@{N='Resource0';E={$_.resource_0}},@{N='Resource1';E={$_.resource_1}},@{N='Resource2';E={$_.resource_2}},@{N='ResourceType';E={$_.resource_type}},@{N='SqlText';E={$_.sql_text}} `
                ,@{N='Statement';E={$_.statement}},@{N='AttachActivityID';E={$_.attach_activity_id}},@{N='AttachActivityIDXfer';E={$_.attach_activity_id_xfer}},@{N='isInProgress';E={0}}
            }
        write-SQLMonitoringEventSessionData -SessionName $EESessionName -EventSessionOutput $EEOutput -FunctionName $FunctionName
        Remove-Variable EESessionName
        Remove-Variable SQLInstances
        Remove-Variable FunctionName               
        Remove-Variable EEOutput                   
    }    

FUNCTION write-SQLMonitoringExtendedEventsData_ObjectModifications
    {
        $EESessionName              = "SQLMonitoring_ObjectModifications"
        $SQLInstances               = (Get-SQLServerList -InstanceType PROD -InstanceRole ALL).SQLInstance
        $FunctionName               = (Get-PSCallStack)[0].FunctionName
        $EEOutput                   = 
        foreach ($Inst in $SQLInstances)
            {
                Get-SQLMonitoringEventSessionData -SessionName $EESessionName -Inst $Inst -TimeAway 10 -FunctionName $FunctionName | `
                Select-Object  @{N='EventName';E={$_.name}},@{N='DateTimestamp';E={$_.timestamp}},@{N='CollectSystemTime';E={$_.collect_system_time}},@{N='SQLInstance';E={$Inst.SQLInstance}},@{N='ImportDateTime';E={get-date}} `
                ,@{N='SessionID';E={$_.session_id}},@{N='TransactionID';E={$_.transaction_id}},@{N='DatabaseID';E={$_.database_id}},@{N='DatabaseName';E={$_.database_name}},@{N='ClientAppName';E={$_.client_app_name}} `
                ,@{N='ClientHostname';E={$_.client_hostname}},@{N='Username';E={$_.username}},@{N='TaskTime';E={$_.task_time}},@{N='DdlPhase';E={$_.ddl_phase}},@{N='IndexID';E={$_.index_id}},@{N='ObjectID';E={$_.object_id}} `
                ,@{N='ObjectName';E={$_.object_name}},@{N='ObjectType';E={$_.object_type}},@{N='RelatedObjectID';E={$_.related_object_id}},@{N='SqlText';E={$_.sql_text}},@{N='AttachActivityID';E={$_.attach_activity_id}} `
                ,@{N='AttachActivityIDXfer';E={$_.attach_activity_id_xfer}},@{N='isInProgress';E={0}}
            }
        write-SQLMonitoringEventSessionData -SessionName $EESessionName -EventSessionOutput $EEOutput -FunctionName $FunctionName
        Remove-Variable EESessionName
        Remove-Variable SQLInstances
        Remove-Variable FunctionName               
        Remove-Variable EEOutput                   
    }    

FUNCTION write-SQLMonitoringExtendedEventsData_PageSplits
    {
        $EESessionName              = "SQLMonitoring_PageSplits"
        $SQLInstances               = (Get-SQLServerList -InstanceType PROD -InstanceRole ALL).SQLInstance
        $FunctionName               = (Get-PSCallStack)[0].FunctionName
        $EEOutput                   = 
        foreach ($Inst in $SQLInstances)
            {
                Get-SQLMonitoringEventSessionData -SessionName $EESessionName -Inst $Inst -TimeAway 10 -FunctionName $FunctionName | `
                Select-Object  @{N='EventName';E={$_.name}},@{N='DateTimestamp';E={$_.timestamp}},@{N='CollectSystemTime';E={$_.collect_system_time}},@{N='SQLInstance';E={$Inst.SQLInstance}},@{N='ImportDateTime';E={get-date}} `
                ,@{N='SessionID';E={$_.session_id}},@{N='TransactionID';E={$_.transaction_id}},@{N='DatabaseID';E={$_.database_id}},@{N='ClientAppName';E={$_.client_app_name}},@{N='ClientHostname';E={$_.client_hostname}} `
                ,@{N='FileID';E={$_.file_id}},@{N='NewPageFileID';E={$_.new_page_file_id}},@{N='NewPagePageID';E={$_.new_page_page_id}},@{N='PageID';E={$_.page_id}},@{N='RowsetID';E={$_.rowset_id}} `
                ,@{N='Splitoperation';E={$_.splitOperation}},@{N='SqlText';E={$_.sql_text}},@{N='AttachActivityID';E={$_.attach_activity_id}},@{N='AttachActivityIDXfer';E={$_.attach_activity_id_xfer}},@{N='isInProgress';E={0}}
            }
        write-SQLMonitoringEventSessionData -SessionName $EESessionName -EventSessionOutput $EEOutput -FunctionName $FunctionName
        Remove-Variable EESessionName
        Remove-Variable SQLInstances
        Remove-Variable FunctionName               
        Remove-Variable EEOutput                   
    }    

FUNCTION write-SQLMonitoringExtendedEventsData_PerfmonCounters
    {
        $EESessionName              = "SQLMonitoring_PerfmonCounters"
        $SQLInstances               = (Get-SQLServerList -InstanceType PROD -InstanceRole ALL).SQLInstance
        $FunctionName               = (Get-PSCallStack)[0].FunctionName
        $EEOutput                   = 
        foreach ($Inst in $SQLInstances)
            {
                Get-SQLMonitoringEventSessionData -SessionName $EESessionName -Inst $Inst -TimeAway 10 -FunctionName $FunctionName | `
                Select-Object  @{N='EventName';E={$_.name}},@{N='DateTimestamp';E={$_.timestamp}},@{N='CollectSystemTime';E={$_.collect_system_time}},@{N='SQLInstance';E={$Inst.SQLInstance}},@{N='ImportDateTime';E={get-date}} `
                ,@{N='InstanceName';E={$_.instance_name}},@{N='AlignmentFixupsPerSecond';E={$_.alignment_fixups_per_second}},@{N='AverageDiskBytesPerRead';E={$_.average_disk_bytes_per_read}} `
                ,@{N='AverageDiskBytesPerTransfer';E={$_.average_disk_bytes_per_transfer}},@{N='AverageDiskBytesPerWrite';E={$_.average_disk_bytes_per_write}},@{N='AverageDiskQueueLength';E={$_.average_disk_queue_length}} `
                ,@{N='AverageDiskReadQueueLength';E={$_.average_disk_read_queue_length}},@{N='AverageDiskSecondsPerRead';E={$_.average_disk_seconds_per_read}},@{N='AverageDiskSecondsPerTransfer';E={$_.average_disk_seconds_per_transfer}} `
                ,@{N='AverageDiskSecondsPerWrite';E={$_.average_disk_seconds_per_write}},@{N='AverageDiskWriteQueueLength';E={$_.average_disk_write_queue_length}},@{N='C1TransitionsPerSecond';E={$_.c1_transitions_per_second}} `
                ,@{N='C2TransitionsPerSecond';E={$_.c2_transitions_per_second}},@{N='C3TransitionsPerSecond';E={$_.c3_transitions_per_second}},@{N='ContextSwitchesPerSecond';E={$_.context_switches_per_second}} `
                ,@{N='CurrentDiskQueueLength';E={$_.current_disk_queue_length}},@{N='DiskBytesPerSecond';E={$_.disk_bytes_per_second}},@{N='DiskReadBytesPerSecond';E={$_.disk_read_bytes_per_second}} `
                ,@{N='DiskReadsPerSecond';E={$_.disk_reads_per_second}},@{N='DiskTransfersPerSecond';E={$_.disk_transfers_per_second}},@{N='DiskWriteBytesPerSecond';E={$_.disk_write_bytes_per_second}} `
                ,@{N='DiskWritesPerSecond';E={$_.disk_writes_per_second}},@{N='DpcRate';E={$_.dpc_rate}},@{N='DpcsQueuedPerSecond';E={$_.dpcs_queued_per_second}},@{N='ExceptionDispatchesPerSecond';E={$_.exception_dispatches_per_second}} `
                ,@{N='FileControlBytesPerSecond';E={$_.file_control_bytes_per_second}},@{N='FileControlOperationsPerSecond';E={$_.file_control_operations_per_second}},@{N='FileDataOperationsPerSecond';E={$_.file_data_operations_per_second}} `
                ,@{N='FileReadBytesPerSecond';E={$_.file_read_bytes_per_second}},@{N='FileReadOperationsPerSecond';E={$_.file_read_operations_per_second}},@{N='FileWriteBytesPerSecond';E={$_.file_write_bytes_per_second}} `
                ,@{N='FileWriteOperationsPerSecond';E={$_.file_write_operations_per_second}},@{N='FloatingEmulationsPerSecond';E={$_.floating_emulations_per_second}},@{N='FreeMegabytes';E={$_.free_megabytes}} `
                ,@{N='InterruptsPerSecond';E={$_.interrupts_per_second}},@{N='ParkingStatus';E={$_.parking_status}},@{N='PercentC1Time';E={$_.percent_c1_time}},@{N='PercentC2Time';E={$_.percent_c2_time}} `
                ,@{N='PercentC3Time';E={$_.percent_c3_time}},@{N='PercentDiskReadTime';E={$_.percent_disk_read_time}},@{N='PercentDiskTime';E={$_.percent_disk_time}},@{N='PercentDiskWriteTime';E={$_.percent_disk_write_time}} `
                ,@{N='PercentDpcTime';E={$_.percent_dpc_time}},@{N='PercentFreeSpace';E={$_.percent_free_space}},@{N='PercentIdleTime';E={$_.percent_idle_time}},@{N='PercentInterruptTime';E={$_.percent_interrupt_time}} `
                ,@{N='PercentMaximumFrequency';E={$_.percent_maximum_frequency}},@{N='PercentPriorityTime';E={$_.percent_priority_time}},@{N='PercentPrivilegedTime';E={$_.percent_privileged_time}} `
                ,@{N='PercentProcessorTime';E={$_.percent_processor_time}},@{N='PercentRegistryQuotaInUse';E={$_.percent_registry_quota_in_use}},@{N='PercentUserTime';E={$_.percent_user_time}},@{N='Processes';E={$_.processes}} `
                ,@{N='ProcessorFrequency';E={$_.processor_frequency}},@{N='ProcessorQueueLength';E={$_.processor_queue_length}},@{N='ProcessorStateFlags';E={$_.processor_state_flags}},@{N='SplitIoPerSecond';E={$_.split_io_per_second}} `
                ,@{N='SystemCallsPerSecond';E={$_.system_calls_per_second}},@{N='SystemUpTime';E={$_.system_up_time}},@{N='Threads';E={$_.threads}},@{N='VirtualBytes';E={$_.virtual_bytes}},@{N='VirtualBytesPeak';E={$_.virtual_bytes_peak}} `
                ,@{N='WorkingSet';E={$_.working_set}},@{N='WorkingSetPeak';E={$_.working_set_peak}},@{N='WorkingSetPrivate';E={$_.working_set_private}},@{N='AttachActivityID';E={$_.attach_activity_id}} `
                ,@{N='AttachActivityIDXfer';E={$_.attach_activity_id_xfer}},@{N='isInProgress';E={0}}

            }
        write-SQLMonitoringEventSessionData -SessionName $EESessionName -EventSessionOutput $EEOutput -FunctionName $FunctionName
        Remove-Variable EESessionName
        Remove-Variable SQLInstances
        Remove-Variable FunctionName               
        Remove-Variable EEOutput                   
    }    
