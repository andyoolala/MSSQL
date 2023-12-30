CREATE　PROCEDURE [dbo].[sp_hadr_monitor] 
(
@operatorname nvarchar(max),
@profile_name nvarchar(max),
@apname nvarchar(24),
@mailtrigger int = 0
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

SELECT rcs.replica_server_name,
	  rs.[role_desc], 
      rs.[connected_state_desc],
      CASE WHEN rs.[recovery_health_desc] is NULL THEN 'NONE' else [recovery_health_desc] END AS [recovery_health_desc],
      rs.[synchronization_health_desc]
	  INTO #TEMP
      FROM [master].[sys].[dm_hadr_availability_replica_states] rs inner join
	   [master].[sys].[dm_hadr_availability_replica_cluster_states] rcs 
	   on rs.replica_id=rcs.replica_id and rsCREATE　PROCEDURE [dbo].[sp_hadr_monitor] 
(
@operatorname nvarchar(max),
@profile_name nvarchar(max),
@apname nvarchar(24),
@mailtrigger int = 0
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

SELECT rcs.replica_server_name,
	  rs.[role_desc], 
      rs.[connected_state_desc],
      CASE WHEN rs.[recovery_health_desc] is NULL THEN 'NONE' else [recovery_health_desc] END AS [recovery_health_desc],
      rs.[synchronization_health_desc]
	  INTO #TEMP
      FROM [master].[sys].[dm_hadr_availability_replica_states] rs inner join
	   [master].[sys].[dm_hadr_availability_replica_cluster_states] rcs 
	   on rs.replica_id=rcs.replica_id and rs.group_id=rcs.group_id

SET @body ='<html><body>
<H3>SQL Server AlwaysOn Health Info</H3>
<H3>Host Name : '+@svrname+'</H3>
<H3>Application : '+@apname+'</H3>.group_id=rcs.group_id

SET @body ='<html><body>
<H3>SQL Server AlwaysOn Health Info</H3>
<H3>Host Name : '+@svrname+'</H3>
<H3>Application : '+@apname+'</H3>
<H4>Description : </H4>
<H4>SQL Server AlwaysOn Health Status . Login with SSMS and view AG dashboard for more informations  </H4>
<table border = 1> 
<tr>
<th> Server Name </th> <th> AG Role </th> <th> Connected State </th> <th> Recovery Health </th><th> Synchronize Health </th></tr>'


SET @xml = CAST(( SELECT replica_server_name AS 'td','',
	  [role_desc] AS 'td','', 
      [connected_state_desc] AS 'td','',
      [recovery_health_desc] AS 'td','',
      [synchronization_health_desc] AS 'td'
	  FROM #TEMP
	  FOR XML PATH('tr'),TYPE  ) AS  NVARCHAR(MAX))

IF EXISTS (select 1  from #TEMP where  connected_state_desc <> 'CONNECTED' OR synchronization_health_desc <> 'HEALTHY' OR (role_desc='PRIMARY' and recovery_health_desc <> 'ONLINE') ) 
BEGIN select @mailtrigger=1 END

SET @body = @body + @xml +'</table></body></html>'
SET @subject = '['+@svrname +']SQL Server AlwaysOn Health Notice'

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

SET @subject_sms = '['+@svrname +']SQL Server AlwaysOn Health Usage Alert'

DROP TABLE  #TEMP

END
GO


