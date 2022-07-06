CREATE SEQUENCE lch.application_id_sequence INCREMENT BY 1;
CREATE TABLE lch.license_application_id (
    id            bigint NOT NULL DEFAULT NEXTVAL('lch.application_id_sequence'),
    application_id  varchar(255) NOT NULL
);