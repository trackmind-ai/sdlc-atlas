# /analyze-query <sql-or-file>
Invoke query-performance-agent: run EXPLAIN (ANALYZE, BUFFERS), diagnose seq scans/bad joins/N+1/stale stats, propose minimal fix.
Refuses to change schema directly — routes index/DDL proposals to index-agent/schema-design-agent.
