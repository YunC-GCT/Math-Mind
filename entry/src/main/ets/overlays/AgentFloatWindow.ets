/**
 * MathMind 智能体浮窗 — 紧凑重制版 (2026-07-14)
 *
 * 设计参照: D:\HMgent\MathMind\MathMind-MVP\styles.css .ai-overlay
 *   - 紧凑化: 高度 44% 视口 (~360vp @ 816vp, 比 iOS Web MVP 420 还小)
 *   - 不太透明: 95% alpha (微半透, 内容清晰可读)
 *   - 移除大欢迎语: 改用一行简洁提示
 *   - 全 padding 减半: 顶栏 8+8 / 4 快捷 6+6 / 消息流 8+8 / 输入区 6+10
 *   - 字号普遍小一档 (F_BASE → F_SM)
 *   - 4 文本快捷 + 紫底紫字 AI 气泡 + mint 浅底 mint 字 用户气泡 (沿用)
 *
 * 触发: Index.ets AI 按钮 onClick → 弹出浮窗(不跳转页面)
 * 关闭: 浮窗外点遮罩 或 顶栏 [✕]
 * 接图: @Prop @Watch pendingImageUri
 */

import {
  MINT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4, S_5,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL,
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
  // 待发送图片预览 (W1.2: 拍照后存这里, 不立即发送, 让用户先补充文字)
  @State imagePreview: string = '';

  aboutToAppear(): void {
    // 持久化开场白 (W1.1: 用 AppStorage 标记, 整个 App 生命周期只显示一次)
    if (AppStorage.get<boolean>('shownGreeting') !== true) {
      this.messages = [
        {
          id: 1,
          role: 'ai',
          content: '👋 你好我是 MathMind AI 助手\n\n点击上方 4 个快捷按钮（分析题目/总结知识/出练习题/学习路径）开始对话，或直接在底部输入问题',
          ts: Date.now(),
        },
      ];
      AppStorage.setOrCreate<boolean>('shownGreeting', true);
    }
  }

  // @Watch 回调: pendingImageUri 变化时存到 imagePreview (W1.2: 不立即发送)
  onPendingImageChange(): void {
    if (this.pendingImageUri && this.pendingImageUri.length > 0) {
      // 存为待发送图片预览, 不调 ingestImage
      this.imagePreview = this.pendingImageUri;
      // 清空 pendingImageUri 防重复触发
      setTimeout(() => { this.pendingImageUri = ''; }, 100);
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

  // 发送消息 (W1.2: 支持文字 + 图片一起发)
  private send = (): void => {
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    const hasText: boolean = text.length > 0;

    if (!hasText && !hasImage) {
      return;
    }
    if (this.busy) {
      promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 });
      return;
    }

    // 构造 user message content (文字 + 图片)
    const content: string = hasImage
      ? `📷 已发送图片${hasText ? '\n' + text : ''}`
      : text;

    this.messages = [
      ...this.messages,
      { id: nowId(), role: 'user', content, ts: Date.now() },
    ];
    this.inputText = '';
    this.imagePreview = '';

    // mock reply
    const reply: string = hasImage
      ? `已收到图片${hasText ? ' + 「' + text + '」' : ''}，正在分析...`
      : `已收到：「${text}」`;
    this.mockReply(reply);
  };

  // 快捷 prompt 发送 (W1.2: 支持 SugBtn 文字 + inputText 补充 + imagePreview 一起发)
  private sendQuick = (prompt: string): void => {
    if (this.busy) {
      promptAction.openToast({ message: 'AI 正在回复中...', duration: 1200 });
      return;
    }
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imagePreview.length > 0;
    const hasText: boolean = text.length > 0;

    let content: string = prompt;
    if (hasText) {
      content += '\n' + text;
    }
    if (hasImage) {
      content += '\n📷 已发送图片';
    }

    this.messages = [
      ...this.messages,
      { id: nowId(), role: 'user', content, ts: Date.now() },
    ];
    this.inputText = '';
    this.imagePreview = '';

    let reply: string = `已收到：「${prompt}」`;
    if (hasText) {
      reply += ` + 「${text}」`;
    }
    if (hasImage) {
      reply += ' + 图片';
    }
    reply += '，正在分析...';
    this.mockReply(reply);
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
      Text('✦ MathMind AI')
        .fontSize(F_SM + 1)
        .fontWeight(700)
        .fontColor(PURPLE);

      Blank();

      this.CloseBtn();
    }
    .width('100%')
    .padding({ left: 14, right: 8, top: 8, bottom: 8 });
  }

  @Builder
  CloseBtn() {
    Stack() {
      Text('✕')
        .fontSize(14)
        .fontWeight(500)
        .fontColor(TEXT_3);
    }
    .width(24).height(24)
    .borderRadius(12)
    .alignContent(Alignment.Center)
    .onClick(() => this.onClose());
  }

  // 4 快捷 (一行紧凑)
  @Builder
  SugBtn(label: string, prompt: string) {
    Text(label)
      .fontSize(F_XS)
      .fontColor(PURPLE)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(10)
      .backgroundColor(PURPLE_LIGHT)
      .onClick(() => this.sendQuick(prompt));
  }

  // 用户气泡 (mint 浅底 + mint 字 + 右对齐)
  @Builder
  UserBubble(msg: ChatMsg) {
    Row() {
      Blank();
      Text(msg.content)
        .fontSize(F_SM)
        .fontColor(MINT)
        .lineHeight(18)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .borderRadius(10)
        .backgroundColor('#245BE3B0')  // MINT_LIGHT
        .constraintSize({ maxWidth: '78%' })
        .textAlign(TextAlign.Start);
    }
    .width('100%')
    .margin({ top: 6 });
  }

  // AI 气泡 (紫底 + 紫字 + 左对齐)
  @Builder
  AiBubble(msg: ChatMsg) {
    Row() {
      Text(msg.content)
        .fontSize(F_SM)
        .fontColor(TEXT_2)
        .lineHeight(18)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .borderRadius(10)
        .backgroundColor(PURPLE_LIGHT)
        .constraintSize({ maxWidth: '85%' })
        .textAlign(TextAlign.Start);
      Blank();
    }
    .width('100%')
    .margin({ top: 6 });
  }

  // 打字中
  @Builder
  TypingBubble() {
    Row() {
      Row() {
        LoadingProgress()
          .width(12).height(12)
          .color(PURPLE);
        Text(' AI 思考中...')
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ left: 4 });
      }
      .padding({ left: 10, right: 10, top: 8, bottom: 8 })
      .borderRadius(10)
      .backgroundColor(PURPLE_LIGHT);
      Blank();
    }
    .width('100%')
    .margin({ top: 6 });
  }

  // 简洁空状态 (W1: messages 被清空时 fallback, 现在用大字+emoji 更明显)
  @Builder
  EmptyHint() {
    Column() {
      Text('👋')
        .fontSize(36)
        .margin({ bottom: 8 });
      Text('你好我是 MathMind AI 助手')
        .fontSize(F_BASE)
        .fontWeight(600)
        .fontColor(TEXT)
        .margin({ bottom: 6 });
      Text('点击上方 4 个快捷按钮开始对话\n或直接在底部输入问题')
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .textAlign(TextAlign.Center)
        .lineHeight(18);
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 24, bottom: 24 })
    .alignItems(HorizontalAlign.Center);
  }

  build() {
    Stack() {
      if (this.show) {
        // ===== 半透明遮罩 =====
        Column()
          .width('100%').height('100%')
          .backgroundColor('#80000000')
          .onClick(() => this.onClose());

        // ===== 浮窗主体 — 紧凑设计 =====
        Column() {
          // 顶栏 (32vp)
          this.Header();

          // 分隔线
          Row()
            .width('100%').height(0.5)
            .backgroundColor(BORDER);

          // ===== 4 快捷 (40vp 紧凑一行) =====
          Row() {
            this.SugBtn('分析题目', '帮我分析这道题');
            this.SugBtn('总结知识', '总结知识点');
            this.SugBtn('出练习题', '出几道练习题');
            this.SugBtn('学习路径', '推荐学习路径');
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 });

          // 分隔线
          Row()
            .width('100%').height(0.5)
            .backgroundColor(BORDER);

          // ===== 消息流 =====
          Scroll() {
            Column() {
              if (this.messages.length === 0 && !this.busy) {
                this.EmptyHint();
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

              Blank().height(4);
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 });
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring);

          // 分隔线
          Row()
            .width('100%').height(0.5)
            .backgroundColor(BORDER);

          // ===== 底部输入区 (52vp 紧凑) =====
          Row() {
            // 图片预览 (W1.2: 拍照后缩略图 + X 取消, 跟文字一起发送)
            if (this.imagePreview.length > 0) {
              Stack() {
                Image(this.imagePreview)
                  .width(40).height(40)
                  .borderRadius(6)
                  .objectFit(ImageFit.Cover);

                // 取消 X (右上角)
                Text('✕')
                  .fontSize(10).fontWeight(700)
                  .fontColor('#FFFFFF')
                  .width(18).height(18)
                  .borderRadius(9)
                  .backgroundColor('#80000000')
                  .textAlign(TextAlign.Center)
                  .position({ x: '100%', y: 0 })
                  .markAnchor({ x: '100%', y: 0 })
                  .offset({ x: -4, y: -4 })
                  .onClick(() => { this.imagePreview = ''; });
              }
              .width(40).height(40)
              .margin({ right: 8 });
            }

            // 输入框
            TextInput({ text: this.inputText, placeholder: '输入问题...' })
              .layoutWeight(1)
              .height(32)
              .fontSize(F_SM)
              .fontColor(TEXT)
              .placeholderColor(TEXT_3)
              .backgroundColor('#1AFFFFFF')
              .borderRadius(16)
              .padding({ left: 12, right: 6 })
              .onChange((value: string) => {
                this.inputText = value;
              })
              .onSubmit(() => {
                this.send();
              });

            // 拍照按钮 (28×28) - SVG ic_camera 替换 emoji
            Stack() {
              Image($r('app.media.ic_camera'))
                .width(16)
                .height(16)
                .fillColor(TEXT_3);
            }
            .width(28).height(28)
            .borderRadius(14)
            .backgroundColor('#1AFFFFFF')
            .border({ width: 1, color: BORDER })
            .alignContent(Alignment.Center)
            .margin({ left: 4 })
            .onClick(() => {
              this.onGoCamera();
            });

            // 发送按钮 (28×28)
            Stack() {
              Text('↑')
                .fontSize(15)
                .fontWeight(700)
                .fontColor(this.inputText.trim().length > 0 && !this.busy ? BG_DARK : TEXT_3);
            }
            .width(28).height(28)
            .borderRadius(14)
            .backgroundColor(this.inputText.trim().length > 0 && !this.busy ? MINT : '#1AFFFFFF')
            .alignContent(Alignment.Center)
            .margin({ left: 4 })
            .onClick(() => {
              this.send();
            });
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 6, bottom: 10 })
          .alignItems(VerticalAlign.Center);
        }
          .width('100%')
          .height('40%')                     // 40% 视口高 (~325vp @ 816vp, 更紧凑)
          // Stack 默认 alignContent TopStart, 子元素顶贴 Stack 顶.
          // 强制底对齐 Stack 底 (用 position + markAnchor).
          // margin 在 Stack 子元素不生效, 改用 .offset({ y: -74 }) 强制上移 74vp
          // (= Tab 栏高, 浮窗底贴菜单栏顶).
          .position({ x: 0, y: '100%' })     // 元素 (0,0) 在 (0, 100%) = Stack 左下角
          .markAnchor({ x: 0, y: '100%' })  // 元素 (0, 100%) 作为锚点 = 元素底
          .offset({ y: -74 })               // 强制上移 74vp (offset 在 position 后一定生效)
          .backgroundColor('#F20A0C10')      // 95% alpha (微半透)
        .borderRadius(20)
        .border({ width: 1, color: PURPLE_LIGHT })
        .shadow({
          radius: 20,
          color: '#CC000000',
          offsetX: 0,
          offsetY: -4,
        })
        .margin({ left: 12, right: 12 })    // 去掉 bottom 74 (offset 替代)
      }
    }
    .width('100%').height('100%')
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
  }
}
