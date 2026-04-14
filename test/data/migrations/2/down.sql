PRAGMA user_version = 1;
PRAGMA foreign_keys = OFF;

ALTER TABLE ProcessInPlant DROP COLUMN refurbishment_lifetime;
ALTER TABLE ProcessInPlant DROP COLUMN years_since_last_refurbishment;
DROP TABLE ProcessInPlant_time_series_refurbishment;

-- create v1 ProcessInPlant
CREATE TABLE ProcessInPlant_old (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    process_id INTEGER,
    min_capacity REAL DEFAULT 0.0,
    max_capacity REAL NOT NULL,
    max_expansion REAL DEFAULT 0.0,
    implementation_delay INTEGER DEFAULT 0,
    expansion_delay INTEGER DEFAULT 0,
    status INTEGER NOT NULL,
    process_substitution INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_id) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_substitution) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- migrate ProcessInPlant
INSERT INTO ProcessInPlant_old (
    id, label, plant_id, process_id,
    min_capacity, max_capacity, max_expansion,
    implementation_delay, expansion_delay,
    status, process_substitution
)
SELECT
    new.id,
    new.label,
    new.plant_id,
    new.process_id,
    new.min_capacity,
    new.max_capacity,
    new.max_expansion,
    new.implementation_delay,
    new.expansion_delay,
    new.status,
    (
        SELECT pip.process_id
        FROM ProcessInPlant pip
        WHERE pip.id = new.processinplant_substitution
        LIMIT 1
    ) AS process_substitution
FROM ProcessInPlant new;

-- drop v2 ProcessInPlant
DROP TABLE ProcessInPlant;

-- rename v1 ProcessInPlant
ALTER TABLE ProcessInPlant_old RENAME TO ProcessInPlant;

-- recreate ProcessInPlant_time_series_parameters (unchanged)
CREATE TABLE ProcessInPlant_time_series_parameters_old (
    id INTEGER,
    date_time TEXT,
    investment_cost REAL NOT NULL,
    operational_cost REAL NOT NULL,
    capacity_expansion_reference_cost REAL,
    capacity_expansion_reference_capacity REAL,
    capacity_expansion_scale_factor REAL,
    FOREIGN KEY (id) REFERENCES ProcessInPlant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

-- migrate ProcessInPlant_time_series_parameters
INSERT INTO ProcessInPlant_time_series_parameters_old
SELECT * FROM ProcessInPlant_time_series_parameters;

-- drop v2 ProcessInPlant_time_series_parameters
DROP TABLE ProcessInPlant_time_series_parameters;

-- rename v1 ProcessInPlant_time_series_parameters
ALTER TABLE ProcessInPlant_time_series_parameters_old RENAME TO ProcessInPlant_time_series_parameters;
