"""
公式识别工具模块 — MathMind Agent 可调用
=======================================
提供 FormulaTool 类，封装 PaddleOCR 公式识别，
供后端 Agent（TypeClassifier、KnowledgeModel 等）直接 import 调用。

用法:
    from formula_tool import FormulaTool
    tool = FormulaTool()
    latex_list = tool.recognize("公式图片.png")
"""

import json
import logging
from pathlib import Path
from typing import List, Optional

from paddleocr import FormulaRecognitionPipeline

logger = logging.getLogger("mathmind.formula_tool")


class FormulaTool:
    """
    公式识别工具，可被任意 Agent 调用。

    首次初始化时会自动下载模型（~600 MB），缓存到用户目录。
    之后秒级加载。
    """

    def __init__(self, use_layout: bool = False, use_preprocessor: bool = False):
        """
        初始化公式识别器。

        参数:
            use_layout: 是否启用版面检测
                False = 整图直接送公式识别（适合截图类纯公式图片）
                True  = 先检测版面定位公式区域（适合整页文档/论文）
            use_preprocessor: 是否启用图像预处理（方向矫正 + 扭曲矫正）
        """
        self.use_layout = use_layout
        self.use_preprocessor = use_preprocessor

        config = {
            "pipeline_name": "formula_recognition",
            "use_doc_preprocessor": use_preprocessor,
            "use_layout_detection": use_layout,
            "SubModules": {
                "FormulaRecognition": {
                    "model_name": "PP-FormulaNet_plus-M",
                    "batch_size": 1,
                }
            },
        }

        # 如果开启版面检测，需要配置版面检测模型
        if use_layout:
            config["SubModules"]["LayoutDetection"] = {
                "model_name": "PP-DocLayout_plus-L",
                "batch_size": 1,
            }

        logger.info(
            "初始化公式识别器 (layout=%s, preprocessor=%s)",
            use_layout, use_preprocessor,
        )
        self._pipeline = FormulaRecognitionPipeline(
            engine="paddle_static",
            engine_config={"run_mode": "paddle", "device_type": "cpu"},
            paddlex_config=config,
        )

    def recognize(self, image_path: str) -> List[str]:
        """
        识别图片中的数学公式。

        参数:
            image_path: 图片路径（支持 jpg/png/bmp 等常见格式）

        返回:
            list[str]: LaTeX 格式的公式字符串列表

        示例:
            tool = FormulaTool()
            results = tool.recognize("test.png")
            for latex in results:
                print(latex)
        """
        logger.info("识别公式: %s", image_path)

        if not Path(image_path).exists():
            raise FileNotFoundError(f"图片不存在: {image_path}")

        results: List[str] = []
        output = self._pipeline.predict(image_path)

        for res in output:
            data = res.json
            if isinstance(data, str):
                data = json.loads(data)
            formula_list = data["res"].get("formula_res_list", [])
            for f in formula_list:
                results.append(f["rec_formula"])

        logger.info("识别到 %d 个公式", len(results))
        return results

    def recognize_from_bytes(self, image_bytes: bytes, filename: str = "temp.png") -> List[str]:
        """
        从字节数据识别公式（适合 API 上传场景）。

        参数:
            image_bytes: 图片的二进制数据
            filename: 临时文件名（用于确定后缀）

        返回:
            list[str]: LaTeX 格式的公式字符串列表
        """
        tmp_path = Path(f"_formula_tmp_{filename}")
        try:
            tmp_path.write_bytes(image_bytes)
            return self.recognize(str(tmp_path))
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    def recognize_with_metadata(self, image_path: str) -> List[dict]:
        """
        识别公式并返回结构化元数据。

        返回:
            list[dict]: 每个公式包含:
                - latex: LaTeX 源码
                - region_id: 公式区域编号
                - 后续可扩展 confidence 等字段
        """
        if not Path(image_path).exists():
            raise FileNotFoundError(f"图片不存在: {image_path}")

        results: List[dict] = []
        output = self._pipeline.predict(image_path)

        for res in output:
            data = res.json
            if isinstance(data, str):
                data = json.loads(data)
            formula_list = data["res"].get("formula_res_list", [])
            for f in formula_list:
                results.append({
                    "latex": f["rec_formula"],
                    "region_id": f.get("formula_region_id"),
                })

        return results


# ===== 快捷函数（开箱即用） =====

_default_tool: Optional[FormulaTool] = None


def recognize(image_path: str) -> List[str]:
    """快捷函数：一行调用公式识别。"""
    global _default_tool
    if _default_tool is None:
        _default_tool = FormulaTool()
    return _default_tool.recognize(image_path)
