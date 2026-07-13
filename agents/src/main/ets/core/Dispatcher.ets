// MathMind - Dispatcher (Agent 调度中枢)
// 任务编号: D
// 责任: 用户 (我)
// 状态: TODO - 空壳,等待实现
// 依赖: A1 (NoteDao) + B1 (OcrTool) + B2 (TypeClassifier) + C (KnowledgeModel) 全部完成
//
// 接口约定 (D1_CAPTURE_CHAIN_PLAN.md):
//   routeDispatch(request: DispatchRequest): Promise<DispatchResult>
//
//   DispatchRequest: { source, payload (base64), imageUri }
//   DispatchResult:  { success, route: 'D1', data: KnowledgeUnit, durationMs }
//
// 精简版 D1 链 (单一意图 "笔记整理"):
//   L1 关键词匹配: "记" / "拍" / "这题" → 命中 D1
//   (L2 DeepSeek 语义兜底 砍掉, MVP 不需要)
//
// 实现路径:
//   1) 关键词判断 (text in ['记','拍','这题','笔记','题']?)
//      - 命中: 走 D1 分支
//      - 未命中: 返回 success: false, errorMessage: '意图不识别'
//   2) D1 分支:
//      - 调 TypeClassifier.classify({ imageBase64: payload })
//      - 拿 OCR 文本 + ClassificationResult
//      - 调 KnowledgeModel.structure(ocrText, classification)
//      - 拿 KnowledgeUnit
//   3) 包装成 DispatchResult 返回
//      { success: true, route: 'D1', data: unit, durationMs }
//
// 验证方式: POST /agents/dispatch 传 base64 → 返回完整 KnowledgeUnit

export class Dispatcher {
  // TODO(D): 实现 routeDispatch() — L1 关键词 → D1 分支
}
