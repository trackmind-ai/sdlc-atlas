# /review-indexes <table-or-query>
Invoke index-agent: select index type (B-tree/GIN/GiST/BRIN), check FK/composite/partial/covering opportunities, output CONCURRENTLY migration.
Refuses indexes with no query/join/sort justification. Never applies directly — hands off to migration-safety-agent.
