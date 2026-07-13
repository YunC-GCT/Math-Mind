// MathMind - CameraOverlay (相机/相册覆盖层)
// 任务编号: E2
// 责任: 用户 (我)
// 状态: TODO - 空壳,等待实现
// 依赖: E1 (AiService) 完成
//
// 接口约定 (D1_CAPTURE_CHAIN_PLAN.md):
//   触发: 用户点首页 FAB [+] → 弹 CameraOverlay
//   功能: 相机预览 + 快门按钮 + 相册按钮
//   输出: 拍照/选图后返回 imageUri → 调 AiService.capture()
//
// 实现要点 (UI 组件, ArkTS 严格语法):
//   - 加 @Component 装饰器 (实现时)
//   - 相机: cameraPicker 或 @ohos.multimedia.camera
//   - 相册: photoPicker (photoAccessHelper.PhotoViewPicker)
//   - 拍完/选完: 拿 imageUri → 调 AiService.capture(imageUri)
//   - 拿回 KnowledgeUnit → 关 overlay → 通知 HomePage 刷新
//
// 注意: ArkTS 严格语法,不能用 any/unknown
//   Want 必须显式类型 + import from '@ohos.app.ability.Want'
//
// 验证方式: 点快门 → 拍照 → 日志见 note.id
//
// ⚠️ 此处不放 @Component/@Entry,等 E2 实际写 UI 时再加
//    (一个 module 只能一个 @Entry, 跟 entry/pages/Index.ets 冲突)

export class CameraOverlay {
  // TODO(E2): 加 @Component 装饰器 + 相机预览 + 快门 + 相册 UI
}
