// MathMind - AiService (拍照/调用 Dispatcher)
// 任务编号: E1
// 责任: 用户 (我)
// 状态: TODO - 空壳,等待实现
// 依赖: A2 (ApiClient) + D (Dispatcher) 完成
//
// 接口约定 (D1_CAPTURE_CHAIN_PLAN.md):
//   capture(imageUri: string): Promise<KnowledgeUnit>
//
// 实现路径:
//   1) imageUri 读文件 → 转 base64 字符串
//      (用 @ohos.file.fs / @ohos.media.image)
//   2) ApiClient.request('POST', '/agents/dispatch', {
//        body: { source: 'app', payload: base64, imageUri }
//      })
//   3) 解析响应: { success, route: 'D1', data: KnowledgeUnit, durationMs }
//   4) 日志打 note.id,返回 KnowledgeUnit
//
// 验证方式: 日志打返回的 note.id
//   (E1 可先用硬编码 base64 自测,不等 E2 相机)

export class AiService {
  // TODO(E1): 实现 capture() — imageUri → base64 → POST dispatch
}
