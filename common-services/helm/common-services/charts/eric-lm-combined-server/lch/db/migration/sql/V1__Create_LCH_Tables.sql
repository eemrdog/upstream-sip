CREATE SEQUENCE lch.report_id_sequence INCREMENT BY 20;
CREATE TABLE lch.reports (
    id            bigint NOT NULL DEFAULT NEXTVAL('lch.report_id_sequence'),
    consumer_id   varchar(95) NOT NULL,
    product_type  varchar(255) NOT NULL,
    license_id    varchar(30) NOT NULL,
    capacity_type smallint NOT NULL,
    usage         bigint NOT NULL,
    PRIMARY KEY (id)
);

CREATE SEQUENCE lch.server_status_id_sequence INCREMENT BY 1;
CREATE TABLE lch.server_status (
    id               integer NOT NULL DEFAULT NEXTVAL('lch.server_status_id_sequence'),
    operational_mode smallint NOT NULL,
    autonomous_start bigint,
    PRIMARY KEY (id)
);

CREATE SEQUENCE lch.license_request_id_sequence INCREMENT BY 20;
CREATE TABLE lch.license_requests (
    id            bigint NOT NULL DEFAULT NEXTVAL('lch.license_request_id_sequence'),
    product_type  varchar(255) NOT NULL,
    license_id    varchar(30) NOT NULL,
    license_type  smallint NOT NULL,
    PRIMARY KEY (id)
);

CREATE SEQUENCE lch.license_key_id_sequence INCREMENT BY 20;
CREATE TABLE lch.license_keys (
    id            bigint NOT NULL DEFAULT NEXTVAL('lch.license_key_id_sequence'),
    product_type  varchar(255) NOT NULL,
    license_id    varchar(30) NOT NULL,
    license_type  smallint NOT NULL,
    key_start     bigint NOT NULL,
    key_stop      bigint,
    capacity      bigint,
    PRIMARY KEY (id)
);

CREATE TABLE lch.capacity_usages (
    product_type  varchar(255) NOT NULL,
    license_id    varchar(30) NOT NULL,
    unused_capacity bigint NOT NULL
);
