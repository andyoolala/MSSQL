CREATE TABLE #fg ( database_name sysname,filegroup_name sysname,[Allocated space(MB)] Decimal(15,2),[Max Allocate space(MB)] Decimal(15,2),[Used space(MB)] Decimal(15,2),[Percent Used] int)
EXEC sp_msforeachdb '
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
SELECT *
FROM #fg
DROP TABLE #fg