"""
Formula OCR + text OCR FastAPI service for MathMind.

The combined OCR endpoint is optimized for competition demos:
- text mode is the default and skips the slow formula model;
- formula mode runs FormulaNet with a timeout and output quality filter;
- auto mode only runs FormulaNet for small, formula-like images.
"""

import asyncio
import io
import logging
import re
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from fastapi import APIRouter, File, HTTPException, Query, UploadFile
from PIL import Image, ImageChops, ImageFilter
from pydantic import BaseModel, Field

from formula_tool import FormulaTool
from ocr_text_tool import OcrTextTool

logger = logging.getLogger("mathmind.api.formula")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

router = APIRouter(prefix="/formula", tags=["formula"])
ocr_router = APIRouter(prefix="/ocr", tags=["ocr"])

_formula_tool: Optional[FormulaTool] = None
_ocr_tool: Optional[OcrTextTool] = None
_formula_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="formula-ocr")

VALID_OCR_MODES = {"text", "formula", "auto"}
FORMULA_MAX_EDGE = 960
UPLOAD_LIMIT_BYTES = 20 * 1024 * 1024
MAX_FORMULA_CANDIDATES = 3
MIN_FORMULA_BLOCK_HEIGHT = 22
MAX_FORMULA_BLOCK_HEIGHT_RATIO = 0.38
MAX_FORMULA_BLOCK_AREA_RATIO = 0.45
MIN_FORMULA_SIGNAL_SCORE = 2.5


def get_formula_tool() -> FormulaTool:
    global _formula_tool
    if _formula_tool is None:
        logger.info("Initializing formula OCR tool")
        _formula_tool = FormulaTool()
    return _formula_tool


def get_ocr_tool() -> OcrTextTool:
    global _ocr_tool
    if _ocr_tool is None:
        logger.info("Initializing text OCR tool")
        _ocr_tool = OcrTextTool()
    return _ocr_tool


class FormulaResponse(BaseModel):
    success: bool
    count: int
    formulas: List[str]
    message: str = ""


class HealthResponse(BaseModel):
    status: str
    model: str
    engine: str


class FormulaRegion(BaseModel):
    left: int
    top: int
    right: int
    bottom: int
    width: int
    height: int
    score: float
    reason: str = ""


class OcrResponse(BaseModel):
    success: bool
    formula_count: int
    formulas: List[str]
    text_line_count: int
    text_lines: List[str]
    text: str = ""
    message: str = ""
    mode: str = "text"
    formula_skipped: bool = False
    formula_timeout: bool = False
    formula_rejected: bool = False
    formula_candidates: int = 0
    formula_skipped_reason: str = ""
    formula_regions: List[FormulaRegion] = Field(default_factory=list)
    timings: Dict[str, float] = Field(default_factory=dict)


@router.post("/recognize", response_model=FormulaResponse)
async def recognize_formula(
    file: UploadFile = File(...),
    use_layout: bool = Query(False),
    use_preprocessor: bool = Query(False),
):
    validate_image_upload(file)
    contents = await read_upload(file)

    try:
        filename = file.filename or "upload.png"
        tool = get_formula_tool()
        formulas = tool.recognize_from_bytes(contents, filename)
        formulas, rejected = filter_formulas(formulas)
        return FormulaResponse(
            success=True,
            count=len(formulas),
            formulas=formulas,
            message=build_formula_message(len(formulas), rejected),
        )
    except Exception as e:
        logger.exception("Formula OCR failed")
        raise HTTPException(status_code=500, detail=f"Formula OCR failed: {str(e)}")


@router.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="ok",
        model="PP-FormulaNet_plus-M",
        engine="paddle_static",
    )


@ocr_router.post("/recognize", response_model=OcrResponse)
async def recognize_ocr(
    file: UploadFile = File(...),
    mode: str = Query("text", description="text | formula | auto"),
    formula_timeout: int = Query(30, ge=3, le=120),
):
    validate_image_upload(file)
    normalized_mode = mode.lower().strip()
    if normalized_mode not in VALID_OCR_MODES:
        raise HTTPException(status_code=400, detail="mode must be text, formula, or auto")

    total_start = time.perf_counter()
    read_start = time.perf_counter()
    contents = await read_upload(file)
    read_ms = elapsed_ms(read_start)

    filename = file.filename or "upload.png"
    size_kb = len(contents) / 1024
    timings: Dict[str, float] = {"read_ms": round(read_ms, 1)}
    formulas: List[str] = []
    formula_skipped = False
    formula_timed_out = False
    formula_rejected = False

    try:
        text_lines, source_image, preprocess_ms, text_ocr_ms = recognize_text(contents)
        text = " ".join(text_lines)
        timings["text_preprocess_ms"] = round(preprocess_ms, 1)
        timings["text_ocr_ms"] = round(text_ocr_ms, 1)

        should_run_formula, skip_reason = should_run_formula_ocr(
            normalized_mode,
            source_image.size,
            text_lines,
            text,
        )
        formula_regions: List[FormulaRegion] = []
        candidate_count = 0
        if should_run_formula:
            formula_start = time.perf_counter()
            candidates, formula_regions, candidate_skip_reason = prepare_formula_candidates(
                source_image,
                normalized_mode,
                text_lines,
                text,
            )
            candidate_count = len(candidates)
            timings["formula_prepare_ms"] = round(elapsed_ms(formula_start), 1)

            if len(candidates) == 0:
                formula_skipped = True
                skip_reason = candidate_skip_reason
                timings["formula_resize_ms"] = 0
                timings["formula_ocr_ms"] = 0
            else:
                formula_ocr_start = time.perf_counter()
                raw_formulas: List[str] = []
                for candidate_image, _region in candidates:
                    candidate_formulas, candidate_timed_out = await recognize_formula_with_timeout(
                        candidate_image,
                        Path(filename).suffix or ".png",
                        formula_timeout,
                    )
                    formula_timed_out = formula_timed_out or candidate_timed_out
                    raw_formulas.extend(candidate_formulas)
                    if candidate_timed_out:
                        break
                timings["formula_resize_ms"] = 0
                timings["formula_ocr_ms"] = round(elapsed_ms(formula_ocr_start), 1)
                formulas, formula_rejected = filter_formulas(raw_formulas)
        else:
            formula_skipped = True
            candidate_count = 0
            formula_regions = []
            timings["formula_prepare_ms"] = 0
            timings["formula_resize_ms"] = 0
            timings["formula_ocr_ms"] = 0

        timings["total_ms"] = round(elapsed_ms(total_start), 1)
        message = build_ocr_message(
            len(text_lines),
            len(formulas),
            normalized_mode,
            formula_skipped,
            formula_timed_out,
            formula_rejected,
            skip_reason,
        )

        logger.info(
            "OCR timing file=%s mode=%s size=%.1fKB read=%.1fms text_preprocess=%.1fms "
            "text_ocr=%.1fms formula_resize=%.1fms formula_ocr=%.1fms total=%.1fms "
            "image_size=%s text_lines=%d candidates=%d formulas=%d skipped=%s timeout=%s rejected=%s reason=%s",
            filename,
            normalized_mode,
            size_kb,
            timings["read_ms"],
            timings["text_preprocess_ms"],
            timings["text_ocr_ms"],
            timings["formula_resize_ms"],
            timings["formula_ocr_ms"],
            timings["total_ms"],
            source_image.size,
            len(text_lines),
            candidate_count,
            len(formulas),
            formula_skipped,
            formula_timed_out,
            formula_rejected,
            skip_reason,
        )

        return OcrResponse(
            success=len(text.strip()) > 0 or len(formulas) > 0,
            formula_count=len(formulas),
            formulas=formulas,
            text_line_count=len(text_lines),
            text_lines=text_lines,
            text=text,
            message=message,
            mode=normalized_mode,
            formula_skipped=formula_skipped,
            formula_timeout=formula_timed_out,
            formula_rejected=formula_rejected,
            formula_candidates=candidate_count,
            formula_skipped_reason=skip_reason if formula_skipped else "",
            formula_regions=formula_regions,
            timings=timings,
        )
    except Exception as e:
        logger.exception("Combined OCR failed")
        raise HTTPException(status_code=500, detail=f"OCR failed: {str(e)}")


def validate_image_upload(file: UploadFile) -> None:
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file.content_type}. Please upload an image.",
        )


async def read_upload(file: UploadFile) -> bytes:
    contents = await file.read()
    if len(contents) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")
    if len(contents) > UPLOAD_LIMIT_BYTES:
        raise HTTPException(status_code=400, detail="Uploaded file is larger than 20MB")
    return contents


def recognize_text(contents: bytes) -> Tuple[List[str], Image.Image, float, float]:
    preprocess_start = time.perf_counter()
    source_image = Image.open(io.BytesIO(contents))
    source_image.load()
    text_image, _bbox = crop_document_region(source_image)
    if text_image.mode != "L":
        text_image = text_image.convert("L")
    text_image = text_image.filter(ImageFilter.SHARPEN)
    preprocess_ms = elapsed_ms(preprocess_start)

    text_ocr_start = time.perf_counter()
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as ocr_tmp:
        text_image.save(ocr_tmp.name)
        text_lines = get_ocr_tool().recognize(ocr_tmp.name)
        temp_name = ocr_tmp.name
    safe_unlink(temp_name)
    text_ocr_ms = elapsed_ms(text_ocr_start)
    return text_lines, source_image, preprocess_ms, text_ocr_ms


def should_run_formula_ocr(
    mode: str,
    image_size: Tuple[int, int],
    text_lines: List[str],
    text: str,
) -> Tuple[bool, str]:
    if mode == "text":
        return False, "text_mode"
    if mode == "formula":
        return True, ""

    width, height = image_size
    max_edge = max(width, height)
    aspect = max_edge / max(1, min(width, height))
    signal_count = formula_signal_count(text)
    if len(text_lines) > 10:
        return False, "too_many_text_lines"
    if aspect > 2.2 and len(text_lines) > 4:
        return False, "long_document"
    if max_edge > 1800 and len(text_lines) > 6:
        return False, "large_document"
    if signal_count < 2:
        return False, "weak_formula_signal"
    return True, ""


def formula_signal_count(text: str) -> int:
    signals = [
        "=", "+", "-", "×", "÷", "/", "^", "_", "∫", "∑", "√", "lim",
        "sin", "cos", "tan", "sec", "csc", "cot", "ln", "log", "frac",
    ]
    lower = text.lower()
    return sum(1 for signal in signals if signal in lower)


def prepare_formula_image(image: Image.Image) -> Image.Image:
    formula_image, _bbox = crop_document_region(image)
    if formula_image.mode not in ("RGB", "L"):
        formula_image = formula_image.convert("RGB")
    if max(formula_image.size) > FORMULA_MAX_EDGE:
        formula_image.thumbnail((FORMULA_MAX_EDGE, FORMULA_MAX_EDGE), Image.LANCZOS)
    return formula_image


def prepare_formula_candidates(
    image: Image.Image,
    mode: str,
    text_lines: List[str],
    text: str,
) -> Tuple[List[Tuple[Image.Image, FormulaRegion]], List[FormulaRegion], str]:
    document, doc_bbox = crop_document_region(image)
    if is_full_page_formula_risk(mode, document.size, text_lines):
        return [], [], "full_page_document"

    columns = split_document_columns(document)
    all_candidates: List[Tuple[Image.Image, FormulaRegion]] = []
    all_regions: List[FormulaRegion] = []
    for column_image, column_bbox in columns:
        blocks = detect_formula_blocks(column_image, text)
        for block_image, block_region in blocks:
            absolute_region = offset_region(block_region, doc_bbox[0] + column_bbox[0], doc_bbox[1] + column_bbox[1])
            all_candidates.append((prepare_candidate_image(block_image), absolute_region))
            all_regions.append(absolute_region)

    all_candidates.sort(key=lambda item: item[1].score, reverse=True)
    all_regions.sort(key=lambda item: item.score, reverse=True)
    if len(all_candidates) == 0:
        return [], [], "no_formula_candidates"
    return all_candidates[:MAX_FORMULA_CANDIDATES], all_regions, ""


def is_full_page_formula_risk(mode: str, image_size: Tuple[int, int], text_lines: List[str]) -> bool:
    if mode != "formula":
        return False
    width, height = image_size
    aspect = max(width, height) / max(1, min(width, height))
    return len(text_lines) > 18 and aspect > 1.6


def crop_document_region(image: Image.Image) -> Tuple[Image.Image, Tuple[int, int, int, int]]:
    base = image.convert("RGB")
    gray = base.convert("L")
    width, height = gray.size
    pixels = gray.load()

    white_row_flags: List[bool] = []
    for y in range(height):
        near_white = 0
        for x in range(0, width, 3):
            if pixels[x, y] >= 250:
                near_white += 1
        sample_count = max(1, (width + 2) // 3)
        white_row_flags.append(near_white / sample_count >= 0.55)

    white_bands = contiguous_bands(white_row_flags, min_len=max(36, height // 40))
    white_bands = merge_close_bands(white_bands, max_gap=max(32, height // 12))
    large_white_bands = [band for band in white_bands if band[1] - band[0] >= height * 0.25]
    if len(large_white_bands) > 0:
        top, bottom = max(large_white_bands, key=lambda band: band[1] - band[0])
        band_image = base.crop((0, top, width, bottom))
        band_bbox = content_bbox(band_image.convert("L"))
        bbox = (
            max(0, band_bbox[0] - 20),
            max(0, top + band_bbox[1] - 20),
            min(width, band_bbox[2] + 20),
            min(height, top + band_bbox[3] + 20),
        )
        if bbox[2] - bbox[0] >= 64 and bbox[3] - bbox[1] >= 64:
            return base.crop(bbox), bbox

    row_scores: List[float] = []
    for y in range(height):
        bright = 0
        dark = 0
        for x in range(0, width, 3):
            value = pixels[x, y]
            if value >= 238:
                bright += 1
            if value <= 190:
                dark += 1
        sample_count = max(1, (width + 2) // 3)
        bright_ratio = bright / sample_count
        dark_ratio = dark / sample_count
        row_scores.append(bright_ratio + min(0.4, dark_ratio * 6))

    bands = contiguous_bands([score >= 0.58 for score in row_scores], min_len=max(40, height // 20))
    if len(bands) == 0:
        bbox = content_bbox(gray)
        return crop_with_bbox(base, bbox, 16)

    best_band = max(bands, key=lambda band: band[1] - band[0])
    top = best_band[0]
    bottom = best_band[1]
    band_image = base.crop((0, top, width, bottom))
    band_bbox = content_bbox(band_image.convert("L"))
    left = band_bbox[0]
    right = band_bbox[2]

    bbox = (
        max(0, left - 20),
        max(0, top + band_bbox[1] - 20),
        min(width, right + 20),
        min(height, top + band_bbox[3] + 20),
    )
    if bbox[2] - bbox[0] < 64 or bbox[3] - bbox[1] < 64:
        bbox = (0, top, width, bottom)
    return base.crop(bbox), bbox


def split_document_columns(image: Image.Image) -> List[Tuple[Image.Image, Tuple[int, int, int, int]]]:
    width, height = image.size
    if width < 700 or height < 400:
        return [(image, (0, 0, width, height))]

    mask = dark_pixel_mask(image.convert("L"))
    column_counts: List[int] = []
    for x in range(width):
        count = 0
        for y in range(height):
            if mask[y][x]:
                count += 1
        column_counts.append(count)

    center_left = width // 3
    center_right = width * 2 // 3
    min_gap_width = max(24, width // 25)
    gap_candidates = contiguous_bands(
        [column_counts[x] <= max(2, height // 120) for x in range(width)],
        min_len=min_gap_width,
    )
    center_gaps = [
        gap for gap in gap_candidates
        if gap[0] >= center_left and gap[1] <= center_right
    ]
    if len(center_gaps) == 0:
        return [(image, (0, 0, width, height))]

    gap = max(center_gaps, key=lambda item: item[1] - item[0])
    split_x = (gap[0] + gap[1]) // 2
    left_bbox = content_bbox(image.crop((0, 0, split_x, height)).convert("L"))
    right_raw = image.crop((split_x, 0, width, height))
    right_bbox_local = content_bbox(right_raw.convert("L"))

    left = (max(0, left_bbox[0] - 8), max(0, left_bbox[1] - 8), min(split_x, left_bbox[2] + 8), min(height, left_bbox[3] + 8))
    right = (
        split_x + max(0, right_bbox_local[0] - 8),
        max(0, right_bbox_local[1] - 8),
        split_x + min(width - split_x, right_bbox_local[2] + 8),
        min(height, right_bbox_local[3] + 8),
    )
    columns: List[Tuple[Image.Image, Tuple[int, int, int, int]]] = []
    for bbox in [left, right]:
        if bbox[2] - bbox[0] > 80 and bbox[3] - bbox[1] > 80:
            columns.append((image.crop(bbox), bbox))
    return columns if len(columns) >= 2 else [(image, (0, 0, width, height))]


def detect_formula_blocks(image: Image.Image, text: str) -> List[Tuple[Image.Image, FormulaRegion]]:
    gray = image.convert("L")
    mask = dark_pixel_mask(gray)
    width, height = gray.size
    row_counts = [sum(1 for value in row if value) for row in mask]
    active_rows = [count >= max(2, width // 120) for count in row_counts]
    row_bands = contiguous_bands(active_rows, min_len=3)
    merged_bands = merge_close_bands(row_bands, max_gap=max(8, height // 90))

    candidates: List[Tuple[Image.Image, FormulaRegion]] = []
    for top, bottom in merged_bands:
        if bottom - top < MIN_FORMULA_BLOCK_HEIGHT:
            continue
        bbox = block_content_bbox(mask, top, bottom)
        if bbox is None:
            continue
        left, block_top, right, block_bottom = expand_bbox(bbox, width, height, 10)
        block_width = right - left
        block_height = block_bottom - block_top
        if is_oversized_block(block_width, block_height, width, height):
            continue
        crop = image.crop((left, block_top, right, block_bottom))
        score = formula_block_score(crop, text)
        if score < MIN_FORMULA_SIGNAL_SCORE:
            continue
        region = FormulaRegion(
            left=left,
            top=block_top,
            right=right,
            bottom=block_bottom,
            width=block_width,
            height=block_height,
            score=round(score, 2),
            reason="projection",
        )
        candidates.append((crop, region))

    candidates.sort(key=lambda item: item[1].score, reverse=True)
    return candidates[:MAX_FORMULA_CANDIDATES]


def prepare_candidate_image(image: Image.Image) -> Image.Image:
    candidate = image.convert("RGB")
    if max(candidate.size) > FORMULA_MAX_EDGE:
        candidate.thumbnail((FORMULA_MAX_EDGE, FORMULA_MAX_EDGE), Image.LANCZOS)
    return candidate


def formula_block_score(image: Image.Image, text: str) -> float:
    gray = image.convert("L")
    width, height = gray.size
    pixels = gray.load()
    dark = 0
    very_dark = 0
    for y in range(height):
        for x in range(width):
            value = pixels[x, y]
            if value < 190:
                dark += 1
            if value < 90:
                very_dark += 1
    area = max(1, width * height)
    dark_ratio = dark / area
    very_dark_ratio = very_dark / area
    shape_score = 0.0
    if width >= 80:
        shape_score += 0.8
    if 24 <= height <= 260:
        shape_score += 0.8
    if 0.015 <= dark_ratio <= 0.45:
        shape_score += 0.8
    if very_dark_ratio > 0.003:
        shape_score += 0.4
    return shape_score + min(2.0, formula_signal_count(text) * 0.25)


def is_oversized_block(block_width: int, block_height: int, width: int, height: int) -> bool:
    if block_height / max(1, height) > MAX_FORMULA_BLOCK_HEIGHT_RATIO:
        return True
    if (block_width * block_height) / max(1, width * height) > MAX_FORMULA_BLOCK_AREA_RATIO:
        return True
    return block_width < 40 or block_height < MIN_FORMULA_BLOCK_HEIGHT


def dark_pixel_mask(gray: Image.Image) -> List[List[bool]]:
    pixels = gray.load()
    width, height = gray.size
    return [[pixels[x, y] < 205 for x in range(width)] for y in range(height)]


def content_bbox(gray: Image.Image) -> Tuple[int, int, int, int]:
    pixels = gray.load()
    width, height = gray.size
    left = width
    top = height
    right = 0
    bottom = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] < 220:
                left = min(left, x)
                top = min(top, y)
                right = max(right, x + 1)
                bottom = max(bottom, y + 1)
    if right <= left or bottom <= top:
        return (0, 0, width, height)
    return (left, top, right, bottom)


def block_content_bbox(mask: List[List[bool]], top: int, bottom: int) -> Optional[Tuple[int, int, int, int]]:
    width = len(mask[0]) if len(mask) > 0 else 0
    left = width
    right = 0
    for y in range(top, bottom):
        for x, active in enumerate(mask[y]):
            if active:
                left = min(left, x)
                right = max(right, x + 1)
    if right <= left:
        return None
    return (left, top, right, bottom)


def expand_bbox(bbox: Tuple[int, int, int, int], width: int, height: int, pad: int) -> Tuple[int, int, int, int]:
    return (
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(width, bbox[2] + pad),
        min(height, bbox[3] + pad),
    )


def crop_with_bbox(image: Image.Image, bbox: Tuple[int, int, int, int], pad: int) -> Tuple[Image.Image, Tuple[int, int, int, int]]:
    expanded = expand_bbox(bbox, image.width, image.height, pad)
    return image.crop(expanded), expanded


def contiguous_bands(flags: List[bool], min_len: int) -> List[Tuple[int, int]]:
    bands: List[Tuple[int, int]] = []
    start = -1
    for index, active in enumerate(flags):
        if active and start < 0:
            start = index
        elif not active and start >= 0:
            if index - start >= min_len:
                bands.append((start, index))
            start = -1
    if start >= 0 and len(flags) - start >= min_len:
        bands.append((start, len(flags)))
    return bands


def merge_close_bands(bands: List[Tuple[int, int]], max_gap: int) -> List[Tuple[int, int]]:
    if len(bands) == 0:
        return []
    merged: List[Tuple[int, int]] = [bands[0]]
    for start, end in bands[1:]:
        last_start, last_end = merged[-1]
        if start - last_end <= max_gap:
            merged[-1] = (last_start, end)
        else:
            merged.append((start, end))
    return merged


def offset_region(region: FormulaRegion, dx: int, dy: int) -> FormulaRegion:
    return FormulaRegion(
        left=region.left + dx,
        top=region.top + dy,
        right=region.right + dx,
        bottom=region.bottom + dy,
        width=region.width,
        height=region.height,
        score=region.score,
        reason=region.reason,
    )


async def recognize_formula_with_timeout(
    image: Image.Image,
    suffix: str,
    timeout_seconds: int,
) -> Tuple[List[str], bool]:
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        image.save(tmp.name)
        temp_name = tmp.name

    loop = asyncio.get_running_loop()
    timed_out = False
    try:
        future = loop.run_in_executor(_formula_executor, recognize_formula_file, temp_name)
        formulas = await asyncio.wait_for(future, timeout=timeout_seconds)
        return formulas, False
    except asyncio.TimeoutError:
        timed_out = True
        logger.warning("Formula OCR timed out after %ss", timeout_seconds)
        return [], True
    finally:
        if not timed_out:
            safe_unlink(temp_name)


def recognize_formula_file(path: str) -> List[str]:
    return get_formula_tool().recognize(path)


def filter_formulas(formulas: List[str]) -> Tuple[List[str], bool]:
    accepted: List[str] = []
    rejected = False
    for formula in formulas:
        normalized = normalize_formula(formula)
        if is_bad_formula(normalized):
            rejected = True
            continue
        accepted.append(normalized)
    return accepted, rejected


def normalize_formula(formula: str) -> str:
    return re.sub(r"\s+", " ", formula).strip()


def is_bad_formula(formula: str) -> bool:
    if len(formula) == 0:
        return True
    if len(formula) > 800:
        return True
    cjk_count = len(re.findall(r"[\u4e00-\u9fff]", formula))
    if cjk_count > 8 or cjk_count / max(1, len(formula)) > 0.12:
        return True
    if re.search(r"(.{1,8})\1{8,}", formula):
        return True
    if formula.count("或") >= 4 or formula.count("x 或") >= 2:
        return True
    unique_ratio = len(set(formula)) / max(1, len(formula))
    if len(formula) > 80 and unique_ratio < 0.12:
        return True
    return False


def trim_uniform_border(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    background = Image.new("RGB", rgb.size, rgb.getpixel((0, 0)))
    diff = ImageChops.difference(rgb, background)
    diff = ImageChops.add(diff, diff, 2.0, -20)
    bbox = diff.getbbox()
    if bbox is None:
        return image.copy()
    left, top, right, bottom = bbox
    pad = 12
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(image.width, right + pad)
    bottom = min(image.height, bottom + pad)
    if right - left < 32 or bottom - top < 32:
        return image.copy()
    return image.crop((left, top, right, bottom))


def build_formula_message(count: int, rejected: bool) -> str:
    if count > 0:
        return f"Recognized {count} formulas"
    if rejected:
        return "Formula OCR result rejected by quality filter"
    return "No formula recognized"


def build_ocr_message(
    text_count: int,
    formula_count: int,
    mode: str,
    skipped: bool,
    timed_out: bool,
    rejected: bool,
    skip_reason: str,
) -> str:
    parts = [f"mode={mode}", f"text_lines={text_count}", f"formulas={formula_count}"]
    if skipped:
        parts.append(f"formula_skipped={skip_reason}")
    if timed_out:
        parts.append("formula_timeout=true")
    if rejected:
        parts.append("formula_rejected=true")
    return "; ".join(parts)


def elapsed_ms(start: float) -> float:
    return (time.perf_counter() - start) * 1000


def safe_unlink(path: str) -> None:
    try:
        Path(path).unlink()
    except FileNotFoundError:
        pass
