PRAGMA user_version = 13;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN num_extra_years_in_simulation INTEGER DEFAULT 0;

DROP TABLE Storage;
