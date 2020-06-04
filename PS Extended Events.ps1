clear-host
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