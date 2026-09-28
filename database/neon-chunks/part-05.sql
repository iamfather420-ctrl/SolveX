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
