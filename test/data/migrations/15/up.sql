PRAGMA user_version = 15;
PRAGMA foreign_keys = OFF;

ALTER TABLE ProcessInPlant ADD COLUMN last_action INTEGER DEFAULT 1;
