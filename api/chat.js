{\rtf1\ansi\ansicpg932\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 // api/chat.js\
\
export default async function handler(req, res) \{\
  // POST \uc0\u20197 \u22806 \u12399 \u24382 \u12367 \
  if (req.method !== "POST") \{\
    res.status(405).json(\{ error: "Method Not Allowed" \});\
    return;\
  \}\
\
  try \{\
    const apiKey = process.env.ANTHROPIC_API_KEY;\
\
    if (!apiKey) \{\
      console.error("ANTHROPIC_API_KEY is not set");\
      res.status(500).json(\{ error: "Missing API key" \});\
      return;\
    \}\
\
    // \uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12363 \u12425  messages \u12434 \u21463 \u12369 \u21462 \u12427 \
    const \{ messages \} = req.body || \{\};\
\
    if (!messages || !Array.isArray(messages)) \{\
      res.status(400).json(\{ error: "Invalid request body" \});\
      return;\
    \}\
\
    // Claude API \uc0\u12395 \u12522 \u12463 \u12456 \u12473 \u12488 \
    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", \{\
      method: "POST",\
      headers: \{\
        "Content-Type": "application/json",\
        "x-api-key": apiKey,\
        "anthropic-version": "2023-06-01",\
      \},\
      body: JSON.stringify(\{\
        model: "claude-3-haiku-20240307",\
        max_tokens: 512,\
        messages: messages.map((m) => (\{\
          role: m.role === "assistant" ? "assistant" : "user",\
          content: m.content,\
        \})),\
      \}),\
    \});\
\
    if (!anthropicRes.ok) \{\
      const errorText = await anthropicRes.text();\
      console.error("Anthropic API error:", errorText);\
      res.status(500).json(\{ error: "Claude API error" \});\
      return;\
    \}\
\
    const data = await anthropicRes.json();\
\
    // Claude \uc0\u12398 \u36820 \u20449 \u12486 \u12461 \u12473 \u12488 \u12434 \u21462 \u12426 \u20986 \u12377 \
    const reply =\
      data?.content?.[0]?.text ||\
      "\uc0\u12377 \u12415 \u12414 \u12379 \u12435 \u12289 \u12358 \u12414 \u12367 \u36820 \u20449 \u12434 \u29983 \u25104 \u12391 \u12365 \u12414 \u12379 \u12435 \u12391 \u12375 \u12383 \u12290 ";\
\
    res.status(200).json(\{ reply \});\
  \} catch (err) \{\
    console.error("Server error:", err);\
    res.status(500).json(\{ error: "Server error" \});\
  \}\
\}}