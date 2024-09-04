-- Preview data from otodom_data_dump
SELECT * FROM otodom_data_dump
LIMIT 50;

-- Preview data from otodom_data_translated
SELECT * FROM otodom_data_translated
LIMIT 20;

------------------------------------------------------------------------------------------------

-- Cleaning Surface Column

-- Add a new column for cleaned surface
ALTER TABLE otodom_data_dump ADD COLUMN surface_cleaned FLOAT;

-- Update the cleaned surface column to convert to numerical values
UPDATE otodom_data_dump
SET surface_cleaned = TRY_TO_DOUBLE(REPLACE(REPLACE(REPLACE(SURFACE, 'm²', ''), 'м²', ''), ',', '.'), '9999.99');

------------------------------------------------------------------------------------------------

-- Cleaning and Translating FORM_OF_PROPERTY Column

-- Check distinct values for FORM_OF_PROPERTY
SELECT form_of_property, COUNT(form_of_property) 
FROM otodom_data_dump
GROUP BY form_of_property;

-- Translate FORM_OF_PROPERTY values to English
UPDATE otodom_data_dump
SET FORM_OF_PROPERTY = CASE
    WHEN FORM_OF_PROPERTY = 'pełna własność' THEN 'ownership'
    WHEN FORM_OF_PROPERTY = 'spółdzielcze wł. prawo do lokalu' THEN 'co-ownership'
    WHEN FORM_OF_PROPERTY = 'udział' THEN 'share'
    WHEN FORM_OF_PROPERTY = 'użytkowanie wieczyste / dzierżawa' THEN 'lease'
    ELSE FORM_OF_PROPERTY
END;

------------------------------------------------------------------------------------------------

-- Cleaning and Translating PRICE Column

-- Check distinct values for PRICE
SELECT DISTINCT price 
FROM otodom_data_dump;

-- Add a new column for cleaned prices
ALTER TABLE otodom_data_dump ADD COLUMN price_cleaned FLOAT;

-- Update the cleaned price column to convert to numerical values
UPDATE otodom_data_dump
SET price_cleaned = TRY_TO_NUMBER(REPLACE(REPLACE(REPLACE(price, 'PLN', ''), '€', ''), ' ', ''), '999,999,999.99');

------------------------------------------------------------------------------------------------

-- Extracting City Name from Location

-- Add a new column for city
ALTER TABLE otodom_data_dump ADD COLUMN city STRING;

-- Update the city column based on location patterns
UPDATE otodom_data_dump
SET city = CASE
    -- When the 3rd part is a known district/region, use the 2nd part as the city
    WHEN SPLIT_PART(location, ',', 3) IN (
        'Bemowo', 'Jeżyce', 'Bronowice', 'Sianów', 'Stare Miasto', 'Stare Polesie', 
        'Polesie', 'Śródmieście', 'Krzyki', 'Widzew', 'Rumia', 'Borek Fałęcki', 
        'Zaspa-Rozstaje', 'Bieżanów-Prokocim'
    ) THEN SPLIT_PART(location, ',', 2)
    
    -- When the 2nd part is a known district/region, use the 3rd part as the city
    WHEN SPLIT_PART(location, ',', 2) IN (
        'ul. Wojsławska', 'ul. Stanisława Szczepanowskiego', 'ul. Słowiańska', 
        'ul. Lwowska', 'ul. Grunwaldzka', 'ul. 1 Maja', 'ul. Lipowa', 
        'ul. Bohaterów Warszawy', 'Przedmieście Świdnickie', 'ul. Marii Skłodowskiej-Curie', 
        'ul. Za Groblą', 'ul. Mieczysława Romanowskiego', 'ul. Tatarska 4', 
        'ul. Młodkowskiego', 'ul. Oswobodzenia', 'ul. Zachodnia', 'ul. Stefana Batorego', 
        'ul. Tarnopolska', 'ul. Lubostroń', 'ul. Bagno 5', 'os. Bolesława Chrobrego', 
        'ul. Brzozowa', 'ul. Wigilijna', 'ul. Poznańska', 'Jana Kantego Federowicza', 
        'ul. Juliusza Słowackiego'
    ) THEN SPLIT_PART(location, ',', 4)

    -- Otherwise, use the 2nd part as the city
    ELSE SPLIT_PART(location, ',', 3)
END;

------------------------------------------------------------------------------------------------

-- Joining Tables

-- Create a new table with the joined data
CREATE OR REPLACE TABLE joined_otodom_data AS
SELECT 
    d.developer,
    d.description AS dump_description,
    d.form_of_property,
    d.is_for_sale,
    d.location,
    d.market,
    d.rooms,
    d.posting_id AS dump_posting_id,
    d.price,
    d.surface,
    d.date,
    d.title AS dump_title,
    d.url,
    d.price_cleaned,
    d.surface_cleaned,
    d.city,
    t.posting_id AS translated_posting_id,
    t.title_en AS translated_title,
    t.description_en AS translated_description
FROM 
    otodom_data_dump d
JOIN 
    otodom_data_translated t
ON 
    d.posting_id = t.posting_id
LIMIT 50;

------------------------------------------------------------------------------------------------

-- Preview the joined data
SELECT * FROM joined_otodom_data;