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