PRAGMA user_version = 12;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration DROP COLUMN hide_solver_log;
ALTER TABLE Configuration DROP COLUMN solver;

CREATE TABLE ProcessInPlant_set_candidate_routes (
    id INTEGER,
    route_id INTEGER,
    adaptation_cost REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES ProcessInPlant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (route_id) REFERENCES Route(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (id, route_id, adaptation_cost)
) STRICT;

ALTER TABLE ProcessInPlant ADD COLUMN must_run INTEGER NOT NULL DEFAULT 0;
ALTER TABLE ProcessInPlant ADD COLUMN year_of_activation INTEGER;
