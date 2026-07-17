// ============================================================================
//  overlays/AgentFloatWindow.ets — 智能体浮窗(纯 UI 装配层)
//  ----------------------------------------------------------------------------
//  职责: UI 组装 + 状态管理 + 用户交互 → 委托 AgentChatService 处理业务
//
//  子组件:
//    AgentMessageList  — 消息列表 (Scroll + 气泡)
//    ImagePreviewBar   — 图片预览行
//    AgentInputBar     — 底部输入栏
//
//  业务逻辑: AgentChatService (services/AgentChatService.ets)
//    captureReply / realReply / persistTextNote
//
//  Props:
//    show / onClose / onGoCamera / pendingImageUri
//  ============================================================================

import {
  MINT, PURPLE, PURPLE_LIGHT,
  TEXT_3, BORDER,
  F_XS, F_SM, F_LG, W_BOLD,
} from 'common';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import window from '@ohos.window';
import { AgentChatService, AgentChatCallbacks } from '../services/AgentChatService';
import { AgentMessageList } from './AgentFloatWindow/AgentMessageList';
import { ImagePreviewBar } from './AgentFloatWindow/ImagePreviewBar';
import { AgentInputBar } from './AgentFloatWindow/AgentInputBar';
import { ChatMsg } from '../prototypes/chat/ChatModels';

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
  private service: AgentChatService | null = null;

  aboutToAppear(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.imagePreview = this.pendingImageUri;
    }
    if (AppStorage.get<boolean>('shownGreeting') !== true) {
      this.messages = [{
        id: 1, role: 'ai',
        content: '👋 你好我是 MathMind AI 助手\n\n点击上方 4 个快捷按钮开始对话,或直接在底部输入问题',
        ts: Date.now(),
      }];
      AppStorage.setOrCreate<boolean>('shownGreeting', true);
    }
    // 绑定业务逻辑回调
    const cbs: AgentChatCallbacks = {
      addAiMsg: (content: string): void => {
        this.messages = [...this.messages, { id: nowId(), role: 'ai', content, ts: Date.now() }];
      },
      bumpNotesVersion: (): void => {
        const cur: number = AppStorage.get<number>('notesVersion') ?? 0;
        AppStorage.setOrCreate('notesVersion', cur + 1);
      },
      setBusy: (v: boolean): void => { this.busy = v; },
      getContext: (): common.UIAbilityContext => getContext(this) as common.UIAbilityContext,
    };
    this.service = new AgentChatService(cbs);
    // 键盘监听
    try {
      const hostCtx = this.getUIContext().getHostContext();
      if (hostCtx) {
        window.getLastWindow(hostCtx).then((win: window.Window) => {
          this.mainWindow = win;
          win.on('keyboardHeightChange', (data: number) => {
            try { this.keyboardHeight = this.getUIContext().px2vp(data); } catch (e) {}
          });
        }).catch(() => {});
      }
    } catch (e) {}
  }

  aboutToDisappear(): void {
    if (this.mainWindow) { this.mainWindow.off('keyboardHeightChange'); }
  }

  onPendingImageChange(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.imagePreview = this.pendingImageUri;
    }
  }

  // ===== 交互逻辑 (轻量编排，业务委托给 service) =====

  private canSend = (): boolean =>
    !this.busy && (this.inputText.trim().length > 0 || this.imagePreview.length > 0);

  private send = (): void => {
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    if (!text && !hasImage) { return; }
    if (this.busy) { promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 }); return; }

    const content: string = hasImage ? (text || '分享了一张照片') : text;
    this.messages = [...this.messages, { id: nowId(), role: 'user', content, ts: Date.now() }];

    const imageUri: string = this.imagePreview;
    this.inputText = '';
    this.imagePreview = '';

    if (hasImage && this.service) { this.service.captureReply(imageUri, text); return; }
    if (this.service) { this.service.realReply(content); }
  };

  private sendQuick = (prompt: string): void => {
    if (this.busy) { promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 }); return; }

    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    let content: string = prompt;
    if (text.length > 0) { content += '\n' + text; }
    if (hasImage) { content += '\n分享了一张照片'; }

    this.messages = [...this.messages, { id: nowId(), role: 'user', content, ts: Date.now() }];

    const imageUri: string = this.imagePreview;
    this.inputText = '';
    this.imagePreview = '';

    if (hasImage && this.service) { this.service.captureReply(imageUri, content); return; }
    if (this.service) { this.service.realReply(content); }
  };

  // ===== @Builders =====

  @Builder
  Header() {
    Row() {
      Text('🧠 MathMind AI').fontSize(F_SM + 1).fontWeight(700).fontColor(PURPLE);
      Blank();
      Stack() {
        Text('✕').fontSize(14).fontWeight(500).fontColor(TEXT_3);
      }.width(24).height(24).borderRadius(12).alignContent(Alignment.Center).onClick((): void => this.onClose());
    }.width('100%').padding({ left: 14, right: 8, top: 8, bottom: 8 });
  }

  @Builder
  SugBtn(label: string, prompt: string) {
    Text(label).fontSize(F_XS).fontColor(PURPLE)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(10).backgroundColor(PURPLE_LIGHT)
      .onClick((): void => this.sendQuick(prompt));
  }

  // ===== build (纯 UI 装配) =====

  build() {
    Stack() {
      if (this.show) {
        Column().width('100%').height('100%').backgroundColor('#80000000')
          .onClick((): void => this.onClose());

        Column() {
          this.Header();
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          Row() {
            this.SugBtn('分析题目', '帮我分析这道题');
            this.SugBtn('总结知识', '总结知识点');
            this.SugBtn('出练习题', '出几道练习题');
            this.SugBtn('学习路径', '推荐学习路径');
          }.width('100%').padding({ left: 10, right: 10, top: 6, bottom: 6 });

          Row().width('100%').height(0.5).backgroundColor(BORDER);

          AgentMessageList({ messages: this.messages, busy: this.busy });

          Row().width('100%').height(0.5).backgroundColor(BORDER);

          ImagePreviewBar({
            imagePreview: this.imagePreview,
            onClear: (): void => { this.imagePreview = ''; },
          });

          AgentInputBar({
            inputText: this.inputText,
            canSend: this.canSend(),
            onTextChange: (v: string): void => { this.inputText = v; },
            onSubmit: (): void => { this.send(); },
            onCamera: (): void => { this.onGoCamera(); },
          });
        }
        .width('100%').height('40%')
        .position({ x: 0, y: '100%' }).markAnchor({ x: 0, y: '100%' })
        .translate({ y: -(74 + this.keyboardHeight) })
        .backgroundColor('#F20A0C10').borderRadius(20)
        .border({ width: 1, color: PURPLE_LIGHT })
        .shadow({ radius: 20, color: '#CC000000', offsetX: 0, offsetY: -4 })
        .margin({ left: 12, right: 12 });
      }
    }
    .width('100%').height('100%')
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None);
  }
}
