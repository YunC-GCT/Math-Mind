/**
 * test_agent.js — KnowledgeModelMVP 的 Node.js 测试脚本
 *
 * 对齐 KnowledgeModelMVP.ets 的分段逻辑和 P0 防护：
 *   1) 按空行分割多段文本 → 每段独立调用 AI
 *   2) JSON 安全解析（剥离 markdown 代码块 + 提取 {} 块）
 *   3) category 白名单校验（非法值降级为"概念"）
 *
 * 用法（PowerShell）:
 *   $env:DEEPSEEK_KEY = "sk-xxx"
 *   node test_agent.js
 */

const fs = require("fs");
const https = require("https");

// ─── 配置区 ───

// Prompt 文件路径（与 KnowledgeModelMVP.buildPrompt() 内容一致）
const prompt = fs.readFileSync("E:/AAAharmonyrace/mathmind/agent_prompt.txt", "utf8");

// 测试文本：用空行分隔多段，每段独立处理
//          空行之间的内容视为一段，连续多空行视为一个分隔符
//          修改这里来测试不同输入
const userText = `一致连续性：设函数 $f$ 在区间 $I$ 上有定义。若对任意给定的 $\\varepsilon > 0$，都存在一个只与 $\\varepsilon$ 有关的 $\\delta > 0$，使得对于 $I$ 上的任意两点 $x_1, x_2$，只要满足 $|x_1 - x_2| < \\delta$，就有 $|f(x_1) - f(x_2)| < \\varepsilon$，则称 $f$ 在 $I$ 上一致连续。

证明 $\\displaystyle \\lim_{n \\to \\infty} \\sqrt[n]{n} = 1$。设 $x_n = \\sqrt[n]{n} - 1$，显然 $x_n \\ge 0$。于是 $n = (1 + x_n)^n$。根据二项式定理展开，取第三项（当 $n \\ge 2$ 时）：$n = (1 + x_n)^n = 1 + n x_n + \\frac{n(n-1)}{2} x_n^2 + \\cdots \\ge \\frac{n(n-1)}{2} x_n^2.$ 化简得 $0 \\le x_n^2 \\le \\frac{2}{n-1}$，因此 $0 \\le x_n \\le \\sqrt{\\frac{2}{n-1}}$。当 $n \\to \\infty$ 时，$\\sqrt{\\frac{2}{n-1}} \\to 0$，由夹逼准则可知 $x_n \\to 0$。所以 $\\lim_{n \\to \\infty} \\sqrt[n]{n} = \\lim_{n \\to \\infty} (1 + x_n) = 1$。`;

const MAX_SEGMENTS = 3; // 初赛限定最多处理 3 段

// ─── P0 防护：category 白名单 ───

const VALID_CATEGORIES = ["概念", "定理", "公式", "证明题", "计算题"];

function validateCategory(raw) {
  return VALID_CATEGORIES.includes(raw) ? raw : "概念";
}

// ─── JSON 安全解析：剥离 markdown 代码块 + 提取 {} 块 ───

function safeExtractJSON(rawContent) {
  let cleaned = rawContent.trim();

  // ① 剥离 markdown 代码块包裹（```json ... ``` 或 ``` ... ```）
  const codeBlockMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (codeBlockMatch) {
    cleaned = codeBlockMatch[1].trim();
  }

  // ② 提取第一个 { 到最后一个 } 之间的内容
  const braceStart = cleaned.indexOf("{");
  const braceEnd = cleaned.lastIndexOf("}");
  if (braceStart !== -1 && braceEnd > braceStart) {
    cleaned = cleaned.substring(braceStart, braceEnd + 1);
  }

  // ③ 解析 + category 白名单校验
  const parsed = JSON.parse(cleaned);
  parsed.category = validateCategory(parsed.category || "");
  return parsed;
}

// ─── 分段逻辑：按空行分割（对齐 KnowledgeModelMVP.structureBatch） ───

function splitIntoSegments(text) {
  const lines = text.split("\n");
  const segments = [];
  let current = "";

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.length === 0) {
      // 空行作分隔符：提交当前累积的段落
      if (current.length > 0) {
        segments.push(current);
        current = "";
      }
    } else {
      if (current.length > 0) {
        current += "\n";
      }
      current += trimmed;
    }
  }
  // 提交最后一段（如果文本不以空行结尾）
  if (current.length > 0) {
    segments.push(current);
  }

  return segments;
}

// ─── 调用 DeepSeek API（返回 Promise） ───

function callDeepSeek(segmentText, segmentIndex) {
  return new Promise((resolve, reject) => {
    const key = process.env.DEEPSEEK_KEY;
    if (!key) {
      reject(new Error("Please set DEEPSEEK_KEY env var"));
      return;
    }

    const postData = JSON.stringify({
      model: "deepseek-chat",
      messages: [
        { role: "system", content: prompt },
        { role: "user", content: segmentText },
      ],
      response_format: { type: "json_object" },
      temperature: 0.3,
      max_tokens: 4096,
    });

    const req = https.request(
      {
        hostname: "api.deepseek.com",
        path: "/v1/chat/completions",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + key,
        },
      },
      (res) => {
        let body = "";
        res.on("data", (chunk) => (body += chunk));
        res.on("end", () => {
          try {
            const parsed = JSON.parse(body);
            if (parsed.error) {
              reject(new Error("API Error: " + parsed.error.message));
              return;
            }
            const result = safeExtractJSON(
              parsed.choices[0].message.content
            );
            resolve(result);
          } catch (e) {
            reject(new Error("Parse failed: " + e.message));
          }
        });
      }
    );

    req.on("error", (e) => reject(new Error("Request failed: " + e.message)));
    req.write(postData);
    req.end();
  });
}

// ─── 打印单段结果 ───

function printResult(result, index) {
  console.log("");
  console.log("═".repeat(60));
  console.log("  第 " + index + " 段");
  console.log("═".repeat(60));
  console.log("  Category  : " + result.category);
  console.log("  Title     : " + result.title);
  for (const f of result.fields || []) {
    const preview =
      f.value.length > 150 ? f.value.substring(0, 150) + "..." : f.value;
    console.log("  [" + f.label + "] " + preview);
  }
  console.log("  Difficulty: " + result.difficulty + "/5");
  console.log("  Importance: " + result.importance + "/5");
  console.log("  Tags      : " + (result.tags || []).join(", "));
}

// ─── 主流程：分段 → 逐段调 AI → 打印结果 ───

async function main() {
  console.log("══════════════════════════════════════");
  console.log("  KnowledgeModelMVP — Node.js 测试");
  console.log("══════════════════════════════════════");

  // Step 1: 分段
  const segments = splitIntoSegments(userText);
  const toProcess = segments.slice(0, MAX_SEGMENTS);
  console.log(
    "\n输入文本共 " + segments.length + " 段" +
    (segments.length > MAX_SEGMENTS ? "（超过上限" + MAX_SEGMENTS + "，仅处理前 " + MAX_SEGMENTS + " 段）" : "")
  );

  // Step 2: 逐段处理（顺序调用，避免并发限频）
  let successCount = 0;
  for (let i = 0; i < toProcess.length; i++) {
    const seg = toProcess[i];
    const segPreview =
      seg.length > 80 ? seg.substring(0, 80) + "..." : seg;
    console.log("\n[" + (i + 1) + "/" + toProcess.length + "] 正在处理: " + segPreview);

    try {
      const result = await callDeepSeek(seg, i);
      printResult(result, i + 1);
      successCount++;
    } catch (e) {
      console.error("  ✗ 第 " + (i + 1) + " 段处理失败: " + e.message);
    }
  }

  console.log(
    "\n══════════════════════════════════════\n" +
    "  完成: " + successCount + "/" + toProcess.length + " 段成功\n" +
    "══════════════════════════════════════"
  );
}

main().catch((e) => console.error("Fatal error:", e));
