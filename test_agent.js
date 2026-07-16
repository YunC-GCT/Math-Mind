const fs = require("fs");
const https = require("https");

// Read the prompt from the extracted file
const prompt = fs.readFileSync("E:/AAAharmonyrace/mathmind/agent_prompt.txt", "utf8");

// Change this text to test different inputs
const userText = "一致连续性：设函数 $f$ 在区间 $I$ 上有定义。若对任意给定的 $\varepsilon > 0$，都存在一个只与 $\varepsilon$ 有关的 $\delta > 0$，使得对于 $I$ 上的任意两点 $x_1, x_2$，只要满足 $|x_1 - x_2| < \delta$，就有|f(x_1) - f(x_2)| < \varepsilon,则称 $f$ 在 $I$ 上一致连续。";

const data = JSON.stringify({
  model: "deepseek-chat",
  messages: [
    { role: "system", content: prompt },
    { role: "user", content: userText }
  ],
  response_format: { type: "json_object" },
  temperature: 0.3,
  max_tokens: 2000
});

const key = process.env.DEEPSEEK_KEY;
if (!key) { console.error("Please set DEEPSEEK_KEY env var"); process.exit(1); }

const options = {
  hostname: "api.deepseek.com",
  path: "/v1/chat/completions",
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + key
  }
};

const req = https.request(options, (res) => {
  let body = "";
  res.on("data", (chunk) => body += chunk);
  res.on("end", () => {
    try {
      const parsed = JSON.parse(body);
      if (parsed.error) { console.error("API Error:", parsed.error.message); return; }
      const result = JSON.parse(parsed.choices[0].message.content);
      console.log("Category: " + result.category);
      console.log("Title: " + result.title);
      for (const f of result.fields || []) {
        console.log("[" + f.label + "] " + f.value.substring(0, 200));
      }
      console.log("Difficulty: " + result.difficulty + "/5");
      console.log("Importance: " + result.importance + "/5");
      console.log("Tags: " + (result.tags || []).join(", "));
    } catch(e) {
      console.error("Parse failed:", e.message);
      console.log("Raw response:", body.substring(0, 500));
    }
  });
});
req.on("error", (e) => console.error("Request failed:", e.message));
req.write(data);
req.end();
