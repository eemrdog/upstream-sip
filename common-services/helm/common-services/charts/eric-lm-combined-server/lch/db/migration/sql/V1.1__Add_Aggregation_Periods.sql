ALTER TABLE lch.server_status
ADD COLUMN report_period_seconds BIGINT NOT NULL DEFAULT 50,
ADD COLUMN request_period_seconds BIGINT NOT NULL DEFAULT 3500;
