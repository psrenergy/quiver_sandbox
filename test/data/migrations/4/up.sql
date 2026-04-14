PRAGMA user_version = 4;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN discount_rate REAL DEFAULT 0.0;

CREATE TABLE Process_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    global_investment_limit REAL,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

CREATE TABLE Material_time_series_parameters (
    id INTEGER,
    date_time TEXT,
    demand REAL,
    global_buy_limit REAL,
    FOREIGN KEY (id) REFERENCES Material(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

INSERT INTO Material_time_series_parameters (id, date_time, demand)
SELECT id, date_time, demand
FROM Material_time_series_demand;

DROP TABLE Material_time_series_demand;

PRAGMA foreign_keys = ON;
