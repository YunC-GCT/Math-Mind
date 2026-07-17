// ============================================================================
//  overlays/AgentFloatWindow/AgentFloatWindow.ets — 智能体浮窗(完整版)
//  ----------------------------------------------------------------------------
//  特性: 拖拽缩放(floatHeight) · 多会话(SessionBar+ChatSession) · 拍照整链(captureReply)
//  子组件: ChatHeader / SessionBar / AgentMessageList / QuickSuggestions / ImagePreviewBar / AgentInputBar
//  业务: AgentChatService
//  ============================================================================

import { MINT, PURPLE, PURPLE_LIGHT, BG_DARK, TEXT_3, TEXT_4, BORDER, S_3, S_6, R_XL, OVERLAY_MASK, SCREEN_H, F_XS } from 'common';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import window from '@ohos.window';
import { AgentChatService, AgentChatCallbacks } from '../../services/AgentChatService';
import { ChatHeader } from '../../prototypes/chat/ChatHeader';
import { QuickSuggestions } from '../../prototypes/chat/QuickSuggestions';
import { ChatSessionManager, sid } from '../../prototypes/chat/ChatSession';
import { SessionBar } from '../../prototypes/chat/SessionBar';
import { ChatMsg, ChatSession } from '../../prototypes/chat/ChatModels';
import { AgentMessageList } from './AgentMessageList';
import { ImagePreviewBar } from './ImagePreviewBar';
import { AgentInputBar } from './AgentInputBar';

function nowId(): number { return Date.now() * 1000 + Math.floor(Math.random() * 1000); }

@Component
export struct AgentFloatWindow {
  @Prop show: boolean = false;
  onClose: () => void = (): void => {};
  onGoCamera: () => void = (): void => {};
  @Prop @Watch('onPendingImageChange') pendingImageUri: string = '';

  @State @Watch('onMessagesChange') messages: ChatMsg[] = [];
  @State inputText: string = '';
  @State busy: boolean = false;
  @State deepThink: boolean = false;
  @State imagePreview: string = '';
  @State keyboardHeight: number = 0;
  @State sessions: ChatSession[] = [{ id: 's1', name: '会话 1', messages: [] }];
  @State activeSid: string = 's1';
  @State renderKey: number = 0;
  @State floatHeight: number = 48;
  private dragStartH: number = 48;
  private mainWindow: window.Window | null = null;
  private scroller: Scroller = new Scroller();
  private sm: ChatSessionManager = new ChatSessionManager();
  private service: AgentChatService | null = null;

  // ===== 生命周期 =====

  aboutToAppear(): void { this.loadHistory(); this.initKeyboard(); }
  aboutToDisappear(): void { if (this.mainWindow) { this.mainWindow.off('keyboardHeightChange'); }; this.sm.save(this.sessions); }
  onPendingImageChange(): void { if (this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri; } }
  onMessagesChange(): void {
    if (this.messages.length > 0) {
      this.sync(); this.sm.save(this.sessions);
      setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom); }, 200);
    }
  }

  private initKeyboard(): void {
    try { const ctx = this.getUIContext().getHostContext();
      if (ctx) { window.getLastWindow(ctx).then((w: window.Window) => { this.mainWindow = w; w.on('keyboardHeightChange', (d: number) => { try { this.keyboardHeight = this.getUIContext().px2vp(d); } catch (e) { } }); }).catch(() => {}); }
    } catch (e) {}
  }

  // ===== 会话管理 =====

  private async loadHistory(): Promise<void> {
    const cbs: AgentChatCallbacks = {
      addAiMsg: (c: string): void => { this.messages = [...this.messages, { id: nowId(), role: 'ai', content: c, ts: Date.now() }]; },
      bumpNotesVersion: (): void => { const v: number = AppStorage.get<number>('notesVersion') ?? 0; AppStorage.setOrCreate('notesVersion', v + 1); },
      setBusy: (v: boolean): void => { this.busy = v; },
      getContext: (): common.UIAbilityContext => getContext(this) as common.UIAbilityContext,
    };
    this.service = new AgentChatService(cbs);
    const ss: ChatSession[] = await this.sm.init(getContext(this));
    if (ss.length > 0) { this.sessions = ss; this.activeSid = ss[0].id; this.messages = ss[0].messages; return; }
    this.messages = [{ id: 1, role: 'ai', content: '👋 你好，我是 MathMind AI。可以帮你分析题目、讲解知识点、整理笔记。试试问我吧 👉', ts: Date.now() }];
  }

  private sync(): void {
    const s: ChatSession | undefined = this.sessions.find((item: ChatSession): boolean => item.id === this.activeSid);
    if (s !== undefined) { s.messages = this.messages; }
  }
  private switchSession(sid: string): void { this.sync(); const s = this.sessions.find((item: ChatSession): boolean => item.id === sid); if (s !== undefined) { this.activeSid = sid; this.messages = s.messages; } }
  private newSession(): void { this.sync(); const s: ChatSession = { id: sid(), name: '会话 ' + (this.sessions.length + 1).toString(), messages: [] }; this.sessions = [...this.sessions, s]; this.activeSid = s.id; this.messages = []; this.sm.save(this.sessions); }
  private deleteSession(sid: string): void { if (this.sessions.length <= 1) { return; } const f = this.sessions.filter((s: ChatSession): boolean => s.id !== sid); this.sessions = f; if (sid === this.activeSid) { this.activeSid = f[0].id; this.messages = f[0].messages; }; this.sm.save(this.sessions); }

  // ===== 交互逻辑 =====

  private canSend = (): boolean => !this.busy && (this.inputText.trim().length > 0 || this.imagePreview.length > 0);

  private send = (text?: string): void => {
    const msg: string = (text ?? this.inputText).trim();
    if (!msg && !this.imagePreview) { return; }
    if (this.busy) { promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 }); return; }
    const uri: string = this.imagePreview;
    this.messages = [...this.messages, { id: nowId(), role: 'user', content: msg || '[图片]', ts: Date.now() }];
    this.inputText = ''; this.imagePreview = '';
    if (uri.length > 0) { this.service?.captureReply(uri, msg); return; }
    this.service?.realReply(msg);
  };

  private retryFromAiMessage = (msg: ChatMsg): void => {
    if (msg.role !== 'ai') { return; }
    const idx: number = this.messages.findIndex((item: ChatMsg): boolean => item.id === msg.id);
    if (idx > 0 && this.messages[idx - 1].role === 'user') { this.send(this.messages[idx - 1].content); }
  };

  // ===== build =====

  build() {
    Stack() {
      if (this.show) {
        Column().width('100%').height('100%').backgroundColor(OVERLAY_MASK).onClick((): void => this.onClose());
        Column() {
          // 拖拽手柄
          Row() { Row().width(36).height(5).borderRadius(3).backgroundColor(TEXT_4); }
          .width('100%').height(S_6).justifyContent(FlexAlign.Center)
          .gesture(PanGesture({ direction: PanDirection.Vertical })
            .onActionStart((): void => { this.dragStartH = this.floatHeight; })
            .onActionUpdate((event: GestureEvent): void => { this.floatHeight = Math.max(30, Math.min(90, this.dragStartH - event.offsetY / SCREEN_H * 100)); }));

          ChatHeader({ deepThink: this.deepThink, onToggleThink: (): void => { this.deepThink = !this.deepThink; }, onNewChat: (): void => { this.newSession(); }, onClose: this.onClose });
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          SessionBar({ sessions: this.sessions, activeSid: this.activeSid, onSwitch: (sid: string): void => { this.switchSession(sid); }, onDelete: (sid: string): void => { this.deleteSession(sid); }, onNew: (): void => { this.newSession(); } });

          AgentMessageList({ messages: this.messages, busy: this.busy, scroller: this.scroller, onRetry: (msg: ChatMsg): void => { this.retryFromAiMessage(msg); } });
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          QuickSuggestions({ onSelect: (p: string): void => { this.send(p); } });
          ImagePreviewBar({ imagePreview: this.imagePreview, onClear: (): void => { this.imagePreview = ''; } });
          AgentInputBar({ inputText: this.inputText, canSend: this.canSend(), onTextChange: (v: string): void => { this.inputText = v; }, onSubmit: (): void => { this.send(); }, onCamera: (): void => { this.onGoCamera(); } });
        }
        .width('100%').height(this.floatHeight + '%').backgroundColor(BG_DARK)
        .borderRadius({ topLeft: R_XL, topRight: R_XL }).padding({ left: S_3, right: S_3 })
        .position({ x: 0, y: '100%' }).markAnchor({ x: 0, y: '100%' }).translate({ y: -(74 + this.keyboardHeight) });
      }
    }.width('100%').height('100%').hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None);
  }
}
