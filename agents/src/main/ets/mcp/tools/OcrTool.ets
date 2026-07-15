import { http } from '@kit.NetworkKit';

// OCR 识别结果接口：对外暴露的统一返回格式
export interface OcrRecognitionResult {
  success: boolean;      // 识别是否成功
  formulas: string[];    // 识别出的 LaTeX 公式列表
  textLines: string[];   // 按行分割的文本行
  text: string;          // 完整识别文本（所有文本行拼接）
  message: string;       // 错误或状态提示信息
}

// OCR API 原始响应接口：与后端 /ocr/recognize 返回的 JSON 结构一一对应
interface OcrResponse {
  success: boolean;
  formula_count: number;
  formulas: string[];
  text_line_count: number;
  text_lines: string[];
  text: string;
  message: string;
}

/**
 * OCR 工具类：将图片发送至后端 OCR 服务进行文字与公式识别。
 * 支持自动重试、文件路径规范化、MIME 类型推断及结果格式化。
 */
export class OcrTool {
  // OCR 服务端点地址，默认指向本地开发服务
  private endpoint: string;

  constructor(endpoint?: string) {
    this.endpoint = endpoint ?? 'http://127.0.0.1:8000/api/v1/ocr/recognize';
  }

  /**
   * 执行 OCR 识别，返回格式化后的 prompt 文本。
   * @param imageUri 图片 URI（支持 file:// 协议或普通文件路径）
   * @returns 拼接好的识别结果字符串（文本 + LaTeX 公式）
   */
  async recognize(imageUri: string): Promise<string> {
    const result: OcrRecognitionResult = await this.recognizeImage(imageUri);
    return this.toPromptText(result);
  }

  /**
   * 调用 OCR 服务识别图片，返回结构化识别结果。
   * @param imageUri 图片 URI
   * @returns OcrRecognitionResult 结构，包含文本、公式等信息
   */
  async recognizeImage(imageUri: string): Promise<OcrRecognitionResult> {
    // 发起带重试的 HTTP 请求，获取原始响应
    const resp: OcrResponse = await this.requestWithRetry(imageUri);
    const formulas: string[] = resp.formulas ?? [];
    const textLines: string[] = resp.text_lines ?? [];
    // 若服务端未返回统一 text，则用所有文本行拼接
    const text: string = resp.text ?? textLines.join(' ');

    return {
      success: resp.success,
      formulas: formulas,
      textLines: textLines,
      text: text,
      message: resp.message ?? '',
    };
  }

  /**
   * 带重试的请求封装：最多尝试 2 次，全部失败后返回错误结果。
   * 这样可应对网络瞬时抖动，避免上层因单次超时就彻底失败。
   */
  private async requestWithRetry(imageUri: string): Promise<OcrResponse> {
    let lastError: string = '';
    for (let i = 0; i < 2; i++) {
      try {
        return await this.postImage(imageUri);
      } catch (e) {
        lastError = e instanceof Error ? e.message : String(e);
      }
    }
    // 所有重试均失败，返回统一错误结构，保持接口契约一致
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

  /**
   * 通过 HTTP multipart/form-data 将图片文件上传至 OCR 服务。
   * 使用 HarmonyOS http 模块完成 POST 请求，请求完成后销毁 http 实例释放资源。
   */
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
            contentType: this.mimeFromName(fileName),  // 根据后缀自动推断 MIME
            filePath: filePath,
            remoteFileName: fileName,
          },
        ],
        connectTimeout: 5000,   // 连接超时 5 秒
        readTimeout: 30000,     // 读取超时 30 秒（图片上传可能较慢）
      });

      // 非 2xx 状态码视为请求失败
      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        throw new Error('HTTP ' + resp.responseCode.toString() + ': ' + ((resp.result as string) ?? ''));
      }

      return JSON.parse(resp.result as string) as OcrResponse;
    } finally {
      // 无论成功失败，确保释放 HTTP 连接资源
      httpReq.destroy();
    }
  }

  /**
   * 将结构化识别结果格式化为可嵌入 prompt 的文本。
   * 格式：普通文本（如有） + 空行 + LaTeX 公式列表。
   */
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

  /**
   * 规范化文件路径：去掉 file:// 协议前缀，得到可直接使用的本地路径。
   */
  private normalizeFilePath(imageUri: string): string {
    if (imageUri.startsWith('file://')) {
      return imageUri.substring('file://'.length);
    }
    return imageUri;
  }

  /**
   * 从 URI 路径中提取文件名（去除查询参数后取最后一段）。
   * 兼容正斜杠 / 和反斜杠 \ 两种路径分隔符（Windows 与 Unix 风格）。
   */
  private fileNameFromUri(uri: string): string {
    const clean: string = uri.split('?')[0];           // 去除 ? 后的查询参数
    const slash: number = clean.lastIndexOf('/');
    const backslash: number = clean.lastIndexOf('\\');
    const index: number = Math.max(slash, backslash);  // 取最末级分隔符位置
    if (index >= 0 && index + 1 < clean.length) {
      return clean.substring(index + 1);
    }
    return 'upload.png';  // 兜底：无法解析时使用默认文件名
  }

  /**
   * 根据文件名后缀推断 MIME 类型，用于 multipart 上传时设置 Content-Type。
   * 默认返回 image/png。
   */
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
