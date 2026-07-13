// MathMind - ApiClient (HTTP 客户端)
// 任务编号: A2
// 责任: Mavis(我)
// 状态: TODO - 空壳,等待实现
// 依赖: 无 (A 阶段基础设施,可与 A1 并行)
//
// 接口约定 (TONIGHT_TASKS.md):
//   request(method, path, options): Promise<ApiResponse>
//     - method: 'GET' | 'POST' | 'PUT' | 'DELETE'
//     - path: 后端路径,例如 '/agents/dispatch'
//     - options.body / options.headers / options.timeout
//   自动注入 JWT (Authorization: Bearer ...)
//   401 时尝试一次 token 刷新后重试
//
// 验证方式: curl 打后端 /health 端点返回 200

export class ApiClient {
  // TODO(A2): 实现 request() + JWT 注入 + 401 重试
}
