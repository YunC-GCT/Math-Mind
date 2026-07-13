/**
 * MathMind AI 对话浮层 — 第 3 批
 * 状态: 浮层可见性由父组件控制 (show: boolean)
 *
 * 触发: Index.ets AI Tab /  CameraOverlay 拍完确认
 * 流程: 用户输入 -> mock AI 回复(第 4 批接真 AI)
 *
 * MVP 阶段:
 *   - 4 快捷 prompt(拍照/总结/出题/复习)
 *   - 用户气泡(右 mint 渐变) / AI 气泡(左 灰底)
 *   - 发送 = mock 回复"我已收到..."
 *   - 真实 AI 调用留 W1 (Dispatcher + AiService)
 *
 * 拍照联动:
 *   - 父组件传 onGoCamera callback,点 [拍照] 按钮触发
 *   - 拍照回来后用 pendingImageUri 状态显示"已收到图片,正在分析..."
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

// 顶层 mock 工具
function nowId(): number {
  return Date.now() + Math.floor(Math.random() * 1000);
}

function mockAiReply(userInput: string): string {
  if (!userInput || userInput.length === 0) {
    return '我在这里,有什么能帮到你的?';
  }
  // 简单 mock: 关键字触发不同回复
  if (userInput.indexOf('总结') >= 0) {
    return '好的,我已分析你的笔记库:\n- 5 条笔记\n- 平均掌握率 85%\n- 建议优先复习:极限 ε-δ 定义';
  }
  if (userInput.indexOf('复习') >= 0) {
    return '根据你的学习记录,我建议:\n1. 拉格朗日中值定理(掌握度 92%)\n2. 矩阵行列式(88%)\n3. 极限 ε-δ(85%)\n每天 30 分钟,坚持一周。';
  }
  if (userInput.indexOf('题') >= 0) {
    return '我根据你的笔记出 3 道题:\n1. 证明: 若 f 在 [a,b] 连续,开区间可导,则...\n2. 计算: 4 阶行列式 |A|=?\n3. 概念: ε-δ 定义的本质是?';
  }
  return `收到: "${userInput}"\n\n(MVP 阶段,这是 mock 回复。W1 会接真 AI:DeepSeek / 本地模型)`;
}

@Component
export struct AiChatOverlay {
  @State messages: ChatMsg[] = [];
  @State inputText: string = '';
  @State busy: boolean = false;
  @State hasInit: boolean = false;
  // 父组件传入的待处理图片 uri(HomePage 拍完图 -> 跳 AI Tab)
  @Prop @Watch('onPendingImageChange') pendingImageUri: string = '';

  // 回调
  onClose: () => void = () => {};
  onGoCamera: () => void = () => {};

  // @Watch 回调:pendingImageUri 变化时 ingest
  onPendingImageChange(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.ingestImage(this.pendingImageUri);
    }
  }

  // 外部设置 pending image(也可直接调用)
  setPendingImage(uri: string): void {
    this.ingestImage(uri);
  }

  // 吞图:加到消息流 + mock AI 回应
  private ingestImage = (uri: string): void => {
    this.messages = [
      ...this.messages,
      {
        id: nowId(),
        role: 'user',
        content: `📷 已发送图片 (${uri})`,
        ts: Date.now(),
      },
    ];
    this.busy = true;
    setTimeout(() => {
      this.messages = [
        ...this.messages,
        {
          id: nowId(),
          role: 'ai',
          content: '我看到了!正在分析图片中的题目...\n\n(模拟分析中,W1 会真调 OCR + 分类 + 建模)',
          ts: Date.now(),
        },
      ];
      this.busy = false;
    }, 600);
  };

  aboutToAppear(): void {
    if (!this.hasInit) {
      this.hasInit = true;
      this.messages = [
        {
          id: 1,
          role: 'ai',
          content: '你好 Mini 👋\n我是 MathMind AI,可以帮你:\n· 拍照整理数学题\n· 总结已有笔记\n· 出题 / 复习建议\n\n试试下面的快捷指令,或直接打字。',
          ts: Date.now(),
        },
      ];
    }
    // 第一次 aboutToAppear 时也要检查 pendingImageUri
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      this.ingestImage(this.pendingImageUri);
    }
  }

  build() {
    Stack() {
      // ===== 半透明遮罩 =====
      Column()
        .width('100%').height('100%')
        .backgroundColor('#CC000000');

      // ===== 浮层主体 =====
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

        // 顶栏(标题 + 关闭)
        Row() {
          Column() {
            Text('MathMind AI')
              .fontSize(F_MD)
              .fontWeight(700)
              .fontColor(TEXT);
            Text('在线 · 基于 DeepSeek')
              .fontSize(F_XS)
              .fontColor(MINT)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start);

          Blank();

          // 新对话按钮
          this.NewChatBtn();

          Blank().width(8);

          // 关闭
          this.CloseBtn();
        }
        .width('100%')
        .padding({ left: 20, right: 16, top: 4, bottom: 12 });

        // ===== 4 快捷 prompt =====
        Row() {
          this.QuickBtn('📷', '拍照', () => this.onGoCamera());
          this.QuickBtn('📝', '总结', () => this.sendQuick('帮我总结笔记'));
          this.QuickBtn('✏️', '出题', () => this.sendQuick('给我出几道题'));
          this.QuickBtn('🔄', '复习', () => this.sendQuick('帮我做复习计划'));
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 });

        // ===== 消息流 =====
        Scroll() {
          Column() {
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

        // ===== 底部输入 =====
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
            .padding({ left: 14, right: 14 })
            .onChange((v: string) => { this.inputText = v; });

          Blank().width(8);

          // 发送按钮
          Row() {
            Text('➤')
              .fontSize(16)
              .fontColor(this.inputText.length > 0 ? BG_DARK : TEXT_3)
              .fontWeight(700);
          }
          .width(40).height(40)
          .borderRadius(20)
          .backgroundColor(this.inputText.length > 0 ? MINT : '#1AFFFFFF')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => this.sendCurrent());
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 24 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK);
    }
    .width('100%').height('100%');
  }

  // ========== 消息气泡 ==========

  // 用户气泡(右对齐)
  @Builder
  UserBubble(msg: ChatMsg) {
    Row() {
      Blank();
      Row() {
        Text(msg.content)
          .fontSize(F_BASE)
          .fontColor(BG_DARK)
          .lineHeight(20);
      }
      .constraintSize({ maxWidth: '75%' })
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 })
      .linearGradient({ angle: 135, colors: [[MINT, 0], [MINT_DARK, 1]] });
    }
    .width('100%')
    .margin({ top: 8 })
    .justifyContent(FlexAlign.End);
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
      .layoutWeight(1)
      .constraintSize({ maxWidth: '80%' })
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      .backgroundColor('#1AFFFFFF')
      .border({ width: 1, color: BORDER });

      Blank();
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

      Blank();
    }
    .width('100%')
    .margin({ top: 8 })
    .alignItems(VerticalAlign.Center);
  }

  // ========== 顶栏按钮 ==========

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

  @Builder
  NewChatBtn() {
    Stack() {
      Text('+')
        .fontSize(18)
        .fontWeight(600)
        .fontColor(MINT);
    }
    .width(32).height(32)
    .borderRadius(16)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => {
      this.messages = [
        {
          id: nowId(),
          role: 'ai',
          content: '新对话已开启 👋\n有什么想问的?',
          ts: Date.now(),
        },
      ];
    });
  }

  // ========== 快捷 prompt ==========
  @Builder
  QuickBtn(icon: string, label: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(20)
        .margin({ bottom: 2 });
      Text(label)
        .fontSize(F_XS)
        .fontColor(TEXT_2)
        .fontWeight(500);
    }
    .layoutWeight(1)
    .height(60)
    .borderRadius(R_MD + 2)
    .backgroundColor('#0DFFFFFF')
    .border({ width: 1, color: BORDER })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => action());
  }

  // ========== 行为 ==========

  // 发送当前输入
  private sendCurrent = (): void => {
    const txt = this.inputText.trim();
    if (txt.length === 0) {
      promptAction.showToast({ message: '说点什么吧 ✨', duration: 1500 });
      return;
    }
    this.messages = [
      ...this.messages,
      { id: nowId(), role: 'user', content: txt, ts: Date.now() },
    ];
    this.inputText = '';
    this.simulateAiReply(txt);
  };

  // 快捷 prompt
  private sendQuick = (prompt: string): void => {
    this.messages = [
      ...this.messages,
      { id: nowId(), role: 'user', content: prompt, ts: Date.now() },
    ];
    this.simulateAiReply(prompt);
  };

  // mock AI 回复(模拟思考延迟)
  private simulateAiReply = (userInput: string): void => {
    this.busy = true;
    setTimeout(() => {
      const reply = mockAiReply(userInput);
      this.messages = [
        ...this.messages,
        { id: nowId(), role: 'ai', content: reply, ts: Date.now() },
      ];
      this.busy = false;
    }, 700);
  };
}
