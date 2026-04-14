PRAGMA user_version = 8;
PRAGMA foreign_keys = OFF;

-- Drop Process vector tables
DROP TABLE Process_vector_subsidy;
DROP TABLE Process_vector_disbursement_schedule;

-- Drop financing columns from Process table
ALTER TABLE Process DROP COLUMN depreciation_period;
ALTER TABLE Process DROP COLUMN pay_interest_during_grace;
ALTER TABLE Process DROP COLUMN fixed_rate;
ALTER TABLE Process DROP COLUMN amortization_period;
ALTER TABLE Process DROP COLUMN grace_period;
ALTER TABLE Process DROP COLUMN disbursement_period;
ALTER TABLE Process DROP COLUMN equity_share;

-- Drop tax columns from Plant table
ALTER TABLE Plant DROP COLUMN tax_over_net_income;
ALTER TABLE Plant DROP COLUMN tax_over_gross_income;
ALTER TABLE Plant DROP COLUMN tax_over_sales;

-- Drop financing column from Configuration table
ALTER TABLE Configuration DROP COLUMN financing;

PRAGMA foreign_keys = ON;
