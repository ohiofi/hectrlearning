import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

const supabaseClient = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

const mylist = document.getElementById("mylist");
const textbox = document.getElementById("userQuestionBox");

// Context tracker for self-learning
let lastBotKeyword = "feeling"; // Initial seed keyword context

document.onkeydown = function(e) {
  if (e.key === "Enter") {
    e.preventDefault();
    submitQuestion();
  }
};

async function submitQuestion() {
  const userInput = textbox.value.trim();
  if (!userInput) return;

  addMessage(userInput, "from-me");
  textbox.value = "";

  // Call Supabase Database RPC
  const { data, error } = await supabase.rpc("process_chat", {
    p_user_input: userInput,
    p_last_bot_keyword: lastBotKeyword
  });

  if (error) {
    console.error("Error communicating with backend:", error);
    addMessage("Error processing message.", "to-me");
    return;
  }

  if (data.is_banned) {
    addMessage("Please keep messages appropriate.", "to-me");
    return;
  }

  // Update context keyword for the next message loop
  lastBotKeyword = data.next_keyword || null;

  addMessage(data.response, "to-me");
}

function addMessage(text, className) {
  const node = document.createElement("LI");
  node.textContent = text;
  node.classList.add(className);
  mylist.appendChild(node);
  setTimeout(() => window.scrollTo(0, document.body.scrollHeight - 300), 10);
}