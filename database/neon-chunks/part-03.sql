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
