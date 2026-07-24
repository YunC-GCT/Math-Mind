"""
通用文字 OCR 工具模块 — MathMind Agent 可调用
===========================================
提供 OcrTextTool 类，封装 Tesseract OCR 通用文字识别，
供后端 Agent 提取图片中的普通文本（非公式）。

与 formula_tool.py 配合：
    - formula_tool.py: 公式 → LaTeX
    - ocr_text_tool.py: 普通文字 → 文本字符串

依赖:
    - Tesseract OCR 5.x 已安装
    - pip install pytesseract Pillow

用法:
    from ocr_text_tool import OcrTextTool
    tool = OcrTextTool()
    text_lines = tool.recognize("试卷截图.png")
    # → ["已知函数 f(x) = ...", "求下列极限：", ...]
"""

import logging
import os
from pathlib import Path
from typing import List, Optional

import pytesseract
from PIL import Image

logger = logging.getLogger("mathmind.ocr_text_tool")

# Tesseract 路径配置
_TESSERACT_EXE = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
_TESSDATA_DIR = r"D:\Tesseract\tessdata"

if os.path.exists(_TESSERACT_EXE):
    pytesseract.pytesseract.tesseract_cmd = _TESSERACT_EXE
if os.path.isdir(_TESSDATA_DIR):
    os.environ["TESSDATA_PREFIX"] = _TESSDATA_DIR


class OcrTextTool:
    """
    通用文字 OCR 工具，基于 Tesseract OCR 引擎。

    与 FormulaTool 的区别：
        - FormulaTool: 专用公式识别，输出 LaTeX
        - OcrTextTool: 通用文字识别，输出纯文本

    Tesseract 模型约 48MB（中英双语），速度快（每张 < 1s）。
    """

    def __init__(self, lang: str = "chi_sim+eng"):
        """
        初始化文字识别器。

        参数:
            lang: Tesseract 语言代码
                "chi_sim+eng" = 中英混合（默认，适合数学试卷）
                "eng" = 纯英文
        """
        self.lang = lang
        logger.info("初始化 Tesseract OCR (lang=%s, exe=%s)", lang, _TESSERACT_EXE)

    def recognize(self, image_path: str) -> List[str]:
        """
        识别图片中的文字行。

        返回:
            list[str]: 按阅读顺序排列的文字行列表
        """
        logger.info("文字 OCR: %s", image_path)

        if not Path(image_path).exists():
            raise FileNotFoundError(f"图片不存在: {image_path}")

        img = Image.open(image_path)
        text = pytesseract.image_to_string(img, lang=self.lang, config="--psm 6")

        # 按行分割，过滤空行
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        logger.info("识别到 %d 行文字", len(lines))
        return lines

    def recognize_from_bytes(
        self, image_bytes: bytes, filename: str = "temp.png"
    ) -> List[str]:
        """
        从字节数据识别文字（适合 API 上传场景）。
        """
        tmp_path = Path(f"_ocr_tmp_{filename}")
        try:
            tmp_path.write_bytes(image_bytes)
            return self.recognize(str(tmp_path))
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    def recognize_to_plain_text(self, image_path: str) -> str:
        """
        识别并拼接为一段纯文本。
        """
        lines = self.recognize(image_path)
        return " ".join(lines)


# ===== 快捷函数 =====

_default_ocr: Optional[OcrTextTool] = None


def recognize_text(image_path: str) -> List[str]:
    """快捷函数：一行调用文字识别。"""
    global _default_ocr
    if _default_ocr is None:
        _default_ocr = OcrTextTool()
    return _default_ocr.recognize(image_path)


def recognize_text_plain(image_path: str) -> str:
    """快捷函数：一行调用，返回拼接全文。"""
    global _default_ocr
    if _default_ocr is None:
        _default_ocr = OcrTextTool()
    return _default_ocr.recognize_to_plain_text(image_path)
