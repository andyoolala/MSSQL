select
fg.name,
SUM(df.[總空間(MB)]) as '總空間(MB)',
SUM(df.[已用空間(MB)]) as '已用空間(MB)',
SUM(df.[剩餘空間(MB)]) as '剩餘空間(MB)',
(SUM(df.[總空間(MB)])-SUM(df.[已用空間(MB)]))/SUM(df.[總空間(MB)]) as '剩餘空間(%)'
from
(
SELECT
data_space_id,
name,
size/128.0 as '總空間(MB)',
CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 as '已用空間(MB)' ,
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS '剩餘空間(MB)'
FROM sys.database_files
) df,sys.filegroups fg
where df.data_space_id=fg.data_space_id
group by fg.name
order by '剩餘空間(MB)' DESC