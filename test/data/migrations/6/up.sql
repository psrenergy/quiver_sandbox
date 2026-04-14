PRAGMA user_version = 6;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN ghg_target_type INTEGER DEFAULT 0;

ALTER TABLE Material_time_series_parameters ADD COLUMN relative_emission_target REAL;

ALTER TABLE Plant ADD COLUMN material_reference_product INTEGER REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE;

UPDATE Plant SET material_reference_product = (
    SELECT m.id
    FROM Material m
    JOIN Material_time_series_parameters mtsp
        ON m.id = mtsp.id
    WHERE mtsp.demand IS NOT NULL
    ORDER BY m.id
    LIMIT 1
);

-- Remove NOT NULL constraint from emission_target in Configuration_time_series_emissions
ALTER TABLE Configuration_time_series_emissions RENAME TO Configuration_time_series_emissions_old;

CREATE TABLE Configuration_time_series_emissions (
    id INTEGER,
    date_time TEXT,
    emission_target REAL,
    emission_cost REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Configuration(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

INSERT INTO Configuration_time_series_emissions (id, date_time, emission_target, emission_cost)
SELECT id, date_time, emission_target, emission_cost FROM Configuration_time_series_emissions_old;

DROP TABLE Configuration_time_series_emissions_old;

PRAGMA foreign_keys = ON;
