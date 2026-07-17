/**
 * ImageUriResolver.ets — 拍照/选图 URI → 本地沙箱文件路径解析
 *
 * 路径: entry/src/main/ets/services/ImageUriResolver.ets
 * 职责: 把拍照/相册返回的 file:// URI 复制到应用 cacheDir 下，产出
 *       后续 OCR / KnowledgeModel 可以稳定读取的本地路径 + 文件名 + MIME。
 * 依赖: @ohos.file.fs (fileIo)、@kit.AbilityKit (common.UIAbilityContext)
 *
 * 数据流:
 *   拍照/相册 → imageUri (file://xxx)
 *     → resolve(imageUri)
 *       → ensureDir(cacheDir/mathmind_capture)
 *       → buildFileName(uri)  // capture_{ts}_{rand}{ext}
 *       → fileIo.copy(imageUri, file://localPath)
 *       → 返回 ResolvedImageFile
 *
 * 设计要点:
 *   - 拒绝 mock_ 前缀: 测试夹具不能进入真实 capture pipeline
 *   - 扩展名映射: jpg/jpeg/webp/bmp/png（其他按 png 兜底）
 *   - MIME 自动从文件名推断（image/jpeg | image/webp | image/bmp | image/png）
 */
import fileIo from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';

export interface ResolvedImageFile {
  originalUri: string;
  localPath: string;
  fileName: string;
  mimeType: string;
}

export class ImageUriResolver {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async resolve(imageUri: string): Promise<ResolvedImageFile> {
    if (imageUri.startsWith('mock_')) {
      throw new Error('mock image uri cannot be processed by capture pipeline: ' + imageUri);
    }

    const dir: string = this.context.cacheDir + '/mathmind_capture';
    this.ensureDir(dir);

    const fileName: string = this.buildFileName(imageUri);
    const localPath: string = dir + '/' + fileName;
    const destUri: string = 'file://' + localPath;

    await fileIo.copy(imageUri, destUri);

    return {
      originalUri: imageUri,
      localPath: localPath,
      fileName: fileName,
      mimeType: this.mimeFromName(fileName),
    };
  }

  private ensureDir(path: string): void {
    try {
      if (!fileIo.accessSync(path)) {
        fileIo.mkdirSync(path, true);
      }
    } catch (e) {
      fileIo.mkdirSync(path, true);
    }
  }

  private buildFileName(uri: string): string {
    const ext: string = this.extFromUri(uri);
    return 'capture_' + Date.now().toString() + '_' + Math.floor(Math.random() * 100000).toString() + ext;
  }

  private extFromUri(uri: string): string {
    const clean: string = uri.split('?')[0].toLowerCase();
    if (clean.endsWith('.jpg') || clean.endsWith('.jpeg')) {
      return '.jpg';
    }
    if (clean.endsWith('.webp')) {
      return '.webp';
    }
    if (clean.endsWith('.bmp')) {
      return '.bmp';
    }
    return '.png';
  }

  private mimeFromName(fileName: string): string {
    const lower: string = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.bmp')) {
      return 'image/bmp';
    }
    return 'image/png';
  }
}