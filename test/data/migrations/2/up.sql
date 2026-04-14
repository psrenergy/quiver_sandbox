PRAGMA user_version = 2;
PRAGMA foreign_keys = OFF;

-- create v2 ProcessInPlant
CREATE TABLE ProcessInPlant_new (
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
    processinplant_substitution INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_id) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (processinplant_substitution) REFERENCES ProcessInPlant(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- migrate ProcessInPlant
INSERT INTO ProcessInPlant_new (
    id, label, plant_id, process_id,
    min_capacity, max_capacity, max_expansion,
    implementation_delay, expansion_delay,
    status, processinplant_substitution
)
SELECT
    old.id,
    old.label,
    old.plant_id,
    old.process_id,
    old.min_capacity,
    old.max_capacity,
    old.max_expansion,
    old.implementation_delay,
    old.expansion_delay,
    old.status,
    (
        SELECT pip.id
        FROM ProcessInPlant pip
        WHERE pip.plant_id  = old.plant_id
          AND pip.process_id = old.process_substitution
        LIMIT 1
    ) AS processinplant_substitution
FROM ProcessInPlant old;

-- drop v1 ProcessInPlant
DROP TABLE ProcessInPlant;

-- rename v2 ProcessInPlant
ALTER TABLE ProcessInPlant_new RENAME TO ProcessInPlant;

-- recreate ProcessInPlant_time_series_parameters (unchanged)
CREATE TABLE ProcessInPlant_time_series_parameters_new (
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
INSERT INTO ProcessInPlant_time_series_parameters_new
SELECT * FROM ProcessInPlant_time_series_parameters;

-- drop v1 ProcessInPlant_time_series_parameters
DROP TABLE ProcessInPlant_time_series_parameters;

-- rename v2 ProcessInPlant_time_series_parameters
ALTER TABLE ProcessInPlant_time_series_parameters_new RENAME TO ProcessInPlant_time_series_parameters;

ALTER TABLE ProcessInPlant ADD COLUMN refurbishment_lifetime INTEGER;
ALTER TABLE ProcessInPlant ADD COLUMN refurbishment_delay INTEGER DEFAULT 0;
ALTER TABLE ProcessInPlant ADD COLUMN years_since_last_refurbishment INTEGER DEFAULT 0;
CREATE TABLE ProcessInPlant_time_series_refurbishment (
    id INTEGER NOT NULL, -- TODO - check why the interface requires this to be NOT NULL
    date_time TEXT NOT NULL, -- TODO - check why the interface requires this to be NOT NULL
    refurbishment_cost REAL DEFAULT 0.0,
    FOREIGN KEY (id) REFERENCES ProcessInPlant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
)
