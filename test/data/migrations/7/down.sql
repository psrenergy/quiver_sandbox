PRAGMA user_version = 6;
PRAGMA foreign_keys = OFF;

-- Recreate InputMarket table
CREATE TABLE InputMarket (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    material_resource INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- Recreate OutputMarket table
CREATE TABLE OutputMarket (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    material_product INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- Recreate InputMarket_time_series_parameters table
CREATE TABLE InputMarket_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    buy_cost REAL NOT NULL,
    buy_min_limit REAL,
    buy_max_limit REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES InputMarket(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

-- Recreate OutputMarket_time_series_parameters table
CREATE TABLE OutputMarket_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    sell_price REAL NOT NULL,
    sell_min_limit REAL,
    sell_max_limit REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES OutputMarket(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

-- Migrate Market data back to InputMarket (type = 0)
INSERT INTO InputMarket (id, label, plant_id, material_resource)
SELECT id, label, plant_id, material_id
FROM Market
WHERE type = 0;

-- Migrate Market data back to OutputMarket (type = 1)
INSERT INTO OutputMarket (id, label, plant_id, material_product)
SELECT id, label, plant_id, material_id
FROM Market
WHERE type = 1;

-- Migrate Market_time_series_parameters back to InputMarket_time_series_parameters
INSERT INTO InputMarket_time_series_parameters (id, date_time, buy_cost, buy_min_limit, buy_max_limit)
SELECT mtp.id, mtp.date_time, mtp.price, mtp.min_limit, mtp.max_limit
FROM Market_time_series_parameters mtp
JOIN Market m ON mtp.id = m.id
WHERE m.type = 0;

-- Migrate Market_time_series_parameters back to OutputMarket_time_series_parameters
INSERT INTO OutputMarket_time_series_parameters (id, date_time, sell_price, sell_min_limit, sell_max_limit)
SELECT mtp.id, mtp.date_time, mtp.price, mtp.min_limit, mtp.max_limit
FROM Market_time_series_parameters mtp
JOIN Market m ON mtp.id = m.id
WHERE m.type = 1;

-- Drop Market tables
DROP TABLE Market_time_series_parameters;
DROP TABLE Market;

-- Convert investment_cost and refurbishment_cost back to absolute values
-- Multiply by max_capacity to restore original absolute values
UPDATE ProcessInPlant_time_series_parameters
SET investment_cost = investment_cost * (
    SELECT max_capacity
    FROM ProcessInPlant
    WHERE ProcessInPlant.id = ProcessInPlant_time_series_parameters.id
)
WHERE EXISTS (
    SELECT 1 FROM ProcessInPlant
    WHERE ProcessInPlant.id = ProcessInPlant_time_series_parameters.id
      AND ProcessInPlant.max_capacity > 0
);

UPDATE ProcessInPlant_time_series_parameters
SET refurbishment_cost = refurbishment_cost * (
    SELECT max_capacity
    FROM ProcessInPlant
    WHERE ProcessInPlant.id = ProcessInPlant_time_series_parameters.id
)
WHERE refurbishment_cost IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM ProcessInPlant
    WHERE ProcessInPlant.id = ProcessInPlant_time_series_parameters.id
      AND ProcessInPlant.max_capacity > 0
);

-- Recreate ProcessInPlant_time_series_refurbishment table
CREATE TABLE ProcessInPlant_time_series_refurbishment (
    id INTEGER NOT NULL,
    date_time TEXT NOT NULL,
    refurbishment_cost REAL DEFAULT 0.0,
    FOREIGN KEY (id) REFERENCES ProcessInPlant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

-- Migrate refurbishment_cost data back to ProcessInPlant_time_series_refurbishment
INSERT INTO ProcessInPlant_time_series_refurbishment (id, date_time, refurbishment_cost)
SELECT id, date_time, refurbishment_cost
FROM ProcessInPlant_time_series_parameters
WHERE refurbishment_cost IS NOT NULL;

-- Drop refurbishment_cost column from ProcessInPlant_time_series_parameters
ALTER TABLE ProcessInPlant_time_series_parameters DROP COLUMN refurbishment_cost;

-- Add back capacity expansion columns to time series parameters
ALTER TABLE ProcessInPlant_time_series_parameters ADD COLUMN capacity_expansion_reference_capacity REAL;
ALTER TABLE ProcessInPlant_time_series_parameters ADD COLUMN capacity_expansion_scale_factor REAL;

-- Migrate capacity expansion parameters from ProcessInPlant to all time series entries
UPDATE ProcessInPlant_time_series_parameters
SET capacity_expansion_reference_capacity = (
    SELECT capacity_expansion_reference_capacity
    FROM ProcessInPlant
    WHERE ProcessInPlant.id = ProcessInPlant_time_series_parameters.id
),
capacity_expansion_scale_factor = (
    SELECT capacity_expansion_scale_factor
    FROM ProcessInPlant
    WHERE ProcessInPlant.id = ProcessInPlant_time_series_parameters.id
);

-- Drop capacity expansion columns from ProcessInPlant
ALTER TABLE ProcessInPlant DROP COLUMN capacity_expansion_reference_capacity;
ALTER TABLE ProcessInPlant DROP COLUMN capacity_expansion_scale_factor;

-- Add back years_since_last_refurbishment column
ALTER TABLE ProcessInPlant ADD COLUMN years_since_last_refurbishment INTEGER DEFAULT 0;

-- Calculate years_since_last_refurbishment from year_of_previous_refurbishment
-- the years since last refurbishment is:
-- initial_year - year_of_previous_refurbishment
-- Only run the update if ProcessInPlant has any rows
UPDATE ProcessInPlant
SET years_since_last_refurbishment =
    ((SELECT c.initial_year FROM Configuration c LIMIT 1) - ProcessInPlant.year_of_previous_refurbishment)
WHERE year_of_previous_refurbishment IS NOT NULL
  AND EXISTS (SELECT 1 FROM ProcessInPlant);

-- Drop year_of_previous_refurbishment column
ALTER TABLE ProcessInPlant DROP COLUMN year_of_previous_refurbishment;

-- Drop substitution_type column
ALTER TABLE ProcessInPlant DROP COLUMN substitution_type;

PRAGMA foreign_keys = ON;
