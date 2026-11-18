-- How many decks each account made with AI on each UTC day, so one learner
-- can't spend the free Workers AI allowance everyone shares.
CREATE TABLE ai_usage (
  uid TEXT NOT NULL,
  day TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (uid, day)
);
