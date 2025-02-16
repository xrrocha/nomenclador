\timing on
\set echo all
\set on_error_stop on

\o esquema.log

CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

CREATE OR REPLACE FUNCTION distancia_edicion(a TEXT, b TEXT) RETURNS REAL AS
$$
    SELECT levenshtein(a, b)::REAL / GREATEST(LENGTH(a), LENGTH(b));
$$
    LANGUAGE SQL;

\o
\q
