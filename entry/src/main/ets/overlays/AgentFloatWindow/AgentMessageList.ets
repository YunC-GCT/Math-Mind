/**
 * AgentMessageList.ets — AI 浮窗消息列表区
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/AgentMessageList.ets
 * 职责: Scroll 消息列表 + 空状态 + 打字指示器
 * 依赖: common
 */

import {
  MINT, PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_3,
  F_XS, F_SM, F_BASE, F_LG, W_BOLD,
} from 'common';

// 消息类型(本组件内部用)
interface ChatMsg {
  id: number;
  role: 'user' | 'ai';
  content: string;
  ts: number;
}

@Component
export struct AgentMessageList {
  @Prop messages: ChatMsg[] = [];
  @Prop busy: boolean = false;

  build() {
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
  }

  // 用户气泡(mint 浅底 + mint 字 + 右对齐)
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
        .backgroundColor('#245BE3B0')
        .constraintSize({ maxWidth: '78%' })
        .textAlign(TextAlign.Start);
    }
    .width('100%')
    .margin({ top: 6 });
  }

  // AI 气泡(紫底 + 紫字 + 左对齐)
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

  // 打字指示器
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

  // 空状态
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
}
