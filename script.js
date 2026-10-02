import { createClient } from '@supabase/supabase-js';

// 1. Initialize Supabase Client
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

// 2. DOM Elements
const chatForm = document.querySelector('#chat-form');
const userInputEl = document.querySelector('#user-input');
const chatWindow = document.querySelector('#chat-window');

// 3. Context Tracker for Self-Learning
let lastBotKeyword = 'welcome';

// 4. Initial Greeting on Load
async function triggerInitialGreeting() {
  try {
    const { data, error } = await supabase.rpc('process_chat', {
      p_user_input: 'hello',
      p_last_bot_keyword: 'welcome'
    });

    if (error) throw error;

    const result = Array.isArray(data) ? data[0] : data;

    if (result && result.next_keyword) {
      lastBotKeyword = result.next_keyword;
    }

    renderMessage(result ? result.response : 'Hello! I am HECT-R. How are you?', 'bot');

  } catch (err) {
    console.error('Error fetching initial greeting:', err);
    renderMessage('Hello! I am HECT-R. How are you?', 'bot');
  }
}

// Execute initial greeting when app starts
triggerInitialGreeting();

// 5. Handle User Submissions
async function handleUserMessage(userInput) {
  if (!userInput.trim()) return;

  try {
    const { data, error } = await supabase.rpc('process_chat', {
      p_user_input: userInput,
      p_last_bot_keyword: lastBotKeyword
    });

    if (error) throw error;

    const result = Array.isArray(data) ? data[0] : data;

    if (result && result.next_keyword) {
      lastBotKeyword = result.next_keyword;
    }

    renderMessage(result ? result.response : 'Sorry, I got confused.', 'bot');

  } catch (err) {
    console.error('Error communicating with HECT-R:', err);
    renderMessage('Sorry, something went wrong on my end.', 'bot');
  }
}

// 6. Form Event Listener
chatForm.addEventListener('submit', (e) => {
  e.preventDefault();
  const text = userInputEl.value;
  
  renderMessage(text, 'user');
  userInputEl.value = '';
  
  handleUserMessage(text);
});

// 7. UI Render Helper
function renderMessage(text, sender) {
  const msg = document.createElement('div');
  msg.className = `message ${sender}`;
  msg.textContent = text;
  chatWindow.appendChild(msg);
  
  window.scrollTo({
    top: document.body.scrollHeight,
    behavior: 'smooth'
  });
}