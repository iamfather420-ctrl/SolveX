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
