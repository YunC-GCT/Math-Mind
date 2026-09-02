#!/usr/bin/env node
/**
 * audit-arkts-strict.mjs — ArkTS 1.1 strict 规则静态扫描器
 *
 * 对 [docs/style/arkts-1.1.md]  中的官方 strict-mode 规则做正则扫描,
 * 输出报告 + 设置退出码 (有 error 违规 → 1, 否则 0)。
 *
 * 用法:
 *   node scripts/audit-arkts-strict.mjs                      # 默认扫 process.cwd()
 *   node scripts/audit-arkts-strict.mjs --root=<dir>          # 扫指定根
 *   node scripts/audit-arkts-strict.mjs --json               # JSON 输出 (CI 解析)
 *   node scripts/audit-arkts-strict.mjs --baseline=<file>    # 写 baseline JSON
 *   node scripts/audit-arkts-strict.mjs --quiet               # 仅打印 summary
 *
 * 与 docs/style/arkts-1.1.md 配套 — 规则定义见该文件 §官方 strict-mode 规则总表.
 *
 * 已知限制:
 *   - 正则法, 注释 /import path 内字符串可能误报; 复杂 AST 规则 (解构嵌套/嵌套函数) 覆盖率有限
 *   - Phase 4 ticket #15 计划升级为基于 AST (tsserver / tree-sitter)
 *
 * 关联:
 *   - 文档: docs/style/arkts-1.1.md (权威规则定义)
 *   - 审计: docs/architecture-audit-full-20260901.md §4.18
 *   - ticket: Phase 4 #15
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, extname, relative } from 'node:path';

// ────────────────────────── 规则定义 ──────────────────────────
// 来源: docs/style/arkts-1.1.md §官方 strict-mode 规则总表
// pattern: 全局正则, 匹配整行. exclude: 过滤函数 (true = 跳过此行).

const RULES = [
  // ─── A. 类型系统 ───
  {
    id: 'arkts-no-any-unknown',
    code: '10605008',
    severity: 'error',
    title: 'any / unknown 类型禁用',
    pattern: /(?<![A-Za-z0-9_])(any|unknown)(?![A-Za-z0-9_])/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /["'].*\b(any|unknown)\b.*["']/.test(line),
    fixHint: '用具体类型; catch 处 (e as Error).message ?? String(e)',
  },
  {
    id: 'arkts-as-casts',
    code: '10605053',
    severity: 'error',
    title: '尖括号强转 <T>x 禁用, 用 x as T',
    // 匹配 <Foo>bar 形式. 排除 JSX-like (<Foo />) 和泛型调用 foo<Foo>(x)
    pattern: /(?<![A-Za-z0-9_)\]])<([A-Z][A-Za-z0-9_]*)>([A-Za-z_][A-Za-z0-9_]*)/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '改为 `(x as Foo)` 形式',
  },
  {
    id: 'arkts-no-is',
    code: '10605096',
    severity: 'error',
    title: '类型谓词 arg is T 禁用',
    pattern: /(\w+)\s+is\s+[A-Z][A-Za-z0-9_<>,\s|&\[\]]*(\)|,|\s*=>|\s*$)/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '用 `instanceof` + `as` 组合',
  },
  {
    id: 'arkts-no-intersection-types',
    code: '10605019',
    severity: 'error',
    title: '类型位置上的 T & U 交叉类型禁用',
    pattern: /:\s*[A-Z][A-Za-z0-9_<>,\s]*\s+&\s+[A-Z][A-Za-z0-9_<>,\s[\]|,]+/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /^\s*&/.test(line) || /\/\//.test(line),
    fixHint: '用 interface extends 替代',
  },
  {
    id: 'arkts-no-mapped-types',
    code: '10605083',
    severity: 'error',
    title: 'mapped types 禁用 (keyof / [K in keyof T])',
    pattern: /\[(\w+)\s+in\s+keyof\s+/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '显式字段声明',
  },

  // ─── B. 控制流 ───
  {
    id: 'arkts-no-for-in',
    code: '10605080',
    severity: 'error',
    title: 'for..in 禁用 (官方); C-style for 允许',
    pattern: /for\s*\(\s*(let|const|var)\s+(\w+)\s+in\s+/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '用 for...of 或 forEach',
  },
  {
    id: 'arkts-no-with',
    code: '10605084',
    severity: 'error',
    title: 'with 语句禁用',
    pattern: /\bwith\s*\(/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '重构成显式属性访问',
  },
  {
    id: 'arkts-no-delete',
    code: '10605059',
    severity: 'error',
    title: 'delete obj.prop 禁用',
    pattern: /\bdelete\s+[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '设 undefined 或过滤重建对象',
  },
  {
    id: 'arkts-no-comma-outside-loops',
    code: '10605071',
    severity: 'warn',
    title: 'for 外的逗号运算符 (粗扫) — 当前禁用, 正则难处理嵌套',
    pattern: /^(?!.*\bfor\b).*\)\s*,\s*[A-Za-z_]/,
    enabled: false,  // 2026-09-01 首次运行 87 误报 (multi-line obj literal `.scale({ x: 1, y: 2 })`), 需 AST
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /^\s*(const|let|var)\s+/.test(line),
    fixHint: '用分号或单独语句',
  },

  // ─── C. 变量与声明 ───
  {
    id: 'arkts-no-var',
    code: '10605005',
    severity: 'error',
    title: 'var 禁用, 用 let',
    pattern: /(?<![A-Za-z0-9_])var\s+[a-zA-Z_][A-Za-z0-9_]*\s*[:=]/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: 'var 改 let',
  },
  {
    id: 'arkts-no-private-identifiers',
    code: '10605003',
    severity: 'error',
    title: '#field 语法禁用, 用 private',
    pattern: /^\s*#([A-Za-z_][A-Za-z0-9_]*)\s*[:=]/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: 'private 关键字 (TS 风格) 替代',
  },
  {
    id: 'arkts-no-symbol',
    code: '10605002',
    severity: 'error',
    title: 'Symbol() 禁用',
    pattern: /\bSymbol\s*\(/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '用 enum 或静态常量',
  },
  {
    id: 'arkts-no-types-in-catch',
    code: '10605079',
    severity: 'error',
    title: 'catch (e: T) typed 禁用',
    pattern: /catch\s*\(\s*[a-zA-Z_]\w*\s*:\s*[A-Z][A-Za-z0-9_<>,\s|&\[\]]*/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: 'catch (e) + (e as Error).message ?? String(e)',
  },

  // ─── D. 类与对象 ───
  {
    id: 'arkts-no-func-expressions',
    code: '10605046',
    severity: 'error',
    title: 'function 表达式禁用, 用箭头函数',
    pattern: /\bfunction\s*\(/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\bfunction\s+\w+\s*\(/.test(line) || /\bfunction\s*\*\s*\(/.test(line),
    fixHint: 'const f = () => {}',
  },
  {
    id: 'arkts-no-class-literals',
    code: '10605050',
    severity: 'error',
    title: 'class 表达式禁用 (粗扫: 行首 class 不接 extends/接 implements?)',
    pattern: /^\s*=\s*class\s*(\{|extends|implements)/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '用 class 声明',
  },
  {
    id: 'arkts-no-jsx',
    code: '10605054',
    severity: 'error',
    title: 'JSX 禁用 (ArkTS 不支持)',
    pattern: /<[A-Z][A-Za-z0-9]*\s+[^>]*\/>/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\.ets['"]/.test(line),
    fixHint: '用 @Builder',
  },
  {
    id: 'arkts-no-generators',
    code: '10605094',
    severity: 'error',
    title: 'function* 生成器禁用',
    pattern: /\bfunction\s*\*/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: 'async/await + Promise',
  },
  {
    id: 'arkts-implements-only-iface',
    code: '10605051',
    severity: 'warn',
    title: 'implements class (应为 interface) — 粗扫, 需人工核',
    pattern: /\bclass\s+\w+\s+implements\s+[A-Z][A-Za-z0-9_]*\b(?!\s*[\{,])/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: '确保 implements 的是 interface (大写 I 前缀或单独命名)',
  },
  {
    id: 'arkts-no-props-by-index',
    code: '10605029',
    severity: 'warn',
    title: '动态属性访问 obj["key"] 禁用 (粗扫)',
    pattern: /[A-Za-z_]\w*\s*\[\s*['"`][^'"`\]]+['"`]\s*\]/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /^\s*import\b/.test(line),
    fixHint: '预定义字段 或 Map.get()',
  },
  {
    id: 'arkts-no-method-reassignment',
    code: '10605052',
    severity: 'warn',
    title: 'obj.method = fn 重赋值禁用 (粗扫) — 当前禁用, 误报多 (this.x = new X() 不是方法重赋值)',
    pattern: /[A-Za-z_]\w*(\.\w+)+\s*=\s*(function|\(|new\s+[A-Z])/g,
    enabled: false,  // 2026-09-01 首次运行 11 误报 (字段初始化), 需 AST 区分字段 vs 方法
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\bclass\s+/.test(line) || /\binterface\s+/.test(line),
    fixHint: '重设计: 持有函数引用而非方法',
  },

  // ─── E. 模块与函数 ───
  {
    id: 'arkts-no-nested-funcs',
    code: '10605092',
    severity: 'warn',
    title: '嵌套函数声明禁用 (粗扫, 行首 function 在函数体内)',
    pattern: /^\s{2,}function\s+\w+\s*\(/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\bfunction\s*\*\s*\(/.test(line),
    fixHint: '提取为模块顶层函数或箭头',
  },
  {
    id: 'arkts-limited-throw',
    code: '10605087',
    severity: 'error',
    title: 'throw 非 Error 禁用 (throw "string" 等)',
    pattern: /\bthrow\s+(['"`])[^'"`]*?\1/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line),
    fixHint: 'throw new Error("...")',
  },
  {
    id: 'arkts-no-destruct-assignment',
    code: '10605069',
    severity: 'error',
    title: '[a, b] = arr 解构赋值禁用',
    pattern: /^\s*(let|const|var)?\s*\[[^\]]+\]\s*=/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\[[A-Z][A-Za-z0-9_<>,\s]*\]\s*\)\s*\{/.test(line),
    fixHint: '用索引访问 const a = arr[0]; const b = arr[1]',
  },
  {
    id: 'arkts-no-destruct-decls',
    code: '10605074',
    severity: 'error',
    title: 'let { a, b } = obj 解构声明禁用',
    pattern: /^\s*(let|const|var)\s*\{[^}]+\}\s*=/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\binterface\s+/.test(line) || /\bclass\s+/.test(line),
    fixHint: 'const a = obj.a; const b = obj.b',
  },
  {
    id: 'arkts-no-destruct-params',
    code: '10605091',
    severity: 'error',
    title: 'function f({a, b}) 解构参数禁用',
    pattern: /\([^)]*\b\w+\s*:\s*[A-Z][A-Za-z0-9_<>,\s|&\[\]]*\s*\{[^}]+\}[^)]*\)/g,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /type:\s*\{/.test(line),
    fixHint: '显式命名参数: function f(req: { a: T; b: U }) { const a = req.a; ... }',
  },

  // ─── F. 项目偏好 (ArkUI, 仅警告) ───
  {
    id: 'ArkUI-1 struct-no-regular-methods',
    code: 'project-pref',
    severity: 'warn',
    title: 'struct 内禁用普通方法 (项目偏好, 官方允许)',
    pattern: /^\s{2,}(public\s+|private\s+|protected\s+)?(\w+\s+)+\w+\s*\([^)]*\)\s*:\s*[A-Z][A-Za-z0-9_<>,\s|&\[\]]*\s*\{/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\bclass\s+/.test(line) || /\binterface\s+/.test(line) || /\bfunction\s*\*\s*\(/.test(line),
    fixHint: '用箭头函数字段 `handleClick = (): void => { ... }`',
  },
  {
    id: 'ArkUI-2 no-get-accessor',
    code: 'project-pref',
    severity: 'warn',
    title: 'struct 内禁 get accessor (项目偏好)',
    pattern: /^\s+get\s+\w+\s*\([^)]*\)\s*:\s*[A-Z][A-Za-z0-9_<>,\s|&\[\]]*\s*\{/gm,
    exclude: (line) => /^\s*(\/\/|\*|\/\*)/.test(line) || /\bclass\s+/.test(line),
    fixHint: '用 @State 直接暴露或 @Computed (API 12+)',
  },
];

// ────────────────────────── 扫描器 ──────────────────────────

const SKIP_DIRS = new Set([
  'node_modules', 'build', 'oh_modules', '.hvigor', '.git',
  '.idea', '.appanalyzer', '.reasonix', '.worktrees',
  'docs', '.designer', '.deveco', 'archive',
  'scripts/arkts-lint/fixtures',  // v0.3 fixtures have intentional violations
]);

function checkRulesValidity() {
  const errors = [];
  const seenIds = new Set();
  for (let i = 0; i < RULES.length; i++) {
    const r = RULES[i];
    const tag = `[${i}] ${r.id ?? '(no id)'}`;
    if (!r.id) errors.push(`${tag} missing id`);
    else if (seenIds.has(r.id)) errors.push(`${tag} duplicate id`);
    else seenIds.add(r.id);
    if (!r.title) errors.push(`${tag} missing title`);
    if (!r.fixHint) errors.push(`${tag} missing fixHint`);
    if (!['error', 'warn'].includes(r.severity)) {
      errors.push(`${tag} severity must be 'error' or 'warn', got '${r.severity}'`);
    }
    if (!(r.pattern instanceof RegExp)) {
      errors.push(`${tag} pattern is not a RegExp`);
    } else {
      // Probe the pattern to make sure it compiles.
      try {
        // Force /g flag for probing matchAll semantics
        const probePattern = r.pattern.flags.includes('g') ? r.pattern : new RegExp(r.pattern.source, r.pattern.flags + 'g');
        // Test against a synthetic line
        'test string with some keywords any unknown for-in'.matchAll(probePattern);
      } catch (e) {
        errors.push(`${tag} pattern invalid: ${e.message}`);
      }
    }
    if (r.exclude !== undefined && typeof r.exclude !== 'function') {
      errors.push(`${tag} exclude must be function, got ${typeof r.exclude}`);
    }
    if (r.code && !r.code.startsWith('10605') && r.code !== 'project-pref') {
      errors.push(`${tag} code '${r.code}' should start with 10605 (ArkTS) or be 'project-pref'`);
    }
  }

  const enabled = RULES.filter(r => r.enabled !== false);
  console.log(`Rules table validation:`);
  console.log(`  Total rules: ${RULES.length}`);
  console.log(`  Enabled:     ${enabled.length}`);
  console.log(`  Disabled:    ${RULES.length - enabled.length}`);
  console.log(`  Errors:      ${enabled.filter(r => r.severity === 'error').length}`);
  console.log(`  Warnings:    ${enabled.filter(r => r.severity === 'warn').length}`);
  console.log('');
  if (errors.length === 0) {
    console.log(`✓ ${RULES.length} rules valid`);
    process.exit(0);
  } else {
    console.log(`✗ ${errors.length} errors:`);
    for (const e of errors) console.log(`    ${e}`);
    process.exit(1);
  }
}

function walkEts(dir, out = []) {
  let entries;
  try {
    entries = readdirSync(dir);
  } catch (e) {
    return out;
  }
  for (const entry of entries) {
    if (SKIP_DIRS.has(entry)) continue;
    const p = join(dir, entry);
    let s;
    try {
      s = statSync(p);
    } catch (e) {
      continue;
    }
    // Also skip by relative path from process.cwd() (for v0.3 internal paths the basename check misses).
    // On Windows, relative() returns backslashes — normalize to forward slashes.
    const rel = relative(process.cwd(), p).replace(/\\/g, '/');
    if (rel.includes('arkts-lint/fixtures') || rel.includes('arkts-lint/tests')) continue;
    if (s.isDirectory()) {
      walkEts(p, out);
    } else if (s.isFile() && extname(p) === '.ets') {
      out.push(p);
    }
  }
  return out;
}

// Ensure all patterns carry the /g flag (matchAll requires it).
// Done at module init so we don't re-clone per file.
for (const rule of RULES) {
  if (!rule.pattern.flags.includes('g')) {
    rule.pattern = new RegExp(rule.pattern.source, rule.pattern.flags + 'g');
  }
}

// Filter out disabled rules
for (let i = RULES.length - 1; i >= 0; i--) {
  if (RULES[i].enabled === false) RULES.splice(i, 1);
}

function lintFile(file, root) {
  let content;
  try {
    content = readFileSync(file, 'utf8');
  } catch (e) {
    return [{ rule: 'I/O', severity: 'error', file, line: 0, col: 0,
              title: `无法读取: ${e.message}`, text: '', fixHint: '' }];
  }
  const lines = content.split(/\r?\n/);
  const violations = [];
  for (const rule of RULES) {
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (rule.exclude?.(line)) continue;
      for (const m of line.matchAll(rule.pattern)) {
        violations.push({
          rule: rule.id,
          code: rule.code,
          severity: rule.severity,
          title: rule.title,
          file: relative(root, file),
          line: i + 1,
          col: (m.index ?? 0) + 1,
          match: m[0],
          text: line.trim().slice(0, 120),
          fixHint: rule.fixHint,
        });
      }
    }
  }
  return violations;
}

function main() {
  const args = process.argv.slice(2);
  const json = args.includes('--json');
  const quiet = args.includes('--quiet');
  const checkRules = args.includes('--check-rules');
  const rootArg = args.find(a => a.startsWith('--root='));
  const baselineArg = args.find(a => a.startsWith('--baseline='));
  const root = rootArg ? rootArg.slice('--root='.length) : process.cwd();

  if (checkRules) {
    return checkRulesValidity();
  }

  const files = walkEts(root);
  const allViolations = [];
  for (const f of files) {
    allViolations.push(...lintFile(f, root));
  }

  const byError = allViolations.filter(v => v.severity === 'error');
  const byWarn = allViolations.filter(v => v.severity === 'warn');
  const byRule = {};
  for (const v of allViolations) {
    byRule[v.rule] = (byRule[v.rule] || 0) + 1;
  }

  if (baselineArg) {
    const baselinePath = baselineArg.slice('--baseline='.length);
    const baseline = {
      generated: new Date().toISOString(),
      root,
      filesScanned: files.length,
      totals: { errors: byError.length, warnings: byWarn.length },
      byRule,
      violations: allViolations,
    };
    writeFileSync(baselinePath, JSON.stringify(baseline, null, 2));
    if (!quiet) console.log(`Baseline written to ${baselinePath}`);
  }

  if (json) {
    console.log(JSON.stringify({
      root,
      filesScanned: files.length,
      totals: { errors: byError.length, warnings: byWarn.length },
      byRule,
      violations: allViolations,
    }, null, 2));
  } else if (!quiet) {
    const W = 78;
    console.log('━'.repeat(W));
    console.log('  ArkTS 1.1 strict lint');
    console.log('━'.repeat(W));
    console.log(`  Root:       ${root}`);
    console.log(`  Files:      ${files.length} .ets`);
    console.log(`  Rules:      ${RULES.length} (${RULES.filter(r => r.severity === 'error').length} error, ${RULES.filter(r => r.severity === 'warn').length} warn)`);
    console.log(`  Errors:     ${byError.length}`);
    console.log(`  Warnings:   ${byWarn.length}`);
    console.log('━'.repeat(W));
    if (allViolations.length === 0) {
      console.log('  ✓ No violations.');
    } else {
      console.log('');
      for (const v of allViolations) {
        const tag = v.severity === 'error' ? '[ERROR]' : '[WARN] ';
        console.log(`  ${tag} ${v.rule} (${v.code})`);
        console.log(`          ${v.file}:${v.line}:${v.col}`);
        console.log(`          ${v.text}`);
        console.log(`          match: "${v.match}"`);
        console.log(`          fix:  ${v.fixHint}`);
        console.log('');
      }
    }
    console.log('━'.repeat(W));
    if (byRule && Object.keys(byRule).length > 0) {
      console.log('  By rule:');
      const sorted = Object.entries(byRule).sort((a, b) => b[1] - a[1]);
      for (const [rule, count] of sorted) {
        console.log(`    ${rule.padEnd(40)} ${count}`);
      }
      console.log('━'.repeat(W));
    }
  }

  process.exit(byError.length > 0 ? 1 : 0);
}

main();