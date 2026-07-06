// Steelman-loop spike server. Throwaway code; the prompts are the artifact.
//
//   node server.mjs            # stub model (offline, tests the flow)
//   ANTHROPIC_API_KEY=... node server.mjs
//   OPENAI_API_KEY=...    node server.mjs
//
// Zero dependencies; serves index.html and POST /api/steelman.

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { SYSTEM_PROMPT, buildFirstRoundPrompt, buildRevisionPrompt } from "./prompts.mjs";

const PORT = process.env.PORT || 8788;
const DIR = dirname(fileURLToPath(import.meta.url));

const ANTHROPIC_KEY = process.env.ANTHROPIC_API_KEY;
const OPENAI_KEY = process.env.OPENAI_API_KEY;
const ANTHROPIC_MODEL = process.env.ANTHROPIC_MODEL || "claude-sonnet-4-5";
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5.2";

const provider = ANTHROPIC_KEY ? "anthropic" : OPENAI_KEY ? "openai" : "stub";
console.log(`model provider: ${provider}`);

async function callAnthropic(messages) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": ANTHROPIC_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages,
    }),
  });
  if (!res.ok) throw new Error(`anthropic ${res.status}: ${await res.text()}`);
  const body = await res.json();
  return body.content.map((c) => c.text || "").join("");
}

async function callOpenAI(messages) {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${OPENAI_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages: [{ role: "system", content: SYSTEM_PROMPT }, ...messages],
    }),
  });
  if (!res.ok) throw new Error(`openai ${res.status}: ${await res.text()}`);
  const body = await res.json();
  return body.choices[0].message.content;
}

// Offline stand-in so the interaction flow is testable without a key: it
// performs a crude mechanical "steelman" and echoes feedback acknowledgment.
function callStub(messages) {
  const last = messages[messages.length - 1].content;
  const original = (last.match(/---\n([\s\S]*?)\n---/) || [, last])[1].trim();
  const isRevision = /revision round/.test(last);
  const cleaned = original
    .replace(/\b(stupid|idiotic|insane|moronic|garbage|bullshit)\b/gi, "deeply flawed")
    .replace(/!+/g, ".")
    .trim();
  const steelman = isRevision
    ? cleaned + " (revised per your feedback)"
    : "The core of my position: " + cleaned;
  return Promise.resolve(
    JSON.stringify({
      steelman,
      notes: "- [stub model] softened insults, kept your position\n- set an API key for real steelmanning",
      question: null,
    })
  );
}

const callModel = provider === "anthropic" ? callAnthropic : provider === "openai" ? callOpenAI : callStub;

function parseModelJson(text) {
  // Models occasionally wrap JSON in fences despite instructions.
  const cleaned = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "").trim();
  const parsed = JSON.parse(cleaned);
  if (typeof parsed.steelman !== "string") throw new Error("model reply missing steelman");
  return {
    steelman: parsed.steelman,
    notes: typeof parsed.notes === "string" ? parsed.notes : "",
    question: typeof parsed.question === "string" ? parsed.question : null,
  };
}

async function handleSteelman(req, res) {
  let raw = "";
  for await (const chunk of req) raw += chunk;
  const body = JSON.parse(raw);

  // Rebuild the conversation from the client-held transcript. rounds is
  // [{draft, feedback}, ...] for completed rounds.
  const messages = [
    { role: "user", content: buildFirstRoundPrompt(body) },
  ];
  (body.rounds || []).forEach((r, i) => {
    messages.push({ role: "assistant", content: JSON.stringify({ steelman: r.draft }) });
    messages.push({
      role: "user",
      content: buildRevisionPrompt({
        original: body.original,
        draft: r.draft,
        feedback: r.feedback,
        round: i + 1,
      }),
    });
  });

  const reply = await callModel(messages);
  const parsed = parseModelJson(reply);
  res.writeHead(200, { "content-type": "application/json" });
  res.end(JSON.stringify(parsed));
}

const server = createServer(async (req, res) => {
  try {
    if (req.method === "POST" && req.url === "/api/steelman") {
      return await handleSteelman(req, res);
    }
    if (req.method === "GET" && (req.url === "/" || req.url === "/index.html")) {
      const html = await readFile(join(DIR, "index.html"));
      res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
      return res.end(html);
    }
    res.writeHead(404);
    res.end("not found");
  } catch (err) {
    console.error(err);
    res.writeHead(500, { "content-type": "application/json" });
    res.end(JSON.stringify({ error: String(err.message || err) }));
  }
});

server.listen(PORT, () => console.log(`steelman spike: http://127.0.0.1:${PORT}/`));
