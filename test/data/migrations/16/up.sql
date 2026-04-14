PRAGMA user_version = 16;
PRAGMA foreign_keys = OFF;

ALTER TABLE Plant DROP COLUMN tax_over_sales;

PRAGMA foreign_keys = ON;
