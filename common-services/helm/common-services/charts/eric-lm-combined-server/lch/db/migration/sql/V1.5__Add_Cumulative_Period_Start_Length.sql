ALTER TABLE lch.license_keys
ADD COLUMN cumulative_period_start SMALLINT,
ADD COLUMN cumulative_period_length SMALLINT;
