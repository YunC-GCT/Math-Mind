# chapter 字段独立拆分 + source 语义修正

> 日期: 2026-07-22 · 会话范围: 复习界面分析 → chapter 列拆分 B 方案增强版

## 背景

`knowledge_unit` 表的 `source` 列被复用装两种数据: 来源标记(`camera_capture`/`manual`) 和 章节名(`微分中值定理`)。TypeClassifier 的 LLM prompt 有 chapter 输出字段, 但 `KnowledgeUnit` 接口无独立 `chapter` 列, 章节信息被塞进 `source`, 语义混乱。

结果:
- 知识星系"章节轨道"读的是 `unit.source`, 大部分笔记 `source = "camera_capture"` → 全部塌缩到「未分章节」
- 主 LLM(`KnowledgeModel.callAi`) 的 prompt 不要求输出 chapter, `AiRawResponse` 接口无此字段
- 纯文字生成笔记 `source` 也被标成 `camera_capture`, 名不副实

## 目标

1. 新增独立 `chapter` 列, `source` 回归来源本义(按 `payload.kind` 填)
2. 主 LLM prompt 增加 `chapter` 输出字段, 提高非空率
3. 所有读取端改读 `chapter` 列

## 改动清单(12 个文件, +55 -22 行)

### 1. 类型定义(依赖顺序最前)

**`common/src/main/ets/models/CommonTypes.ets`**
- `KnowledgeUnit` 接口: `subject` 后新增 `chapter: string;`
- `source` 注释从"来源(教材/网页/笔记路径)"改为"来源标记(camera_capture/manual/file_import)"

**`agents/src/main/ets/models/KnowledgeUnitExt.ets`**
- `AiRawResponse` 新增 `chapter: string` 字段(主 LLM 直出)
- `KnowledgeUnitExt` 新增 `chapter: string` 字段
- `createUnitExt()` 工厂返回对象加 `chapter: ''`

### 2. 数据库 Schema

**`common/src/main/ets/DatabaseHelper.ets`**
- `SQL_CREATE_KNOWLEDGE`: 新增 `chapter TEXT NOT NULL DEFAULT ""`
- `DB_SCHEMA_VERSION`: `3 → 4`
- 新增 `SQL_MIGRATE_KNOWLEDGE_CHAPTER`: `ALTER TABLE knowledge_unit ADD COLUMN chapter ...`
- `ensureSchema()`: 加 `hasChapter` 判断 + `executeAddColumn`, 对齐已有 subject/category 迁移模式

### 3. DAO

**`entry/src/main/ets/database/NoteDao.ets`**
- `rowToUnit(L148)`: 新增 `chapter: NoteDao.readString(rs, 'chapter', '')`
- `toBucket(L174)`: 新增 `'chapter': unit.chapter`

### 4. 写入端(核心)

**`agents/src/main/ets/agents/KnowledgeModel.ets`**(共 7 处):

| 位置 | 改前 | 改后 |
|------|------|------|
| `structure()` 签名 L93 | `(ocrText, type?, subject?, chapter)` | `(ocrText, type?, subject?, chapter, source: string = 'camera_capture')` |
| `structure()` L143 | `ext.source = chapterHint ? chapterHint : 'camera_capture'` | `ext.source = source; ext.chapter = aiRaw.chapter ? aiRaw.chapter : chapterHint` |
| `toKnowledgeUnit()` L190 | 无 chapter | 新增 `chapter: ext.chapter` |
| `buildFallbackFromClassify()` 签名 L213 | `(ocrText, type?, subject?, chapter)` | `(ocrText, type?, subject?, chapter, source)` |
| `buildFallbackFromClassify()` L237-240 | `source: chapter ? chapter : 'camera_capture'` | `source: source` + `chapter: chapter` |
| `buildPrompt()` L414 前 | 字段清单无 chapter | 新增 `- chapter: 章节/知识点短语, 无法判断返回空字符串` |
| `callAi()` L332 | aiRaw 7 字段 | 新增 `chapter: this.normalizeChapter(String(parsed['chapter'] ?? ''))` |
| 新增 `normalizeChapter()` | 无 | 仿 normalizeSubject: 过滤 `未知/null/undefined`, 空返 `''` |

- `structureWithClassification()`: 签名加 `source` 参数, 透传
- `validateAiJson()`: **不动** — 白名单校验, 不强制 chapter, 多余字段自动无视
- `buildFallbackFromClassify()` 调用处: 加 `source` 实参

### 5. Dispatcher 传 source

**`agents/src/main/ets/core/Dispatcher.ets`**
- 新增 import `DispatchPayload` type
- 新增 `private static sourceFromPayload(payload: DispatchPayload): string`:
  - `kind === 'image'` → `'camera_capture'`
  - `kind === 'text'` → `'manual'`
  - 其他 → `'file_import'`
- `dispatch()`: `model.structure(ocrText, undefined, undefined, '', source)`

### 6. 读取端

**`entry/src/main/ets/viewmodels/KnowledgeGalaxyViewModel.ets`**
- 删除 `CAMERA_SOURCE` / `MANUAL_SOURCE` 常量
- `resolveChapter()`: 从 `unit.source` 黑名单过滤 → `unit.chapter.trim()`, 空归 `UNCLASSIFIED_CHAPTER`

**`entry/src/main/ets/utils/NoteItemMapper.ets`**
- 删除 `CAMERA_SOURCE` 常量
- `unitToNoteItem()` L95: `unit.source !== CAMERA_SOURCE ? unit.source : subject` → `unit.chapter.length > 0 ? unit.chapter : subject`

**`entry/src/main/ets/overlays/NoteDetailOverlay/model/DetailRenderModel.ets`**
- `resolveSource()`: 从 `unit.source.trim()` + `SOURCE_CAMERA` 过滤 → `unit.chapter.trim()`
- `SOURCE_CAMERA` 常量保留: `filterTags()` 仍需用它过滤来源标记标签

### 7. 笔记详情编辑保存

**`entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailOverlay.ets`**
- `buildManualUnit()`: 新增 `chapter: ''`(手工新建时章节留空)
- `buildUpdatedUnit()`: 新增 `chapter: current.chapter`(编辑保存保留原章节)

### 8. 顺手改动(同会话)

**`entry/src/main/ets/pages/Review/ReviewPage.ets`**
- 默认 Tab: `REVIEW_TAB_GRAPH` → `REVIEW_TAB_PLAN`(复习计划是主功能)

**`entry/src/main/ets/pages/Index.ets`**
- ReviewPage 传入 `onGoAI` 回调(会话前已有, 非本次改动)

## 数据流(改后)

```
拍照 → Dispatcher(sourceFromPayload: kind=image → camera_capture)
  → KnowledgeModel.structure(ocrText, undefined, undefined, '', 'camera_capture')
    → resolveClassificationHint() 调 TypeClassifier.classifyText() 辅助获取 chapterHint
    → callAi() 主 LLM 输出 chapter 字段(AiRawResponse.chapter)
    → ext.chapter = aiRaw.chapter || chapterHint  (主 LLM 优先)
    → ext.source = 'camera_capture'  (不再复用装章节)
  → NoteDao.insert() → knowledge_unit.chapter / knowledge_unit.source
  → 星系 resolveChapter() 读 unit.chapter
  → 笔记映射 NoteItemMapper 读 unit.chapter
  → 详情渲染 DetailRenderModel 读 unit.chapter
```

source 取值规则:
- 图片 → `camera_capture`
- 纯文本 → `manual`
- 文件 → `file_import`
- 手动新建笔记 → `'manual'`

## 兼容性

- **旧数据**: `chapter` 列为空 → 星系归「未分章节」(与旧行为一致, 无回归)
- **旧 `source` 列**: 保留, 只装来源标记, 不再装章节
- **不需要批量回填**: 旧数据的章节靠 LLM 判, 回填不准; 新笔记自然带 chapter
- **LLM 不返回 chapter**: `normalizeChapter` 兜底 `''`, `validateAiJson` 不强制校验(可选字段)
- **ArkTS 1.1 strict**: 全部新增代码显式类型, 无 any/unknown/spread/C 风格 for

## 验证要点

1. DevEco Studio GUI Build, 5/5 module BUILD SUCCESSFUL
2. 拍照生成笔记: 检查 `knowledge_unit.chapter` 有值, `source = 'camera_capture'`
3. 纯文本生成笔记: `source = 'manual'`, `chapter` 有值
4. 复习页知识星系: 章节轨道按真实章节分组, 不再全部「未分章节」
5. 旧数据(无 chapter): 星系无崩溃, 轨道落「未分章节」
6. `git diff --check HEAD` 无 whitespace error

## 回滚方法

如果出问题, 恢复 `source` 的双重语义:

```bash
git checkout HEAD -- \
  agents/src/main/ets/agents/KnowledgeModel.ets \
  agents/src/main/ets/core/Dispatcher.ets \
  agents/src/main/ets/models/KnowledgeUnitExt.ets \
  common/src/main/ets/DatabaseHelper.ets \
  common/src/main/ets/models/CommonTypes.ets \
  entry/src/main/ets/database/NoteDao.ets \
  entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailOverlay.ets \
  entry/src/main/ets/overlays/NoteDetailOverlay/model/DetailRenderModel.ets \
  entry/src/main/ets/utils/NoteItemMapper.ets \
  entry/src/main/ets/viewmodels/KnowledgeGalaxyViewModel.ets
```

注意: 回滚后 DB schema version 不一致, 需在 DevEco 中卸载 App 重新安装, 或手动删 `MathMind.db`。
