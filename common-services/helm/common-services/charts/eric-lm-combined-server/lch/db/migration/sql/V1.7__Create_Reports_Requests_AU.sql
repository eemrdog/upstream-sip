CREATE TABLE lch.reports_requests_AU (
    product_type  varchar(255) NOT NULL,
    license_id    varchar(30) NOT NULL,
    license_type  smallint NOT NULL,
    usage         bigint NOT NULL,
    require_end_report boolean DEFAULT FALSE NOT NULL
);
