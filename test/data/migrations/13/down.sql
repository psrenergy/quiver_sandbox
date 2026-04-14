PRAGMA user_version = 12;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration DROP COLUMN num_extra_years_in_simulation;

CREATE TABLE Storage(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    material_id INTEGER,
    initial_storage REAL NOT NULL DEFAULT 0.0,
    min_storage REAL NOT NULL DEFAULT 0.0,
    max_storage REAL NOT NULL,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_id) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;
