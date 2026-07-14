// MathMind - 模型配置页
// 创建: 2026-07-14 · 更新: endpoint预设 + 模型选择器 + 状态栏适配

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

// 预设端点
const ENDPOINT_PRESETS: string[] = [
  'https://api.siliconflow.cn/v1/chat/completions',
  'https://api.deepseek.com/chat/completions',
];
const ENDPOINT_LABELS: string[] = ['硅基流动 (SiliconFlow)', 'DeepSeek 官方 (api.deepseek.com)'];

// 预设模型
interface ModelPreset { label: string; value: string; }
// SiliconFlow 格式 — 模型名带 `deepseek-ai/` 前缀
const SF_MODELS: ModelPreset[] = [
  { label: 'DeepSeek-V3', value: 'deepseek-ai/DeepSeek-V3' },
  { label: 'DeepSeek-R1', value: 'deepseek-ai/DeepSeek-R1' },
];
// DeepSeek 官方格式 — 直接模型名
const DS_MODELS: ModelPreset[] = [
  { label: 'DeepSeek-V4-Flash', value: 'deepseek-v4-flash' },
  { label: 'DeepSeek-V4-Pro', value: 'deepseek-v4-pro' },
];

@Entry
@Component
struct AiSettingsPage {
  // 状态栏偏移
  @StorageProp('statusBarHeight') statusBarH: number = 0;

  @State apiKey: string = '';
  @State endpoint: string = '';
  @State endpointIdx: number = 0;
  @State endpointCustom: string = '';
  @State useCustomEndpoint: boolean = false;

  @State model: string = '';
  @State modelIdx: number = 0;
  @State modelCustom: string = '';
  @State useCustomModel: boolean = false;

  @State temperature: number = 0.1;
  @State maxTokens: number = 256;
  @State timeoutMs: number = 5000;
  @State configured: boolean = false;
  @State testing: boolean = false;
  @State showKey: boolean = false;
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
    const ep = c.getEndpoint();
    const m = c.getModel();

    // 匹配端点预设
    let epMatch = -1;
    for (let i = 0; i < ENDPOINT_PRESETS.length; i++) {
      if (ep === ENDPOINT_PRESETS[i]) { epMatch = i; break; }
    }
    if (epMatch >= 0) {
      this.endpointIdx = epMatch;
      this.useCustomEndpoint = false;
    } else {
      this.endpointCustom = ep;
      this.useCustomEndpoint = true;
    }
    this.endpoint = ep;

    // 匹配模型预设
    let mMatch = -1;
    for (let i = 0; i < this.getModelPresets().length; i++) {
      if (m === MODEL_PRESETS[i].value) { mMatch = i; break; }
    }
    if (mMatch >= 0) {
      this.modelIdx = mMatch;
      this.useCustomModel = false;
    } else {
      this.modelCustom = m;
      this.useCustomModel = true;
    }
    this.model = m;

    this.temperature = c.getTemperature();
    this.maxTokens = c.getMaxTokens();
    this.timeoutMs = c.getTimeoutMs();
    this.tempText = this.temperature.toString();
    this.maxTokensText = this.maxTokens.toString();
    this.timeoutText = this.timeoutMs.toString();
  }

  // 当前实际端点/模型
  private getCurrentEndpoint(): string {
    return this.useCustomEndpoint ? this.endpointCustom : ENDPOINT_PRESETS[this.endpointIdx];
  }
  private getModelPresets(): ModelPreset[] { return this.useCustomEndpoint || this.endpointIdx !== 1 ? SF_MODELS : DS_MODELS; }
  private getCurrentModel(): string {
    return this.useCustomModel ? this.modelCustom : MODEL_PRESETS[this.modelIdx].value;
  }

  async handleSave(): Promise<void> {
    try {
      const tp = parseFloat(this.tempText);
      const mt = parseInt(this.maxTokensText);
      const to = parseInt(this.timeoutText);
      if (isNaN(tp) || isNaN(mt) || isNaN(to)) {
        promptAction.showToast({ message: '参数必须为数字', duration: 2000 });
        return;
      }
      const c = LlmConfig.getInstance();
      await c.saveAll(
        this.getCurrentEndpoint(), this.getCurrentModel(),
        tp, mt, to,
      );
      if (this.apiKey.trim().length > 0) {
        await c.setApiKey(this.apiKey.trim());
        this.configured = true;
        this.statusText = '已保存';
      }
      promptAction.showToast({ message: '配置已保存', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  async handleReset(): Promise<void> {
    try {
      await LlmConfig.getInstance().resetDefaults();
      await LlmConfig.getInstance().clearApiKey();
      this.apiKey = '';
      this.endpointIdx = 0;
      this.useCustomEndpoint = false;
      this.endpointCustom = '';
      this.modelIdx = 0;
      this.useCustomModel = false;
      this.modelCustom = '';
      this.configured = false;
      this.statusText = '已恢复默认';
      promptAction.showToast({ message: '已恢复默认', duration: 1500 });
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
    const c = LlmConfig.getInstance();
    await c.setApiKey(key);
    // 临时写入当前端点/模型用于测试
    await c.saveAll(
      this.getCurrentEndpoint(), this.getCurrentModel(),
      this.temperature, this.maxTokens, this.timeoutMs,
    );
    this.testing = true;
    try {
      const client = new LlmClient();
      await client.call([
        { role: 'system', content: 'Reply "OK".' },
        { role: 'user', content: 'OK' },
      ]);
      promptAction.showToast({ message: '连接成功', duration: 1500 });
      this.statusText = '已配置 · 连接正常';
    } catch (e) {
      promptAction.showToast({ message: '连接失败: ' + JSON.stringify(e), duration: 2500 });
      this.statusText = '已配置 · 连接失败';
    } finally {
      this.testing = false;
    }
  }

  build() {
    Column() {
      // 顶栏 — 加 statusBarH 避让状态栏
      Row() {
        Text('← 返回')
          .fontSize(F_SM).fontColor(MINT)
          .onClick(() => { router.back(); });
        Blank();
        Text('模型配置')
          .fontSize(F_MD).fontWeight(600).fontColor(TEXT);
        Blank();
        Row().width(60);
      }
      .width('100%').padding({ left: S_2, right: S_2, top: 12, bottom: 12 })
      .margin({ top: this.statusBarH });

      Row().width('100%').height(0.5).backgroundColor(BORDER);

      Scroll() {
        Column() {
          // ===== 状态 =====
          Row() {
            Column() {
              Text('连接状态').fontSize(F_XS).fontColor(TEXT_3).margin({ bottom: 4 });
              Text(this.statusText).fontSize(F_BASE).fontWeight(600)
                .fontColor(this.configured ? MINT : TEXT_4);
            }.alignItems(HorizontalAlign.Start);
            Blank();
            Row().width(10).height(10).borderRadius(5)
              .backgroundColor(this.configured ? MINT : '#FF666666');
          }
          .width('100%').padding(16).borderRadius(R_LG)
          .backgroundColor(BG_CARD).margin({ left: S_2, right: S_2, top: 16 });

          // ===== 端点选择 =====
          this.SectionHeader('服务端点', '选择预设或输入自定义地址');
          Column() {
            ForEach(ENDPOINT_PRESETS, (ep: string, i: number) => {
              Row() {
                Radio({ value: 'ep' + i, group: 'endpoint' })
                  .checked(!this.useCustomEndpoint && this.endpointIdx === i)
                  .onChange((v: boolean) => { if (v) { this.useCustomEndpoint = false; this.endpointIdx = i; } });
                Column() {
                  Text(ENDPOINT_LABELS[i]).fontSize(F_SM).fontColor(TEXT);
                  Text(ep).fontSize(10).fontColor(TEXT_4).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis });
                }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1);
              }
              .width('100%').padding({ left: 4, right: 4, top: 6, bottom: 6 });
            }, (ep: string, i: number) => i.toString());

            // 自定义端点
            Row() {
              Radio({ value: 'ep_custom', group: 'endpoint' })
                .checked(this.useCustomEndpoint)
                .onChange((v: boolean) => { if (v) { this.useCustomEndpoint = true; } });
              Text('自定义').fontSize(F_SM).fontColor(TEXT_3).margin({ left: 8 }).width(50);
              TextInput({ text: this.endpointCustom, placeholder: 'https://...' })
                .layoutWeight(1).height(34).fontSize(F_XS)
                .fontColor(TEXT).placeholderColor(TEXT_4).backgroundColor('#0AFFFFFF')
                .borderRadius(R_MD)
                .onChange((v: string) => { this.endpointCustom = v; });
            }
            .width('100%').padding({ left: 4, right: 8, top: 6, bottom: 10 });
          }
          .width('100%').borderRadius(R_LG).backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2 });

          // ===== 模型选择 =====
          this.SectionHeader('模型', '选择 DeepSeek 模型或自定义');
          Column() {
            ForEach(this.getModelPresets(), (mp: ModelPreset, i: number) => {
              Row() {
                Radio({ value: 'md' + i, group: 'model' })
                  .checked(!this.useCustomModel && this.modelIdx === i)
                  .onChange((v: boolean) => { if (v) { this.useCustomModel = false; this.modelIdx = i; } });
                Text(mp.label).fontSize(F_SM).fontColor(TEXT).margin({ left: 8 }).layoutWeight(1);
                Text(mp.value).fontSize(10).fontColor(TEXT_4).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
              }
              .width('100%').padding({ left: 4, right: 4, top: 6, bottom: 6 });
            }, (mp: ModelPreset, i: number) => i.toString());

            Row() {
              Radio({ value: 'md_custom', group: 'model' })
                .checked(this.useCustomModel)
                .onChange((v: boolean) => { if (v) { this.useCustomModel = true; } });
              Text('自定义').fontSize(F_SM).fontColor(TEXT_3).margin({ left: 8 }).width(50);
              TextInput({ text: this.modelCustom, placeholder: 'model-id' })
                .layoutWeight(1).height(34).fontSize(F_XS)
                .fontColor(TEXT).placeholderColor(TEXT_4).backgroundColor('#0AFFFFFF')
                .borderRadius(R_MD)
                .onChange((v: string) => { this.modelCustom = v; });
            }
            .width('100%').padding({ left: 4, right: 8, top: 6, bottom: 10 });
          }
          .width('100%').borderRadius(R_LG).backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2 });

          // ===== API Key =====
          this.SectionHeader('API Key', '从模型服务商获取的密钥，支持复制粘贴');
          Row() {
            // 显示/隐藏切换
            Text(this.showKey ? '🙈' : '👁')
              .fontSize(18).width(36).textAlign(TextAlign.Center)
              .onClick(() => { this.showKey = !this.showKey; });

            TextInput({ text: this.apiKey, placeholder: 'sk-...' })
              .type(this.showKey ? InputType.Normal : InputType.Password)
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

          // ===== 请求参数 =====
          this.SectionHeader('请求参数', '');
          Column() {
            this.NumberRow('温度', this.tempText, '0 - 2', (v: string) => { this.tempText = v; });
            Row().width('100%').height(0.5).backgroundColor(BORDER);
            this.NumberRow('最大 Token', this.maxTokensText, '1 - 8192', (v: string) => { this.maxTokensText = v; });
            Row().width('100%').height(0.5).backgroundColor(BORDER);
            this.NumberRow('超时(毫秒)', this.timeoutText, '1000 - 60000', (v: string) => { this.timeoutText = v; });
          }
          .width('100%').borderRadius(R_LG).backgroundColor(BG_CARD)
          .margin({ left: S_2, right: S_2 });

          // ===== 操作按钮 =====
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

  @Builder SectionHeader(title: string, desc: string) {
    Column() {
      Text(title).fontSize(F_SM).fontWeight(600).fontColor(TEXT);
      if (desc.length > 0) {
        Text(desc).fontSize(F_XS).fontColor(TEXT_4).margin({ top: 2 });
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').padding({ left: 20, right: S_2, top: 20, bottom: 8 });
  }

  @Builder NumberRow(label: string, value: string, hint: string, onChange: (v: string) => void) {
    Row() {
      Column() {
        Text(label).fontSize(F_SM).fontColor(TEXT_2);
        Text(hint).fontSize(10).fontColor(TEXT_4).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start);
      Blank();
      TextInput({ text: value, placeholder: hint })
        .type(InputType.Number).width(90).height(34)
        .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
        .backgroundColor('#0AFFFFFF').borderRadius(R_MD).textAlign(TextAlign.Center)
        .onChange(onChange);
    }
    .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 });
  }
}