ALTER TABLE lch.server_status
ADD COLUMN report_period_peak_seconds BIGINT NOT NULL DEFAULT 50,
ADD COLUMN report_period_cumulative_seconds BIGINT NOT NULL DEFAULT 50,
DROP COLUMN IF EXISTS report_period_seconds;
