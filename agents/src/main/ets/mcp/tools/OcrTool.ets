import { http } from '@kit.NetworkKit';
import { OcrConfig, fileNameFromUri, mimeFromExtension } from 'common';
import fileIo from '@ohos.file.fs';

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
  private context: Context | null;
  private currentEndpoint: string = '';

  constructor(context?: Context) {
    this.context = context ?? null;
  }

  private async resolveEndpoint(): Promise<string> {
    const config: OcrConfig = OcrConfig.getInstance();
    if (this.context !== null) {
      try {
        await config.init(this.context);
      } catch (_e) {
        // keep cached value
      }
    }
    const endpoint: string = config.getEndpoint().trim();
    return endpoint.length > 0 ? endpoint : 'http://127.0.0.1:8000/api/v1/ocr/recognize';
  }

  private async isEnabled(): Promise<boolean> {
    const config: OcrConfig = OcrConfig.getInstance();
    if (this.context !== null) {
      try {
        await config.init(this.context);
      } catch (_e) {
        return true;
      }
    }
    try {
      return config.isEnabled();
    } catch (_e) {
      return true;
    }
  }

  async recognize(imageUri: string): Promise<string> {
    console.info('[OcrTool] recognize called, uri=' + imageUri.substring(0, 60));
    if (!await this.isEnabled()) {
      console.info('[OcrTool] OCR disabled in settings, skipping');
      return '';
    }
    const result: OcrRecognitionResult = await this.recognizeImage(imageUri);
    const promptText: string = this.toPromptText(result);
    console.info('[OcrTool] recognize done, textLen=' + result.text.length.toString()
      + ', formulas=' + result.formulas.length.toString()
      + ', promptLen=' + promptText.length.toString());
    return promptText;
  }

  async recognizeBytes(imageBytes: ArrayBuffer, fileName: string = 'upload.png'): Promise<OcrRecognitionResult> {
    if (!await this.isEnabled()) {
      return {
        success: false,
        formulas: [],
        textLines: [],
        text: '',
        message: 'OCR disabled in settings',
      };
    }
    const resp: OcrResponse = await this.requestWithRetryBytes(imageBytes, fileName);
    return this.toRecognitionResult(resp);
  }

  async recognizeBytesWithEndpoint(
    imageBytes: ArrayBuffer,
    endpoint: string,
    fileName: string = 'upload.png',
  ): Promise<OcrRecognitionResult> {
    if (!await this.isEnabled()) {
      return {
        success: false,
        formulas: [],
        textLines: [],
        text: '',
        message: 'OCR disabled in settings',
      };
    }
    const resp: OcrResponse = await this.requestWithRetryBytes(imageBytes, fileName, endpoint);
    return this.toRecognitionResult(resp);
  }

  async recognizeImage(imageUri: string): Promise<OcrRecognitionResult> {
    const resp: OcrResponse = await this.requestWithRetry(imageUri);
    return this.toRecognitionResult(resp);
  }

  private async requestWithRetry(imageUri: string): Promise<OcrResponse> {
    const filePath: string = this.normalizeFilePath(imageUri);
    const fileName: string = fileNameFromUri(filePath);
    const stat: fileIo.Stat = fileIo.statSync(filePath);
    const fileBuf: ArrayBuffer = new ArrayBuffer(stat.size);
    const file: fileIo.File = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    try {
      fileIo.readSync(file.fd, fileBuf);
    } finally {
      fileIo.closeSync(file);
    }
    return await this.requestWithRetryBytes(fileBuf, fileName);
  }

  private async requestWithRetryBytes(
    imageBytes: ArrayBuffer,
    fileName: string,
    endpointOverride: string = '',
  ): Promise<OcrResponse> {
    this.currentEndpoint = endpointOverride.trim().length > 0 ? endpointOverride.trim() : await this.resolveEndpoint();
    console.info('[OcrTool] requestWithRetry endpoint=' + this.currentEndpoint);
    let lastError: string = '';
    for (let i = 0; i < 2; i++) {
      try {
        return await this.postBytes(imageBytes, fileName);
      } catch (e) {
        const detail: string = e instanceof Error ? e.message
          : (typeof e === 'string' ? e : JSON.stringify(e));
        lastError = detail;
        console.warn('[OcrTool] request attempt ' + (i + 1).toString() + '/2 failed: ' + detail);
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

  private async postBytes(imageBytes: ArrayBuffer, fileName: string): Promise<OcrResponse> {
    const mimeType: string = mimeFromExtension(fileName);
    const httpReq = http.createHttp();
    try {
      const boundary: string = '----MathMindOcr' + Date.now().toString();
      const fileBytes: Uint8Array = new Uint8Array(imageBytes);

      const headerStr: string =
        '--' + boundary + '\r\n' +
        'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
        'Content-Type: ' + mimeType + '\r\n\r\n';
      const footerStr: string = '\r\n--' + boundary + '--\r\n';

      const headerBuf: Uint8Array = this.strToUtf8(headerStr);
      const footerBuf: Uint8Array = this.strToUtf8(footerStr);
      const totalSize: number = headerBuf.length + fileBytes.length + footerBuf.length;
      const body: Uint8Array = new Uint8Array(totalSize);
      body.set(headerBuf, 0);
      body.set(fileBytes, headerBuf.length);
      body.set(footerBuf, headerBuf.length + fileBytes.length);

      const resp: http.HttpResponse = await httpReq.request(this.currentEndpoint, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data; boundary=' + boundary,
        },
        extraData: body.buffer as ArrayBuffer,
        connectTimeout: 10000,
        readTimeout: 120000,
      });

      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        throw new Error('HTTP ' + resp.responseCode.toString() + ': ' + ((resp.result as string) ?? ''));
      }

      return JSON.parse(resp.result as string) as OcrResponse;
    } finally {
      httpReq.destroy();
    }
  }

  private strToUtf8(s: string): Uint8Array {
    const buf: Uint8Array = new Uint8Array(s.length * 3);
    let pos: number = 0;
    for (let i: number = 0; i < s.length; i++) {
      const cp: number = s.charCodeAt(i);
      if (cp < 0x80) {
        buf[pos] = cp;
        pos = pos + 1;
      } else if (cp < 0x800) {
        buf[pos] = 0xC0 | (cp >> 6);
        buf[pos + 1] = 0x80 | (cp & 0x3F);
        pos = pos + 2;
      } else {
        buf[pos] = 0xE0 | (cp >> 12);
        buf[pos + 1] = 0x80 | ((cp >> 6) & 0x3F);
        buf[pos + 2] = 0x80 | (cp & 0x3F);
        pos = pos + 3;
      }
    }
    return buf.slice(0, pos);
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

  private toRecognitionResult(resp: OcrResponse): OcrRecognitionResult {
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

  private normalizeFilePath(imageUri: string): string {
    if (imageUri.startsWith('file://')) {
      return imageUri.substring('file://'.length);
    }
    return imageUri;
  }
}
