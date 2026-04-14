PRAGMA user_version = 9;
PRAGMA foreign_keys = OFF;

-- Add financing column to Configuration table
ALTER TABLE Configuration ADD COLUMN financing INTEGER DEFAULT 0;

-- Add tax columns to Plant table
ALTER TABLE Plant ADD COLUMN tax_over_sales REAL NOT NULL DEFAULT 0.0;
ALTER TABLE Plant ADD COLUMN tax_over_gross_income REAL NOT NULL DEFAULT 0.0;
ALTER TABLE Plant ADD COLUMN tax_over_net_income REAL NOT NULL DEFAULT 0.0;

-- Add financing columns to Process table
ALTER TABLE Process ADD COLUMN equity_share REAL DEFAULT 1.0;
ALTER TABLE Process ADD COLUMN disbursement_period INTEGER DEFAULT 1;
ALTER TABLE Process ADD COLUMN grace_period INTEGER DEFAULT 0;
ALTER TABLE Process ADD COLUMN amortization_period INTEGER DEFAULT 0;
ALTER TABLE Process ADD COLUMN fixed_rate REAL DEFAULT 0.0;
ALTER TABLE Process ADD COLUMN pay_interest_during_grace INTEGER DEFAULT 0;
ALTER TABLE Process ADD COLUMN depreciation_period INTEGER DEFAULT 0;

-- Create Process_vector_disbursement_schedule table
CREATE TABLE Process_vector_disbursement_schedule (
    id INTEGER,
    vector_index INTEGER,
    disbursement_share REAL,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

-- Create Process_vector_subsidy table
CREATE TABLE Process_vector_subsidy (
    id INTEGER,
    vector_index INTEGER,
    subsidy_share REAL,
    FOREIGN KEY (id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

PRAGMA foreign_keys = ON;
