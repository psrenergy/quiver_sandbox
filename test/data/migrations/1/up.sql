PRAGMA user_version = 1;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL DEFAULT "Configuration",
    initial_year INTEGER NOT NULL,
    final_year INTEGER NOT NULL,
    hide_solver_log INTEGER DEFAULT 0,
    solver INTEGER DEFAULT 0,
    lp_time_limit REAL DEFAULT 300.0,
    mip_gap_tolerance REAL DEFAULT 1e-4,
    monetary_unit TEXT,
    ghg_emission_unit TEXT
) STRICT;

CREATE TABLE Configuration_time_series_emissions (
    id INTEGER,
    date_time TEXT,
    emission_target REAL NOT NULL,
    emission_cost REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Configuration(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

CREATE TABLE Material (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    unit TEXT
) STRICT;

CREATE TABLE Material_time_series_demand (
    id INTEGER,
    date_time TEXT,
    demand REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Material(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

CREATE TABLE Recipe (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    material_reference_product INTEGER,
    material_ghg INTEGER,
    FOREIGN KEY (material_reference_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_ghg) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

CREATE TABLE Recipe_vector_resource (
    id INTEGER,
    vector_index INTEGER,
    material_resource INTEGER, -- resource used as input in the process
    resource_weight REAL NOT NULL, -- weight of resource in the process
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Recipe(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Recipe_vector_product (
    id INTEGER,
    vector_index INTEGER,
    material_product INTEGER, -- product produced by the process
    product_weight REAL NOT NULL, -- weight of output product in the process
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id) REFERENCES Recipe(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Process (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL
) STRICT;

CREATE TABLE Process_vector_recipe (
    id INTEGER,
    vector_index INTEGER,
    recipe_id INTEGER,
    FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    latitude REAL,
    longitude REAL
) STRICT;

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

CREATE TABLE InputMarket (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    material_resource INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_resource) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

CREATE TABLE InputMarket_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    buy_cost REAL NOT NULL,
    buy_min_limit REAL, -- default 0 in Julia
    buy_max_limit REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES InputMarket(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

CREATE TABLE OutputMarket (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    material_product INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (material_product) REFERENCES Material(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

CREATE TABLE OutputMarket_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    sell_price REAL NOT NULL,
    sell_min_limit REAL, -- default 0 in Julia
    sell_max_limit REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES OutputMarket(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

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

CREATE TABLE ProcessInPlant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    process_id INTEGER,
    min_capacity REAL DEFAULT 0.0, -- default 0 in Julia
    max_capacity REAL NOT NULL,
    max_expansion REAL DEFAULT 0.0, -- default 0 in Julia
    implementation_delay INTEGER DEFAULT 0, -- default 0 in Julia
    expansion_delay INTEGER DEFAULT 0, -- default 0 in Julia
    status INTEGER NOT NULL,
    process_substitution INTEGER,
    FOREIGN KEY (plant_id) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_id) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (process_substitution) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

CREATE TABLE ProcessInPlant_time_series_parameters (
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
