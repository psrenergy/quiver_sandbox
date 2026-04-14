PRAGMA user_version = 3;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN deficit_cost REAL DEFAULT 1e12;
