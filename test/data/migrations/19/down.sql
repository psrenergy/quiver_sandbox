PRAGMA user_version = 18;
PRAGMA foreign_keys = OFF;

-- Rename new tables
ALTER TABLE Route_set_resource RENAME TO Route_set_resource_old;
ALTER TABLE Route_set_product RENAME TO Route_set_product_old;
ALTER TABLE Process_set_route RENAME TO Process_set_route_old;
ALTER TABLE Plant_set_topology RENAME TO Plant_set_topology_old;

-- Recreate old Route_vector_resource table
CREATE TABLE Route_vector_resource (
    id INTEGER,
    vector_index INTEGER,
    material_resource INTEGER,
    resource_weight REAL NOT NULL,
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Recreate old Route_vector_product table
CREATE TABLE Route_vector_product (
    id INTEGER,
    vector_index INTEGER,
    material_product INTEGER,
    product_weight REAL NOT NULL,
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Recreate old Process_vector_route table
CREATE TABLE Process_vector_route (
    id INTEGER,
    vector_index INTEGER,
    route_id INTEGER,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (route_id) REFERENCES Route(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Recreate old Plant_vector_topology table
CREATE TABLE Plant_vector_topology (
    id INTEGER,
    vector_index INTEGER,
    process_from INTEGER,
    process_to INTEGER,
    FOREIGN KEY (id) REFERENCES Plant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (process_from) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_to) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Copy data from new tables with generated vector_index
INSERT INTO Route_vector_resource (id, vector_index, material_resource, resource_weight)
SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY material_resource) - 1, material_resource, resource_weight
FROM Route_set_resource_old;

INSERT INTO Route_vector_product (id, vector_index, material_product, product_weight)
SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY material_product) - 1, material_product, product_weight
FROM Route_set_product_old;

INSERT INTO Process_vector_route (id, vector_index, route_id)
SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY route_id) - 1, route_id
FROM Process_set_route_old;

INSERT INTO Plant_vector_topology (id, vector_index, process_from, process_to)
SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY process_from, process_to) - 1, process_from, process_to
FROM Plant_set_topology_old;

-- Drop new tables
DROP TABLE Route_set_resource_old;
DROP TABLE Route_set_product_old;
DROP TABLE Process_set_route_old;
DROP TABLE Plant_set_topology_old;

PRAGMA foreign_keys = ON;
