// MathMind - TypeClassifier (类型/学科分类器)
// 任务编号: B2
// 责任: D
// 状态: 骨架 mock(2026-07-14) - 接 DispatchPayload discriminated union
// 依赖: LLM 模块(已就位 fecaed1) + ML Kit OCR
//
// 接口约定 (api_contract.md 第 2.2 节):
//   classify(payload: DispatchPayload): Promise<ClassificationResult>
//
//   DispatchPayload:
//     | { kind: 'image'; imageUri: string; userText?: string }
//     | { kind: 'text'; text: string }
//     | { kind: 'file'; fileUri: string; mimeType: string; userText?: string }
//
//   ClassificationResult: {
//     type: '概念' | '计算' | '证明'
//     subject: '高等代数' | '数学分析' | '解析几何'
//     chapter?: string
//     confidence: number    // 0.0-1.0
//     ocrText?: string      // D 真实现时必填(图片/file 路径)
//   }
//
// D 接手时: 删 mock body, 写真实现
//   1) 按 payload.kind 分流:
//      - 'image' / 'file' (image/*) → ML Kit OCR 拿文本
//      - 'text' / 'file' (text/plain) → 直接用
//      - 其他 mime → 暂返 error
//   2) cleanText 清洗
//   3) 调 LlmClient.call() 走 SiliconFlow DeepSeek-V3
//      prompt = system 模板 + ocrText + userText(若有)
//   4) 解析 JSON → ClassificationResult, **必须填 ocrText 字段**

import { ClassificationResult, DispatchPayload } from 'common';

export class TypeClassifier {
  // 骨架 mock: 按 payload.kind 模拟不同的"OCR 文本"输入,
  // 返固定 mock ClassificationResult,让 Dispatcher 整链跑通
  // D 接手时整个 method body 替换掉
  async classify(payload: DispatchPayload): Promise<ClassificationResult> {
    let ocrText: string;
    if (payload.kind === 'image') {
      const ut: string = payload.userText ? ', userText=' + payload.userText : '';
      ocrText = 'mock OCR text from imageUri=' + payload.imageUri + ut;
    } else if (payload.kind === 'text') {
      ocrText = payload.text;
    } else {
      // payload.kind === 'file'
      const ut: string = payload.userText ? ', userText=' + payload.userText : '';
      ocrText = 'mock OCR text from fileUri=' + payload.fileUri
        + ', mime=' + payload.mimeType + ut;
    }
    return {
      type: '计算',
      subject: '高等代数',
      chapter: '行列式',
      confidence: 0.85,
      ocrText: ocrText,
    };
  }
}
