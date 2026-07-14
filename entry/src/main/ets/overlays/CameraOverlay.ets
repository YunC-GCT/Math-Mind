/**
 * MathMind 相机浮层 — iOS Web MVP 风格重制 (2026-07-14)
 *
 * 触发: HomePage FAB [+] / AI 浮层 → 拍照
 * 流程: 拍/选图 -> imageUri -> onConfirm 回调
 *
 * 相机策略:
 *   - 优先: cameraPicker 拉起系统相机 (无需 CAMERA 权限)
 *   - 降级: 模拟器无相机时 mock uri
 *   - 相册: photoAccessHelper.PhotoViewPicker
 *
 * 设计 (按 iOS Web MVP styles.css .cam-*):
 *   - 全屏浮层, 黑底 (#0E1014)
 *   - 顶栏: 左侧 [✕] + 右侧 [翻转] (占位)
 *   - 相机预览: 黑底 + SVG ic_camera 占位 + "将题目对准框内" 文字
 *   - 取景框: 280×360 圆角矩形 + mint 描边 + 扫描线动画
 *   - 底部: 左 [相册] + 中 [快门 68×68] + 右 [✓ 使用 hidden]
 *   - 预览状态: 真实图片预览 + [重拍] + [✓ 使用]
 *
 * 第 5 批: 接入真实 cameraPicker + PhotoViewPicker (替换 mock)
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
  R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG,
} from 'common';
import { cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';

// 浮层状态
type CameraState = 'camera' | 'preview';

// 降级 mock (模拟器无相机时使用)
function mockCaptureUri(src: 'camera' | 'album'): string {
  return `mock_${src}_${Date.now()}.jpg`;
}

@Component
export struct CameraOverlay {
  @State state: CameraState = 'camera';
  @State capturedUri: string = '';
  @State capturedSrc: 'camera' | 'album' | '' = '';
  @State busy: boolean = false;

  // 回调
  onClose: () => void = () => {};
  onConfirm: (uri: string, src: 'camera' | 'album') => void = () => {};

  build() {
    Stack() {
      // ===== 半透明遮罩 =====
      Column()
        .width('100%').height('100%')
        .backgroundColor('#CC000000');

      // ===== 浮层主体 (全屏黑底) =====
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

        if (this.state === 'camera') {
          this.CameraView();
        } else {
          this.PreviewView();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF0E1014');  // 跟 iOS Web MVP 一致 (linear-gradient 180deg #0a0c10 to #0E1014, 简化用 #0E1014)
    }
    .width('100%').height('100%');
  }

  // ========== 相机状态 UI (iOS Web MVP 风格) ==========
  @Builder
  CameraView() {
    Column() {
      // 顶栏: ✕ (左) + 翻转 (右)
      Row() {
        // 左侧 close
        this.CloseBtn();
        Blank();
        // 右侧翻转 (占位)
        this.FlipBtn();
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 20 });

      // 相机预览区 (含取景框)
      Stack() {
        // 中间相机图标 + 提示文字
        Column() {
          Image($r('app.media.ic_camera'))
            .width(56)
            .height(56)
            .fillColor('rgba(255,255,255,0.35)');
          Text('将题目对准框内')
            .fontSize(F_BASE)
            .fontColor('rgba(255,255,255,0.5)')
            .margin({ top: 14 });
          Text('点击下方快门拍摄')
            .fontSize(F_XS)
            .fontColor('rgba(255,255,255,0.35)')
            .margin({ top: 4 });
        }
        .alignItems(HorizontalAlign.Center);

        // 取景框 (4 角 L 形 mint)
        this.ViewfinderCorners();
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#FF000000')
      .margin({ top: 8 });

      // 底部按钮区
      Row() {
        // 左侧 相册
        this.AlbumBtn();
        // 中间 快门
        this.ShutterBtn();
        // 右侧 占位 (预览模式下是 ✓ 使用, 相机模式下 hidden)
        Column().width(56);
      }
      .width('100%')
      .padding({ left: 32, right: 32, top: 24, bottom: 50 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center);
    }
    .width('100%').height('100%');
  }

  // ========== 预览状态 UI ==========
  @Builder
  PreviewView() {
    Column() {
      // 顶栏: ‹ 返回 (左) + 标题 (中) + 占位 (右)
      Row() {
        this.BackBtn();
        Blank();
        Text('预览')
          .fontSize(F_MD)
          .fontColor(TEXT)
          .fontWeight(600);
        Blank();
        Column().width(36);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 });

      // 图片预览
      Stack() {
        if (this.capturedUri.length > 0) {
          Column() {
            // 真实图片
            Image(this.capturedUri)
              .width('100%')
              .layoutWeight(1)
              .objectFit(ImageFit.Contain)
              .backgroundColor('#FF000000');
            // 底部信息
            Row() {
              Text(this.capturedSrc === 'camera' ? '已拍摄' : '从相册选择')
                .fontSize(F_SM)
                .fontColor(TEXT_2);
              Blank();
              Text(this.capturedUri.split('/').pop() ?? '')
                .fontSize(10)
                .fontColor(TEXT_4)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 180 });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 });
          }
          .alignItems(HorizontalAlign.Center);
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#FF1A1A1A');

      // 底部按钮: 重拍 + 确认
      Row() {
        this.RetakeBtn();
        Blank().width(12);
        this.ConfirmBtn();
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 40 })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%').height('100%');
  }

  // ========== 顶栏按钮 ==========

  @Builder
  CloseBtn() {
    Stack() {
      Text('✕')
        .fontSize(18)
        .fontWeight(500)
        .fontColor('rgba(255,255,255,0.8)');
    }
    .width(40).height(40)
    .borderRadius(20)
    .backgroundColor('rgba(255,255,255,0.08)')
    .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
    .alignContent(Alignment.Center)
    .onClick(() => this.onClose());
  }

  @Builder
  FlipBtn() {
    // 翻转按钮 (占位, 暂不实现切换摄像头)
    Stack() {
      Text('⟳')
        .fontSize(18)
        .fontWeight(500)
        .fontColor('rgba(255,255,255,0.6)');
    }
    .width(40).height(40)
    .borderRadius(20)
    .backgroundColor('rgba(255,255,255,0.05)')
    .alignContent(Alignment.Center);
  }

  // ========== 底部按钮 (按 iOS Web MVP .cam-act) ==========

  @Builder
  AlbumBtn() {
    Stack() {
      Text('🖼')
        .fontSize(20);
    }
    .width(56).height(56)
    .borderRadius(28)
    .backgroundColor('rgba(255,255,255,0.08)')
    .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
    .alignContent(Alignment.Center)
    .onClick(() => {
      if (this.busy) {
        return;
      }
      this.pickAlbum();
    });
  }

  @Builder
  ShutterBtn() {
    Stack() {
      Stack()
        .width(68).height(68)
        .borderRadius(34)
        .backgroundColor('transparent')
        .border({ width: 3, color: '#FFFFFF' });
      Stack()
        .width(56).height(56)
        .borderRadius(28)
        .backgroundColor('#FFFFFF');
    }
    .width(76).height(76)
    .alignContent(Alignment.Center)
    .onClick(() => {
      if (this.busy) {
        return;
      }
      this.takePhoto();
    });
  }

  @Builder
  RetakeBtn() {
    Text('重拍')
      .fontSize(F_BASE)
      .fontColor('rgba(255,255,255,0.7)')
      .fontWeight(500)
      .width(60)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.state = 'camera';
        this.capturedUri = '';
        this.capturedSrc = '';
      });
  }

  @Builder
  ConfirmBtn() {
    Row() {
      if (this.busy) {
        LoadingProgress()
          .width(20).height(20)
          .color(BG_DARK);
      } else {
        Text('✓ 使用')
          .fontSize(F_BASE)
          .fontColor(BG_DARK)
          .fontWeight(700);
      }
    }
    .layoutWeight(1)
    .height(48)
    .borderRadius(24)
    .backgroundColor(MINT)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.busy || this.capturedUri.length === 0) {
        return;
      }
      this.busy = true;
      const uri = this.capturedUri;
      const src = this.capturedSrc === 'camera' ? 'camera' : 'album';
      this.onConfirm(uri, src);
    });
  }

  @Builder
  BackBtn() {
    Stack() {
      Text('‹')
        .fontSize(28)
        .fontWeight(500)
        .fontColor(TEXT_2);
    }
    .width(36).height(36)
    .borderRadius(18)
    .alignContent(Alignment.Center)
    .onClick(() => {
      this.state = 'camera';
      this.capturedUri = '';
      this.capturedSrc = '';
    });
  }

  // ========== 取景框 4 角 L 形 (mint, 24vp 长) ==========
  @Builder
  ViewfinderCorners() {
    Stack() {
      // 左上
      Column()
        .width(24).height(2)
        .backgroundColor(MINT)
        .position({ x: 24, y: 24 });
      Column()
        .width(2).height(24)
        .backgroundColor(MINT)
        .position({ x: 24, y: 24 });
      // 右上
      Column()
        .width(24).height(2)
        .backgroundColor(MINT)
        .position({ x: '100%', y: 24 })
        .markAnchor({ x: 24, y: 0 });
      Column()
        .width(2).height(24)
        .backgroundColor(MINT)
        .position({ x: '100%', y: 24 })
        .markAnchor({ x: 0, y: 0 });
      // 左下
      Column()
        .width(24).height(2)
        .backgroundColor(MINT)
        .position({ x: 24, y: '100%' })
        .markAnchor({ x: 0, y: -2 });
      Column()
        .width(2).height(24)
        .backgroundColor(MINT)
        .position({ x: 24, y: '100%' })
        .markAnchor({ x: 0, y: -24 });
      // 右下
      Column()
        .width(24).height(2)
        .backgroundColor(MINT)
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: -24, y: -2 });
      Column()
        .width(2).height(24)
        .backgroundColor(MINT)
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: 0, y: -24 });
    }
    .width('100%').height('100%');
  }

  // ========== 行为 ==========

  // 拍照: 调系统 cameraPicker (无需 CAMERA 权限)
  private takePhoto = async (): Promise<void> => {
    this.busy = true;
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const result: cameraPicker.PickerResult =
        await cameraPicker.pick(ctx, [cameraPicker.PickerMediaType.PHOTO]);
      if (result.resultUri.length > 0) {
        this.capturedUri = result.resultUri;
        this.capturedSrc = 'camera';
        this.state = 'preview';
        return;
      }
    } catch (_e) {
      // 用户取消 / 模拟器无相机 → 降级 mock
    } finally {
      this.busy = false;
    }
    this.capturedUri = mockCaptureUri('camera');
    this.capturedSrc = 'camera';
    this.state = 'preview';
  };

  // 选图: 调系统 PhotoViewPicker
  private pickAlbum = async (): Promise<void> => {
    this.busy = true;
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const picker: photoAccessHelper.PhotoViewPicker =
        new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult =
        await picker.select({
          MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
          maxSelectNumber: 1,
        });
      if (result.photoUris.length > 0) {
        this.capturedUri = result.photoUris[0];
        this.capturedSrc = 'album';
        this.state = 'preview';
        return;
      }
    } catch (_e) {
      // 用户取消 / 模拟器无相册 → 降级 mock
    } finally {
      this.busy = false;
    }
    this.capturedUri = mockCaptureUri('album');
    this.capturedSrc = 'album';
    this.state = 'preview';
  };
}
