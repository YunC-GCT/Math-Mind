// MathMind - AI 设置页
// 责任: Z
// 创建: 2026-07-14 — 精简拍照链 UI
//
// 功能:
//   - API Key 输入（密码框）
//   - 连接测试按钮
//   - 当前模型/端点展示（只读）
//   - 保存/清除按钮

import {
  MINT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4,
  R_MD, R_LG, R_XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG,
} from 'common';
import { LlmConfig, LlmClient } from 'common';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AiSettingsPage {
  @State apiKey: string = '';
  @State configured: boolean = false;
  @State testing: boolean = false;
  @State endpoint: string = '';
  @State model: string = '';
  @State statusText: string = '未配置';

  aboutToAppear(): void {
    this.loadConfig();
  }

  async loadConfig(): Promise<void> {
    const config = LlmConfig.getInstance();
    const key: string | null = await config.getApiKey();
    if (key !== null && key.length > 0) {
      this.apiKey = key;
      this.configured = true;
      this.statusText = '已配置';
    }
    this.endpoint = config.getEndpoint();
    this.model = config.getModel();
  }

  async handleSave(): Promise<void> {
    const trimmed: string = this.apiKey.trim();
    if (trimmed.length === 0) {
      promptAction.showToast({ message: '请输入 API Key', duration: 1500 });
      return;
    }
    try {
      await LlmConfig.getInstance().setApiKey(trimmed);
      this.configured = true;
      this.statusText = '已配置';
      promptAction.showToast({ message: 'API Key 已保存', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '保存失败: ' + JSON.stringify(e), duration: 2000 });
    }
  }

  async handleClear(): Promise<void> {
    try {
      await LlmConfig.getInstance().clearApiKey();
      this.apiKey = '';
      this.configured = false;
      this.statusText = '未配置';
      promptAction.showToast({ message: 'API Key 已清除', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '清除失败', duration: 1500 });
    }
  }

  async handleTest(): Promise<void> {
    if (this.apiKey.trim().length === 0) {
      promptAction.showToast({ message: '请先输入 API Key', duration: 1500 });
      return;
    }
    this.testing = true;
    try {
      const client = new LlmClient();
      const reply: string = await client.call([
        { role: 'system', content: 'You are a helpful assistant. Reply with just "OK".' },
        { role: 'user', content: 'Say OK' },
      ]);
      if (reply.length > 0) {
        promptAction.showToast({ message: '连接成功 ?', duration: 1500 });
        this.statusText = '已配置 · 连接正常';
      }
    } catch (e) {
      promptAction.showToast({ message: '连接失败 ? ' + JSON.stringify(e), duration: 2500 });
      this.statusText = '已配置 · 连接失败';
    } finally {
      this.testing = false;
    }
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Text('← 返回')
          .fontSize(F_SM)
          .fontColor(MINT)
          .onClick(() => { router.back(); });

        Blank();

        Text('AI 设置')
          .fontSize(F_MD)
          .fontWeight(600)
          .fontColor(TEXT);

        Blank();
        Row().width(60);
      }
      .width('100%')
      .padding({ left: S_2, right: S_2, top: 12, bottom: 12 });

      // 分隔线
      Row().width('100%').height(0.5).backgroundColor(BORDER);

      Scroll() {
        Column() {
          // ===== 状态卡片 =====
          Row() {
            Column() {
              Text('状态')
                .fontSize(F_XS)
                .fontColor(TEXT_3)
                .margin({ bottom: 4 });
              Text(this.statusText)
                .fontSize(F_BASE)
                .fontWeight(600)
                .fontColor(this.configured ? MINT : TEXT_4);
            }
            .alignItems(HorizontalAlign.Start);

            Blank();

            // 状态指示灯
            Row()
              .width(10).height(10)
              .borderRadius(5)
              .backgroundColor(this.configured ? MINT : '#FF666666');
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .borderRadius(R_LG)
          .backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2, top: 16 });

          // ===== 模型信息 (只读) =====
          Column() {
            this.InfoRow('模型', this.model);
            Row().width('100%').height(0.5).backgroundColor(BORDER);
            this.InfoRow('端点', this.endpoint);
          }
          .width('100%')
          .borderRadius(R_LG)
          .backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2, top: 12 });

          // ===== API Key 输入 =====
          Column() {
            Text('API Key')
              .fontSize(F_XS)
              .fontColor(TEXT_3)
              .margin({ left: 16, top: 14 });

            TextInput({
              text: this.apiKey,
              placeholder: '输入 SiliconFlow / DeepSeek API Key...',
            })
              .type(InputType.Password)
              .width('100%')
              .height(44)
              .fontSize(F_SM)
              .fontColor(TEXT)
              .placeholderColor(TEXT_4)
              .backgroundColor('transparent')
              .margin({ left: 16, right: 16, top: 8 })
              .onChange((value: string) => {
                this.apiKey = value;
              });

            // 按钮行
            Row() {
              // 测试连接
              Button(this.testing ? '测试中...' : '测试连接')
                .fontSize(F_XS)
                .fontColor(PURPLE)
                .height(34)
                .borderRadius(R_MD)
                .backgroundColor(PURPLE_LIGHT)
                .enabled(!this.testing)
                .onClick(() => { this.handleTest(); });

              Blank();

              // 清除
              Button('清除')
                .fontSize(F_XS)
                .fontColor('#FFFF6B6B')
                .height(34)
                .borderRadius(R_MD)
                .backgroundColor('#1AFF6B6B')
                .onClick(() => { this.handleClear(); });

              // 保存
              Button('保存')
                .fontSize(F_XS)
                .fontColor(BG_DARK)
                .height(34)
                .borderRadius(R_MD)
                .backgroundColor(MINT)
                .margin({ left: 8 })
                .onClick(() => { this.handleSave(); });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 14 });
          }
          .width('100%')
          .borderRadius(R_LG)
          .backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2, top: 12 });
        }
        .width('100%')
        .padding({ bottom: 40 });
      }
      .layoutWeight(1)
      .width('100%');
    }
    .width('100%').height('100%')
    .backgroundColor(BG_DARK);
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(F_SM)
        .fontColor(TEXT_3)
        .width(48)
        .flexShrink(0);

      Text(value)
        .fontSize(F_XS)
        .fontColor(TEXT_2)
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 });
  }
}