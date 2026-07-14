// MathMind - 模型配置页
// 创建: 2026-07-14

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
  @State endpoint: string = '';
  @State model: string = '';
  @State temperature: number = 0.1;
  @State maxTokens: number = 256;
  @State timeoutMs: number = 5000;
  @State configured: boolean = false;
  @State testing: boolean = false;
  @State statusText: string = '未配置';
  @State tempText: string = '0.1';
  @State maxTokensText: string = '256';
  @State timeoutText: string = '5000';

  aboutToAppear(): void {
    this.loadConfig();
  }

  async loadConfig(): Promise<void> {
    const c = LlmConfig.getInstance();
    const key = await c.getApiKey();
    if (key !== null && key.length > 0) {
      this.apiKey = key;
      this.configured = true;
      this.statusText = '已配置';
    }
    this.endpoint = c.getEndpoint();
    this.model = c.getModel();
    this.temperature = c.getTemperature();
    this.maxTokens = c.getMaxTokens();
    this.timeoutMs = c.getTimeoutMs();
    this.tempText = this.temperature.toString();
    this.maxTokensText = this.maxTokens.toString();
    this.timeoutText = this.timeoutMs.toString();
  }

  async handleSave(): Promise<void> {
    try {
      const c = LlmConfig.getInstance();
      // 处理数字字段
      const tp = parseFloat(this.tempText);
      const mt = parseInt(this.maxTokensText);
      const to = parseInt(this.timeoutText);
      if (isNaN(tp) || isNaN(mt) || isNaN(to)) {
        promptAction.showToast({ message: '温度/最大Token/超时 必须为数字', duration: 2000 });
        return;
      }
      this.temperature = tp;
      this.maxTokens = mt;
      this.timeoutMs = to;

      // 保存所有配置
      await c.saveAll(this.endpoint, this.model, this.temperature, this.maxTokens, this.timeoutMs);

      // 处理 API Key
      if (this.apiKey.trim().length > 0) {
        await c.setApiKey(this.apiKey.trim());
        this.configured = true;
        this.statusText = '已保存';
      } else {
        this.configured = false;
        this.statusText = '未配置 API Key';
      }
      promptAction.showToast({ message: '配置已保存', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  async handleReset(): Promise<void> {
    try {
      await LlmConfig.getInstance().resetDefaults();
      await this.loadConfig();
      this.apiKey = '';
      this.configured = false;
      this.statusText = '已恢复默认';
      promptAction.showToast({ message: '已恢复默认配置', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '恢复失败', duration: 1500 });
    }
  }

  async handleTest(): Promise<void> {
    const key = this.apiKey.trim();
    if (key.length === 0) {
      promptAction.showToast({ message: '请先输入 API Key', duration: 1500 });
      return;
    }
    // 先临时保存以便测试
    const c = LlmConfig.getInstance();
    await c.setApiKey(key);
    this.testing = true;
    try {
      const client = new LlmClient();
      const reply = await client.call([
        { role: 'system', content: 'Reply with just "OK".' },
        { role: 'user', content: 'Say OK' },
      ]);
      if (reply.length > 0) {
        promptAction.showToast({ message: '连接成功', duration: 1500 });
        this.statusText = '已配置 · 连接正常';
      }
    } catch (e) {
      promptAction.showToast({ message: '连接失败: ' + JSON.stringify(e), duration: 2500 });
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
        Text('模型配置')
          .fontSize(F_MD).fontWeight(600).fontColor(TEXT);
        Blank();
        Row().width(60);
      }
      .width('100%').padding({ left: S_2, right: S_2, top: 12, bottom: 12 });
      Row().width('100%').height(0.5).backgroundColor(BORDER);

      Scroll() {
        Column() {
          // ===== 状态卡 =====
          Row() {
            Column() {
              Text('连接状态')
                .fontSize(F_XS).fontColor(TEXT_3).margin({ bottom: 4 });
              Text(this.statusText)
                .fontSize(F_BASE).fontWeight(600)
                .fontColor(this.configured ? MINT : TEXT_4);
            }.alignItems(HorizontalAlign.Start);
            Blank();
            Row().width(10).height(10).borderRadius(5)
              .backgroundColor(this.configured ? MINT : '#FF666666');
          }
          .width('100%').padding(16).borderRadius(R_LG)
          .backgroundColor(BG_CARD).margin({ left: S_2, right: S_2, top: 16 });

          // ===== 服务端点 =====
          this.SectionHeader('服务端点', 'OpenAI 兼容的 API 地址');
          this.InputField(this.endpoint, 'https://api.siliconflow.cn/v1/chat/completions',
            (v: string) => { this.endpoint = v; });

          // ===== 模型名称 =====
          this.SectionHeader('模型名称', '如 deepseek-ai/DeepSeek-V3');
          this.InputField(this.model, 'deepseek-ai/DeepSeek-V3',
            (v: string) => { this.model = v; });

          // ===== API Key =====
          this.SectionHeader('API Key', '从模型服务商获取的密钥');
          Row() {
            TextInput({ text: this.apiKey, placeholder: 'sk-...' })
              .type(InputType.Password)
              .layoutWeight(1).height(42)
              .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
              .backgroundColor('transparent')
              .onChange((v: string) => { this.apiKey = v; });
            Button(this.testing ? '...' : '测试')
              .fontSize(F_XS).fontColor(BG_DARK)
              .height(34).borderRadius(R_MD).backgroundColor(MINT)
              .enabled(!this.testing).margin({ left: 8 })
              .onClick(() => { this.handleTest(); });
          }
          .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(R_LG).backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2 });

          // ===== 参数 =====
          this.SectionHeader('请求参数', '');
          Column() {
            // Temperature
            this.NumberRow('温度', this.tempText, '0 - 2', (v: string) => { this.tempText = v; });
            Row().width('100%').height(0.5).backgroundColor(BORDER);
            // Max Tokens
            this.NumberRow('最大 Token', this.maxTokensText, '1 - 8192', (v: string) => { this.maxTokensText = v; });
            Row().width('100%').height(0.5).backgroundColor(BORDER);
            // Timeout
            this.NumberRow('超时(毫秒)', this.timeoutText, '1000 - 60000', (v: string) => { this.timeoutText = v; });
          }
          .width('100%').borderRadius(R_LG).backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2 });

          // ===== 按钮 =====
          Row() {
            Button('恢复默认')
              .fontSize(F_SM).fontColor(PURPLE)
              .height(44).borderRadius(R_MD).backgroundColor(PURPLE_LIGHT)
              .layoutWeight(1)
              .onClick(() => { this.handleReset(); });
            Button('保存配置')
              .fontSize(F_SM).fontColor(BG_DARK)
              .height(44).borderRadius(R_MD).backgroundColor(MINT)
              .layoutWeight(1).margin({ left: 12 })
              .onClick(() => { this.handleSave(); });
          }
          .width('100%').padding({ left: S_2, right: S_2, top: 20 });

          Blank().height(40);
        }.width('100%');
      }
      .layoutWeight(1).width('100%');
    }
    .width('100%').height('100%').backgroundColor(BG_DARK);
  }

  @Builder
  SectionHeader(title: string, desc: string) {
    Column() {
      Text(title)
        .fontSize(F_SM).fontWeight(600).fontColor(TEXT);
      if (desc.length > 0) {
        Text(desc)
          .fontSize(F_XS).fontColor(TEXT_4).margin({ top: 2 });
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').padding({ left: 20, right: S_2, top: 20, bottom: 8 });
  }

  @Builder
  InputField(value: string, placeholder: string, onChange: (v: string) => void) {
    TextInput({ text: value, placeholder: placeholder })
      .width('100%').height(42)
      .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
      .backgroundColor('transparent')
      .padding({ left: 16, right: 16 })
      .borderRadius(R_LG).backgroundColor(BG_CARD)
      .margin({ left: S_2, right: S_2 })
      .onChange(onChange);
  }

  @Builder
  NumberRow(label: string, value: string, hint: string, onChange: (v: string) => void) {
    Row() {
      Column() {
        Text(label).fontSize(F_SM).fontColor(TEXT_2);
        Text(hint).fontSize(10).fontColor(TEXT_4).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start);

      Blank();

      TextInput({ text: value, placeholder: hint })
        .type(InputType.Number)
        .width(90).height(34)
        .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
        .backgroundColor('#0AFFFFFF')
        .borderRadius(R_MD).textAlign(TextAlign.Center)
        .onChange(onChange);
    }
    .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 });
  }
}