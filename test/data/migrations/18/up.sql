PRAGMA user_version = 18;
PRAGMA foreign_keys = OFF;

ALTER TABLE Market_time_series_parameters ADD COLUMN emission_factor REAL;

PRAGMA foreign_keys = ON;
