# Solvex Database Design

This directory contains the canonical local database design for the Solvex / dAIsy haMINJA application.

## Files

- `schema.sql` — SQLite DDL with foreign keys, checks, and indexes.
- `schema.dbml` — DBML for import into [dbdiagram.io](https://dbdiagram.io), DrawSQL, or other schema-design tools.
- `solvex.sqlite` — initialized SQLite database generated from `schema.sql`.

## Recreate the database

From the repository root:

```bash
python3 - <<'PY'
import sqlite3
from pathlib import Path

out = Path('database/solvex.sqlite')
if out.exists():
    out.unlink()
conn = sqlite3.connect(out)
conn.executescript(Path('database/schema.sql').read_text())
conn.execute('PRAGMA foreign_keys = ON')
conn.commit()
conn.close()
print(out)
PY
```

## Design principles

- Every tenant-owned record carries `tenant_id` and is indexed for isolation.
- Proofs, evidence, tests, replay results, and verification runs are first-class records.
- Orders, payments, deployments, licenses, checkpoints, and rollback records support the end-to-end lifecycle.
- `audit_records` and `chain_records` provide append-only hash-chain and Merkle evidence.
- Provider credentials are never stored in this database; PayPal and Neon values remain runtime environment secrets.
