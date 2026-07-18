/**
 * FileUriUtils.ets — URI 路径/MIME 类型共享工具函数
 *
 * 路径: common/src/main/ets/utils/FileUriUtils.ets
 * 职责: 从文件 URI 提取文件名/扩展名/推断 MIME 类型
 * 依赖: 无外部模块依赖
 *
 * 设计要点:
 *   - 消除 ImageUriResolver 与 OcrTool 中的重复 MIME 映射逻辑
 *   - 所有图片扩展名→MIME 映射集中在此一处
 */

// 根据文件扩展名推断 MIME 类型
export function mimeFromExtension(fileNameOrExt: string): string {
  const lower: string = fileNameOrExt.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.bmp')) {
    return 'image/bmp';
  }
  return 'image/png';
}

// 从 URI 中提取文件扩展名（去除查询参数后匹配）
export function extFromUri(uri: string): string {
  const clean: string = uri.split('?')[0].toLowerCase();
  if (clean.endsWith('.jpg') || clean.endsWith('.jpeg')) {
    return '.jpg';
  }
  if (clean.endsWith('.webp')) {
    return '.webp';
  }
  if (clean.endsWith('.bmp')) {
    return '.bmp';
  }
  return '.png';
}

// 从 URI 路径中提取文件名（去除查询参数后取最后一段）
export function fileNameFromUri(uri: string): string {
  const clean: string = uri.split('?')[0];
  const slash: number = clean.lastIndexOf('/');
  const backslash: number = clean.lastIndexOf('\\');
  const index: number = Math.max(slash, backslash);
  if (index >= 0 && index + 1 < clean.length) {
    return clean.substring(index + 1);
  }
  return 'upload.png';
}
