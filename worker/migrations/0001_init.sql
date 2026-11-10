-- One row per account. seq is the account's latest change number; every
-- record that wins a write takes the next one.
CREATE TABLE users (
  uid TEXT PRIMARY KEY,
  email TEXT,
  created_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  seq INTEGER NOT NULL DEFAULT 0
);

-- The devices that sync each account.
CREATE TABLE devices (
  uid TEXT NOT NULL,
  device_id TEXT NOT NULL,
  first_seen_at TEXT NOT NULL,
  last_sync_at TEXT NOT NULL,
  PRIMARY KEY (uid, device_id)
);

-- The learning data: the app's records (docs/backend-plan.md). data is JSON,
-- or NULL for a deletion; hlc stamps sort as text.
CREATE TABLE records (
  uid TEXT NOT NULL,
  kind TEXT NOT NULL,
  id TEXT NOT NULL,
  data TEXT,
  hlc TEXT NOT NULL,
  seq INTEGER NOT NULL,
  PRIMARY KEY (uid, kind, id)
);

CREATE INDEX records_by_seq ON records (uid, seq);
