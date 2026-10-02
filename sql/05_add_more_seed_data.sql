-- Query Name: 05_Add_More_Seed_Data.sql

-- 1. Add BRAND NEW keywords (skips if they already exist)
INSERT INTO dictionary (keyword, responses) VALUES
('welcome', ARRAY[
    'Howdy! How are you?',
    'Hello! How are you today?',
    'Good day. How are you?'
]),
('feeling', ARRAY[
    'How are you feeling today?'
]),
('hello', ARRAY[
    'Hi, how are you? I''m HECT-R.',
    'Oh, hi! HECT-R here. How are you?'
]),
('bye', ARRAY[
    'See you later alligator...',
    'Sweet dreams and flying machines!',
    'Peace out! Toodaloo Kangaroo!'
]),
('thanks', ARRAY['You''re welcome!', 'Anytime!', 'No problem!']),
('help', ARRAY['I learn from what you say! Type anything to teach me.'])
ON CONFLICT (keyword) DO NOTHING;

-- 2. Append NEW responses to EXISTING keywords (merges arrays without duplicates)
INSERT INTO dictionary (keyword, responses) VALUES
('default', ARRAY[
    'I''m not sure about that context yet.',
    'Fascinating! Tell me more.',
    'Sorry, I''m not quite sure. How are you?',
    'Sorry, I don''t know what to say. How are you?',
    'Sorry, I don''t understand. How are you?'
]),
('hi', ARRAY[
    'Greetings!',
    'Hey there!',
    'Howdy partner! I''m HECT-R. How are you?',
    'Hi, how are you? My name is HECT-R.',
    'Oh, hi...HECT-R here. How are you?'
])
ON CONFLICT (keyword) 
DO UPDATE SET responses = (
    SELECT array_agg(DISTINCT elem) 
    FROM unnest(dictionary.responses || EXCLUDED.responses) AS elem
);