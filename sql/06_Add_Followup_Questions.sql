-- 06_Add_Followup_Questions.sql

INSERT INTO dictionary (keyword, responses)
VALUES ('followup', ARRAY[
    'How is the weather today?',
    'Do you know how a chatbot works?',
    'What should we discuss next?',
    'How are you feeling?',
    'Can you tell me more?',
    'What''s been the highlight of your week so far?',
    'Have you learned anything cool recently?',
    'If you could be anywhere right now, where would you go?',
    'What kind of projects are you working on lately?',
    'Are you more of a morning person or a night owl?',
    'What''s your go-to way to unwind after a long day?',
    'Is there a topic you could talk about for hours?',
    'Have you watched or read anything good lately?',
    'What''s a random fact that always blows your mind?',
    'If you could instantly master any skill, what would it be?'
])
ON CONFLICT (keyword) DO UPDATE 
SET responses = (
    SELECT array_agg(DISTINCT elem) 
    FROM unnest(dictionary.responses || EXCLUDED.responses) AS elem
);