CREATE TABLE IF NOT EXISTS node_registry (
  id TEXT PRIMARY KEY,
  node_code TEXT NOT NULL UNIQUE,
  node_name TEXT NOT NULL,
  subsystem TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'REGISTERED',
  capabilities_json TEXT NOT NULL DEFAULT '[]',
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS execution_runs (
  id TEXT PRIMARY KEY,
  tenant_id TEXT REFERENCES tenants(id),
  run_type TEXT NOT NULL,
  target_id TEXT,
  status TEXT NOT NULL,
  input_hash TEXT,
  output_hash TEXT,
  evidence_hash TEXT,
  started_at BIGINT NOT NULL,
  completed_at BIGINT
);

CREATE TABLE IF NOT EXISTS failures (
  id TEXT PRIMARY KEY,
  tenant_id TEXT REFERENCES tenants(id),
  execution_run_id TEXT REFERENCES execution_runs(id),
  failure_type TEXT NOT NULL,
  severity TEXT NOT NULL,
  message TEXT NOT NULL,
  quarantined BOOLEAN NOT NULL DEFAULT TRUE,
  resolved_at BIGINT,
  created_at BIGINT NOT NULL
);

ALTER TABLE orders ADD CONSTRAINT orders_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id);

ALTER TABLE orders ADD CONSTRAINT orders_deployment_id_fkey FOREIGN KEY (deployment_id) REFERENCES deployments(id);
