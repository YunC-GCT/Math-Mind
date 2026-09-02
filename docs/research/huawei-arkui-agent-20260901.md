# Huawei HarmonyOS / ArkUI / ArkTS / Agent — Official Source Research

> Date: 2026-09-01
> Purpose: Input for MindTrace architecture audit (Phase 1)
> Source coverage: 72 primary-source files fetched from `developer.huawei.com` / `docs.openharmony.cn` Ability Kit, ArkUI, ArkTS, Network Kit, Ability Kit Agent references. All citations below point at the original `.md` pages these were derived from. The fetched raw text is archived under `docs/research/_fetched/` (to be cleaned up post-audit).
> Citation convention: where the docs page lives on the Huawei docs portal (e.g. `/consumer/cn/doc/harmonyos-guides/...`), the URL ends with the page slug we read; for OpenHarmony native references, the same convention applies.

---

## 1. HarmonyOS NEXT Application Architecture & Stage Model

### 1.1 Stage model is the current model; FA model is deprecated
- Claim: FA model is no longer promoted; Stage model is the current long-term model introduced from API 9.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-models> (`1_application_models.md`)
- Quote: "FA（Feature Ability）模型：从API 7开始支持的模型，已经不再主推。" and "Stage模型：从API 9开始新增的模型，是目前主推且会长期演进的模型。"
- Audit impact: MindTrace W3 already on Stage — no migration risk; any historical FA reference in `archive/` is informational only.

### 1.2 UIAbility lifecycle (Create → WindowStageCreate → Foreground → Background → Destroy)
- Claim: The core UIAbility lifecycle callbacks are `onCreate`, `onWindowStageCreate`, `onForeground`, `onBackground`, `onWindowStageWillDestroy`, `onWindowStageDestroy`, `onDestroy`, plus `onNewWant` for re-launch.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-lifecycle> (`1_uiability_lifecycle.md`)
- Quote: "UIAbility组件的核心生命周期回调包括onCreate、onForeground、onBackground、onDestroy。" and on launch path: "系统会依次触发onCreate()、onWindowStageCreate()、onForeground()生命周期回调。"
- Audit impact: MindTrace's `entrybackupability` (data backup Ability) and `cardservice` (`FormExtensionAbility`) both follow this lifecycle; ensure no heavy work in `onBackground` — "执行时间较短，无法提供足够的时间做一些耗时动作。请勿在该方法中执行保存用户数据或执行数据库事务等耗时操作。"

### 1.3 AbilityStage container is module-level (1:1 with HAP)
- Claim: Each HAP gets one `AbilityStage` instance; `AbilityStage.onCreate` runs before any UIAbility/ExtensionAbility in that HAP.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/abilitystage> (`1_abilitystage.md`)
- Quote: "AbilityStage与HAP一一对应，即每个HAP拥有一个AbilityStage实例。" and "在开始加载对应Module的第一个应用组件实例之前会先创建AbilityStage，并在AbilityStage创建完成之后执行其onCreate()生命周期回调。"
- Audit impact: MindTrace has 1 entry HAP + 3 feature HAPs; each can use `AbilityStage.onCreate` for per-module init (resource preload, worker pool) without polluting `EntryAbility.onCreate`. Currently unused — opportunity.

### 1.4 ExtensionAbility vs UIAbility — purpose split
- Claim: UIAbility is for UI/interaction; ExtensionAbility is system-managed scenario component (FormExtensionAbility for cards, InputMethodExtensionAbility, WorkSchedulerExtensionAbility, etc.) — third-party apps can only derive from system-defined ExtensionAbility types, not extend the base class directly.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/extensionability-overview> (`1_extensionability_overview.md`)
- Quote: "ExtensionAbility组件是一种面向特定场景的应用组件。每一个具体场景对应一个不同类型的ExtensionAbility，例如用于卡片场景的FormExtensionAbility...开发者不能直接继承ExtensionAbility组件，只能使用（包括实现或访问）已定义的ExtensionAbility类型。"
- Audit impact: Confirms `cardservice` correctly derives `FormExtensionAbility`; no `UIAbility` mis-use there.

### 1.5 HAP / HSP / HAR module-type rules
- Claim: A HarmonyOS app can have at most one `type: "entry"` HAP; other HAPs must be `type: "feature"`; shared code goes into HSP (`type: "shared"`) or HAR (`type: "har"`). HAR duplicates code per consumer; HSP loads once at runtime.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-package-overview> (`1_package_overview.md`)
- Quote: "App Pack包中同一设备类型的所有HAP中最多只能包含一个Entry类型的HAP" and "Shared Library：动态共享库。编译后生成一个以.hsp为后缀的文件... HAR中的代码和资源跟随使用方编译，如果有多个使用方，它们的编译产物中会存在多份相同拷贝。"
- Audit impact: Confirms MindTrace's 1 entry + skill/cardservice (feature) + 2 HSP (common, agents) layout is valid; do NOT add a second entry.

### 1.6 Multi-HAP signature consistency requirement
- Claim: All HAPs and HSPs of one app must share the same signing certificate, otherwise installation fails in debug.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hap-package> (`1_hap_package.md`)
- Quote: "同一应用的所有HAP、HSP的签名证书要保持一致...在调试阶段，开发者通过命令行或DevEco Studio将HAP安装到设备上时，要保证所有HAP签名证书一致，否则会出现安装失败的问题。"
- Audit impact: AGENTS.md already mandates root `build-profile.json5` shares `signingConfig` to all HAPs — confirmed necessary by official doc.

### 1.7 HSP `oh-package.json5` must declare `main` field
- Claim: HSP requires `main` pointing at the entry declaration file (e.g. `Index.ets`); without it the consumer cannot resolve imports.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/in-app-hsp> (`1_in_app_hsp.md`) — HAR equivalent: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/har-package> (`1_har_package.md`)
- Quote: "Index.ets文件是HAR导出声明文件的入口，HAR需要导出的接口，统一在Index.ets文件中导出...在模块的oh-package.json5文件中的main字段配置入口声明文件"
- Audit impact: Already enforced per AGENTS.md rule #1; AGENTS.md MEMORY confirms this is a "build 报 Cannot find module" failure mode.

### 1.8 Cross-module import — full path required, not bare alias
- Claim: Consumer modules must import via the `Index.ets` declared in the producer's `oh-package.json5.main`, using the module name registered locally. (Bare relative paths like `from 'common/Index'` fail; full project-relative path like `from 'common/src/main/ets/Index'` works in some configurations but is non-canonical.)
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/in-app-hsp> — usage example
- Quote: "在使用方的代码中，可以这样使用：import { Log, add, MyTitleBar, ResManager, nativeMulti } from 'library';"
- Audit impact: MindTrace today uses `'common/src/main/ets/...'` style imports. The cleaner pattern is to declare the producer name in the consumer's `oh-package.json5.dependencies` and import via that name. Recommend audit Phase 2 check imports for consistency.

### 1.9 HSP cannot declare `pages` / `abilities` / `extensionAbilities` / `mainElement` / `skills` at the top level of `module.json5`
- Claim: Confirmed by `1_module_configuration.md` schema — `pages`, `abilities`, `extensionAbilities` are HAP-only; HSP `module.json5` is restricted to `name`, `type: "shared"`, `deviceTypes`, `deliveryWithInstall`, etc.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file> (`1_module_configuration.md`)
- Quote: From `1_module_configuration.md` Type values table: "shared：动态共享包模块."
- Audit impact: Confirms MindTrace's HSP `module.json5` fields (`name`/`type:shared`/`deviceTypes`/`deliveryWithInstall`) are correct.

### 1.10 HAP module.json5 — `abilities[].skills` for entry requires `ohos.want.action.home` + `entity.system.home`
- Claim: Entry HAP must declare a `skills` array with `actions: ["ohos.want.action.home"]` + `entities: ["entity.system.home"]` for the launcher icon to work.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file> (`1_module_configuration.md` — skills subsection, line ~58 example)
- Quote (from example JSON5): `"actions": ["ohos.want.action.home"], "entities": ["entity.system.home"]`
- Audit impact: MindTrace `entry/src/main/module.json5` must keep this pair; do not remove when refactoring.

---

## 2. ArkUI 1.1 Decorators & State Management

### 2.1 `@State` — component-local state, triggers re-render on set
- Claim: `@State` is the base decorator; lifecycle matches the component; must initialize locally (except for V1 rules re. `@StorageLink`/`@Consume`); object/class change observation is shallow (`Object.keys`-level); nested property mutation is NOT observed unless the class is `@Observed` and consumed via `@ObjectLink`.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state> (`2_state.md`)
- Quote: "当装饰的数据类型为class或Object时，可以观察到自身的赋值和属性赋值的变化，即Object.keys(observedObject)返回的所有属性。" and "对嵌套对象的属性直接赋值无法被框架观察到，因此不会触发UI刷新。"
- Audit impact: `KnowledgeModel` and `StudyPlanViewModel` (`@Observed`) — verify all nested mutations go through `@ObjectLink` or whole-object reassignment. Currently `StudyPlanViewModel` is `@Observed` ✅.

### 2.2 `@Prop` vs `@Link` — one-way vs two-way parent-child sync
- Claim: `@Prop` is one-way sync (parent → child, child's local changes don't propagate); `@Link` is two-way (bidirectional). `@Link` must be initialized by the parent (no local default), `@Prop` must have a local default. Both `@Prop` and `@Link` observe only the first level of object properties.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-overview> (`2_state_overview.md`)
- Quote: "@Prop装饰的变量可以和父组件建立单向同步关系，@Prop装饰的变量是可变的，但修改不会同步回父组件。" and "@Link装饰的变量可以和父组件建立双向同步关系"
- Audit impact: MindTrace uses `@Prop` for the bottom-up data flow from `KnowledgeModel`/`StudyPlanItem` into atom components; correct semantics.

### 2.3 `@ObjectLink` + `@Observed` — nested class observation (only path to deep observe in V1)
- Claim: `@ObjectLink` MUST be initialized by parent with an `@Observed`-decorated class instance (prior to API 19). The variable itself cannot be reassigned (read-only reference); only its properties can be mutated.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-observed-and-objectlink> (`2_observed_objectlink.md`)
- Quote: "@Observed/\@ObjectLink适用于观察嵌套对象（对象的属性是对象）属性的变化...@ObjectLink装饰的变量不能被赋值，如果要使用赋值操作，请使用@Prop。"
- Audit impact: Confirms `StudyPlanViewModel` `@Observed` + atom components using `@ObjectLink` deep-render chain is the canonical pattern.

### 2.4 `@Provide` / `@Consume` — cross-component-layer (multi-level) two-way sync, no prop drilling
- Claim: `@Provide` in ancestor + matching `@Consume` (same key or alias) in descendant; bypasses intermediate component props; `@Consume` requires no local init.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-provide-and-consume> (referenced via `2_state_overview.md`)
- Quote (from overview): "@Provide/\@Consume装饰的变量用于跨组件层级（多层组件）同步状态变量，可以不需要通过参数命名机制传递，通过alias（别名）或者属性名绑定。"
- Audit impact: MindTrace currently avoids `@Provide/@Consume` — okay for W3; if floating Agent overlay ever needs to mutate Home state, `@Provide` could simplify.

### 2.5 `@Watch` — callback when decorated state var changes
- Claim: `@Watch('methodName')` fires the named method on the component after the watched state var's value changes; uses strict equality (`===`); first init does NOT trigger; method signature must be `(changedPropertyName?: string) => void`.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-watch> (`2_watch.md`)
- Quote: "@Watch用于监听状态变量的变化，当状态变量变化时，@Watch的回调方法将被调用。" and "在第一次初始化的时候，@Watch装饰的方法不会被调用"
- Audit impact: Avoid in MindTrace — fast-render callbacks for derived state can cause loops; prefer `@Observed` direct mutation. Project rule #4 already bans `get` accessors; `@Watch` is also discouraged.

### 2.6 API 9 vs API 11+ state-management decorators — version table
- Claim: V2 decorators (`@ComponentV2`, `@Local`, `@Param`, `@Once`, `@Event`, `@Provider`, `@Consumer`, `@Monitor`, `@ObservedV2`, `@Trace`, `@Computed`) require API 12+ (state mgmt V2 GA) and many APIs have different recommendation dates (e.g. `selected` state in `stateStyles` is API 10+).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-overview> (`2_state_overview.md` line ~165), <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-statestyles> (`2_statestyles.md` line ~30)
- Quote: "@ComponentV2装饰器从API version 12开始支持。" and "selected<sup>10+</sup>：选中态。"
- Audit impact: MindTrace W3 (`MainBranch: 5b6f155`) is on V1. Sticking with V1 is fine for audit; recommend documenting a future V2 migration entry point but no urgent change.

### 2.7 `@Builder` — only path to private builder / global builder functions
- Claim: Custom reusable UI blocks via `@Builder`. A `@Builder` function cannot contain `@State`/lifecycle. `@Builder` cannot be assigned to a variable or array element (the framework can't track which scope it belongs to).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-builder> (`2_builder.md`)
- Quote: "@Builder装饰器严格禁止在其内部定义状态变量或使用生命周期函数" and "@Builder方法赋值给变量或数组后在UI方法中无法使用，开发者应避免将@Builder赋值给变量或数组后再使用。"
- Audit impact: MindTrace's `HexLogo`, `GradientRing` atoms are real `@Component`s, not `@Builder`s — correct.

### 2.8 `.stateStyles({ focused, pressed, normal, disabled, clicked, selected })` — API 10+ support window
- Claim: `.stateStyles()` exists; `selected` is API 10+; only generic attributes supported (NOT private component properties like `TextInput.backgroundColor`). For those, use `attributeModifier`.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-statestyles> (`2_statestyles.md`)
- Quote: "多态样式仅支持通用属性。如果多态样式不生效，则该属性可能为组件的私有属性" and "selected<sup>10+</sup>：选中态。"
- Audit impact: MindTrace AGENTS.md notes `.stateStyles()` is API 11+. Actual: API 7 (base states), API 10+ (`selected`) — base is fine for W3.

### 2.9 `.blur()` — visual-effect attribute, API 12+
- Claim: `visualEffect`, `backgroundFilter`, `foregroundFilter`, `compositingFilter` are part of the `@kit.ArkUI` `Filter` family and require API 12+ (visual-effect module). The "blur" semantic comes from `Filter` blur params, not from an `.blur()` chainable on every component.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-blur-filter> (`2_blur_filter.md`)
- Quote: "从API version 12开始支持。后续版本如有新增内容，则采用上角标单独标记该内容的起始版本。"
- Audit impact: Confirms AGENTS.md note that `.blur()` is API 11+ — actually API 12+ for full filter system. Avoid in W3; revisit at API 12 upgrade.

### 2.10 `.offset()` vs `.translate()` — semantic and reactivity difference
- Claim: `.offset()` (position attribute, API 7+) does NOT participate in layout; `.translate()` (transformation, API 7+) is a render-time matrix transform. Both accept `{x, y, z}` object. `.translate({x})` participates in transformation chain and follows `@State` updates like other transforms. `.offset()` likewise follows `@State` updates but only as a layout-phase delta.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-transformation> (`2_transformation.md`), <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-location> (`2_location.md`)
- Quote (from transformation doc, translate signature): "translate(value: TranslateOptions): T...卡片能力：从API version 9开始，该接口支持在ArkTS卡片中使用。"
- Audit impact: MindTrace prefers `.translate()` (per AGENTS.md rule #5). Confirmed correct; transforms are reactive. Note: `.offset()` DOES also respond to `@State` per AGENTS.md note — both are reactive, the difference is z-axis/3D handling and render order.

### 2.11 Image `rotate({ angle })` — accepts object, NOT number
- Claim: The `rotate()` universal attribute signature is `rotate(value: RotateOptions): T` (and `RotateAngleOptions` from API 20). Passing a raw number is NOT supported in API 9 — it must be the object form with at minimum `{ angle: number }` (and optionally `x/y/z/centerX/centerY/centerZ/perspective`).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-transformation> (`2_transformation.md`)
- Quote: "rotate(value: RotateOptions): T 设置组件旋转。" and example code at line 352-360 showing `.rotate({ x:0, y:0, z:1, centerX:'50%', centerY:'50%', angle: 300 })`.
- Audit impact: AGENTS.md rule #5 says `Image.rotate({angle})` accepts object, not number — confirmed by official signature.

### 2.12 Struct field naming — avoid clashing with `CommonAttribute` setters
- Claim: ArkUI struct member names that collide with attribute setters like `.rotate(...)`, `.translate(...)`, `.scale(...)`, `.opacity(...)`, `.backgroundColor(...)` cause the struct to silently shadow the chainable. Standard practice (and MindTrace's MEMORY rule) is to use neutral names: `rotDeg`, `transY`, `opVal`, `bgCol`.
- Source: Derived from the ArkUI transformation/location/general-attribute docs (`2_transformation.md`, `2_location.md`, `2_general_attributes.md`) — each section lists `.rotate()`, `.translate()`, `.scale()`, `.opacity()` as attribute methods on components, which would collide with same-named struct fields. No explicit doc page for "struct field naming" — this is a derived convention from attribute API surface.
- Source for underlying claim: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-transformation> (`2_transformation.md`)
- Audit impact: MindTrace's `rotDeg` / `transY` convention is consistent with avoiding the API names. **GAP: no single primary-source page exists that explicitly states "struct fields must not collide with CommonAttribute method names" — this is a community/conventional rule, not formally documented as a constraint.**

### 2.13 Struct methods — only arrow functions, `@Builder`, `@Watch` allowed
- Claim: ArkTS 1.1 strict mode requires struct members to use specific forms. (This rule is enforced by the compiler; it's covered in §3 below as part of strict-mode constraints.)
- Source: Referenced via the ArkTS 1.1 strict spec (`3_ts_migration.md`) — see §3.2.7.

### 2.14 `access_restrictions` (API 12+): private/public on decorators
- Claim: From API 12, the compiler validates `private`/`public` against decorator rules: `@State`/`@Prop`/`@Provide`/`@BuilderParam` can be private (warning if parent passes via constructor); `@StorageLink`/`@StorageProp`/`@LocalStorageLink`/`@LocalStorageProp`/`@Consume` cannot be public (warning); `@Link`/`@ObjectLink` cannot be private; `protected` not allowed in struct.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-access-restrictions> (`2_access_restrictions.md`)
- Quote: "The member attributes of a struct can not be protected."
- Audit impact: MindTrace is on API 9 — this rule won't fire yet, but worth tracking for the API 12 upgrade.

---

## 3. ArkTS 1.1 Strict Mode Constraints

### 3.1 `any` and `unknown` are banned — use concrete types
- Claim: Rule `arkts-no-any-unknown` (error code 10605008). `any` AND `unknown` are forbidden; explicit concrete types required.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background> (`3_ts_migration.md` line 407)
- Quote: "ArkTS不支持any和unknown类型。显式指定具体类型。"
- Audit impact: AGENTS.md rule #1 (no `any`/`unknown`) — confirmed. Errors fall back to `(e as BusinessError).code / message`. MindTrace's MEMORY rule for `(e as Error).message ?? String(e)` is the right escape hatch.

### 3.2 Other banned TS features (with rule IDs)
- Claim: ArkTS 1.1 strict disallows a long list of TS features. Below is the complete rule inventory extracted from `3_ts_migration.md`:

| Rule ID | Rule | Verdict |
|--------|------|---------|
| `arkts-no-var` (10605005) | `var` declarations | error — use `let` |
| `arkts-no-any-unknown` (10605008) | `any`, `unknown` types | error |
| `arkts-no-symbol` (10605002) | `Symbol()` API | error |
| `arkts-no-private-identifiers` (10605003) | `#privateField` syntax | error — use `private` keyword |
| `arkts-no-call-signatures` (10605014) | object type with call signature | error |
| `arkts-no-ctor-signatures-type` (10605015) | type with `new()` signature | error |
| `arkts-no-ctor-signatures-iface` (10605027) | interface with `new()` signature | error |
| `arkts-no-ctor-prop-decls` (10605025) | field declarations in constructor params | error |
| `arkts-no-multiple-static-blocks` (10605016) | >1 static `{}` block in class | error |
| `arkts-no-indexed-signatures` (10605017) | `[k: T]: V` index signature | error |
| `arkts-no-intersection-types` (10605019) | `T & U` intersection | error — use `extends` |
| `arkts-no-typing-with-this` (10605021) | `this` as a type | error |
| `arkts-no-conditional-types` (10605022) | conditional types | error |
| `arkts-no-mapped-types` (10605083) | mapped types | error |
| `arkts-no-structural-typing` (10605030) | structural compatibility | error |
| `arkts-no-inferred-generic-params` (10605034) | un-annotated generic type params (when not inferable) | error |
| `arkts-no-untyped-obj-literals` (10605038) | untyped object literals | error |
| `arkts-no-obj-literals-as-types` (10605040) | `{ a: T }` as type | error |
| `arkts-no-noninferrable-arr-literals` (10605043) | array literals with non-inferable elements | error |
| `arkts-no-func-expressions` (10605046) | `function` expressions | error — use arrow `=>` |
| `arkts-no-class-literals` (10605050) | class expressions | error |
| `arkts-implements-only-iface` (10605051) | `class A implements ClassB` | error |
| `arkts-no-method-reassignment` (10605052) | `obj.method = ...` | error |
| `arkts-as-casts` (10605053) | `<T>x` casts | error — use `x as T` |
| `arkts-no-jsx` (10605054) | JSX | error |
| `arkts-no-polymorphic-unops` (10605055) | `+`/`-`/`~` on non-numeric | error |
| `arkts-no-delete` (10605059) | `delete obj.prop` | error |
| `arkts-no-type-query` (10605060) | `typeof x` as a type | error |
| `arkts-instanceof-ref-types` (10605065) | `instanceof` on primitive | error |
| `arkts-no-in` (10605066) | `key in obj` operator | error |
| `arkts-no-destruct-assignment` (10605069) | `[a,b] = arr` destructure | error |
| `arkts-no-comma-outside-loops` (10605071) | `,` outside `for` | error |
| `arkts-no-destruct-decls` (10605074) | `let { a, b } = obj` destructure | error |
| `arkts-no-types-in-catch` (10605079) | `catch (e: any)` typed catch | error |
| `arkts-no-for-in` (10605080) | `for (let k in obj)` | error |
| `arkts-no-with` (10605084) | `with` statement | error |
| `arkts-limited-throw` (10605087) | `throw "msg"` of non-Error | error — only `throw new Error()` |
| `arkts-no-implicit-return-types` (10605090) | implicit return types in recursive calls | error |
| `arkts-no-destruct-params` (10605091) | `function f({a, b})` destructure params | error |
| `arkts-no-nested-funcs` (10605092) | nested function declarations | error |
| `arkts-no-standalone-this` (10605093) | `this` in free function / static method | error |
| `arkts-no-generators` (10605094) | `function*` generator | error |
| `arkts-no-is` (10605096) | `arg is T` type predicate | error — use `instanceof` + `as` |
| `arkts-no-props-by-index` (10605029) | `obj['key']` dynamic access | error |
| `arkts-identifiers-as-prop-names` (10605001) | numeric / string property keys | error — use `Map` |

- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background> (`3_ts_migration.md`) — entire rules catalogue from line 226 through ~2400.

- Audit impact: MindTrace's "ArkTS 1.1 strict 铁律" set aligns with the most-common subset (`any`/`unknown`, `for(let i;i<n;i++)`, struct regular methods, `get` accessors). The full list above is much larger — recommend W4 follow-up: a `pnpm lint`/hvigor lint job that enforces the full table, not just the 5 hand-picked rules.

### 3.3 C-style `for (let i; i<n; i++)` is fine, but `for..in` is banned
- Claim: C-style `for (let i = 0; i < n; ++i)` is **allowed**; `for..in` is banned (rule `arkts-no-for-in`, error 10605080). AGENTS.md rule #2 says "C-style `for` ban" which is INVERTED from the official doc — official: C-style `for` is fine, `for..in` is banned.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background> (`3_ts_migration.md` line 1967-1997)
- Quote: "ArkTS不支持for .. in迭代对象属性。"
- Audit impact: **DISCREPANCY**: AGENTS.md says "禁 C 风格 `for (let i; i<10; i++)` ❌ → `for...of` / `forEach` / `while` ✅". The official doc does NOT ban C-style `for`. AGENTS.md may be conflating "no `for..in`" with "no `for(let i;..)`". Recommend Phase 2 audit reconcile this rule with reality.

### 3.4 Object spread / destructuring — both banned
- Claim: `arkts-no-destruct-assignment` (10605069) AND `arkts-no-destruct-decls` (10605074) AND `arkts-no-destruct-params` (10605091) all error. Object spread `{...obj}` is not explicitly listed as a banned rule, but it implies dynamic shape which conflicts with the static-typing rule `arkts-no-props-by-index` (10605029) — the practical effect is the same: `{...obj, newKey: 1}` will compile-error because the literal has no declared type. AGENTS.md rule #2 ("as const / object spread / destructuring bans") is half-correct: `as const` and spread/destructure are blocked, but `as const` is not literally in the official rule table.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background> (`3_ts_migration.md` lines 1803-1931)
- Quote: "ArkTS不支持解构赋值。可使用其他替代方法，例如，使用临时变量。" and "ArkTS不支持解构变量声明。"
- Audit impact: Confirms MindTrace MEMORY "no spread / no destructure" — strict mode will reject both. MindTrace uses object literal reassignment and individual field updates, consistent.

### 3.5 JSON serialization under strict mode — `JSON.stringify` on live data
- Claim: `JSON.stringify` is available but must be called on plain object/array literals (not class instances with methods, not cycles, not Sendable cross-thread objects). The doc explicitly lists supported: "ArkTS对象或数组。支持线性容器的转换，不支持非线性容器." from `@ohos.util.json` (the same rules apply to the built-in `JSON`).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-json> (`3_json.md`)
- Quote: "该方法将一个ArkTS对象或数组转换为JSON字符串，支持线性容器的转换，不支持非线性容器。"
- Audit impact: Confirms AGENTS.md line "JSON.stringify 限制 (live data)" — MindTrace's `ApiClient` likely passes plain DTOs to `JSON.stringify`, which is correct.

### 3.6 `JSON.parse` / `JSON.stringify` recommended module
- Claim: For ArkTS 1.1 strict, prefer the `@kit.ArkTS` `JSON` module (API 12+) — provides `JSON.parse`, `JSON.stringify`, `JSON.has`, `JSON.remove` with explicit ArkTS typing. Built-in `JSON` works but lacks the additional helpers.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-json> (`3_json.md`)
- Quote: "import { JSON } from '@kit.ArkTS';"
- Audit impact: MindTrace is on API 9 (per AGENTS.md "API 9 = ArkUI 1.1"). The kit's `JSON` is API 12+, not usable. Built-in `JSON` is the path. Recommend Phase 2: when upgrading to API 12+, swap to `@kit.ArkTS.JSON`.

### 3.7 Discriminated unions — pattern support
- Claim: ArkTS supports literal-type union members; type narrowing via `instanceof` + `as` cast is the documented pattern. Example pattern: `class Foo {...} class Bar {...}; function isFoo(arg: Object): boolean { return arg instanceof Foo } if (isFoo(arg)) { let f = arg as Foo; ... }`. No `arg is Foo` predicate (banned by `arkts-no-is`).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background> (`3_ts_migration.md` line 2339-2402)
- Quote: "必须使用instanceof运算符来替代。在使用instanceof之前，必须先使用as运算符将对象转换为所需类型。"
- Audit impact: MindTrace's `StudyPlanItem` discriminated-by-`status` (LEARNING/REVIEW/GRADUATED/LAPSED) is a literal-union pattern, not a class hierarchy — works fine. If they ever move to a class-based discriminator, follow `instanceof`+`as`.

### 3.8 Type inference rules — `let x = ...` and `let x: T = ...` both OK when initial value present
- Claim: Type can be omitted when initial value present. `let s: string` without initializer is invalid.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-get-started> (`3_intro_arkts.md` lines 53-65)
- Quote: "如果变量或常量的声明包含初始值，开发者无需显式指定类型"
- Audit impact: MindTrace code follows this.

### 3.9 `.ets` file compatibility — API version gate
- Claim: `compatibleSdkVersion >= 10` ⇒ strict mode enforced (compile error); `< 10` ⇒ warning only. MindTrace at API 9 is in the warning band — strict rules fire as warnings, not errors.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background> (`3_migration_bg.md` lines 143-146)
- Quote: "compatibleSdkVersion >= 10 为标准模式。在该模式下，所有.ets文件必须严格遵循ArkTS语法规则，任何语法违规工程都会编译不通过"
- Audit impact: **Important caveat for MindTrace**: since `compileSdkVersion` is likely 9 (per AGENTS.md note "ArkUI 1.1 = API 9"), strict rules are warnings, not errors. AGENTS.md treats them as hard rules, but DevEco Studio may not actually fail builds on violations. Recommend Phase 2: bump `compileSdkVersion` to ≥10 to make strict mode enforced.

---

## 4. Agent Framework & AgentService Kit

### 4.1 There is NO high-level "Agent" concept — only `AgentExtensionAbility`
- Claim: HarmonyOS NEXT defines "Agent" through `AgentExtensionAbility`, a type of ExtensionAbility introduced in **API 24**. There is no separate `AgentService` Kit at the SDK level — `AgentExtensionAbility` lives in `@kit.AbilityKit`.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agent-extension-ability> (`4_agent_extension.md`)
- Quote: "从API version 24开始，支持开发者使用AgentExtensionAbility类型的组件提供智能体服务。系统应用可以连接其他应用实现的AgentExtensionAbility组件，并使用相应的智能体服务。"
- Audit impact: **Major finding for MindTrace's "Agent framework" intent**: API 24 is the gate (HarmonyOS NEXT 5.0+ era). On current API 9, there is NO agent SDK. The `agents` HSP in MindTrace is a business-logic module (Dispatcher / TypeClassifier / KnowledgeModel), not a Huawei SDK integration. This needs to be explicit in the audit.

### 4.2 `AgentExtensionAbility` lifecycle (server side)
- Claim: Callbacks: `onCreate(want)`, `onConnect(want, proxy)`, `onDisconnect(want, proxy)`, `onData(proxy, data)`, `onAuth(proxy, handshakeData)`, `onDestroy()`. Data flows via `proxy.sendData(dataString)` and `proxy.authorize(authResultString)`.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agent-extension-ability> (`4_agent_extension.md` lines 36-87)
- Quote: "onConnect(want: Want, proxy: common.AgentHostProxy) { ... this.comProxy = proxy; }"
- Audit impact: If/when MindTrace moves to API 24+, the agent transport pattern is string-based JSON over a bidirectional IPC. Not a streaming SSE pattern.

### 4.3 `agentManager` (client side, system apps only)
- Claim: System apps connect to `AgentExtensionAbility` via `agentManager.connectAgentExtensionAbility(want, agentId, callback)`. Returns an `AgentProxy`. NOT available to third-party apps.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agent-extension-ability-manager> (`4_agent_manager.md`)
- Quote: "从API version 24开始，支持系统应用可以通过agentManager中的connectAgentExtensionAbility方法"
- Audit impact: Third-party apps (MindTrace) can only be the **server** (declaring `AgentExtensionAbility`); cannot initiate connection to another app's agent. The `agents` HSP cannot be an "agent client".

### 4.4 No "AgentService Kit" — only the above two pages
- Claim: No standalone `AgentService` Kit exists in the public HarmonyOS SDK at the time of writing. Searches for "AgentService Kit" on developer.huawei.com returned only the two pages above.
- Source: Gap — see §5.
- Audit impact: MindTrace's `agents` HSP is independent of any AgentService SDK. LLM integration is via plain HTTP (§4.5).

### 4.5 LLM integration via HTTP — `http.createHttp()` is the canonical path
- Claim: `import { http } from '@kit.NetworkKit'`; create with `http.createHttp()`; configure `HttpRequestOptions { method, header, extraData, ... }`; call `request(url, options, callback)` (or `requestInStream(url, options)` for streaming).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-request> (`4_http_request.md`)
- Quote: "应用通过HTTP发起一个数据请求，支持常见的GET、POST、OPTIONS、HEAD、PUT、DELETE、TRACE、CONNECT方法。当前提供了2种HTTP请求方式，若请求发送或接收的数据量较少，可使用HttpRequest.request...大文件的上传或者下载，且关注数据发送和接收进度，可使用HTTP请求流式传输HttpRequest.requestInstream。"
- Audit impact: MindTrace's `common/llm/LlmClient.ets` (per AGENTS.md) is on the right path — HTTP via `@kit.NetworkKit` is the only sanctioned route. No native LLM SDK exists.

### 4.6 SSE / streaming response handling — `requestInStream` + `on('dataReceive', ...)`
- Claim: For SSE (text/event-stream) from an OpenAI-compatible API, use `requestInStream(url, options)` then subscribe to `on('dataReceive', (data: ArrayBuffer) => ...)` and `on('dataEnd', ...)`. There is NO dedicated SSE parser in the SDK — the app must parse `data: ...\n\n` chunks from the ArrayBuffer manually.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-request> (`4_http_request.md` lines 230-265)
- Quote: "服务器响应的数据在dataReceive回调中返回，可通过订阅该信息获取服务器响应的数据" and "用于订阅HTTP流式响应数据接收完毕事件...on('dataEnd', () => { ... No more data in response, data receive end })"
- Audit impact: Critical for the AI agent panel's chat streaming. MindTrace's `AgentFloatWindow` will need to: (a) `httpRequest.requestInStream(...)`, (b) subscribe `dataReceive` + `dataEnd`, (c) UTF-8 decode ArrayBuffer → split on `\n\n` → parse `data: {json}` → update `@State`. Recommend documenting this SSE-on-requestInStream pattern as the audit's "Agent LLM streaming" reference design.

### 4.7 No MCP (Model Context Protocol) SDK from Huawei
- Claim: No public HarmonyOS / OpenHarmony SDK ships an MCP client or server. `web_search` and primary-source inspection returned no `developer.huawei.com` page mentioning MCP.
- Source: Gap — see §5.
- Audit impact: If MindTrace wants MCP, it must implement it in-app over raw HTTP/WebSocket (no native binding). Phase 2 should document this as an explicit decision (roll-your-own vs. defer).

### 4.8 WebSocket API as alternative streaming channel
- Claim: Beyond `requestInStream`, HarmonyOS provides `webSocket` in `@kit.NetworkKit` for full-duplex streaming. Useful for LLM provider protocols that prefer WS (e.g., some MCP transports).
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/websocket-request> (referenced via `4_http_request.md` line 665)
- Quote: "通过websocketrequestoptions的skipServerCertVerification = false 配置。" — confirms WS API surface exists.
- Audit impact: Phase 2 may want to evaluate WS for MCP-style transports.

### 4.9 `InsightIntent` — separate API surface, not Agent-related
- Claim: `InsightIntent` is a separate framework for declarative intent binding (e.g., voice/AI shortcuts). Not relevant to MindTrace's LLM agent.
- Source: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-overview> (`4_insight_intent_overview.md`) — fetched but out of scope for audit.

---

## 5. Open Questions / Gaps

1. **"AgentService Kit" not found** — searches for `developer.huawei.com/.../agent-service-kit` returned no first-party Kit page. The only "Agent" surface in `@kit.AbilityKit` is `AgentExtensionAbility` (API 24+). If MindTrace's design assumes a richer SDK, that assumption needs revisiting.
2. **MCP integration** — no HarmonyOS-native MCP SDK exists in the public docs as of the fetched snapshot. Treat as gap; recommend deciding build-vs-defer.
3. **"struct field naming avoids CommonAttribute method names"** — no single official doc page codifies this rule; it's an implicit ArkUI compiler convention. The rule is real (field `rotate` shadows `.rotate()` chainable), but documentation is scattered across the per-attribute pages. AGENTS.md rule #5 is conventional, not formally documented as a constraint.
4. **AGENTS.md "禁 C 风格 `for`" rule inversion** — official doc bans `for..in`, not C-style `for`. The current MEMORY rule text is wrong; needs correction in Phase 2.
5. **API 9 vs 10 strict-mode enforcement** — MindTrace is on API 9 where strict rules are warnings. If the audit wants them enforced, `compileSdkVersion` must be raised to ≥10.
6. **Struct method constraint** — the AGENTS.md rule "struct 内禁普通方法" is conventional enforcement; the actual compiler rule comes from `class` semantics in ArkTS (structs can't have regular methods in the usual OOP sense). Needs verification on a recent hvigor release whether this is a hard error or warning.
7. **`@kit.ArkTS.JSON`** — only API 12+. MindTrace on API 9 must use built-in `JSON`. Track for upgrade.

---

## 6. Sources Index (primary URLs / docs.openharmony.cn page slugs)

> The Huawei docs portal URL pattern is `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/<slug>` — pages are also mirrored under `https://docs.openharmony.cn`. The fetched files are at `docs/research/_fetched/<topic>_<slug>.md`.

| # | Topic | File | Primary source slug |
|---|-------|------|---------------------|
| 1 | Stage model overview | `1_stage_overview.md` | `stage-model-development-overview` |
| 2 | FA model (legacy) | `1_fa_overview.md` | `fa-model-development-overview` |
| 3 | AbilityStage container | `1_abilitystage.md` | `abilitystage` |
| 4 | UIAbility lifecycle | `1_uiability_lifecycle.md` | `uiability-lifecycle` |
| 5 | UIAbility overview | `1_uiability_overview.md` | `uiability-overview` |
| 6 | ExtensionAbility overview | `1_extensionability_overview.md` | `extensionability-overview` |
| 7 | HAP package | `1_hap_package.md` | `hap-package` |
| 8 | HAR package | `1_har_package.md` | `har-package` |
| 9 | HSP (in-app) | `1_in_app_hsp.md` | `in-app-hsp` |
| 10 | HAR ↔ HSP conversion | `1_har_to_hsp.md`, `1_hsp_to_har.md` | `har-to-hsp`, `hsp-to-har` |
| 11 | HAP ↔ HAR conversion | `1_hap_to_har.md` | `hap-to-har` |
| 12 | App package overview | `1_package_overview.md` | `application-package-overview` |
| 13 | App structure (app.json5) | `1_app_structure.md` | `app-object-internal-structure` |
| 14 | module.json5 | `1_module_configuration.md` | `module-configuration-file` |
| 15 | Application models (Stage vs FA) | `1_application_models.md` | `application-models` |
| 16 | Install/update consistency | `1_install_update.md` | `install-and-update-consistency-verification` |
| 17 | App clone, app configuration | `1_app_clone.md`, `1_app_config_overview_stage.md`, `1_app_configuration.md` | (related) |
| 18 | Launch types | `1_launch_type.md` | `uiability-launch-type` |
| 19 | Start with ETS (Stage) | `1_start_with_ets_stage.md` | (entry setup) |
| 20 | Typical config | `1_typical_config.md` | (entry setup) |
| 21 | Package glossary | `1_package_glossary.md`, `1_ability_terminology.md` | (terminology) |
| 22 | Package structure (FA/Stage) | `1_package_structure_fa.md`, `1_package_structure_stage.md` | (structure) |
| 23 | AgentExtensionAbility (server) | `4_agent_extension.md` | `agent-extension-ability` |
| 24 | AgentExtensionAbility config | `4_agent_ext_config.md` | `agent-extension-configuration` |
| 25 | AgentExtension config | `1_agent_extension_configur...md` | (config) |
| 26 | agentManager (client, sys-only) | `4_agent_manager.md` | `agent-extension-ability-manager` |
| 27 | Agent manager sys | `1_agent_manager_sys.md` | (sys API) |
| 28 | HTTP request | `4_http_request.md` | `http-request` |
| 29 | @State decorator | `2_state.md` | `arkts-state` |
| 30 | State mgmt overview | `2_state_overview.md`, `2_state_introduce.md` | `arkts-state-management-overview` |
| 31 | @Prop / @Link | (in `2_state_overview.md` index) | `arkts-prop`, `arkts-link` |
| 32 | @ObjectLink / @Observed | `2_observed_objectlink.md` | `arkts-observed-and-objectlink` |
| 33 | @Provide / @Consume | `2_provide_consume.md` | `arkts-provide-and-consume` |
| 34 | @Watch | `2_watch.md` | `arkts-watch` |
| 35 | @Builder | `2_builder.md` | `arkts-builder` |
| 36 | @Styles | `2_style.md` | `arkts-style` |
| 37 | stateStyles | `2_statestyles.md` | `arkts-statestyles` |
| 38 | Decorator overview (V1+V2) | `2_decorator_overview.md` | `arkts-decorator-overview` |
| 39 | Transformation (rotate/translate/scale) | `2_transformation.md` | `arkts-transformation` |
| 40 | Image component | `2_image.md` | `ts-basic-components-image` |
| 41 | Location (position/offset/align) | `2_location.md` | `ts-universal-attributes-location` |
| 42 | Opacity | `2_opacity.md` | `ts-universal-attributes-opacity` |
| 43 | Filter / blur / visualEffect | `2_blur_filter.md` | `ts-universal-attributes-filter-effect` |
| 44 | Custom components | `2_custom_components.md` | `arkts-create-custom-components` |
| 45 | Custom lifecycle | `2_custom_lifecycle.md` | `ts-custom-component-lifecycle` |
| 46 | Access restrictions | `2_access_restrictions.md` | `arkts-access-restrictions` |
| 47 | General attributes index | `2_general_attributes.md` | `ts-component-general-attributes` |
| 48 | ArkTS TS-migration rules (full) | `3_ts_migration.md` | `arkts-migration-background` |
| 49 | ArkTS coding style guide | `3_coding_style.md` | `arkts-coding-style-guide` |
| 50 | ArkTS lang basics (`@arkts.lang`) | `3_arkts_lang.md` | `arkts-lang` |
| 51 | ArkTS get-started | `3_get_started.md` | `arkts-get-started` |
| 52 | ArkTS introduction | `3_intro_arkts.md` | `introduction-to-arkts` |
| 53 | ArkTS high-perf guide | `3_high_perf.md` | `arkts-high-performance-programming` |
| 54 | @kit.ArkTS JSON module | `3_json.md` | `js-apis-json` |
| 55 | @kit.ArkTS util | `3_util.md` | `js-apis-util` |
| 56 | ArkTS more cases | `3_more_cases.md` | `arkts-more-cases` |
| 57 | Swift-to-ArkTS migration | `3_swift_prog.md` | (out of scope) |
| 58 | Insight Intent (out of scope) | `4_insight_intent_*.md` | (5 files) |

All 72 fetched files are listed under `docs/research/_fetched/` for traceability and will be cleaned up after Phase 2 audit is complete.
