/**
 * AgentInputBar.ets — AI 浮窗底部输入栏
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/AgentInputBar.ets
 * 职责: 输入框 + 拍照按钮 + 发送按钮
 * 依赖: common, app.media.ic_camera
 */

import {
  MINT, BG_DARK, TEXT, TEXT_3, BORDER,
  F_SM, F_LG, W_BOLD,
} from 'common';

@Component
export struct AgentInputBar {
  @Prop inputText: string = '';
  @Prop canSend: boolean = false;
  onTextChange: (v: string) => void = (_v: string): void => {};
  onSubmit: () => void = (): void => {};
  onCamera: () => void = (): void => {};

  build() {
    Row() {
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
        .onChange((value: string): void => {
          this.onTextChange(value);
        })
        .onSubmit((): void => {
          this.onSubmit();
        });

      // 拍照按钮(28×28)
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
      .onClick((): void => {
        this.onCamera();
      });

      // 发送按钮(28×28)
      Stack() {
        Text('➤')
          .fontSize(F_LG)
          .fontWeight(W_BOLD)
          .fontColor(this.canSend ? BG_DARK : TEXT_3);
      }
      .width(28).height(28)
      .borderRadius(14)
      .backgroundColor(this.canSend ? MINT : '#1AFFFFFF')
      .alignContent(Alignment.Center)
      .margin({ left: 4 })
      .onClick((): void => {
        this.onSubmit();
      });
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 6, bottom: 10 })
    .alignItems(VerticalAlign.Center);
  }
}
