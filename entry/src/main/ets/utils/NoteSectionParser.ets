/**
 * NoteSectionParser.ets — 笔记正文章节解析工具
 *
 * 路径: entry/src/main/ets/utils/NoteSectionParser.ets
 * 职责: 把笔记正文按 "## 标题" 切分成章节列表
 * 依赖: 无（纯函数，可单测）
 */

export interface Section {
  title: string;
  content: string;
}

/**
 * 按 "## 标题" 切分 body 为章节数组。
 * 空 body 时返回默认 "内容" 段。
 */
export function parseSections(body: string): Section[] {
  if (!body) {
    return [];
  }
  const lines: string[] = body.split('\n');
  const sections: Section[] = [];
  let curTitle: string = '内容';
  let curLines: string[] = [];

  for (const line of lines) {
    if (line.indexOf('## ') === 0) {
      if (curLines.length > 0) {
        sections.push({ title: curTitle, content: curLines.join('\n').trim() });
      }
      curTitle = line.substring(3).trim();
      curLines = [];
    } else {
      curLines.push(line);
    }
  }
  if (curLines.length > 0 || sections.length === 0) {
    sections.push({ title: curTitle, content: curLines.join('\n').trim() });
  }
  return sections;
}
