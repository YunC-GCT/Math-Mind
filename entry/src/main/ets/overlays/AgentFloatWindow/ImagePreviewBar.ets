/**
 * ImagePreviewBar.ets — 图片预览行
 *
 * 路径: entry/src/main/ets/overlays/AgentFloatWindow/ImagePreviewBar.ets
 * 职责: 发送前显示已选图片缩略图 + 提示文字 + 清除按钮
 * 依赖: common
 */

import { BORDER, TEXT_3, F_XS, F_BASE } from 'common';

@Component
export struct ImagePreviewBar {
  @Prop imagePreview: string = '';
  onClear: () => void = (): void => {};

  build() {
    if (this.imagePreview.length > 0) {
      Row() {
        Image(this.imagePreview)
          .width(48).height(48)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
          .border({ width: 1, color: BORDER });

        Text('已选图片,可补充文字后发送')
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ left: 10 })
          .layoutWeight(1);

        Text('✕')
          .fontSize(F_BASE)
          .fontColor(TEXT_3)
          .width(28).height(28)
          .borderRadius(14)
          .textAlign(TextAlign.Center)
          .backgroundColor('#1AFFFFFF')
          .onClick((): void => this.onClear());
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 6, bottom: 4 });
    }
  }
}
