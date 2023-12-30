CREATE　PROCEDURE [dbo].[sp_job_monitor] 
(
@operatorname nvarchar(max),
@profile_name nvarchar(max),
@apname nvarchar(24),
@threshold int = 60,
@mailtrigger int = 0
)
AS

DECLARE @body nvarchar(max)
DECLARE @xml nvarchar(max)
DECLARE @subject nvarchar(max)
DECLARE @OperatorEmailAddress nvarchar(100)
DECLARE @svrname nvarchar(24)
select @svrname=@@servername

BEGIN
CREATE TABLE  #jtemp  (  Job_Name nvarchar(128),Run_Requested_Date　datetime,Elapsed int )

insert into #jtemp
SELECT
    job.Name, --nvarchar(128)
	activity.run_requested_Date, --datetime
    datediff(minute, activity.run_requested_Date, getdate()) AS Elapsed --datetime
FROM
    msdb.dbo.sysjobs_view job (NOLOCK)
        INNER JOIN msdb.dbo.sysjobactivity activity (NOLOCK)
        ON (job.job_id = activity.job_id) 
WHERE
    run_Requested_date is not null
    AND start_execution_date is not null
    AND stop_execution_date is null
    AND activity.session_id=(select max(session_id) from msdb.dbo.syssessions)


IF EXISTS (select 1 from #jtemp where Elapsed > @threshold ) BEGIN select @mailtrigger=1 END

SET @body ='<html><body>
<H3>SQL Server Job Monitor</H3>
<H3>Host Name : '+@svrname+'</H3>
<H4>Description : </H4>
<H4>The notice is used to remind SQL Server job running too long</H4>
<H4>[Elapsed Time threshold] : '+convert(nvarchar(10),@threshold)+' </H4>
<table border = 1> 
<tr>
<th> Job_Name </th> <th> Run_Requested_Date </th><th> Elapsed </th></tr>'

SET @xml = CAST((SELECT Job_Name AS 'td','',
Run_Requested_Date　as 'td','',
Elapsed AS 'td'
FROM #jtemp
FOR XML PATH('tr'),TYPE) AS NVARCHAR(MAX))

SET @body = @body + @xml +'</table></body></html>'
SET @subject = '['+@svrname +'] SQL Server Job Monitor'

SET @OperatorEmailAddress = (SELECT email_address 
                             FROM msdb.dbo.sysoperators
                             WHERE [name] = @operatorname)

IF @mailtrigger=1
BEGIN
exec msdb.dbo.sp_send_dbmail
@profile_name=@profile_name, 
@recipients=@OperatorEmailAddress,
@subject= @subject,
@body=@body,
@body_format=HTML 
END

DROP TABLE  #jtemp

END
GO

## sp_logfile_monitor
CREATE　PROCEDURE [dbo].[sp_logfile_monitor] 
(
@operatorname nvarchar(max),
@profile_name nvarchar(max),
@apname nvarchar(24),
@threshold int = 80,
@threshold_s int = 10240,
@mailtrigger int = 0,
@smstrigger int = 0
)
AS

DECLARE @body nvarchar(max)
DECLARE @xml nvarchar(max)
DECLARE @subject nvarchar(max)
DECLARE @OperatorEmailAddress nvarchar(100) 
DECLARE @svrname nvarchar(24)
DECLARE @subject_sms nvarchar(50)
DECLARE @body_sms nvarchar(50)
select @svrname=@@servername

BEGIN
CREATE TABLE  #lf  (  database_name sysname,[Total_Space_MB]　decimal(10,1),[Percent_Used] int) 
 EXEC  sp_msforeachdb  ' 
use ? 
insert into #lf select
db_name() database_name,
cast((total_log_size_in_bytes)*1.0/1024/1024 as decimal(10,1))
as Total_Space_MB,
cast(used_log_space_in_percent AS INT)
AS Percent_Used
from sys.dm_db_log_space_usage　(NOLOCK)
' 
SET @body ='<html><body>
<H3>SQL Server Datafile Usage Info</H3>
<H3>Host Name : '+@svrname+'</H3>
<H3>Application : '+@apname+'</H3>
<H4>Description : </H4>
<H4>The notice is used to prevent SQL Server transaction log growth abnormally </H4>
<H4>[size threshold] : '+convert(nvarchar(10),@threshold_s)+'   [usage threshold] : '+convert(nvarchar(3),@threshold)+' </H4>
<table border = 1> 
<tr>
<th> DatabaseName </th> <th> Total_Space(MB) </th><th> Percent_Used </th></tr>'


SET @xml = CAST(( SELECT database_name AS 'td','',
case when [Total_Space_MB] >= @threshold_s Then 'color:red;font-weight:bold' END [td/@style],
[Total_Space_MB]　as 'td','',
case when [Percent_Used] >= @threshold Then 'color:red;font-weight:bold' END [td/@style],
case when [Percent_Used] is NULL then 0 else [Percent_Used] end AS 'td'
FROM #lf
FOR XML PATH('tr'),TYPE   ) AS  NVARCHAR(MAX))

IF EXISTS (select 1  from #lf where  [Percent_Used] >= @threshold　or [Total_Space_MB] >= @threshold_s ) BEGIN select @mailtrigger=1 END

SET @body = @body + @xml +'</table></body></html>'
SET @subject = '['+@svrname +']SQL Server Logfile Usage Notice'

SET @OperatorEmailAddress = (SELECT email_address 
                             FROM msdb.dbo.sysoperators
                             WHERE [name] = @operatorname)

IF @mailtrigger=1
BEGIN
exec msdb.dbo.sp_send_dbmail
@profile_name=@profile_name, 
@recipients=@OperatorEmailAddress,
@subject= @subject,
@body=@body,
@body_format=HTML 
END

DROP TABLE  #lf

END
GO
