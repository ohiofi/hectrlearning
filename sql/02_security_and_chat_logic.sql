-- Query Name: 02_security_and_chat_logic.sql
-- Description: Configures RLS policies, access controls, and the process_chat stored procedure.

-- ==========================================
-- 1. ROW LEVEL SECURITY (RLS) & PRIVILEGES
-- ==========================================

-- Enable Row Level Security on both tables
ALTER TABLE dictionary ENABLE ROW LEVEL SECURITY;
ALTER TABLE banlist ENABLE ROW LEVEL SECURITY;

-- Allow public read access to the dictionary
DROP POLICY IF EXISTS "Public read dictionary" ON dictionary;
CREATE POLICY "Public read dictionary" ON dictionary 
    FOR SELECT TO public USING (true);

-- Restrict direct access to the moderation banlist
REVOKE ALL ON banlist FROM anon, authenticated, public;

-- Grant execution permissions for the stored procedure
GRANT EXECUTE ON FUNCTION process_chat(TEXT, TEXT) TO anon, authenticated, public;

-- ==========================================
-- 2. CORE CHAT LOGIC PROCEDURE
-- ==========================================

CREATE OR REPLACE FUNCTION process_chat(
    p_user_input TEXT,
    p_last_bot_keyword TEXT
)
RETURNS TABLE (
    response TEXT,
    next_keyword TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with creator privileges to bypass direct banlist/dictionary write restrictions
AS $$
DECLARE
    v_clean_input TEXT;
    v_clean_context TEXT;
    v_selected_response TEXT;
    v_next_keyword TEXT;
    v_is_banned BOOLEAN := FALSE;
BEGIN
    -- 1. Normalize inputs
    v_clean_input := lower(trim(p_user_input));
    v_clean_context := COALESCE(lower(trim(p_last_bot_keyword)), 'welcome');

    -- 2. Moderation Check: Scan input against banlist
    IF EXISTS (
        SELECT 1 FROM banlist 
        WHERE v_clean_input LIKE '%' || lower(phrase) || '%'
    ) THEN
        v_is_banned := TRUE;
    END IF;

    -- 3. Self-Learning Step: Update previous keyword array (Only if input is safe)
    IF NOT v_is_banned AND EXISTS (SELECT 1 FROM dictionary WHERE keyword = v_clean_context) THEN
        UPDATE dictionary 
        SET responses = (
            SELECT array_agg(DISTINCT elem) 
            FROM unnest(responses || ARRAY[p_user_input]) AS elem
        )
        WHERE keyword = v_clean_context;
    END IF;

    -- 4. Banned Input Guardrail Response
    IF v_is_banned THEN
        RETURN QUERY SELECT 
            'Please keep the conversation respectful and safe.'::TEXT, 
            'default'::TEXT;
        RETURN;
    END IF;

    -- 5. Matching Step: Find longest matching keyword inside user input
    SELECT keyword INTO v_next_keyword
    FROM dictionary
    WHERE v_clean_input LIKE '%' || keyword || '%'
    ORDER BY length(keyword) DESC
    LIMIT 1;

    -- 6. Auto-Seed Missing Keywords: Create new dictionary entry if unknown
    IF v_next_keyword IS NULL THEN
        v_next_keyword := v_clean_input;
        
        INSERT INTO dictionary (keyword, responses)
        VALUES (
            v_next_keyword, 
            ARRAY['That''s interesting! Tell me more.', 'I see. How does that make you feel?']
        )
        ON CONFLICT (keyword) DO NOTHING;
    END IF;

    -- 7. Response Selection: Pick a random string from the target keyword's array
    SELECT elem INTO v_selected_response
    FROM dictionary, unnest(responses) AS elem
    WHERE keyword = v_next_keyword
    ORDER BY random()
    LIMIT 1;

    -- Fallback safety check
    IF v_selected_response IS NULL THEN
        v_selected_response := 'Fascinating! Tell me more.';
    END IF;

    -- Return response payload to client
    RETURN QUERY SELECT v_selected_response, v_next_keyword;
END;
$$;