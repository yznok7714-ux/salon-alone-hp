/* ===================================
   csks Hair Salon - Main JavaScript
   =================================== */

document.addEventListener("DOMContentLoaded", () => {
  // ---------- Hero load animations ----------
  const heroMain = document.querySelector(".hero__image-main");
  const heroSub = document.querySelector(".hero__image-sub");
  const heroDecos = document.querySelectorAll(".hero__deco");

  if (heroMain) setTimeout(() => heroMain.classList.add("is-visible"), 300);
  if (heroSub) setTimeout(() => heroSub.classList.add("is-visible"), 600);
  heroDecos.forEach((deco) => {
    setTimeout(() => deco.classList.add("is-visible"), 800);
  });

  // ---------- Scroll reveal (IntersectionObserver) ----------
  const revealTargets = document.querySelectorAll(
    ".concept__image, .staff__image"
  );

  if (revealTargets.length > 0) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.2 }
    );
    revealTargets.forEach((el) => observer.observe(el));
  }

  // ---------- Header scroll shadow ----------
  const header = document.getElementById("header");
  window.addEventListener("scroll", () => {
    header.classList.toggle("header--scrolled", window.scrollY > 10);
  });

  // ---------- Hamburger menu ----------
  const hamburger = document.getElementById("hamburger");
  const nav = document.getElementById("nav");

  // Create overlay
  const overlay = document.createElement("div");
  overlay.classList.add("nav-overlay");
  document.body.appendChild(overlay);

  function toggleMenu() {
    const isOpen = nav.classList.toggle("is-open");
    hamburger.classList.toggle("is-active", isOpen);
    hamburger.setAttribute("aria-expanded", isOpen);
    document.body.classList.toggle("nav-open", isOpen);
    overlay.classList.toggle("is-visible", isOpen);
  }

  function closeMenu() {
    nav.classList.remove("is-open");
    hamburger.classList.remove("is-active");
    hamburger.setAttribute("aria-expanded", "false");
    document.body.classList.remove("nav-open");
    overlay.classList.remove("is-visible");
  }

  hamburger.addEventListener("click", toggleMenu);
  overlay.addEventListener("click", closeMenu);

  // Close menu when a nav link is clicked
  nav.querySelectorAll(".header__nav-link").forEach((link) => {
    link.addEventListener("click", closeMenu);
  });

  // ---------- Chatbot ----------
  const chatToggle = document.getElementById("chatbot-toggle");
  const chatWindow = document.getElementById("chatbot-window");
  const chatMessages = document.getElementById("chatbot-messages");
  const chatInput = document.getElementById("chatbot-input");
  const chatSend = document.getElementById("chatbot-send");
  const iconOpen = chatToggle.querySelector(".chatbot__toggle-icon--open");
  const iconClose = chatToggle.querySelector(".chatbot__toggle-icon--close");

  let chatHistory = [];
  let isSending = false;

  function toggleChat() {
    const isOpen = chatWindow.classList.toggle("is-open");
    iconOpen.style.display = isOpen ? "none" : "block";
    iconClose.style.display = isOpen ? "block" : "none";
    if (isOpen) chatInput.focus();
  }

  chatToggle.addEventListener("click", toggleChat);

  // 閉じるボタン（モバイル用）
  const chatClose = document.getElementById("chatbot-close");
  if (chatClose) {
    chatClose.addEventListener("click", function () {
      chatWindow.classList.remove("is-open");
      iconOpen.style.display = "block";
      iconClose.style.display = "none";
    });
  }

  function addMessage(text, sender) {
    const msg = document.createElement("div");
    msg.className = `chatbot__message chatbot__message--${sender}`;
    msg.innerHTML = `<div class="chatbot__message-content">${escapeHtml(text)}</div>`;
    chatMessages.appendChild(msg);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML.replace(/\n/g, "<br>");
  }

  function showTyping() {
    const typing = document.createElement("div");
    typing.className = "chatbot__typing";
    typing.id = "chatbot-typing";
    typing.innerHTML =
      '<div class="chatbot__typing-dot"></div><div class="chatbot__typing-dot"></div><div class="chatbot__typing-dot"></div>';
    chatMessages.appendChild(typing);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  function removeTyping() {
    const typing = document.getElementById("chatbot-typing");
    if (typing) typing.remove();
  }

  async function sendMessage() {
    const text = chatInput.value.trim();
    if (!text || isSending) return;

    isSending = true;
    chatSend.disabled = true;
    chatInput.value = "";

    addMessage(text, "user");
    chatHistory.push({ role: "user", content: text });

    showTyping();

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: chatHistory }),
      });

      const data = await res.json();
      removeTyping();

      if (data.reply) {
        addMessage(data.reply, "bot");
        chatHistory.push({ role: "assistant", content: data.reply });
      } else {
        addMessage(
          "申し訳ございません。現在応答できません。しばらくしてからお試しください。",
          "bot"
        );
      }
    } catch (err) {
      removeTyping();
      addMessage(
        "通信エラーが発生しました。しばらくしてからお試しください。",
        "bot"
      );
    }

    isSending = false;
    chatSend.disabled = false;
    chatInput.focus();
  }

  chatSend.addEventListener("click", sendMessage);
  chatInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.isComposing) sendMessage();
  });
});
