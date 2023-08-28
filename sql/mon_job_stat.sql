SELECT
job.Name, job.job_ID
,job.Originating_Server
,activity.run_requested_Date
,datediff(minute, activity.run_requested_Date, getdate()) AS Elapsed
FROM
msdb.dbo.sysjobs_view job
INNER JOIN msdb.dbo.sysjobactivity activity
ON (job.job_id = activity.job_id)
WHERE
run_Requested_date is not null
AND start_execution_date is not null
AND stop_execution_date is null
AND activity.session_id=(select max(session_id) from msdb.dbo.syssessions)