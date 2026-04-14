PRAGMA user_version = 17;
PRAGMA foreign_keys = OFF;

ALTER TABLE Market_time_series_parameters DROP COLUMN emission_factor;

PRAGMA foreign_keys = ON;
