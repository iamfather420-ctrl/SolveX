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
