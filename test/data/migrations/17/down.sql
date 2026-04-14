PRAGMA user_version = 16;
PRAGMA foreign_keys = OFF;

UPDATE Configuration SET mip_gap_tolerance = mip_gap_tolerance / 100;
ALTER TABLE Configuration DROP COLUMN solver;

PRAGMA foreign_keys = ON;
