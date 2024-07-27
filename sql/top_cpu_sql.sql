SELECT TOP 50
       query_stats.total_worker_time                                                                                                                                                  AS [total CPU time]
      ,query_stats.total_worker_time / (query_stats.execution_count * 1000)                                                                                                           AS [avg CPU Time MS]
      ,query_stats.total_elapsed_time / (query_stats.execution_count * 1000)                                                                                                          AS [avg Duration MS]
      ,CASE DATEDIFF(MINUTE, query_stats.creation_time, query_stats.last_execution_time)
         WHEN 0 THEN 0 ELSE CONVERT(decimal(16, 2), query_stats.total_worker_time * 1.0 / DATEDIFF(MINUTE, query_stats.creation_time, query_stats.last_execution_time) / 1000000) END AS CPUSecondsPerMinute
      ,query_stats.execution_count                                                                                                                                                    AS [executes]
      ,CASE DATEDIFF(MINUTE, query_stats.creation_time, query_stats.last_execution_time)
         WHEN 0 THEN 0 ELSE CONVERT(decimal(16, 2), query_stats.execution_count * 1.0 / DATEDIFF(MINUTE, query_stats.creation_time, query_stats.last_execution_time)) END             AS executionsPerMinute
      ,query_stats.total_logical_reads                                                                                                                                                AS [total logical reads]
      ,query_stats.total_logical_reads / query_stats.execution_count                                                                                                                  AS [avg logical reads]
      ,query_stats.total_logical_writes                                                                                                                                               AS [total logical writes]
      ,query_stats.total_logical_writes / query_stats.execution_count                                                                                                                 AS [avg logical writes]
      ,query_stats.creation_time                                                                                                                                                      AS creation_time
      ,query_stats.last_execution_time                                                                                                                                                AS last_execution_time
      ,query_stats.ProcName                                                                                                                                                           AS ProcName
      ,query_stats.DBName                                                                                                                                                             AS DBName
      ,query_stats.statement_text                                                                                                                                                     AS [statement text]
      ,TRY_CONVERT(XML, query_stats.query_plan)                                                                                                                                       AS ExecPlan
      ,query_stats.query_hash
FROM
(
  SELECT QS.*
        ,OBJECT_NAME(ST.objectid, ST.[dbid])  AS ProcName
        ,DB_NAME(ST.[dbid])                   AS DBName
        ,CONVERT(nvarchar(MAX), p.query_plan) AS query_plan
        ,SUBSTRING( ST.text
                   ,(QS.statement_start_offset / 2) + 1
                   ,((CASE statement_end_offset
                        WHEN-1 THEN DATALENGTH(ST.text) ELSE QS.statement_end_offset END - QS.statement_start_offset
                     ) / 2
                    ) + 1
                  )                           AS statement_text
  FROM sys.dm_exec_query_stats                    AS QS
  CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
  OUTER APPLY sys.dm_exec_text_query_plan(QS.plan_handle, QS.statement_start_offset, QS.statement_end_offset) AS p
) AS query_stats
WHERE query_stats.last_execution_time >= DATEADD(MINUTE, -10, GETDATE())
ORDER BY 1 DESC;