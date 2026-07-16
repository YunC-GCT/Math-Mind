/**
 * AiTestPageMVP.ets — KnowledgeModel MVP 测试页面
 *
 * 使用方式：
 *   1. 在模拟器/真机上运行 App
 *   2. 底部 navigation 切换到 "我的" Tab
 *   3. 点击"AI 测试"按钮（需手动添加到 MePage）
 *
 * 功能：
 *   - 输入一段数学文本
 *   - 点"发送测试"按钮
 *   - 调用 KnowledgeModelMVP.structure()
 *   - 显示 AI 返回的完整结果
 */

import { KnowledgeModelMVP } from 'agents';
import { NoteDaoInterface } from 'agents';
import { KnowledgeUnitExt } from 'agents';

// Mock NoteDao（测试/演示用，不进真实数据库；正式版注入真实 NoteDao 实现）
class MockNoteDao implements NoteDaoInterface {
  async insert(unit: KnowledgeUnitExt): Promise<number> {
    console.info('[AiTestPageMVP] MockNoteDao.insert ' + unit.title);
    return 1;
  }
  // Mock 版 update 仅打日志，不做实际持久化
  async update(unit: KnowledgeUnitExt): Promise<void> {
    console.info('[AiTestPageMVP] MockNoteDao.update ' + unit.title);
  }
}

@Entry
@Component
struct AiTestPageMVP {
  @State inputText: string = '勾股定理：直角三角形两直角边的平方和等于斜边的平方。';
  @State resultText: string = '';
  @State isLoading: boolean = false;
  @State statusText: string = '就绪';

  build() {
    Column() {
      Text('AI \u5206\u8BCD\u9020\u8868\u6D4B\u8BD5')
        .fontSize(20)
        .fontWeight(700)
        .margin({ top: 20, bottom: 16 });

      TextArea({ placeholder: '\u8BF7\u8F93\u5165\u6570\u5B66\u6587\u672C...', text: this.inputText })
        .height(150)
        .borderRadius(8)
        .border({ width: 1, color: '#ccc' })
        .padding(8)
        .margin({ left: 16, right: 16 })
        .onChange((val: string) => {
          this.inputText = val;
        });

      Button('\u53D1\u9001\u6D4B\u8BD5')
        .width('90%')
        .height(44)
        .backgroundColor('#4A90D9')
        .fontColor('#fff')
        .borderRadius(8)
        .margin({ top: 12 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.runTest();
        });

      Text(this.statusText)
        .fontSize(14)
        .fontColor('#888')
        .margin({ top: 8 });

      Scroll() {
        Text(this.resultText)
          .fontSize(13)
          .fontFamily('monospace')
          .width('100%')
      }
      .height(300)
      .border({ width: 1, color: '#ddd' })
      .borderRadius(8)
      .padding(12)
      .margin({ left: 16, right: 16, top: 12 })
      .layoutWeight(1);

      Divider().margin({ top: 16 });
      Text('\u6CE8\u610F\uFF1A\u9700\u8981 INTERNET \u6743\u9650\u548C API Key')
        .fontSize(12)
        .fontColor('#aaa')
        .margin({ bottom: 16 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }

  async runTest(): Promise<void> {
    if (!this.inputText || this.inputText.trim().length === 0) {
      this.statusText = '\u8BF7\u8F93\u5165\u6587\u672C';
      return;
    }

    this.isLoading = true;
    this.statusText = '\u6B63\u5728\u8C03\u7528 AI...';
    this.resultText = '';

    try {
      const mockDao: MockNoteDao = new MockNoteDao();
      const km: KnowledgeModelMVP = new KnowledgeModelMVP(mockDao);
      const result: KnowledgeUnitExt = await km.structure(this.inputText);

      const output: string =
        '\u2705 \u6210\u529F\n\n' +
        '\u5206\u7C7B: ' + result.type + '\n' +
        '\u6807\u9898: ' + result.title + '\n' +
        '\u96BE\u5EA6: ' + String(result.difficulty) + '/5\n' +
        '\u91CD\u8981\u6027: ' + String(result.importance) + '/5\n' +
        '\u6807\u7B7E: ' + result.tags.join(', ') + '\n' +
        '\u771F\u503C\u68C0\u9A8C: ' + (result.truthFlag ? '\u2713 \u901A\u8FC7' : '\u2717 \u5F02\u5E38') + '\n' +
        (result.truthDetails.length > 0 ? '\u68C0\u9A8C\u8BE6\u60C5: ' + result.truthDetails.join('; ') + '\n' : '') +
        '\n--- \u7ED3\u6784\u5316\u5B57\u6BB5 ---\n';

      let fieldsStr: string = '';
      for (let i: number = 0; i < result.fields.length; i++) {
        const f = result.fields[i];
        fieldsStr = fieldsStr + '[' + f.label + ']\n' + f.value + '\n\n';
      }

      this.resultText = output + (fieldsStr || '(\u65E0\u5B57\u6BB5)');
      this.statusText = '\u5B8C\u6210\uFF0C\u8017\u65F6\u8BF7\u67E5\u770B\u65E5\u5FD7';

    } catch (err) {
      this.resultText = '\u274C \u9519\u8BEF:\n' + String(err);
      this.statusText = '\u8C03\u7528\u5931\u8D25';
    } finally {
      this.isLoading = false;
    }
  }
}
