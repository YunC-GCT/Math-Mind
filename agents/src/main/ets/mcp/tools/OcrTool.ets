// MathMind - OcrTool (ML Kit OCR 工具)
// 任务编号: B1
// 责任: D
// 状态: TODO - 空壳,等待实现
// 依赖: 无 (B 阶段,可与 B2 并行,只要 A 完成)
//
// 接口约定 (TONIGHT_TASKS.md):
//   recognize(imageBase64: string): Promise<string>   // 返回 OCR 文本
//
// 实现要点:
//   - 调 HarmonyOS ML Kit Vision API (textRecognition)
//   - 路径: @ohos.ai.mlnlp.textRecognition 或 media.nlp.textRecognition
//   - 输入 base64 字符串 → 解码为 PixelMap → 调 OCR
//
// 验证方式: 传一张含数学公式的图 → 返回非空文本

export class OcrTool {
  // TODO(B1): 实现 recognize(imageBase64)
}
