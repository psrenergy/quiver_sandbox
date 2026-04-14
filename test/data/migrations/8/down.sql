PRAGMA user_version = 7;
PRAGMA foreign_keys = OFF;

-- Drop refurbishment_capacity_reduction column from ProcessInPlant
ALTER TABLE ProcessInPlant DROP COLUMN refurbishment_capacity_reduction;

-- Rename Route back to Recipe and restore material_ghg column
-- We need to recreate all tables that reference Route

-- Rename old tables
ALTER TABLE Route RENAME TO Route_old;
ALTER TABLE Route_vector_resource RENAME TO Route_vector_resource_old;
ALTER TABLE Route_vector_product RENAME TO Route_vector_product_old;
ALTER TABLE Process_vector_route RENAME TO Process_vector_route_old;

-- Create new Recipe table (renamed from Route, with material_ghg column)
CREATE TABLE Recipe (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    material_reference_product INTEGER,
    material_ghg INTEGER,
    FOREIGN KEY (material_reference_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_ghg) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

-- Create new Recipe vector tables
CREATE TABLE Recipe_vector_resource (
    id INTEGER,
    vector_index INTEGER,
    material_resource INTEGER,
    resource_weight REAL NOT NULL,
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Recipe(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Recipe_vector_product (
    id INTEGER,
    vector_index INTEGER,
    material_product INTEGER,
    product_weight REAL NOT NULL,
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Recipe(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Create new Process_vector_recipe table (renamed from Process_vector_route)
CREATE TABLE Process_vector_recipe (
    id INTEGER,
    vector_index INTEGER,
    recipe_id INTEGER,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Copy data from old tables and attempt to restore material_ghg
-- Set material_ghg to materials that have has_co2e_emission = 1
INSERT INTO Recipe (id, label, material_reference_product, material_ghg)
SELECT
    id,
    label,
    material_reference_product,
    (SELECT id FROM Material WHERE has_co2e_emission = 1 LIMIT 1)
FROM Route_old;

INSERT INTO Recipe_vector_resource (id, vector_index, material_resource, resource_weight)
SELECT id, vector_index, material_resource, resource_weight
FROM Route_vector_resource_old;

INSERT INTO Recipe_vector_product (id, vector_index, material_product, product_weight)
SELECT id, vector_index, material_product, product_weight
FROM Route_vector_product_old;

INSERT INTO Process_vector_recipe (id, vector_index, recipe_id)
SELECT id, vector_index, route_id
FROM Process_vector_route_old;

-- Drop old tables
DROP TABLE Process_vector_route_old;
DROP TABLE Route_vector_product_old;
DROP TABLE Route_vector_resource_old;
DROP TABLE Route_old;

-- Drop new columns from Material table
ALTER TABLE Material DROP COLUMN has_co2e_emission;
ALTER TABLE Material DROP COLUMN co2e_factor;

PRAGMA foreign_keys = ON;
