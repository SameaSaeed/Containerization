#!/bin/bash

echo "=== MySQL Database Monitoring ==="
echo "Date: $(date)"
echo

# Check container status
echo "Container Status:"
docker ps --filter name=mysql-restored --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo

# Check database connections
echo "Active Connections:"
docker exec mysql-restored mysql -u root -pSecurePass123 -e "SHOW PROCESSLIST;" 2>/dev/null
echo

# Check database sizes
echo "Database Sizes:"
docker exec mysql-restored mysql -u root -pSecurePass123 -e "
SELECT 
    table_schema as 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as 'Size (MB)'
FROM information_schema.tables 
GROUP BY table_schema;" 2>/dev/null
echo

# Check table row counts
echo "Table Row Counts (company_db):"
docker exec mysql-restored mysql -u root -pSecurePass123 -e "
USE company_db;
SELECT 
    TABLE_NAME as 'Table',
    TABLE_ROWS as 'Rows'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'company_db';" 2>/dev/null