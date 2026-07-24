MathMind OCR 服务 — 使用说明
================================

一、环境要求
-----------
- Windows 10/11
- Python 3.10+
- Tesseract OCR 5.x (文字 OCR 需要，公式识别不需要)
  - 下载: https://github.com/tesseract-ocr/tesseract/releases
  - 安装到默认路径: C:\Program Files\Tesseract-OCR\
  - 中文包放到: C:\Program Files\Tesseract-OCR\tessdata\chi_sim.traineddata
    (下载: https://github.com/tesseract-ocr/tessdata/raw/main/chi_sim.traineddata)


二、使用方法
-----------
1. 解压此文件夹

2. 双击 start.bat 启动服务
   - 首次运行会自动下载模型（~720MB），请等待 3-5 分钟
   - 看到 "Uvicorn running on http://0.0.0.0:8000" 表示启动成功

3. 调用 API

   测试是否启动成功:
   浏览器打开 http://localhost:8000/docs

   命令行测试:
   curl -X POST http://localhost:8000/api/v1/ocr/recognize -F "file=@你的图片.png"


三、API 说明
-----------

POST /api/v1/ocr/recognize
  上传图片，返回公式 LaTeX + 文字
  请求: multipart/form-data, field 名 "file"
  响应:
  {
    "success": true,
    "formula_count": 10,
    "formulas": ["\\frac{x}{y}", "E=mc^2", ...],
    "text_line_count": 14,
    "text_lines": ["题目文字", ...],
    "text": "拼接全文",
    "message": "识别到 10 个公式、14 行文字"
  }

POST /api/v1/formula/recognize
  仅公式识别（不包含文字 OCR）

GET /api/v1/formula/health
  健康检查


四、手动启动（不用 start.bat）
----------------------------
cd 到此目录
pip install -r requirements.txt
python -c "from fastapi import FastAPI; import uvicorn; from formula_api import router, ocr_router; app=FastAPI(); app.include_router(router, prefix='/api/v1'); app.include_router(ocr_router, prefix='/api/v1'); uvicorn.run(app, host='0.0.0.0', port=8000)"


五、性能说明
-----------
- 文字 OCR: ~1.6 秒/张
- 公式识别: ~28 秒/张（CPU，自动缩放到 1200px）
- 第一次启动下载模型约 3-5 分钟，之后秒级启动


六、文件清单
-----------
formula_tool.py      公式识别引擎 (PaddleOCR PP-FormulaNet)
ocr_text_tool.py     文字 OCR 引擎 (Tesseract)
formula_api.py       FastAPI 服务端点
start.bat            一键启动脚本
requirements.txt     Python 依赖
README.txt           本文件
