# Neon import chunks

The Neon SQL editor/clipboard truncated the full schema at 1,324 characters. Run these files **in numeric order** in the Neon SQL Editor:

1. `part-01.sql`
2. `part-02.sql`
3. Continue through the final part.

Each part contains complete PostgreSQL statements and is intentionally below the clipboard limit. Do not add `BEGIN` or `COMMIT` around the individual files. The final part adds the circular order foreign-key constraints and indexes.
