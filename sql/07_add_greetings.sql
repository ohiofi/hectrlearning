-- 07_add_greetings.sql

INSERT INTO dictionary (keyword, responses)
VALUES 
(
  'hi', 
  ARRAY[
    'Howdy partner! I''m HECT-R. How are you?',
    'Hi, how are you? My name is HECT-R.',
    'Oh, hi...HECT-R here. How are you?',
    'I''m HECT-R. How are you?',
    'Hi I’m HECT-R. How are you?',
    'Hey I’m HECT-R. How are you?',
    'Hello I’m HECT-R. How are you?',
    'Howdy, I’m HECT-R. How are you?',
    'Well hello! I’m HECT-R. How are you?',
    'Hello there. I’m HECT-R. How are you?',
    'Hola Amigo! Soy HECT-R. How are you?',
    'Good day my citizens. I''m HECT-R How are you?',
    'Muy buenos! Soy HECT-R. How are you?',
    'Buenos dias! Soy HECT-R. How are you?',
    'Good morning. I''m HECT-R. How are you?',
    'What''s up bro? I''m HECT-R. How are you?'
  ]
),
(
  'hello',
  ARRAY[
    'Hi, how are you? I''m HECT-R.',
    'Oh, hi! HECT-R here. How are you?',
    'I''m HECT-R. How are you?',
    'Hi I am HECT-R. How are you?',
    'Hi I’m HECT-R. How are you?',
    'Hey, I’m HECT-R. How are you?',
    'Hello I’m HECT-R. How are you?',
    'Howdy, I’m HECT-R. How are you?',
    'Well hello! I’m HECT-R. How are you?',
    'Hello there. I’m HECT-R. How are you?',
    'Hola Amigo! Soy HECT-R. How are you?',
    'Good day my citizens. I''m HECT-R How are you?',
    'Muy buenos! Soy HECT-R. How are you?',
    'Buenos dias! Soy HECT-R. How are you?',
    'Sup boss! I''m HECT-R. How are you?',
    'Good morning. I''m HECT-R. How are you?',
    'What''s up bro? I''m HECT-R. How are you?'
  ]
)
ON CONFLICT (keyword) DO UPDATE 
SET responses = EXCLUDED.responses;