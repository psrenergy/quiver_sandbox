PRAGMA user_version = 14;
PRAGMA foreign_keys = OFF;

CREATE TABLE Route_set_shared_technology (
    id INTEGER,
    route_id INTEGER,
    FOREIGN KEY (id) REFERENCES Route(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (route_id) REFERENCES Route(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (id, route_id)
) STRICT;
