\timing on
\set ECHO all
\set ON_ERROR_STOP on

\o escuelas.log

CREATE SCHEMA IF NOT EXISTS escuelas;
SET SEARCH_PATH TO escuelas, public;

DROP TABLE IF EXISTS escuelas;
CREATE TABLE escuelas (
    area   VARCHAR(6)       NOT NULL,
    nombre VARCHAR(48)      NOT NULL,
    codigo VARCHAR(5)       NOT NULL UNIQUE
);
\COPY escuelas FROM data/escuelas.tsv DELIMITER E'\t';

\o
\q
