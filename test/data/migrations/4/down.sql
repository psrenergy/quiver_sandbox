PRAGMA user_version = 3;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration DROP COLUMN discount_rate;

DROP TABLE Process_time_series_parameters;

CREATE TABLE Material_time_series_demand (
    id INTEGER,
    date_time TEXT,
    demand REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Material(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT;

INSERT INTO Material_time_series_demand (id, date_time, demand)
SELECT id, date_time, demand
FROM Material_time_series_parameters;

DROP TABLE Material_time_series_parameters;

PRAGMA foreign_keys = ON;
