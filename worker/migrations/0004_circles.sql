-- Study groups and classes (Community, steps 3 and 4), both "circles":
-- joined by a six-character code. A group shares a goal of study days a
-- week; a class has a teacher (its owner) who sets decks to learn by a date.
CREATE TABLE circles (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('group', 'class')),
  name TEXT NOT NULL,
  goal INTEGER NOT NULL DEFAULT 3,
  code TEXT NOT NULL UNIQUE,
  owner TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE circle_members (
  circle_id TEXT NOT NULL,
  uid TEXT NOT NULL,
  joined_at TEXT NOT NULL,
  PRIMARY KEY (circle_id, uid)
);

CREATE INDEX circle_members_by_uid ON circle_members (uid);

-- A deck a teacher set: the shared deck's code, its title, its words as
-- lower-case text (how reviews name them) and the date it is due.
CREATE TABLE assignments (
  id TEXT PRIMARY KEY,
  circle_id TEXT NOT NULL,
  share_code TEXT NOT NULL,
  title TEXT NOT NULL,
  words TEXT NOT NULL,
  due TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX assignments_by_circle ON assignments (circle_id);
