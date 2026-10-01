-- 01_create_tables.sql

CREATE TABLE dictionary (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    keyword TEXT UNIQUE NOT NULL,
    responses TEXT[] NOT NULL DEFAULT '{}'
);

CREATE TABLE banlist (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    word TEXT UNIQUE NOT NULL
);

CREATE INDEX idx_dictionary_keyword ON dictionary (keyword);
CREATE INDEX idx_banlist_word ON banlist (word);