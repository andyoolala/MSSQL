SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
   p.data_compression_desc,
   'ALTER INDEX '+i.name+' ON '+s.name+'.'+t.name+' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE); ' AS SQL,
   CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
	AND p.data_compression_desc='NONE' 
GROUP BY 
    t.Name, s.Name, p.data_compression_desc,'ALTER INDEX '+i.name+' ON '+s.name+'.'+t.name+' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE); '
ORDER BY 5 desc 
