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
