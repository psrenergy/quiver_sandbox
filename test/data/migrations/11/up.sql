PRAGMA user_version = 11;
PRAGMA foreign_keys = OFF;

ALTER TABLE Plant ADD COLUMN min_plant_capacity REAL DEFAULT 0;
