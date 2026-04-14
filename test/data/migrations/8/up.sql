PRAGMA user_version = 8;
PRAGMA foreign_keys = OFF;

-- Add new columns to Material table
ALTER TABLE Material ADD COLUMN has_co2e_emission INTEGER NOT NULL DEFAULT 0;
ALTER TABLE Material ADD COLUMN co2e_factor REAL;

-- Set has_co2e_emission = 1 and co2e_factor = 1.0 for materials referenced as material_ghg in Recipe table
UPDATE Material
SET has_co2e_emission = 1,
    co2e_factor = 1.0
WHERE id IN (
    SELECT DISTINCT material_ghg
    FROM Recipe
    WHERE material_ghg IS NOT NULL
);

-- Rename Recipe to Route and drop material_ghg column
-- We need to recreate all tables that reference Recipe

-- Rename old tables
ALTER TABLE Recipe RENAME TO Recipe_old;
ALTER TABLE Recipe_vector_resource RENAME TO Recipe_vector_resource_old;
ALTER TABLE Recipe_vector_product RENAME TO Recipe_vector_product_old;
ALTER TABLE Process_vector_recipe RENAME TO Process_vector_recipe_old;

-- Create new Route table (renamed from Recipe, without material_ghg column)
CREATE TABLE Route (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    material_reference_product INTEGER,
    FOREIGN KEY (material_reference_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- Create new Route vector tables
CREATE TABLE Route_vector_resource (
    id INTEGER,
    vector_index INTEGER,
    material_resource INTEGER,
    resource_weight REAL NOT NULL,
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Route_vector_product (
    id INTEGER,
    vector_index INTEGER,
    material_product INTEGER,
    product_weight REAL NOT NULL,
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Create new Process_vector_route table (renamed from Process_vector_recipe)
CREATE TABLE Process_vector_route (
    id INTEGER,
    vector_index INTEGER,
    route_id INTEGER,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (route_id) REFERENCES Route(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Copy data from old tables (excluding material_ghg from Recipe)
INSERT INTO Route (id, label, material_reference_product)
SELECT id, label, material_reference_product
FROM Recipe_old;

INSERT INTO Route_vector_resource (id, vector_index, material_resource, resource_weight)
SELECT id, vector_index, material_resource, resource_weight
FROM Recipe_vector_resource_old;

INSERT INTO Route_vector_product (id, vector_index, material_product, product_weight)
SELECT id, vector_index, material_product, product_weight
FROM Recipe_vector_product_old;

INSERT INTO Process_vector_route (id, vector_index, route_id)
SELECT id, vector_index, recipe_id
FROM Process_vector_recipe_old;

-- Drop old tables
DROP TABLE Process_vector_recipe_old;
DROP TABLE Recipe_vector_product_old;
DROP TABLE Recipe_vector_resource_old;
DROP TABLE Recipe_old;

-- Add refurbishment_capacity_reduction column to ProcessInPlant
ALTER TABLE ProcessInPlant ADD COLUMN refurbishment_capacity_reduction REAL NOT NULL DEFAULT 100.0;

PRAGMA foreign_keys = ON;
