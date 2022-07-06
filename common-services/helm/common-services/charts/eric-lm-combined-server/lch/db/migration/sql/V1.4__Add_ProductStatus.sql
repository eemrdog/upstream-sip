CREATE SEQUENCE lch.product_status_id_sequence INCREMENT BY 1;
CREATE TABLE lch.product_status (
    id               integer NOT NULL DEFAULT NEXTVAL('lch.product_status_id_sequence'),
    product_type     varchar(255) NOT NULL,
    customer_id      varchar(255) NOT NULL,
    swlt_id          varchar(255) NOT NULL,
    operational_mode smallint NOT NULL,
    autonomous_start bigint,
    PRIMARY KEY (id)
);
