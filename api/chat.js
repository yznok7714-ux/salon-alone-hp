// api/chat.js

export default async function handler(req, res) {
  // POST 以外は弾く
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method Not Allowed" });
    return;
  }

  try {
    const apiKey = process.env.ANTHROPIC_API_KEY;

    if (!apiKey) {
      console.error("ANTHROPIC_API_KEY is not set");
      res.status(500).json({ error: "Missing API key" });
      return;
    }

    // リクエストボディから messages を受け取る
    const { messages } = req.body || {};

    if (!messages || !Array.isArray(messages)) {
      res.status(400).json({ error: "Invalid request body" });
      return;
    }

    // Claude API にリクエスト
    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-2.1", // ★ここだけ後で変えてもOK
        max_tokens: 512,
        messages: messages.map((m) => ({
          role: m.role === "assistant" ? "assistant" : "user",
          content: m.content,
        })),
      }),
    });

    if (!anthropicRes.ok) {
      const errorText = await anthropicRes.text();
      console.error("Anthropic API error:", errorText);
      res.status(500).json({ error: "Claude API error" });
      return;
    }

    const data = await anthropicRes.json();

    // Claude の返信テキストを取り出す
    const reply =
      data?.content?.[0]?.text ||
      "すみません、うまく返信を生成できませんでした。";

    res.status(200).json({ reply });
  } catch (err) {
    console.error("Server error:", err);
    res.status(500).json({ error: "Server error" });
  }
}