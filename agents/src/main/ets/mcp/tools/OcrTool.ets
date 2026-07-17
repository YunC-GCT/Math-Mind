import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';

export interface OcrRecognitionResult {
  success: boolean;
  formulas: string[];
  textLines: string[];
  text: string;
  message: string;
}

interface FormulaResponse {
  success: boolean;
  count: number;
  formulas: string[];
  message: string;
}

interface CombinedOcrResponse {
  success: boolean;
  formula_count: number;
  formulas: string[];
  text_line_count: number;
  text_lines: string[];
  text: string;
  message: string;
}

interface OcrError {
  code?: number;
  message?: string;
}

/**
 * Hybrid image recognition:
 * - HarmonyOS CoreVisionKit recognizes ordinary text on supported devices.
 * - The local FormulaNet HTTP service recognizes formulas as LaTeX.
 * - Devices without CoreVisionKit fall back to the combined OCR endpoint.
 */
export class OcrTool {
  private formulaEndpoint: string;
  private fallbackOcrEndpoint: string;

  constructor(formulaEndpoint?: string, fallbackOcrEndpoint?: string) {
    this.formulaEndpoint = formulaEndpoint ??
      'http://10.0.2.2:8000/api/v1/formula/recognize';
    this.fallbackOcrEndpoint = fallbackOcrEndpoint ??
      'http://10.0.2.2:8000/api/v1/ocr/recognize';
  }

  async recognize(imageUri: string): Promise<string> {
    const result: OcrRecognitionResult = await this.recognizeImage(imageUri);
    if (!result.success) {
      throw new Error('OCR failed: ' + result.message);
    }

    const promptText: string = this.toPromptText(result);
    if (promptText.trim().length === 0) {
      throw new Error('OCR returned empty text');
    }
    return promptText;
  }

  async recognizeImage(imageUri: string): Promise<OcrRecognitionResult> {
    const filePath: string = this.normalizeFilePath(imageUri);
    let textLines: string[] = [];
    let formulas: string[] = [];
    let textError: string = '';
    let formulaError: string = '';
    let usedServerFallback: boolean = false;

    try {
      textLines = await this.recognizeLocalText(filePath);
    } catch (e) {
      textError = this.errorText(e as OcrError);
    }

    if (textError.length > 0) {
      try {
        const fallback: CombinedOcrResponse = await this.requestCombinedWithRetry(filePath);
        if (fallback.success) {
          textLines = fallback.text_lines ?? [];
          if (textLines.length === 0 && fallback.text.trim().length > 0) {
            textLines.push(fallback.text.trim());
          }
          formulas = fallback.formulas ?? [];
          textError = '';
          usedServerFallback = true;
        } else {
          formulaError = fallback.message;
        }
      } catch (e) {
        formulaError = this.errorText(e as OcrError);
      }
    } else {
      try {
        const response: FormulaResponse = await this.requestFormulaWithRetry(filePath);
        if (response.success) {
          formulas = response.formulas ?? [];
        } else {
          formulaError = response.message;
        }
      } catch (e) {
        formulaError = this.errorText(e as OcrError);
      }
    }

    const text: string = textLines.join('\n');
    const success: boolean = text.trim().length > 0 || formulas.length > 0;
    const messages: string[] = [];
    if (textError.length > 0) {
      messages.push('Local text OCR: ' + textError);
    }
    if (formulaError.length > 0) {
      messages.push('Formula OCR: ' + formulaError);
    }
    if (messages.length === 0) {
      const mode: string = usedServerFallback ? 'server fallback' : 'on-device text OCR';
      messages.push('Recognized ' + textLines.length.toString() +
        ' text lines and ' + formulas.length.toString() + ' formulas using ' + mode);
    }

    return {
      success: success,
      formulas: formulas,
      textLines: textLines,
      text: text,
      message: messages.join('; '),
    };
  }

  private async recognizeLocalText(filePath: string): Promise<string[]> {
    if (!canIUse('SystemCapability.AI.OCR.TextRecognition')) {
      throw new Error('CoreVisionKit text OCR is not supported on this device');
    }

    const source: image.ImageSource = image.createImageSource(filePath);
    let pixelMap: image.PixelMap | undefined = undefined;
    let serviceInitialized: boolean = false;

    try {
      pixelMap = await source.createPixelMap({
        editable: false,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      });

      serviceInitialized = await textRecognition.init();
      if (!serviceInitialized) {
        throw new Error('CoreVisionKit initialization failed');
      }

      const result: textRecognition.TextRecognitionResult =
        await textRecognition.recognizeText({ pixelMap: pixelMap });
      return this.extractTextLines(result);
    } finally {
      if (serviceInitialized) {
        await textRecognition.release();
      }
      if (pixelMap !== undefined) {
        await pixelMap.release();
      }
      await source.release();
    }
  }

  private extractTextLines(result: textRecognition.TextRecognitionResult): string[] {
    const lines: string[] = [];
    for (let blockIndex = 0; blockIndex < result.blocks.length; blockIndex++) {
      const block: textRecognition.TextBlock = result.blocks[blockIndex];
      for (let lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        const value: string = block.lines[lineIndex].value.trim();
        if (value.length > 0) {
          lines.push(value);
        }
      }
    }

    const fullText: string = result.value.trim();
    if (lines.length === 0 && fullText.length > 0) {
      lines.push(fullText);
    }
    return lines;
  }

  private async requestFormulaWithRetry(filePath: string): Promise<FormulaResponse> {
    let lastError: string = '';
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const responseText: string = await this.postImage(this.formulaEndpoint, filePath);
        return JSON.parse(responseText) as FormulaResponse;
      } catch (e) {
        lastError = this.errorText(e as OcrError);
      }
    }
    throw new Error('Formula request failed: ' + lastError);
  }

  private async requestCombinedWithRetry(filePath: string): Promise<CombinedOcrResponse> {
    let lastError: string = '';
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const responseText: string = await this.postImage(this.fallbackOcrEndpoint, filePath);
        return JSON.parse(responseText) as CombinedOcrResponse;
      } catch (e) {
        lastError = this.errorText(e as OcrError);
      }
    }
    throw new Error('Fallback OCR request failed: ' + lastError);
  }

  private async postImage(endpoint: string, filePath: string): Promise<string> {
    const fileName: string = this.fileNameFromUri(filePath);
    const httpReq: http.HttpRequest = http.createHttp();

    try {
      const response: http.HttpResponse = await httpReq.request(endpoint, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data',
        },
        multiFormDataList: [
          {
            name: 'file',
            contentType: this.mimeFromName(fileName),
            filePath: filePath,
            remoteFileName: fileName,
          },
        ],
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: 300000,
      });

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('HTTP ' + response.responseCode.toString() + ': ' +
          (response.result as string));
      }
      return response.result as string;
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

  private errorText(error: OcrError): string {
    const message: string = error.message ?? 'Unknown error';
    if (error.code === undefined) {
      return message;
    }
    return 'code=' + error.code.toString() + ', message=' + message;
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
