PRAGMA user_version = 5;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration DROP COLUMN ghg_target_type;

ALTER TABLE Material_time_series_parameters DROP COLUMN relative_emission_target;

ALTER TABLE Plant DROP COLUMN material_reference_product;

-- Restore NOT NULL constraint to emission_target in Configuration_time_series_emissions
ALTER TABLE Configuration_time_series_emissions RENAME TO Configuration_time_series_emissions_new;

CREATE TABLE Configuration_time_series_emissions (
    id INTEGER,
    date_time TEXT,
    emission_target REAL NOT NULL,
    emission_cost REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Configuration(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

INSERT INTO Configuration_time_series_emissions (id, date_time, emission_target, emission_cost)
SELECT id, date_time, emission_target, emission_cost FROM Configuration_time_series_emissions_new;

DROP TABLE Configuration_time_series_emissions_new;

PRAGMA foreign_keys = ON;
