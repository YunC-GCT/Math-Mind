// ============================================================================
//  overlays/AgentFloatWindow/AgentFloatWindow.ets — 智能体浮窗(纯 UI 装配层)
//  ----------------------------------------------------------------------------
//  子组件: ChatHeader / AgentMessageList / QuickSuggestions / ImagePreviewBar / AgentInputBar
//  业务逻辑: AgentChatService (services/AgentChatService.ets)
//  Props: show / onClose / onGoCamera / pendingImageUri
//  ============================================================================

import { PURPLE_LIGHT, BORDER } from 'common';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import window from '@ohos.window';
import { AgentChatService, AgentChatCallbacks } from '../../services/AgentChatService';
import { ChatHeader } from '../../prototypes/chat/ChatHeader';
import { QuickSuggestions } from '../../prototypes/chat/QuickSuggestions';
import { AgentMessageList } from './AgentMessageList';
import { ImagePreviewBar } from './ImagePreviewBar';
import { AgentInputBar } from './AgentInputBar';
import { ChatMsg } from '../../prototypes/chat/ChatModels';

function nowId(): number { return Date.now() * 1000 + Math.floor(Math.random() * 1000); }

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
  @State deepThink: boolean = false;
  private mainWindow: window.Window | null = null;
  private service: AgentChatService | null = null;

  aboutToAppear(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri; }
    if (AppStorage.get<boolean>('shownGreeting') !== true) {
      this.messages = [{ id: 1, role: 'ai', content: '👋 你好我是 MathMind AI 助手\n\n点击上方快捷按钮开始对话,或直接在底部输入问题', ts: Date.now() }];
      AppStorage.setOrCreate<boolean>('shownGreeting', true);
    }
    const cbs: AgentChatCallbacks = {
      addAiMsg: (c: string): void => { this.messages = [...this.messages, { id: nowId(), role: 'ai', content: c, ts: Date.now() }]; },
      bumpNotesVersion: (): void => { const v: number = AppStorage.get<number>('notesVersion') ?? 0; AppStorage.setOrCreate('notesVersion', v + 1); },
      setBusy: (v: boolean): void => { this.busy = v; },
      getContext: (): common.UIAbilityContext => getContext(this) as common.UIAbilityContext,
    };
    this.service = new AgentChatService(cbs);
    try {
      const h = this.getUIContext().getHostContext();
      if (h) { window.getLastWindow(h).then((w: window.Window) => { this.mainWindow = w; w.on('keyboardHeightChange', (d: number) => { try { this.keyboardHeight = this.getUIContext().px2vp(d); } catch (e) {} }); }).catch(() => {}); }
    } catch (e) {}
  }

  aboutToDisappear(): void { if (this.mainWindow) { this.mainWindow.off('keyboardHeightChange'); } }

  onPendingImageChange(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri; }
  }

  private canSend = (): boolean => !this.busy && (this.inputText.trim().length > 0 || this.imagePreview.length > 0);

  private dispatch = (content: string, hasImage: boolean, imageUri: string, userText: string): void => {
    this.messages = [...this.messages, { id: nowId(), role: 'user', content, ts: Date.now() }];
    this.inputText = ''; this.imagePreview = '';
    if (hasImage) { this.service?.captureReply(imageUri, userText); return; }
    this.service?.realReply(content);
  };

  private send = (): void => {
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    if (!text && !hasImage) { return; }
    if (this.busy) { promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 }); return; }
    this.dispatch(hasImage ? (text || '分享了一张照片') : text, hasImage, this.imagePreview, text);
  };

  private sendQuick = (prompt: string): void => {
    if (this.busy) { promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 }); return; }
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    let content: string = prompt;
    if (text.length > 0) { content += '\n' + text; }
    if (hasImage) { content += '\n分享了一张照片'; }
    this.dispatch(content, hasImage, this.imagePreview, content);
  };

  private newSession = (): void => { this.messages = []; };

  build() {
    Stack() {
      if (this.show) {
        Column().width('100%').height('100%').backgroundColor('#80000000').onClick((): void => this.onClose());
        Column() {
          ChatHeader({
            deepThink: this.deepThink,
            onToggleThink: (): void => { this.deepThink = !this.deepThink; },
            onNewChat: (): void => { this.newSession(); },
            onClose: (): void => this.onClose(),
          });
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          QuickSuggestions({ onSelect: (p: string): void => this.sendQuick(p) });
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          AgentMessageList({ messages: this.messages, busy: this.busy });
          Row().width('100%').height(0.5).backgroundColor(BORDER);

          ImagePreviewBar({ imagePreview: this.imagePreview, onClear: (): void => { this.imagePreview = ''; } });
          AgentInputBar({ inputText: this.inputText, canSend: this.canSend(), onTextChange: (v: string): void => { this.inputText = v; }, onSubmit: (): void => { this.send(); }, onCamera: (): void => { this.onGoCamera(); } });
        }
        .width('100%').height('40%').position({ x: 0, y: '100%' }).markAnchor({ x: 0, y: '100%' }).translate({ y: -(74 + this.keyboardHeight) })
        .backgroundColor('#F20A0C10').borderRadius(20).border({ width: 1, color: PURPLE_LIGHT })
        .shadow({ radius: 20, color: '#CC000000', offsetX: 0, offsetY: -4 }).margin({ left: 12, right: 12 });
      }
    }.width('100%').height('100%').hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None);
  }
}
