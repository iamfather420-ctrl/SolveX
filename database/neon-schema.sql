-- Solvex / dAIsy Neon PostgreSQL schema

-- Paste this file into the Neon SQL Editor and run it once.

BEGIN;

CREATE TABLE IF NOT EXISTS tenants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('ENTERPRISE','PRO','STANDARD')),
  isolated_storage_key TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  email TEXT NOT NULL,
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'OPERATOR',
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  UNIQUE (tenant_id, email)
);

CREATE TABLE IF NOT EXISTS roles (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  name TEXT NOT NULL,
  permissions_json TEXT NOT NULL DEFAULT '[]',
  created_at BIGINT NOT NULL,
  UNIQUE (tenant_id, name)
);

CREATE TABLE IF NOT EXISTS permissions (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS tenant_memberships (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  role_id TEXT REFERENCES roles(id),
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at BIGINT NOT NULL,
  UNIQUE (tenant_id, user_id)
);

CREATE TABLE IF NOT EXISTS problems (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  raw_problem TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  domain TEXT NOT NULL,
  detected_constraints_json TEXT NOT NULL DEFAULT '[]',
  invariants_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'INTAKE',
  version TEXT NOT NULL DEFAULT '1.0.0',
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS paradoxes (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  domain TEXT NOT NULL,
  category TEXT NOT NULL,
  classification TEXT NOT NULL,
  scope TEXT NOT NULL,
  formal_invariant TEXT NOT NULL,
  z3_smt_assertion TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS invariants (
  id TEXT PRIMARY KEY,
  problem_id TEXT REFERENCES problems(id),
  paradox_id TEXT REFERENCES paradoxes(id),
  statement TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'UNVERIFIED',
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS proof_bundles (
  id TEXT PRIMARY KEY,
  subject_id TEXT NOT NULL,
  claim TEXT NOT NULL,
  claim_hash TEXT NOT NULL,
  implementation_hash TEXT,
  environment_hash TEXT,
  dependency_hash TEXT,
  verifier_identity TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  evidence_json TEXT NOT NULL DEFAULT '[]',
  formal_proofs_json TEXT NOT NULL DEFAULT '[]',
  independent_oracles_json TEXT NOT NULL DEFAULT '[]',
  replay_results_json TEXT NOT NULL DEFAULT '[]',
  source_references_json TEXT NOT NULL DEFAULT '[]',
  limitations_json TEXT NOT NULL DEFAULT '[]',
  reproducibility_instructions TEXT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS proof_evidence (
  id TEXT PRIMARY KEY,
  proof_bundle_id TEXT NOT NULL REFERENCES proof_bundles(id),
  evidence_type TEXT NOT NULL,
  content_json TEXT NOT NULL,
  receipt_hash TEXT NOT NULL,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS tests (
  id TEXT PRIMARY KEY,
  proof_bundle_id TEXT REFERENCES proof_bundles(id),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  passed BOOLEAN NOT NULL DEFAULT FALSE,
  duration_ms DOUBLE PRECISION NOT NULL DEFAULT 0,
  receipt_hash TEXT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS verification_runs (
  id TEXT PRIMARY KEY,
  tenant_id TEXT REFERENCES tenants(id),
  scope TEXT NOT NULL,
  environment TEXT NOT NULL,
  commit_sha TEXT,
  status TEXT NOT NULL,
  gates_passed BIGINT NOT NULL DEFAULT 0,
  gates_total BIGINT NOT NULL DEFAULT 15,
  root_hash TEXT,
  started_at BIGINT NOT NULL,
  completed_at BIGINT
);

CREATE TABLE IF NOT EXISTS solutions (
  id TEXT PRIMARY KEY,
  tenant_id TEXT REFERENCES tenants(id),
  problem_id TEXT REFERENCES problems(id),
  paradox_id TEXT REFERENCES paradoxes(id),
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  domain TEXT NOT NULL,
  implementation_source TEXT NOT NULL,
  implementation_hash TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  proof_bundle_id TEXT REFERENCES proof_bundles(id),
  performance_boost_percent DOUBLE PRECISION NOT NULL DEFAULT 0,
  reversibility_guaranteed BOOLEAN NOT NULL DEFAULT TRUE,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS offers (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  solution_id TEXT NOT NULL REFERENCES solutions(id),
  proof_bundle_id TEXT NOT NULL REFERENCES proof_bundles(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  cost_basis_cents BIGINT NOT NULL,
  verification_complexity_factor DOUBLE PRECISION NOT NULL,
  risk_class TEXT NOT NULL CHECK (risk_class IN ('LOW','MEDIUM','HIGH')),
  price_cents BIGINT NOT NULL,
  sla_tier TEXT,
  published BOOLEAN NOT NULL DEFAULT FALSE,
  verification_status TEXT NOT NULL,
  publication_blocked_reason TEXT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  offer_id TEXT NOT NULL REFERENCES offers(id),
  solution_id TEXT NOT NULL REFERENCES solutions(id),
  proof_bundle_id TEXT NOT NULL REFERENCES proof_bundles(id),
  price_cents BIGINT NOT NULL,
  status TEXT NOT NULL,
  payment_id TEXT,
  deployment_id TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  order_id TEXT,
  provider TEXT NOT NULL,
  provider_environment TEXT NOT NULL,
  provider_order_id TEXT,
  provider_capture_id TEXT,
  amount_cents BIGINT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  status TEXT NOT NULL,
  idempotency_key TEXT NOT NULL UNIQUE,
  receipt_hash TEXT,
  raw_response_json TEXT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS deployments (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  order_id TEXT REFERENCES orders(id),
  solution_id TEXT REFERENCES solutions(id),
  environment TEXT NOT NULL,
  status TEXT NOT NULL,
  implementation_hash TEXT,
  deployed_at BIGINT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS checkpoints (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  checkpoint_id TEXT NOT NULL,
  target_mutation TEXT NOT NULL,
  classification TEXT NOT NULL,
  snapshot_state_json TEXT NOT NULL,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS rollback_records (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  checkpoint_id TEXT NOT NULL REFERENCES checkpoints(id),
  reason TEXT NOT NULL,
  status TEXT NOT NULL,
  restored_hash TEXT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS telemetry (
  id TEXT PRIMARY KEY,
  tenant_id TEXT REFERENCES tenants(id),
  node_id TEXT,
  metric TEXT NOT NULL,
  value DOUBLE PRECISION NOT NULL,
  unit TEXT,
  recorded_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_records (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  index_num BIGINT NOT NULL,
  actor TEXT NOT NULL,
  action TEXT NOT NULL,
  target_entity TEXT NOT NULL,
  target_id TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  payload_hash TEXT NOT NULL,
  previous_hash TEXT NOT NULL,
  record_hash TEXT NOT NULL UNIQUE,
  created_at BIGINT NOT NULL,
  UNIQUE (tenant_id, index_num)
);

CREATE TABLE IF NOT EXISTS chain_records (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  audit_record_id TEXT NOT NULL REFERENCES audit_records(id),
  chain_height BIGINT NOT NULL,
  merkle_root TEXT NOT NULL,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS licenses (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  solution_id TEXT NOT NULL REFERENCES solutions(id),
  order_id TEXT REFERENCES orders(id),
  license_key_hash TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  issued_at BIGINT NOT NULL,
  expires_at BIGINT
);

CREATE TABLE IF NOT EXISTS adapter_status (
  id TEXT PRIMARY KEY,
  tenant_id TEXT REFERENCES tenants(id),
  adapter_name TEXT NOT NULL,
  provider TEXT NOT NULL,
  environment TEXT NOT NULL,
  status TEXT NOT NULL,
  last_error TEXT,
  checked_at BIGINT NOT NULL
);

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

CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);

CREATE INDEX IF NOT EXISTS idx_problems_tenant ON problems(tenant_id);

CREATE INDEX IF NOT EXISTS idx_solutions_tenant ON solutions(tenant_id);

CREATE INDEX IF NOT EXISTS idx_offers_tenant ON offers(tenant_id);

CREATE INDEX IF NOT EXISTS idx_orders_tenant ON orders(tenant_id);

CREATE INDEX IF NOT EXISTS idx_audit_tenant_height ON audit_records(tenant_id, index_num);

CREATE INDEX IF NOT EXISTS idx_execution_runs_tenant ON execution_runs(tenant_id);

CREATE INDEX IF NOT EXISTS idx_telemetry_node_time ON telemetry(node_id, recorded_at);

COMMIT;
