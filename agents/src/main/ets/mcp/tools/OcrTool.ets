import { http } from '@kit.NetworkKit';

export interface OcrRecognitionResult {
  success: boolean;
  formulas: string[];
  textLines: string[];
  text: string;
  message: string;
}

interface OcrResponse {
  success: boolean;
  formula_count: number;
  formulas: string[];
  text_line_count: number;
  text_lines: string[];
  text: string;
  message: string;
}

export class OcrTool {
  private endpoint: string;

  constructor(endpoint?: string) {
    this.endpoint = endpoint ?? 'http://127.0.0.1:8000/api/v1/ocr/recognize';
  }

  async recognize(imageUri: string): Promise<string> {
    const result: OcrRecognitionResult = await this.recognizeImage(imageUri);
    return this.toPromptText(result);
  }

  async recognizeImage(imageUri: string): Promise<OcrRecognitionResult> {
    const resp: OcrResponse = await this.requestWithRetry(imageUri);
    const formulas: string[] = resp.formulas ?? [];
    const textLines: string[] = resp.text_lines ?? [];
    const text: string = resp.text ?? textLines.join(' ');

    return {
      success: resp.success,
      formulas: formulas,
      textLines: textLines,
      text: text,
      message: resp.message ?? '',
    };
  }

  private async requestWithRetry(imageUri: string): Promise<OcrResponse> {
    let lastError: string = '';
    for (let i = 0; i < 2; i++) {
      try {
        return await this.postImage(imageUri);
      } catch (e) {
        lastError = e instanceof Error ? e.message : String(e);
      }
    }
    return {
      success: false,
      formula_count: 0,
      formulas: [],
      text_line_count: 0,
      text_lines: [],
      text: '',
      message: 'OCR request failed: ' + lastError,
    };
  }

  private async postImage(imageUri: string): Promise<OcrResponse> {
    const filePath: string = this.normalizeFilePath(imageUri);
    const fileName: string = this.fileNameFromUri(filePath);
    const httpReq = http.createHttp();

    try {
      const resp: http.HttpResponse = await httpReq.request(this.endpoint, {
        method: http.RequestMethod.POST,
        multiFormDataList: [
          {
            name: 'file',
            contentType: this.mimeFromName(fileName),
            filePath: filePath,
            remoteFileName: fileName,
          },
        ],
        connectTimeout: 5000,
        readTimeout: 30000,
      });

      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        throw new Error('HTTP ' + resp.responseCode.toString() + ': ' + ((resp.result as string) ?? ''));
      }

      return JSON.parse(resp.result as string) as OcrResponse;
    } finally {
      httpReq.destroy();
    }
  }

  private toPromptText(result: OcrRecognitionResult): string {
    const parts: string[] = [];
    const text: string = result.text.trim();
    if (text.length > 0) {
      parts.push(text);
    }
    if (result.formulas.length > 0) {
      parts.push('LaTeX formulas:\n' + result.formulas.join('\n'));
    }
    return parts.join('\n\n');
  }

  private normalizeFilePath(imageUri: string): string {
    if (imageUri.startsWith('file://')) {
      return imageUri.substring('file://'.length);
    }
    return imageUri;
  }

  private fileNameFromUri(uri: string): string {
    const clean: string = uri.split('?')[0];
    const slash: number = clean.lastIndexOf('/');
    const backslash: number = clean.lastIndexOf('\\');
    const index: number = Math.max(slash, backslash);
    if (index >= 0 && index + 1 < clean.length) {
      return clean.substring(index + 1);
    }
    return 'upload.png';
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
