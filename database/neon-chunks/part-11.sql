CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);

CREATE INDEX IF NOT EXISTS idx_problems_tenant ON problems(tenant_id);

CREATE INDEX IF NOT EXISTS idx_solutions_tenant ON solutions(tenant_id);

CREATE INDEX IF NOT EXISTS idx_offers_tenant ON offers(tenant_id);

CREATE INDEX IF NOT EXISTS idx_orders_tenant ON orders(tenant_id);

CREATE INDEX IF NOT EXISTS idx_audit_tenant_height ON audit_records(tenant_id, index_num);

CREATE INDEX IF NOT EXISTS idx_execution_runs_tenant ON execution_runs(tenant_id);

CREATE INDEX IF NOT EXISTS idx_telemetry_node_time ON telemetry(node_id, recorded_at);
