// MathMind - TypeClassifier (类型/学科分类器)
// 任务编号: B2
// 责任: D
// 状态: TODO - 空壳,等待实现
// 依赖: A 完成 (ApiClient),可与 B1 并行
//
// 接口约定 (D1_CAPTURE_CHAIN_PLAN.md 第四节):
//   classify(input: { ocrText?: string, imageBase64?: string }):
//     Promise<ClassificationResult>
//
//   ClassificationResult: {
//     type: '概念' | '计算' | '证明'
//     subject: '高等代数' | '数学分析' | '解析几何'
//     chapter?: string
//     confidence: number    // 0.0-1.0
//   }
//
// 实现路径:
//   1) 如传 imageBase64,先调 OcrTool.recognize 拿文本
//   2) cleanText 清洗 (TextUtils)
//   3) 调 LLM (默认 SiliconFlow / DeepSeek-V3) 走精简版 Prompt
//      端点: https://api.siliconflow.cn/v1/chat/completions
//      Temperature 0.1 · MaxTokens 256 · Timeout 5s
//   4) 解析 JSON 返回 ClassificationResult
//
// 验证方式: 传文字 "求行列式 |A|" → 返回 {type:"计算", subject:"高等代数", confidence: 0.9}

export class TypeClassifier {
  // TODO(B2): 实现 classify() — OCR + cleanText + DeepSeek 3×3 分类
}
