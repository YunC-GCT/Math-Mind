/**
 * AiTestPage.ets — KnowledgeModel MVP 测试页面
 *
 * 使用方式：
 *   1. 在模拟器/真机上运行 App
 *   2. 底部 navigation 切换到 "我的" Tab
 *   3. 点击"AI 测试"按钮（需手动添加到 MePage）
 *   或直接在代码中调用 navigateToUrl
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

// Mock NoteDao（正式版会注入真实 NoteDao）
class MockNoteDao implements NoteDaoInterface {
  async insert(unit: KnowledgeUnitExt): Promise<number> {
    console.info('[AiTestPage] MockNoteDao.insert ' + unit.title);
    return 1;
  }
}

@Entry
@Component
struct AiTestPage {
  @State inputText: string = '勾股定理：直角三角形两直角边的平方和等于斜边的平方。';
  @State resultText: string = '';
  @State isLoading: boolean = false;
  @State statusText: string = '就绪';

  build() {
    Column() {
      // 标题
      Text('AI 分词造表测试')
        .fontSize(20)
        .fontWeight(700)
        .margin({ top: 20, bottom: 16 });

      // 输入区
      TextArea({ placeholder: '请输入数学文本...', text: this.inputText })
        .height(150)
        .borderRadius(8)
        .border({ width: 1, color: '#ccc' })
        .padding(8)
        .margin({ left: 16, right: 16 })
        .onChange((val: string) => {
          this.inputText = val;
        });

      // 按钮
      Button('发送测试')
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

      // 状态提示
      Text(this.statusText)
        .fontSize(14)
        .fontColor('#888')
        .margin({ top: 8 });

      // 结果区
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

      // 底部填充
      Divider().margin({ top: 16 });
      Text('注意：需要 INTERNET 权限和 API Key')
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
      this.statusText = '请输入文本';
      return;
    }

    this.isLoading = true;
    this.statusText = '正在调用 AI...';
    this.resultText = '';

    try {
      const mockDao: MockNoteDao = new MockNoteDao();
      const km: KnowledgeModelMVP = new KnowledgeModelMVP(mockDao);
      const result: KnowledgeUnitExt = await km.structure(this.inputText);

      // 格式化结果
      const output: string =
        '✅ 成功\n\n' +
        '分类: ' + result.type + '\n' +
        '标题: ' + result.title + '\n' +
        '难度: ' + String(result.difficulty) + '/5\n' +
        '重要性: ' + String(result.importance) + '/5\n' +
        '标签: ' + result.tags.join(', ') + '\n' +
        '真值检验: ' + (result.truthFlag ? '✓ 通过' : '✗ 异常') + '\n' +
        (result.truthDetails.length > 0 ? '检验详情: ' + result.truthDetails.join('; ') + '\n' : '') +
        '\n--- 结构化字段 ---\n';

      let fieldsStr: string = '';
      for (let i: number = 0; i < result.fields.length; i++) {
        const f = result.fields[i];
        fieldsStr = fieldsStr + '[' + f.label + ']\n' + f.value + '\n\n';
      }

      this.resultText = output + (fieldsStr || '(无字段)');
      this.statusText = '完成，耗时请查看日志';

    } catch (err) {
      this.resultText = '❌ 错误:\n' + String(err);
      this.statusText = '调用失败';
    } finally {
      this.isLoading = false;
    }
  }
}

