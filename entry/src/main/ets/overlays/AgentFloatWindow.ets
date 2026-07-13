/**
 * MathMind 智能体浮窗 — 第 4 批
 *
 * 触发: Index.ets AI 按钮点击 → 弹出浮窗(不跳转页面)
 * 与 AiChatOverlay 区别: 底部浮窗样式, 无总结/出题/复习快捷按钮,
 *    拍照按钮放在输入框右侧
 */

import {
  MINT,
  MINT_DARK,
  PURPLE,
  BG_DARK,
  BG_CARD,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  BORDER,
  S_1, S_2, S_3, S_4, S_5,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG,
} from 'common';
import { promptAction } from '@kit.ArkUI';

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
  // 父组件控制可见性
  @Prop show: boolean = false;
  // 关闭浮窗回调
  onClose: () => void = () => {};
  // 打开拍照回调
  onGoCamera: () => void = () => {};
  // 可选: 拍照后带图回调 (@Watch 监听变化触发 ingest)
  @Prop @Watch('onPendingImageChange') pendingImageUri: string = '';

  // 消息列表
  @State messages: ChatMsg[] = [];
  // 输入文本
  @State inputText: string = '';
  // AI 忙
  @State busy: boolean = false;

  aboutToAppear(): void {
    // 初始欢迎语 (空消息时由 build 内 WelcomeBanner 渲染)
  }

  // @Watch 回调: pendingImageUri 变化时吞图
  onPendingImageChange(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.ingestImage(this.pendingImageUri);
    }
  }

  private ingestImage = (uri: string): void => {
    this.messages = [
      ...this.messages,
      {
        id: nowId(),
        role: 'user',
        content: `📷 已发送图片`,
        ts: Date.now(),
      },
    ];
    this.mockReply('已收到图片，正在分析题目...');
  };

  // 发送消息
  private send = (): void => {
    const text: string = this.inputText.trim();
    if (!text) {
      return;
    }
    if (this.busy) {
      promptAction.showToast({ message: 'AI 正在回复中...', duration: 1200 });
      return;
    }
    this.messages = [
      ...this.messages,
      { id: nowId(), role: 'user', content: text, ts: Date.now() },
    ];
    this.inputText = '';
    this.mockReply(`已收到：「${text}」`);
  };

  // Mock AI 回复
  private mockReply = (content: string): void => {
    this.busy = true;
    setTimeout(() => {
      this.messages = [
        ...this.messages,
        { id: nowId(), role: 'ai', content: content, ts: Date.now() },
      ];
      this.busy = false;
    }, 800);
  };

  // ========== UI Builders ==========

  @Builder
  Header() {
    Row() {
      Text('智能助手')
        .fontSize(F_LG)
        .fontWeight(700)
        .fontColor(TEXT);

      Blank();

      this.CloseBtn();
    }
    .width('100%')
    .padding({ left: 20, right: 16, top: 12, bottom: 8 });
  }

  @Builder
  CloseBtn() {
    Stack() {
      Text('✕')
        .fontSize(16)
        .fontWeight(500)
        .fontColor(TEXT_2);
    }
    .width(32).height(32)
    .borderRadius(16)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => this.onClose());
  }

  // 用户气泡(右对齐, mint 渐变)
  @Builder
  UserBubble(msg: ChatMsg) {
    Row() {
      Blank();
      Row() {
        Text(msg.content)
          .fontSize(F_BASE)
          .fontColor(BG_DARK)
          .fontWeight(500)
          .lineHeight(20);
      }
      .constraintSize({ maxWidth: '78%' })
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
      .linearGradient({
        angle: 135,
        colors: [[MINT, 0], [MINT_DARK, 1]],
      });
    }
    .width('100%')
    .margin({ top: 8 })
    .alignItems(VerticalAlign.Top);
  }

  // AI 气泡(左对齐)
  @Builder
  AiBubble(msg: ChatMsg) {
    Row() {
      // AI 头像
      Stack() {
        Text('✦')
          .fontSize(12)
          .fontColor(BG_DARK)
          .fontWeight(700);
      }
      .width(28).height(28)
      .borderRadius(14)
      .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
      .alignContent(Alignment.Center)
      .margin({ right: 8 });

      Row() {
        Text(msg.content)
          .fontSize(F_BASE)
          .fontColor(TEXT)
          .lineHeight(20);
      }
      .constraintSize({ maxWidth: '78%' })
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      .backgroundColor('#1AFFFFFF');
    }
    .width('100%')
    .margin({ top: 8 })
    .alignItems(VerticalAlign.Top);
  }

  // 打字中
  @Builder
  TypingBubble() {
    Row() {
      Stack() {
        Text('✦')
          .fontSize(12)
          .fontColor(BG_DARK)
          .fontWeight(700);
      }
      .width(28).height(28)
      .borderRadius(14)
      .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
      .alignContent(Alignment.Center)
      .margin({ right: 8 });

      Row() {
        LoadingProgress()
          .width(16).height(16)
          .color(MINT);
        Text(' AI 思考中...')
          .fontSize(F_SM)
          .fontColor(TEXT_3)
          .margin({ left: 6 });
      }
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      .backgroundColor('#1AFFFFFF')
      .border({ width: 1, color: BORDER });
    }
    .margin({ top: 8 })
    .alignItems(VerticalAlign.Center);
  }

  // 欢迎语
  @Builder
  WelcomeBanner() {
    Column() {
      Text('✦')
        .fontSize(36)
        .fontColor(MINT)
        .opacity(0.6);
      Text('你好，我是智能助手')
        .fontSize(F_MD)
        .fontColor(TEXT_2)
        .fontWeight(600)
        .margin({ top: 8 });
      Text('请直接输入问题，或点击 📷 拍照提问')
        .fontSize(F_SM)
        .fontColor(TEXT_3)
        .margin({ top: 4 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 32 });
  }

  build() {
    Stack() {
      if (this.show) {
        // ===== 半透明遮罩 =====
        Column()
          .width('100%').height('100%')
          .backgroundColor('#CC000000')
          .onClick(() => this.onClose());

      // ===== 浮窗主体 — 底部弹出 =====
      Column() {
        // drag bar
        Row() {
          Row()
            .width(40).height(4)
            .borderRadius(2)
            .backgroundColor(TEXT_4);
        }
        .width('100%')
        .height(24)
        .margin({ top: 8 })
        .justifyContent(FlexAlign.Center);

        // 顶栏: 标题 + 关闭
        this.Header();

        // 分隔线
        Divider()
          .width('100%')
          .height(0.5)
          .color(BORDER)
          .margin({ left: 20, right: 20, top: 4 });

        // ===== 消息流 =====
        Scroll() {
          Column() {
            if (this.messages.length === 0 && !this.busy) {
              this.WelcomeBanner();
            }

            ForEach(this.messages, (msg: ChatMsg) => {
              if (msg.role === 'user') {
                this.UserBubble(msg);
              } else {
                this.AiBubble(msg);
              }
            }, (msg: ChatMsg) => msg.id.toString());

            if (this.busy) {
              this.TypingBubble();
            }

            Blank().height(8);
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 });
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);

        // ===== 底部输入区 =====
        Row() {
          // 输入框
          TextInput({ text: this.inputText, placeholder: '问 AI 任何问题...' })
            .layoutWeight(1)
            .height(40)
            .fontSize(F_BASE)
            .fontColor(TEXT)
            .placeholderColor(TEXT_3)
            .backgroundColor('#1AFFFFFF')
            .borderRadius(20)
            .padding({ left: 16, right: 8 })
            .onChange((value: string) => {
              this.inputText = value;
            })
            .onSubmit(() => {
              this.send();
            });

          // 拍照按钮(右侧)
          Stack() {
            Text('📷')
              .fontSize(18);
          }
          .width(36).height(36)
          .borderRadius(18)
          .backgroundColor('#1AFFFFFF')
          .alignContent(Alignment.Center)
          .margin({ left: 8 })
          .onClick(() => {
            this.onGoCamera();
          });

          // 发送按钮
          Stack() {
            Text('➤')
              .fontSize(14)
              .fontWeight(700)
              .fontColor(this.inputText.trim().length > 0 && !this.busy ? BG_DARK : TEXT_3);
          }
          .width(36).height(36)
          .borderRadius(18)
          .backgroundColor(this.inputText.trim().length > 0 && !this.busy ? MINT : '#1AFFFFFF')
          .alignContent(Alignment.Center)
          .margin({ left: 8 })
          .onClick(() => {
            this.send();
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 });
      }
      .width('100%')
      .height('78%')
      .backgroundColor(BG_DARK)
      .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 });
      }
    }
    .width('100%').height('100%')
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
    .position({ x: 0, y: 0 });
  }
}
