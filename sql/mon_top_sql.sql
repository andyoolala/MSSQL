SELECT sqltext.TEXT,
req.session_id,
ec.client_net_address,
req.status,
req.command,
req.cpu_time,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
join sys.dm_exec_connections ec on req.session_id=ec.session_id