SET NOCOUNT ON
IF OBJECT_ID('TempDB..#TempResults','U') IS NOT NULL DROP TABLE #TempResults;
CREATE TABLE #TempResults
	(
		 TempResultsID		INT IDENTITY(1,1)	 NOT NULL 
		,SQLText			VARCHAR(MAX)					NULL
		,EventName			NVARCHAR(255)		 NULL
	)
DECLARE @FileName		NVARCHAR(255)
DECLARE @object_name	NVARCHAR(255)
DECLARE @OuterCounter	 INT = 1;
DECLARE @InnerCounter	 INT = 1;
DECLARE @OuterIterations INT = 0;
DECLARE @InnerIterations INT = 0;
DECLARE @SQLToRun			NVARCHAR(MAX) = N''
DECLARE @OverallSQL			NVARCHAR(MAX) = N'
DECLARE @SQL				NVARCHAR(MAX) = N'''';
DECLARE @FileName			NVARCHAR(255) = N''?''
DECLARE @object_name		NVARCHAR(255) = N''!''
DECLARE @SQLCols			NVARCHAR(MAX) = N''''
DECLARE @OutputSQLCols		NVARCHAR(MAX) = N''''
;WITH Cte AS
       (
             SELECT ''callstack''                                     ActionName, ''VARCHAR(255)''       DataType, ''CallStack''                                        ColumnName UNION
             SELECT ''client_app_name''                        ActionName, ''VARCHAR(255)''       DataType, ''ClientAppName''                             ColumnName UNION
             SELECT ''client_connection_id''                   ActionName, ''VARCHAR(255)''       DataType, ''ClientconnectionID''                     ColumnName UNION
             SELECT ''client_hostname''                        ActionName, ''VARCHAR(255)''       DataType, ''Clienthostname''                            ColumnName UNION
             SELECT ''client_pid''                                    ActionName, ''VARCHAR(255)''       DataType, ''Clientpid''                                        ColumnName UNION
             SELECT ''collect_cpu_cycle_time''                 ActionName, ''BIGINT''        DataType, ''CollectCpuCycleTime''                          ColumnName UNION
             SELECT ''collect_system_time''                    ActionName, ''DATETIME2''           DataType, ''CollectSystemTime''                      ColumnName UNION
             SELECT ''database_id''                            ActionName, ''BIGINT''        DataType, ''DatabaseID''                                       ColumnName UNION
             SELECT ''database_name''                                ActionName, ''VARCHAR(255)''      DataType, ''DatabaseName''                                 ColumnName UNION
             SELECT ''is_system''                                     ActionName, ''VARCHAR(255)''       DataType, ''isSystem''                                  ColumnName UNION
             SELECT ''nt_username''                            ActionName, ''VARCHAR(255)''       DataType, ''ntUsername''                                       ColumnName UNION
             SELECT ''plan_handle''                            ActionName, ''VARCHAR(MAX)'' DataType, ''planHandle''                                       ColumnName UNION
             SELECT ''query_hash''                                    ActionName, ''VARCHAR(255)''           DataType, ''queryHash''                                        ColumnName UNION
             SELECT ''query_plan_hash''                        ActionName, ''BINARY(8)''           DataType, ''queryPlanHash''                             ColumnName UNION
             SELECT ''server_instance_name''                   ActionName, ''VARCHAR(255)''       DataType, ''ServerInstanceName''                     ColumnName UNION
             SELECT ''server_principal_name''                  ActionName, ''VARCHAR(255)''       DataType, ''ServerPrincipalName''                          ColumnName UNION
             SELECT ''server_principal_sid''                   ActionName, ''VARCHAR(255)''       DataType, ''ServerPrincipalSid''                     ColumnName UNION
             SELECT ''session_id''                                    ActionName, ''INT''                 DataType, ''SessionID''                                        ColumnName UNION
             SELECT ''session_nt_username''                    ActionName, ''VARCHAR(255)''       DataType, ''SessionntUsername''                      ColumnName UNION
             SELECT ''session_server_principal_name''  ActionName, ''VARCHAR(255)''       DataType, ''SessionServerPrincipalName''      ColumnName UNION
             SELECT ''sql_text''                                      ActionName, ''VARCHAR(MAX)''       DataType, ''SqlText''                                       ColumnName UNION
             SELECT ''task_elapsed_quantum''                   ActionName, ''INT''                 DataType, ''TaskElapsedQuantum''                  ColumnName UNION
'SELECT @OverallSQL += N'             SELECT ''task_time''                                     ActionName, ''BIGINT''        DataType, ''TaskTime''                                  ColumnName UNION
             SELECT ''transaction_id''                               ActionName, ''INT''                 DataType, ''TransactionId''                                ColumnName UNION
             SELECT ''tsql_stack''                                    ActionName, ''VARCHAR(255)''       DataType, ''TSQLStack''                                        ColumnName UNION
             SELECT ''username''                                      ActionName, ''VARCHAR(255)''       DataType, ''Username''                                  ColumnName 
       )
,	OutputCte AS
	(
			SELECT
				 QUOTENAME(ISNULL(ActionName,''PLACEHOLDER''),''['') ColName
			FROM 
			   sys.server_event_session_actions es
			JOIN
				   sys.server_event_sessions SES
			ON
				   es.event_session_id = SES.event_session_id
			LEFT JOIN
				   Cte
			ON
				   es.name = Cte.ActionName
			WHERE 
				   SES.name = @object_name
			UNION
			--QUOTENAME(ISNULL(ColumnName,''PLACEHOLDER''),''['')

			SELECT
				QUOTENAME(ISNULL(cols.name,'''') ,''['')
			FROM
				   sys.dm_xe_object_columns cols
			WHERE
				cols.object_name = @FileName
			AND
				   cols.column_type IN(''data'',''customizable'')
	)
SELECT
	@SQLCols       +=  CHAR(10) + ''			,'' + ColName
--	,@OutputSQLCols +=  CHAR(10) + ''			,'' + ColName

FROM
	OutputCte
SELECT @SQLCols = RIGHT(@SQLCols,LEN(@SQLCols)-5);
--SELECT @SQLCols 
'SELECT @OverallSQL += N'
;WITH Cte AS
       (
             SELECT ''callstack''                                     ActionName, ''VARCHAR(255)''       DataType, ''CallStack''                                        ColumnName UNION
             SELECT ''client_app_name''                        ActionName, ''VARCHAR(255)''       DataType, ''ClientAppName''                             ColumnName UNION
             SELECT ''client_connection_id''                   ActionName, ''VARCHAR(255)''       DataType, ''ClientconnectionID''                     ColumnName UNION
             SELECT ''client_hostname''                        ActionName, ''VARCHAR(255)''       DataType, ''Clienthostname''                            ColumnName UNION
             SELECT ''client_pid''                                    ActionName, ''VARCHAR(255)''       DataType, ''Clientpid''                                        ColumnName UNION
             SELECT ''collect_cpu_cycle_time''                 ActionName, ''BIGINT''        DataType, ''CollectCpuCycleTime''                          ColumnName UNION
             SELECT ''collect_system_time''                    ActionName, ''DATETIME2''           DataType, ''CollectSystemTime''                      ColumnName UNION
             SELECT ''database_id''                            ActionName, ''BIGINT''        DataType, ''DatabaseID''                                       ColumnName UNION
             SELECT ''database_name''                                ActionName, ''VARCHAR(255)''      DataType, ''DatabaseName''                                 ColumnName UNION
             SELECT ''is_system''                                     ActionName, ''VARCHAR(255)''       DataType, ''isSystem''                                  ColumnName UNION
             SELECT ''nt_username''                            ActionName, ''VARCHAR(255)''       DataType, ''ntUsername''                                       ColumnName UNION
             SELECT ''plan_handle''                            ActionName, ''VARCHAR(MAX)'' DataType, ''planHandle''                                       ColumnName UNION
             SELECT ''query_hash''                                    ActionName, ''VARCHAR(255)''           DataType, ''queryHash''                                        ColumnName UNION
             SELECT ''query_plan_hash''                        ActionName, ''BINARY(8)''           DataType, ''queryPlanHash''                             ColumnName UNION
             SELECT ''server_instance_name''                   ActionName, ''VARCHAR(255)''       DataType, ''ServerInstanceName''                     ColumnName UNION
             SELECT ''server_principal_name''                  ActionName, ''VARCHAR(255)''       DataType, ''ServerPrincipalName''                          ColumnName UNION
             SELECT ''server_principal_sid''                   ActionName, ''VARCHAR(255)''       DataType, ''ServerPrincipalSid''                     ColumnName UNION
             SELECT ''session_id''                                    ActionName, ''INT''                 DataType, ''SessionID''                                        ColumnName UNION
             SELECT ''session_nt_username''                    ActionName, ''VARCHAR(255)''       DataType, ''SessionntUsername''                      ColumnName UNION
             SELECT ''session_server_principal_name''  ActionName, ''VARCHAR(255)''       DataType, ''SessionServerPrincipalName''      ColumnName UNION
             SELECT ''sql_text''                                      ActionName, ''VARCHAR(MAX)''       DataType, ''SqlText''                                       ColumnName UNION
             SELECT ''task_elapsed_quantum''                   ActionName, ''INT''                 DataType, ''TaskElapsedQuantum''                  ColumnName UNION
'SELECT @OverallSQL += N'             SELECT ''task_time''                                     ActionName, ''BIGINT''        DataType, ''TaskTime''                                  ColumnName UNION
             SELECT ''transaction_id''                               ActionName, ''INT''                 DataType, ''TransactionId''                                ColumnName UNION
             SELECT ''tsql_stack''                                    ActionName, ''VARCHAR(255)''       DataType, ''TSQLStack''                                        ColumnName UNION
             SELECT ''username''                                      ActionName, ''VARCHAR(255)''       DataType, ''Username''                                  ColumnName 
       )
SELECT
     @OutputSQLCols +=   ''
	 ,TRY_CONVERT( '' + ISNULL(Cte.DataType,''PLACEHOLDER'') + '', '' + Cte.ActionName + '')'' + QUOTENAME(ISNULL(ColumnName,''PLACEHOLDER''),''['')
FROM 
   sys.server_event_session_actions es
JOIN
       sys.server_event_sessions SES
ON
       es.event_session_id = SES.event_session_id
LEFT JOIN
       Cte
ON
       es.name = Cte.ActionName
WHERE 
       SES.name = @object_name
GROUP BY
	''
	 ,TRY_CONVERT( '' + ISNULL(Cte.DataType,''PLACEHOLDER'') + '', '' + Cte.ActionName + '')'' + QUOTENAME(ISNULL(ColumnName,''PLACEHOLDER''),''['')
SELECT @SQL = CASE WHEN @SQL  IS NULL THEN N'''' ELSE @SQL END;

SELECT
		@OutputSQLCols +=
		''
	,TRY_CONVERT('' + CASE cols.type_name
  --These mappings should be safe.
  --They correspond almost directly to each other.
  WHEN ''ansi_string'' THEN ''VARCHAR(MAX)''
  WHEN ''binary_data'' THEN ''VARBINARY(MAX)''
  WHEN ''boolean'' THEN ''BIT''
  WHEN ''char'' THEN ''VARCHAR(MAX)''
  WHEN ''guid'' THEN ''UNIQUEIDENTIFIER''
  WHEN ''int16'' THEN ''SMALLINT''
  WHEN ''int32'' THEN ''INT''
  WHEN ''int64'' THEN ''BIGINT''
  WHEN ''int8'' THEN ''SMALLINT''
  WHEN ''uint16'' THEN ''INT''
  WHEN ''uint32'' THEN ''BIGINT''
  WHEN ''uint64'' THEN ''BIGINT'' --possible overflow?
  WHEN ''uint8'' THEN ''SMALLINT''
  WHEN ''unicode_string'' THEN ''NVARCHAR(MAX)''
  WHEN ''xml'' THEN ''XML''

  --These mappings are based off of descriptions and type_size.
  WHEN ''cpu_cycle'' THEN ''BIGINT''
  WHEN ''filetime'' THEN ''BIGINT''
  WHEN ''wchar'' THEN ''NVARCHAR(2)''

  --How many places of precision?
  WHEN ''float32'' THEN ''NUMERIC(30, 4)''
  WHEN ''float64'' THEN ''NUMERIC(30, 4)''

  --These mappings? Not sure. Default to NVARCHAR(MAX).
  WHEN ''activity_id'' THEN ''NVARCHAR(MAX)''
  WHEN ''activity_id_xfer'' THEN ''NVARCHAR(MAX)''
  WHEN ''ansi_string_ptr'' THEN ''NVARCHAR(MAX)''
  WHEN ''callstack'' THEN ''NVARCHAR(MAX)''
  WHEN ''guid_ptr'' THEN ''NVARCHAR(MAX)''
  WHEN ''null'' THEN ''NVARCHAR(MAX)''
  WHEN ''ptr'' THEN ''NVARCHAR(MAX)''
  WHEN ''unicode_string_ptr'' THEN ''NVARCHAR(MAX)''
  ELSE ''VARCHAR(999)''
END + '', '' + cols.name + '')''  +  QUOTENAME(ISNULL(cols.name,'''') ,''['')

FROM
       sys.dm_xe_object_columns cols
WHERE
	cols.object_name = @FileName
AND
       cols.column_type IN(''data'',''customizable'')
SELECT @OutputSQLCols = CASE WHEN @OutputSQLCols  IS NULL THEN N'''' ELSE @OutputSQLCols END;
SELECT
	@SQL = ''
,	OutputCte AS
	(
		SELECT
		OuterRowNum
			,''''?'''' EventName
			,SQLInstance
			,EventCheckSum
,'' + @SQLCols + ''
	,[attach_activity_id_xfer]
	,[attach_activity_id]	
		FROM
		
			(
				SELECT
					EventName
				   ,SQLInstance
				   ,EventCheckSum
				   ,VarcharValue
				   ,OuterRowNum
				FROM
					PrePivotCte 
			)Dt
		PIVOT
			(
				MAX(VarcharValue)
			FOR 
				EventName IN (''+ @SQLCols + ''
	,[attach_activity_id_Xfer]
	,[attach_activity_id]				
				)
			)PIVOTTABLE
	)	
SELECT 
	 [collect_system_time]
	,DATEADD(HOUR,DATEDIFF(HOUR,GETUTCDATE(),GETDATE()),[collect_system_time]) AS CollectDateTime
	,EventName 
	,SQLInstance
	,EventCheckSum
''+ @OutputSQLCols +''
	,[attach_activity_id_xfer]
	,[attach_activity_id]
	
FROM
	 OutputCte;
BEGIN TRAN
	UPDATE LP
	SET
		 LP.LastProcessedDateTime = SYSDATETIME()	
		,LP.EventSessionChecksum  = ED.EventSessionChecksum	
		,LP.EventCheckSum		  = ED.EventCheckSum	
	FROM
		ExtendedEvents.LastProcessed LP	
	JOIN
		#EventData ED
	ON
		LP.SQLInstance = ED.SQLInstance
	AND
		LP.EventSession	= ED.EventSession
	AND
		LP.EventSessionType	= ED.EventSessionType;

	INSERT INTO ExtendedEvents.LastProcessed
		(
			 SQLInstance            
			,EventSession	
			,EventName		
			,LastProcessedDateTime  
			,EventSessionChecksum  
			,EventCheckSum	
			,EventSessionType	  
		)
	SELECT
		 ED.SQLInstance            
		,ED.EventSession			
		,ED.EventName
		,SYSDATETIME() LastProcessedDateTime  
		,ED.EventSessionChecksum  
		,ED.EventCheckSum		  
		,ED.EventSessionType
	FROM
		#EventData ED
	LEFT JOIN
		ExtendedEvents.LastProcessed LP	
	ON
		ED.SQLInstance			 = LP.SQLInstance
	AND
		ED.EventSession			 = LP.EventSession
	WHERE
		LP.LastProcessedID IS NULL

	DELETE EQ
	FROM
		ExtendedEvents.AsyncEventQueue EQ
	JOIN
		#EventData ED
	ON
		EQ.AsyncEventQueueID = ED.AsyncEventQueueID
	AND
		isInprogress = 1;

COMMIT
''
SELECT @SQL 
'


SELECT @OuterIterations = COUNT(*) FROM sys.dm_xe_sessions s JOIN sys.dm_xe_session_events e ON s.address = e.event_session_address WHERE s.name LIKE 'SQLMonitoring_%';

WHILE @OuterIterations>= @OuterCounter 
	BEGIN
		;WITH Cte AS
			(
				SELECT
					 e.event_name
					,s.name
					,ROW_NUMBER()OVER(ORDER BY s.name,e.event_name) RowNum
				FROM 
					sys.dm_xe_sessions s
				JOIN
					sys.dm_xe_session_events e
				ON
					s.address = e.event_session_address
				WHERE
					s.name LIKE 'SQLMonitoring_%'
			)
		SELECT 
			@SQLToRun			 = REPLACE(REPLACE(@OverallSQL,'!',Cte.name),'?',Cte.event_name)
		FROM
			Cte
		WHERE
			Cte.RowNum = @OuterCounter;
		INSERT INTO #TempResults
			(
			SQLText
			)
		EXEC sys.sp_executesql @SQLToRun
		;WITH Cte AS
			(
				SELECT
					 e.event_name
					,s.name
					,ROW_NUMBER()OVER(ORDER BY s.name,e.event_name) RowNum
				FROM 
					sys.dm_xe_sessions s
				JOIN
					sys.dm_xe_session_events e
				ON
					s.address = e.event_session_address
				WHERE
					s.name LIKE 'SQLMonitoring_%'
			)
		UPDATE #TempResults
		SET EventName = Cte.event_name
		FROM
			#TempResults T
		CROSS JOIN
			Cte
		WHERE
			Cte.RowNum = @OuterCounter
		AND
			T.EventName IS NULL;

		--break
		--SELECT  CAST(@SQLToRun		 AS XML)
		--SELECT @SQLToRun = N'';
		SET @OuterCounter  += 1;
	END
--*/
SET NOCOUNT ON;
GO
IF OBJECT_ID('TempDB..##ProcDefinitions','U')	IS NOT NULL DROP TABLE ##ProcDefinitions;

DECLARE @SQL			NVARCHAR(MAX) = N'';
DECLARE @CreateSQL		NVARCHAR(MAX) = N'';
DECLARE @OuterSQL		NVARCHAR(MAX) = N'';
DECLARE @SQLCols		NVARCHAR(MAX) = N'';
DECLARE @EventName		NVARCHAR(255) = N'';
DECLARE @SessionName	NVARCHAR(255) = N'';
DECLARE @Counter		INT	= 1;
DECLARE @Iterations		INT	= 1;
SELECT  @Iterations		 = COUNT(*) FROM  sys.dm_xe_sessions s JOIN sys.dm_xe_session_events e ON s.address = e.event_session_address WHERE s.name LIKE 'SQLMonitoring_%';
			CREATE TABLE ##ProcDefinitions
				(
					ProcDefinitionID		INT IDENTITY(1,1)		NOT NULL
					,SQLText					VARCHAR(MAX)			NOT NULL
				)
WHILE @Counter	<= @Iterations	
	BEGIN
IF OBJECT_ID('TempDB..##EventSessions','U')		IS NOT NULL DROP TABLE ##EventSessions;
IF OBJECT_ID('TempDB..##Session','U')			IS NOT NULL DROP TABLE ##Session;
IF OBJECT_ID('TempDB..##FinalOutput','U')		IS NOT NULL DROP TABLE ##FinalOutput;

IF OBJECT_ID('TempDB..##PivotedOutput','U')		IS NOT NULL DROP TABLE ##PivotedOutput;

		SELECT
			 @EventName		= event_name
			,@SessionName	= name
		FROM
			(
				SELECT
					 e.event_name
					,s.name
					,ROW_NUMBER()OVER(ORDER BY s.name,e.event_name) RowNum
				FROM 
					sys.dm_xe_sessions s
				JOIN
					sys.dm_xe_session_events e
				ON
					s.address = e.event_session_address
				WHERE
					s.name LIKE 'SQLMonitoring_%'
			)Dt
		WHERE
			Dt.RowNum = @Counter;

			CREATE TABLE ##EventSessions
				(
					 EventSessionID     INT IDENTITY(1,1)   NOT NULL               
					,EventData          XML                 NOT NULL
					,EventName          VARCHAR(55)         NOT NULL
				);
			INSERT INTO ##EventSessions
				(
					 EventData
					,EventName
				)
			SELECT
				 CAST(DXst.target_data AS XML) EventData
				,DxS.name
			FROM
				sys.dm_xe_sessions DxS
			JOIN
				sys.dm_xe_session_targets DxSt
			ON
				DxS.address = DxSt.event_session_address
			WHERE   
				DxS.name = @SessionName
			AND
				DxSt.target_name 
			IN  (
					 'ring_buffer'
				  --  ,'histogram'
				);

			SELECT @OuterSQL = N'
			SELECT TOP 1
				 ED.EventData.query(''/RingBufferTarget/event[@name="' + @EventName + '"]/action'')  ActionEventData
				,ED.EventData.query(''/RingBufferTarget/event[@name="' + @EventName + '"]/data'')  DataEventData
			INTO
				##Session
			FROM 
				##EventSessions ED
				CROSS APPLY EventData.nodes(''//RingBufferTarget/event[@name="' + @EventName + '"]'') AS xed(event_data)';
			EXEC sys.sp_executesql @OuterSQL;
			print @OuterSQL
			IF (SELECT TOP 1 1 FROM ##Session) IS NOT NULL
				BEGIN
					;WITH DataCte AS
						(
							SELECT 
								 ded.event_data.value('@name', 'VARCHAR(MAX)')                                                               EventName
								,ded.event_data.value('value[1]', 'VARCHAR(MAX)')   VarcharValue
								,ROW_NUMBER() OVER(ORDER BY ded.event_data) InnerRowNum
							FROM
								##Session ED
							CROSS APPLY 
								DataEventData.nodes('//data') AS ded(event_data)
						)
					, ActionCte AS
						(
							SELECT 
								 ded.event_data.value('@name', 'VARCHAR(MAX)') EventName
								,ded.event_data.value('value[1]', 'VARCHAR(MAX)')   VarcharValue
								,ROW_NUMBER() OVER(ORDER BY ded.event_data) InnerRowNum
							FROM
								##Session ED
							CROSS APPLY 
								ActionEventData.nodes('//action') AS ded(event_data)
						)
					,FinalCte AS
						(
							SELECT 
								 DataCte.EventName
								,DataCte.VarcharValue
								,DataCte.InnerRowNum 
								,ROW_NUMBER()OVER(PARTITION BY DataCte.EventName ORDER BY DataCte.InnerRowNum) OuterRowNum
								,'Data' DataSource
							FROM 
								DataCte
							UNION
							SELECT 
								ActionCte.EventName
							   ,ActionCte.VarcharValue
							   ,ActionCte.InnerRowNum 
								,ROW_NUMBER()OVER(PARTITION BY ActionCte.EventName ORDER BY ActionCte.InnerRowNum) OuterRowNum
								,'Action' DataSource
							FROM 
								ActionCte
						)
					SELECT 
						FinalCte.EventName
					   ,FinalCte.VarcharValue
					   ,FinalCte.OuterRowNum
					   ,ROW_NUMBER()OVER(PARTITION BY  FinalCte.OuterRowNum ORDER BY FinalCte.DataSource, FinalCte.InnerRowNum)FinalRowNum
					INTO
						##FinalOutput
					FROM  
						FinalCte
					ORDER BY
						FinalCte.OuterRowNum
						,FinalRowNum;
					SELECT
						@SQLCols += + CHAR(10) + '			,' + QUOTENAME(EventName,'[')
					FROM
						(
							SELECT
								 EventName
								,MAX(FinalRowNum) SortColumn
							FROM  
								##FinalOutput
							GROUP BY
								EventName
						)Dt
					GROUP BY
						 + CHAR(10) + '			,' + QUOTENAME(EventName,'[')
					ORDER BY	
						MAX(SortColumn);
					SELECT
						@SQL = N'
					SELECT
						''' + @EventName + ''' EventName
						,*
					INTO
						##PivotedOutput
					FROM

						(
							SELECT
								EventName
							   ,VarcharValue
							   ,OuterRowNum
							FROM
								##FinalOutput
						)Dt
					PIVOT
						(
							MAX(VarcharValue)
						FOR 
							EventName IN (' + RIGHT(@SQLCols,LEN(@SQLCols)-5) + ')
						)PIVOTTABLE';
					PRINT @SQL;
					BEGIN TRY
						EXEC sys.sp_executesql @SQL;
					END TRY
					BEGIN CATCH
						SELECT ERROR_MESSAGE(),CAST(@SQL AS XML)
					END CATCH
				END

			SELECT @CreateSQL = N'
			--CREATE PROC ExtendedEvents.usp_' + @EventName + ' AS
			SET NOCOUNT ON;
			IF OBJECT_ID(''TempDB..#EventData'',''U'')		IS NOT NULL DROP TABLE #EventData;
			IF OBJECT_ID(''TempDB..#AsyncEventData'',''U'') IS NOT NULL DROP TABLE #AsyncEventData;
			CREATE TABLE #EventData
				(
					EventDataId           INT IDENTITY(1,1)   NOT NULL	     
				   ,AsyncEventQueueID		INT					NOT NULL
				   ,SQLInstance				VARCHAR(255)		NOT NULL
				   ,CollectionDateTime		DATETIME2			NOT NULL
				   ,CollectionTimeStamp		DATETIME2			NOT NULL
				   ,EventSession			VARCHAR(255)		NOT NULL
				   ,EventName				VARCHAR(255)		NOT NULL
				   ,EventSessionType		VARCHAR(25)		   NOT NULL
				   ,EventXml				XML					NOT NULL
				   ,EventSessionChecksum	BIGINT				NOT NULL
				   ,EventCheckSum			BIGINT				NOT NULL
				   ,isInprogress			BIT					NOT NULL
				);
			CREATE TABLE #AsyncEventData
				(
					 AsyncEventDataID		INT IDENTITY(1,1)	NOT NULL
					,EventCheckSum			BIGINT				NOT NULL
					,SQLInstance			VARCHAR(255)		NOT NULL
					,ActionEventData		XML					NOT NULL
					,DataEventData			XML					NOT NULL
				);
			BEGIN TRAN
				INSERT INTO #EventData
					(
						 AsyncEventQueueID
						,SQLInstance
						,CollectionDateTime
						,CollectionTimeStamp
						,EventSession
						,EventName
						,EventSessionType
						,EventXml
						,EventSessionChecksum
						,EventCheckSum
						,isInprogress
					)
				SELECT	TOP 2
					 AsyncEventQueueID
					,SQLInstance
					,CollectionDateTime
					,CollectionTimeStamp
					,EventSession
					,EventName
					,EventSessionType
					,EventXml
					,EventSessionChecksum
					,EventCheckSum
					,isInprogress          				
				FROM
					ExtendedEvents.AsyncEventQueue ED
				WHERE
					ED.isInprogress = 0
				AND
					ED.EventSession = ''' + @SessionName + '''
					AND
						ED.EventName =  ''' + @EventName + '''
				ORDER BY
					AsyncEventQueueID;

				UPDATE EQ
				SET isInprogress = 1
				FROM
					ExtendedEvents.AsyncEventQueue EQ
				JOIN
					#EventData ED
				ON
					EQ.AsyncEventQueueID = ED.AsyncEventQueueID;
			COMMIT
			;WITH BaseCte AS
				(
					SELECT
						 ED.EventCheckSum
						,ED.SQLInstance
						,ROW_NUMBER()OVER(ORDER BY (SELECT NULL)) RowNum	
						,ED.EventXML.query(''/event[@name="' + @EventName + '"]/action'')  ActionEventData
						,ED.EventXML.query(''/event[@name="' + @EventName + '"]/data'')  DataEventData
					FROM 
						#EventData ED
					CROSS APPLY 
						EventXML.nodes(''/event[@name="' + @EventName + '"]'') AS xed(event_data)
					WHERE
						ED.EventSession =  ''' + @SessionName + '''
					AND
						ED.EventName =  ''' + @EventName + '''
					AND
						ED.isInprogress = 0
				)
			INSERT INTO #AsyncEventData
				(
					 EventCheckSum
					,SQLInstance
					,ActionEventData		
					,DataEventData								
				)
			SELECT
				BaseCte.EventCheckSum
			   ,BaseCte.SQLInstance
			   ,BaseCte.ActionEventData
			   ,BaseCte.DataEventData
			FROM
				BaseCte
			JOIN
				(
					SELECT
						 BaseCte.EventCheckSum
						,MAX(BaseCte.RowNum) RowNum
					FROM
						BaseCte
					GROUP BY
						BaseCte.EventCheckSum
				)Dt
			ON
				BaseCte.RowNum = Dt.RowNum'
		SELECT @CreateSQL += N'
			;WITH DataCte AS
				(
					SELECT 
						 ded.event_data.value(''@name'', ''VARCHAR(MAX)'') EventName
						,ded.event_data.value(''value[1]'', ''VARCHAR(MAX)'')   VarcharValue
						,ED.SQLInstance
						,ED.EventCheckSum
						,ROW_NUMBER() OVER(ORDER BY ED.SQLInstance,ED.EventCheckSum,ded.event_data) InnerRowNum
					FROM
						#AsyncEventData ED
					CROSS APPLY 
						DataEventData.nodes(''//data'') AS ded(event_data)
				)
			, ActionCte AS
				(
					SELECT 
						 ded.event_data.value(''@name'', ''VARCHAR(MAX)'') EventName
						,ded.event_data.value(''value[1]'', ''VARCHAR(MAX)'')   VarcharValue
						,ED.SQLInstance
						,ED.EventCheckSum
						,ROW_NUMBER() OVER(ORDER BY ED.SQLInstance,ED.EventCheckSum,ded.event_data) InnerRowNum
					FROM
						#AsyncEventData ED
					CROSS APPLY 
						ActionEventData.nodes(''//action'') AS ded(event_data)
				)
			,FinalCte AS
				(
					SELECT 
						 DataCte.EventName
						,DataCte.VarcharValue
						,DataCte.InnerRowNum 
						,DataCte.SQLInstance
						,DataCte.EventCheckSum
						,ROW_NUMBER()OVER(PARTITION BY DataCte.SQLInstance,DataCte.EventCheckSum, DataCte.EventName ORDER BY DataCte.InnerRowNum) OuterRowNum
						,''Data'' DataSource
					FROM 
						DataCte
					UNION
					SELECT 
						ActionCte.EventName
					   ,ActionCte.VarcharValue
					   ,ActionCte.InnerRowNum 
					   ,ActionCte.SQLInstance
					   ,ActionCte.EventCheckSum
						,ROW_NUMBER()OVER(PARTITION BY ActionCte.SQLInstance, ActionCte.EventCheckSum, ActionCte.EventName ORDER BY ActionCte.InnerRowNum) OuterRowNum
						,''Action'' DataSource
					FROM 
						ActionCte
				)
			, PrePivotCte AS
				(
					SELECT 
						FinalCte.EventName
					   ,FinalCte.VarcharValue
					   ,FinalCte.OuterRowNum
					   ,FinalCte.SQLInstance
					   ,FinalCte.EventCheckSum
					   ,ROW_NUMBER()OVER(PARTITION BY  FinalCte.SQLInstance, FinalCte.EventCheckSum, FinalCte.OuterRowNum ORDER BY FinalCte.DataSource, FinalCte.InnerRowNum)FinalRowNum
					FROM  
						FinalCte
				)
				' +  (SELECT SQLText FROM  	#TempResults WHERE EventName = @EventName )
		INSERT INTO ##ProcDefinitions
		SELECT @CreateSQL 
		SELECT @SQLCols = N'';
		SET @Counter += 1;
	END
DECLARE @FinalSQL VARCHAR(MAX) = N'';
SELECT 
	@FinalSQL += CHAR(10) + SQLText 
FROM
	##ProcDefinitions
SELECT CAST(@FinalSQL AS XML)
