PRAGMA user_version = 5;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN when_to_refurbish INTEGER DEFAULT 0;
