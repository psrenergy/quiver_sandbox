PRAGMA user_version = 15;
PRAGMA foreign_keys = OFF;

ALTER TABLE Plant ADD COLUMN tax_over_sales REAL NOT NULL DEFAULT 0.0;

PRAGMA foreign_keys = ON;
