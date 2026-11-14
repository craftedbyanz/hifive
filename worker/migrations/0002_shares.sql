-- Decks shared by link or code (Community, step 1). One row per deck an
-- account shares: sharing it again replaces the snapshot and keeps the code.
-- data is the deck as JSON: title, description, icon, language and words.
CREATE TABLE shares (
  code TEXT PRIMARY KEY,
  uid TEXT NOT NULL,
  deck_id TEXT NOT NULL,
  data TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (uid, deck_id)
);
