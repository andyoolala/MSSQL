SELECT
t.NAME AS TableName,
s.Name AS SchemaName,
p.partition_number,
dateadd(month,-1,convert(datetime,r.value) ) AS LowValue,
convert(datetime,r.value) AS HighValue,
p.row_count AS RowCounts,
SUM(a.total_pages) * 8 AS TotalSpaceKB,
CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
SUM(a.used_pages) * 8 AS UsedSpaceKB,
CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB
FROM
sys.tables t
INNER JOIN
sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
sys.dm_db_partition_stats p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN
sys.schemas s ON t.schema_id = s.schema_id
LEFT OUTER JOIN
sys.partition_range_values r ON p.partition_number=r.boundary_id
WHERE
t.NAME NOT LIKE 'dt%'
AND t.is_ms
