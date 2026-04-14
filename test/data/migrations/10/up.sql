PRAGMA user_version = 10;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN print_lp INTEGER DEFAULT 0;
