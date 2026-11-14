-- Public decks (Community, step 2). A shared deck can be made public: it
-- then shows in Explore, by language, newest or most added first, with the
-- name its owner chose to show. The listing reads these columns, not data.
ALTER TABLE shares ADD COLUMN public INTEGER NOT NULL DEFAULT 0;
ALTER TABLE shares ADD COLUMN author TEXT NOT NULL DEFAULT '';
ALTER TABLE shares ADD COLUMN language TEXT NOT NULL DEFAULT 'en';
ALTER TABLE shares ADD COLUMN title TEXT NOT NULL DEFAULT '';
ALTER TABLE shares ADD COLUMN description TEXT NOT NULL DEFAULT '';
ALTER TABLE shares ADD COLUMN icon INTEGER NOT NULL DEFAULT 0;
ALTER TABLE shares ADD COLUMN word_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE shares ADD COLUMN adds INTEGER NOT NULL DEFAULT 0;
-- Hidden by reports, pending a look; a hidden deck still opens by its code.
ALTER TABLE shares ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0;
ALTER TABLE shares ADD COLUMN published_at TEXT;

CREATE INDEX shares_explore ON shares (public, hidden, language, adds);

-- Who added each public deck, so an account counts once.
CREATE TABLE share_adds (
  code TEXT NOT NULL,
  uid TEXT NOT NULL,
  PRIMARY KEY (code, uid)
);

-- Reports of a deck, one per account. Enough of them hide the deck.
CREATE TABLE share_reports (
  code TEXT NOT NULL,
  uid TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (code, uid)
);

-- Accounts a learner blocked; their decks leave that learner's Explore.
CREATE TABLE blocks (
  uid TEXT NOT NULL,
  blocked_uid TEXT NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (uid, blocked_uid)
);
