PRAGMA user_version = 19;
PRAGMA foreign_keys = OFF;

-- Rename old tables
ALTER TABLE Route_vector_resource RENAME TO Route_vector_resource_old;
ALTER TABLE Route_vector_product RENAME TO Route_vector_product_old;
ALTER TABLE Process_vector_route RENAME TO Process_vector_route_old;
ALTER TABLE Plant_vector_topology RENAME TO Plant_vector_topology_old;

-- Create new Route_set_resource table
CREATE TABLE Route_set_resource (
    id INTEGER,
    material_resource INTEGER,
    resource_weight REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (id, material_resource, resource_weight)
) STRICT;

-- Create new Route_set_product table
CREATE TABLE Route_set_product (
    id INTEGER,
    material_product INTEGER,
    product_weight REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (id, material_product, product_weight)
) STRICT;

-- Create new Process_set_route table
CREATE TABLE Process_set_route (
    id INTEGER,
    route_id INTEGER,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (route_id) REFERENCES Route(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (id, route_id)
) STRICT;

-- Create new Plant_set_topology table
CREATE TABLE Plant_set_topology (
    id INTEGER,
    process_from INTEGER,
    process_to INTEGER,
    FOREIGN KEY (id) REFERENCES Plant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (process_from) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_to) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (id, process_from, process_to)
) STRICT;

-- Copy data from old tables
INSERT INTO Route_set_resource (id, material_resource, resource_weight)
SELECT id, material_resource, resource_weight
FROM Route_vector_resource_old;

INSERT INTO Route_set_product (id, material_product, product_weight)
SELECT id, material_product, product_weight
FROM Route_vector_product_old;

INSERT INTO Process_set_route (id, route_id)
SELECT id, route_id
FROM Process_vector_route_old;

INSERT INTO Plant_set_topology (id, process_from, process_to)
SELECT id, process_from, process_to
FROM Plant_vector_topology_old;

-- Drop old tables
DROP TABLE Route_vector_resource_old;
DROP TABLE Route_vector_product_old;
DROP TABLE Process_vector_route_old;
DROP TABLE Plant_vector_topology_old;

PRAGMA foreign_keys = ON;
