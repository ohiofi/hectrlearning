-- 02_security_and_chat_logic.sql

-- 1. Security Policies
CREATE POLICY "Public read dictionary" ON dictionary FOR SELECT USING (true);
REVOKE ALL ON banlist FROM anon, authenticated;

-- 2. Baseline Seed Data
INSERT INTO dictionary (keyword, responses) VALUES
('default', ARRAY[
    'Sorry, I''m not quite sure. How are you?',
    'Sorry, I don''t know what to say. How are you?',
    'Sorry, I don''t understand. How are you?'
]),
('welcome', ARRAY[
    'Howdy! How are you?',
    'Hello! How are you today?',
    'Good day. How are you?'
]),
('feeling', ARRAY[
    'How are you feeling today?'
]),
('hi', ARRAY[
    'Howdy partner! I''m HECT-R. How are you?',
    'Hi, how are you? My name is HECT-R.',
    'Oh, hi...HECT-R here. How are you?'
]),
('hello', ARRAY[
    'Hi, how are you? I''m HECT-R.',
    'Oh, hi! HECT-R here. How are you?'
]),
('bye', ARRAY[
    'See you later alligator...',
    'Sweet dreams and flying machines!',
    'Peace out! Toodaloo Kangaroo!'
])
ON CONFLICT (keyword) DO NOTHING;

-- 3. Stored Procedure
CREATE OR REPLACE FUNCTION process_chat(
    p_user_input TEXT,
    p_last_bot_keyword TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_cleaned_input TEXT;
    v_is_banned BOOLEAN := FALSE;
    v_matched_responses TEXT[] := '{}';
    v_selected_response TEXT;
    v_next_keyword TEXT := NULL;
BEGIN
    v_cleaned_input := LOWER(TRIM(p_user_input));

    SELECT EXISTS (
        SELECT 1 FROM banlist 
        WHERE v_cleaned_input ~* ('\y' || word || '\y')
    ) INTO v_is_banned;

    IF v_is_banned THEN
        RETURN jsonb_build_object(
            'response', 'Please keep messages appropriate.',
            'is_banned', TRUE,
            'next_keyword', p_last_bot_keyword
        );
    END IF;

    IF p_last_bot_keyword IS NOT NULL AND CHAR_LENGTH(v_cleaned_input) > 0 THEN
        INSERT INTO dictionary (keyword, responses)
        VALUES (LOWER(p_last_bot_keyword), ARRAY[p_user_input])
        ON CONFLICT (keyword) 
        DO UPDATE SET responses = array_append(dictionary.responses, p_user_input)
        WHERE NOT (dictionary.responses @> ARRAY[p_user_input]);
    END IF;

    SELECT array_agg(resp) INTO v_matched_responses
    FROM (
        SELECT unnest(responses) AS resp, keyword
        FROM dictionary
        WHERE v_cleaned_input LIKE '%' || keyword || '%'
    ) sub;

    IF v_matched_responses IS NULL OR cardinality(v_matched_responses) = 0 THEN
        SELECT responses INTO v_matched_responses FROM dictionary WHERE keyword = 'default';
    END IF;

    v_selected_response := v_matched_responses[1 + floor(random() * cardinality(v_matched_responses))::int];

    SELECT keyword INTO v_next_keyword
    FROM dictionary
    WHERE v_cleaned_input LIKE '%' || keyword || '%'
    LIMIT 1;

    RETURN jsonb_build_object(
        'response', v_selected_response,
        'is_banned', FALSE,
        'next_keyword', COALESCE(v_next_keyword, p_last_bot_keyword)
    );
END;
$$;