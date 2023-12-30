CREATE　PROCEDURE [dbo].[sp_filegroup_monitor] 
(
@operatorname nvarchar(max),
@profile_name nvarchar(max),
@apname nvarchar(24),
@threshold int = 80,
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
CREATE TABLE  #fg  (  database_name sysname,filegroup_name sysname,[Allocated space(MB)] Decimal(15,2),[Max Allocate space(MB)]  Decimal(15,2),[Used space(MB)] Decimal(15,2),[Percent Used] int) 
 EXEC  sp_msforeachdb  ' 
use ? 
insert into #fg select
db_name() database_name,
c.groupname filegroup_name,
CONVERT (Decimal(15,2),ROUND(SUM(c.size)/128.000,2)) [Allocated space(MB)],
CONVERT (Decimal(15,2),ROUND(SUM(c.maxsize)/128.000,2)) [Max Allocate space(MB)],
CONVERT (Decimal(15,2),ROUND(SUM(c.sizeused)/128.000,2)) [Used space(MB)],
CONVERT (Decimal(15,2),CAST(SUM(c.sizeused) AS FLOAT)/CAST(SUM(c.maxsize) AS FLOAT))*100 [Percent Used]
from
(
select b.groupname,a.name,a.filename,a.size,case when a.maxsize=-1 and a.growth=0 then a.size
	 when a.maxsize=-1 and a.growth<>0 then NULL
	 when a.maxsize<>-1 then a.maxsize end maxsize,FILEPROPERTY(a.Name,''SpaceUsed'') sizeused
FROM dbo.sysfiles a (NOLOCK)
JOIN sysfilegroups b (NOLOCK) ON a.groupid = b.groupid
) c
group by c.groupname
' 
SET @body ='<html><body>
<H3>SQL Server Datafile Usage Info</H3>
<H3>Host Name : '+@svrname+'</H3>
<H3>Application : '+@apname+'</H3>
<H4>Description : </H4>
<H4>It''s refer to the file space is auto increment when columns [Max Allocate space(MB)] & [Percent Used] shows Zero(0)  </H4>
<H4>In these case ,please take care the usage of the disk partition which the data files reside on .  </H4>
<table border = 1> 
<tr>
<th> DatabaseName </th> <th> FilegroupName </th> <th> Allocated space(MB) </th> <th> Max Allocate space(MB) </th><th> Used space(MB) </th><th> Percent Used </th></tr>'


SET @xml = CAST(( SELECT database_name AS 'td','',filegroup_name AS 'td','', [Allocated space(MB)] AS 'td','',
case when [Max Allocate space(MB)] is NULL then 0 else [Max Allocate space(MB)]  END AS 'td','',[Used space(MB)] AS 'td','',
case when [Percent Used] >= @threshold Then 'color:red;font-weight:bold' END [td/@style],
case when [Percent Used] is NULL then 0 else [Percent Used] end AS 'td'
FROM #fg
FOR XML PATH('tr'),TYPE   ) AS  NVARCHAR(MAX))

IF EXISTS (select 1  from #fg where  [Percent Used] >= @threshold) BEGIN select @mailtrigger=1 END

SET @body = @body + @xml +'</table></body></html>'
SET @subject = '['+@svrname +']SQL Server Filegroup Usage Notice'

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

DROP TABLE  #fg

END
GO
