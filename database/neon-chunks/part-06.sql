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
