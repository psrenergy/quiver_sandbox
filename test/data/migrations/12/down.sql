PRAGMA user_version = 11;
PRAGMA foreign_keys = OFF;

ALTER TABLE Configuration ADD COLUMN hide_solver_log INTEGER DEFAULT 0;
ALTER TABLE Configuration ADD COLUMN solver INTEGER DEFAULT 0;

DROP TABLE ProcessInPlant_set_candidate_routes;

ALTER TABLE ProcessInPlant DROP COLUMN must_run;
ALTER TABLE ProcessInPlant DROP COLUMN year_of_activation;
