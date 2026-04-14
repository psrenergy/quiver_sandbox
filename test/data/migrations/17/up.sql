PRAGMA user_version = 17;
PRAGMA foreign_keys = OFF;

UPDATE Configuration SET mip_gap_tolerance = mip_gap_tolerance * 100;
ALTER TABLE Configuration ADD COLUMN solver INTEGER DEFAULT 0;

PRAGMA foreign_keys = ON;
