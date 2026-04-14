PRAGMA user_version = 7;
PRAGMA foreign_keys = OFF;

-- Add substitution_type column
ALTER TABLE ProcessInPlant ADD COLUMN substitution_type INTEGER;
-- Update substitution_type based on existing columns
UPDATE ProcessInPlant
SET substitution_type = 0
WHERE status = 1
  AND processinplant_substitution IS NOT NULL;

-- Add year_of_previous_refurbishment column
ALTER TABLE ProcessInPlant ADD COLUMN year_of_previous_refurbishment INTEGER;

-- Add capacity expansion columns to ProcessInPlant
ALTER TABLE ProcessInPlant ADD COLUMN capacity_expansion_reference_capacity REAL;
ALTER TABLE ProcessInPlant ADD COLUMN capacity_expansion_scale_factor REAL;

-- Calculate year_of_previous_refurbishment from years_since_last_refurbishment
-- the previous refurbishment year is:
-- initial_year - years_since_last_refurbishment
UPDATE ProcessInPlant
SET year_of_previous_refurbishment = (
    SELECT c.initial_year - ProcessInPlant.years_since_last_refurbishment
    FROM Configuration c
    LIMIT 1
)
WHERE (SELECT COUNT(*) FROM ProcessInPlant) > 0
  AND ProcessInPlant.years_since_last_refurbishment > 0;

-- Migrate first element of capacity expansion parameters from time series to ProcessInPlant
UPDATE ProcessInPlant
SET capacity_expansion_reference_capacity = (
    SELECT capacity_expansion_reference_capacity
    FROM ProcessInPlant_time_series_parameters
    WHERE ProcessInPlant_time_series_parameters.id = ProcessInPlant.id
    ORDER BY date_time
    LIMIT 1
),
capacity_expansion_scale_factor = (
    SELECT capacity_expansion_scale_factor
    FROM ProcessInPlant_time_series_parameters
    WHERE ProcessInPlant_time_series_parameters.id = ProcessInPlant.id
    ORDER BY date_time
    LIMIT 1
);

-- Drop the old years_since_last_refurbishment column
ALTER TABLE ProcessInPlant DROP COLUMN years_since_last_refurbishment;

-- Drop capacity expansion columns from time series parameters
ALTER TABLE ProcessInPlant_time_series_parameters DROP COLUMN capacity_expansion_reference_capacity;
ALTER TABLE ProcessInPlant_time_series_parameters DROP COLUMN capacity_expansion_scale_factor;

-- Add refurbishment_cost column to ProcessInPlant_time_series_parameters
ALTER TABLE ProcessInPlant_time_series_parameters ADD COLUMN refurbishment_cost REAL;

-- Migrate refurbishment_cost data from ProcessInPlant_time_series_refurbishment to ProcessInPlant_time_series_parameters
INSERT INTO ProcessInPlant_time_series_parameters (id, date_time, refurbishment_cost, investment_cost, operational_cost, capacity_expansion_reference_cost)
SELECT
    r.id,
    r.date_time,
    r.refurbishment_cost,
    p.investment_cost,
    p.operational_cost,
    p.capacity_expansion_reference_cost
FROM ProcessInPlant_time_series_refurbishment r
LEFT JOIN ProcessInPlant_time_series_parameters p ON r.id = p.id AND r.date_time = p.date_time
WHERE NOT EXISTS (
    SELECT 1 FROM ProcessInPlant_time_series_parameters
    WHERE id = r.id AND date_time = r.date_time
);

-- Update existing rows in ProcessInPlant_time_series_parameters with refurbishment_cost
UPDATE ProcessInPlant_time_series_parameters
SET refurbishment_cost = (
    SELECT refurbishment_cost
    FROM ProcessInPlant_time_series_refurbishment r
    WHERE r.id = ProcessInPlant_time_series_parameters.id
      AND r.date_time = ProcessInPlant_time_series_parameters.date_time
)
WHERE EXISTS (
    SELECT 1 FROM ProcessInPlant_time_series_refurbishment r
    WHERE r.id = ProcessInPlant_time_series_parameters.id
      AND r.date_time = ProcessInPlant_time_series_parameters.date_time
);

-- Drop the ProcessInPlant_time_series_refurbishment table
DROP TABLE ProcessInPlant_time_series_refurbishment;

-- Convert investment_cost and refurbishment_cost to be relative to max_capacity
-- Divide by max_capacity to make them per-unit-capacity values
UPDATE ProcessInPlant_time_series_parameters
SET investment_cost = investment_cost / (
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
SET refurbishment_cost = refurbishment_cost / (
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

-- Create new unified Market table
-- type: Market_type enum (BUY = 0, SELL = 1)
CREATE TABLE Market (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    material_id INTEGER,
    type INTEGER NOT NULL,  -- Market_type: BUY = 0, SELL = 1
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_id) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- Create new unified Market_time_series_parameters table
CREATE TABLE Market_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    price REAL NOT NULL,
    min_limit REAL,
    max_limit REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Market(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

-- Migrate InputMarket to Market (type = 0 for buy)
INSERT INTO Market (id, label, plant_id, material_id, type)
SELECT id, label, plant_id, material_resource, 0
FROM InputMarket;

-- Migrate OutputMarket to Market (type = 1 for sell)
INSERT INTO Market (id, label, plant_id, material_id, type)
SELECT
    (SELECT MAX(id) FROM Market) + ROW_NUMBER() OVER (ORDER BY id),
    label,
    plant_id,
    material_product,
    1
FROM OutputMarket;

-- Migrate InputMarket_time_series_parameters to Market_time_series_parameters
INSERT INTO Market_time_series_parameters (id, date_time, price, min_limit, max_limit)
SELECT id, date_time, buy_cost, buy_min_limit, buy_max_limit
FROM InputMarket_time_series_parameters;

-- Migrate OutputMarket_time_series_parameters to Market_time_series_parameters
INSERT INTO Market_time_series_parameters (id, date_time, price, min_limit, max_limit)
SELECT
    m.id,
    omtp.date_time,
    omtp.sell_price,
    omtp.sell_min_limit,
    omtp.sell_max_limit
FROM OutputMarket_time_series_parameters omtp
JOIN OutputMarket om ON omtp.id = om.id
JOIN Market m ON m.label = om.label AND m.type = 1;

-- Drop old tables
DROP TABLE InputMarket_time_series_parameters;
DROP TABLE OutputMarket_time_series_parameters;
DROP TABLE InputMarket;
DROP TABLE OutputMarket;

PRAGMA foreign_keys = ON;
