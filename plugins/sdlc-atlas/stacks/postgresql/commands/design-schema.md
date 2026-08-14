# /design-schema <entity-or-feature>
Invoke schema-design-agent: capture entities/access patterns/scale, choose types/constraints, normalize to 3NF, output DDL against an approved spec.
Refuses to design outside the spec. Never applies DDL directly — hands off to migration-safety-agent.
