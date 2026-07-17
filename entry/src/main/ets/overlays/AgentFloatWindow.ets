// ============================================================================
//  overlays/AgentFloatWindow.ets — 智能体浮窗(装配层)
//  ----------------------------------------------------------------------------
//  职责: AI 对话浮窗,从右下角弹出,支持文字 + 图片混合输入,真实调 LLM。
//
//  子组件:
//    AgentMessageList  — 消息列表 (Scroll + 气泡 + 空状态 + 打字指示器)
//    ImagePreviewBar   — 图片预览行
//    AgentInputBar     — 底部输入栏 (输入框 + 拍照 + 发送)
//
//  关键能力:
//    - send(): 发送文字 → LlmClient → DeepSeek
//    - captureReply(): 图片 + 文字 → AiService.capture() → 整链
//    - 4 快捷 prompt: sendQuick(prompt) 触发
//    - 键盘监听: 关闭时 aboutToDisappear 注销
//
//  Props:
//    show:              父组件控制可见性
//    onClose:           关闭浮窗回调
//    onGoCamera:        打开拍照回调
//    pendingImageUri:   拍照后图片 URI,@Watch 触发 imagePreview 存
//
//  来源: W1.2 重写,2026-07-17 拆分子组件
//  ============================================================================

import {
  MINT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4, S_5,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL,
} from 'common';
import { KnowledgeUnit, LlmClient, LlmConfig } from 'common';
import { AiService } from '../services/AiService';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import window from '@ohos.window';
import { AgentMessageList } from './AgentFloatWindow/AgentMessageList';
import { ImagePreviewBar } from './AgentFloatWindow/ImagePreviewBar';
import { AgentInputBar } from './AgentFloatWindow/AgentInputBar';

// 消息类型
interface ChatMsg {
  id: number;
  role: 'user' | 'ai';
  content: string;
  ts: number;
}

function nowId(): number {
  return Date.now() * 1000 + Math.floor(Math.random() * 1000);
}

@Component
export struct AgentFloatWindow {
  @Prop show: boolean = false;
  onClose: () => void = (): void => {};
  onGoCamera: () => void = (): void => {};
  @Prop @Watch('onPendingImageChange') pendingImageUri: string = '';

  @State messages: ChatMsg[] = [];
  @State inputText: string = '';
  @State busy: boolean = false;
  @State imagePreview: string = '';
  @State keyboardHeight: number = 0;
  private mainWindow: window.Window | null = null;

  aboutToAppear(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.imagePreview = this.pendingImageUri;
    }
    if (AppStorage.get<boolean>('shownGreeting') !== true) {
      this.messages = [{
        id: 1, role: 'ai',
        content: '👋 你好我是 MathMind AI 助手\n\n点击上方 4 个快捷按钮(分析题目/总结知识/出练习题/学习路径)开始对话,或直接在底部输入问题',
        ts: Date.now(),
      }];
      AppStorage.setOrCreate<boolean>('shownGreeting', true);
    }
    try {
      const ctx = this.getUIContext().getHostContext();
      if (ctx) {
        window.getLastWindow(ctx).then((win: window.Window) => {
          this.mainWindow = win;
          win.on('keyboardHeightChange', (data: number) => {
            try { this.keyboardHeight = this.getUIContext().px2vp(data); } catch (e) {}
          });
        }).catch((err: Error) => {});
      }
    } catch (e) {}
  }

  aboutToDisappear(): void {
    if (this.mainWindow) { this.mainWindow.off('keyboardHeightChange'); }
  }

  onPendingImageChange(): void {
    console.info('[AgentFloatWindow.onPendingImageChange] pendingImageUri=' + this.pendingImageUri);
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.imagePreview = this.pendingImageUri;
      console.info('[AgentFloatWindow.onPendingImageChange] imagePreview set, len=' + this.imagePreview.length);
    }
  }

  private canSend(): boolean {
    return !this.busy && (this.inputText.trim().length > 0 || this.imagePreview.length > 0);
  }

  // ===== 业务逻辑 =====

  private send = (): void => {
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    const hasText: boolean = text.length > 0;
    if (!hasText && !hasImage) { return; }
    if (this.busy) {
      promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 });
      return;
    }
    const imageUri: string = this.imagePreview;
    const content: string = hasImage ? (hasText ? text : '分享了一张照片') : text;
    this.messages = [...this.messages, { id: nowId(), role: 'user', content, ts: Date.now() }];
    this.inputText = '';
    this.imagePreview = '';
    if (hasImage) { this.captureReply(imageUri, text); return; }
    this.realReply(content);
  };

  private sendQuick = (prompt: string): void => {
    if (this.busy) {
      promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 });
      return;
    }
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    const imageUri: string = this.imagePreview;
    let content: string = prompt;
    if (text.length > 0) { content += '\n' + text; }
    if (hasImage) { content += '\n分享了一张照片'; }
    this.messages = [...this.messages, { id: nowId(), role: 'user', content, ts: Date.now() }];
    this.inputText = '';
    this.imagePreview = '';
    if (hasImage) { this.captureReply(imageUri, content); return; }
    this.realReply(content);
  };

  private captureReply = async (imageUri: string, userText: string): Promise<void> => {
    this.busy = true;
    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) { this.addAiMsg('⚠️ 请先在「我的 → 设置」中配置 API Key'); this.busy = false; return; }
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const unit: KnowledgeUnit = await new AiService(ctx).capture(imageUri, userText);
      this.bumpNotesVersion();
      this.addAiMsg('已识别并整理为知识点:\n' + unit.title + '\n\n' + unit.summary);
    } catch (e) {
      this.addAiMsg('图片处理失败: ' + ((e as Error).message ?? String(e)).substring(0, 120));
    } finally { this.busy = false; }
  };

  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true;
    try {
      const configured: boolean = await LlmConfig.getInstance().isConfigured();
      if (!configured) { this.addAiMsg('⚠️ 请先在「我的 → 设置」中配置 API Key'); this.busy = false; return; }
      const client = new LlmClient();
      const reply: string = await client.call([
        { role: 'system', content: '你是 MathMind AI 助手,专门帮助用户解决数学问题。请用简洁清晰的中文回答,适当使用 LaTeX 公式。' },
        { role: 'user', content: userContent },
      ]);
      this.addAiMsg(reply);
      this.persistTextNote(userContent);
    } catch (e) {
      const errMsg: string = (e as Error).message ?? String(e);
      if (errMsg.indexOf('NO_API_KEY') >= 0) { this.addAiMsg('⚠️ 请先在「我的 → 设置」中配置 API Key'); }
      else if (errMsg.indexOf('NETWORK_ERROR') >= 0) { this.addAiMsg('⚠️ 网络连接失败,请检查网络后重试'); }
      else { this.addAiMsg('⚠️ AI 回复异常: ' + errMsg.substring(0, 100)); }
    } finally { this.busy = false; }
  };

  private persistTextNote = (content: string): void => {
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      new AiService(ctx).captureText(content).then((_unit: KnowledgeUnit): void => {
        console.info('[AgentFloatWindow] text note persisted, id=' + _unit.id);
        this.bumpNotesVersion();
      }).catch((e: Error): void => { console.warn('[AgentFloatWindow] text note persist failed: ' + e.message); });
    } catch (e) { console.warn('[AgentFloatWindow] persistTextNote init failed: ' + (e as Error).message); }
  };

  private bumpNotesVersion = (): void => {
    const cur: number = AppStorage.get<number>('notesVersion') ?? 0;
    AppStorage.setOrCreate('notesVersion', cur + 1);
  };

  private addAiMsg = (content: string): void => {
    this.messages = [...this.messages, { id: nowId(), role: 'ai', content: content, ts: Date.now() }];
  };

  // ===== UI Builders (内联) =====

  @Builder
  Header() {
    Row() {
      Text('🧠 MathMind AI').fontSize(F_SM + 1).fontWeight(700).fontColor(PURPLE);
      Blank();
      this.CloseBtn();
    }.width('100%').padding({ left: 14, right: 8, top: 8, bottom: 8 });
  }

  @Builder
  CloseBtn() {
    Stack() {
      Text('✕').fontSize(14).fontWeight(500).fontColor(TEXT_3);
    }.width(24).height(24).borderRadius(12).alignContent(Alignment.Center).onClick((): void => this.onClose());
  }

  @Builder
  SugBtn(label: string, prompt: string) {
    Text(label).fontSize(F_XS).fontColor(PURPLE)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(10).backgroundColor(PURPLE_LIGHT)
      .onClick((): void => this.sendQuick(prompt));
  }

  // ===== build(装配层) =====

  build() {
    Stack() {
      if (this.show) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('#80000000')
          .onClick((): void => this.onClose());

        Column() {
          // 顶栏
          this.Header();
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          // 4 快捷按钮
          Row() {
            this.SugBtn('分析题目', '帮我分析这道题');
            this.SugBtn('总结知识', '总结知识点');
            this.SugBtn('出练习题', '出几道练习题');
            this.SugBtn('学习路径', '推荐学习路径');
          }.width('100%').padding({ left: 10, right: 10, top: 6, bottom: 6 });

          Row().width('100%').height(0.5).backgroundColor(BORDER);

          // 消息列表 (子组件)
          AgentMessageList({ messages: this.messages, busy: this.busy });

          Row().width('100%').height(0.5).backgroundColor(BORDER);

          // 图片预览行 (子组件)
          ImagePreviewBar({
            imagePreview: this.imagePreview,
            onClear: (): void => { this.imagePreview = ''; },
          });

          // 底部输入栏 (子组件)
          AgentInputBar({
            inputText: this.inputText,
            canSend: this.canSend(),
            onTextChange: (v: string): void => { this.inputText = v; },
            onSubmit: (): void => { this.send(); },
            onCamera: (): void => { this.onGoCamera(); },
          });
        }
        .width('100%').height('40%')
        .position({ x: 0, y: '100%' })
        .markAnchor({ x: 0, y: '100%' })
        .translate({ y: -(74 + this.keyboardHeight) })
        .backgroundColor('#F20A0C10')
        .borderRadius(20)
        .border({ width: 1, color: PURPLE_LIGHT })
        .shadow({ radius: 20, color: '#CC000000', offsetX: 0, offsetY: -4 })
        .margin({ left: 12, right: 12 });
      }
    }
    .width('100%').height('100%')
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None);
  }
}
