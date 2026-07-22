import {
  BG_CARD, BG_DARK, BORDER, GLASS_10, MINT, TEXT, TEXT_2, TEXT_3,
  F_BASE, F_LG, F_SM, F_XS,
  R_FULL, R_LG, R_MD,
  S_2, S_3, S_4, S_5,
  W_BOLD, W_SEMIBOLD,
  KnowledgeUnit, NoteItem,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { AppIcon } from "../../shared/components/AppIcon"
import { NoteDetailOverlay } from "../../overlays/NoteDetailOverlay/NoteDetailOverlay"
import {
  ChapterOrbit,
  KnowledgeGalaxyViewModel,
  PlanetNode,
  SubjectSystem,
} from "../../viewmodels/KnowledgeGalaxyViewModel"
import { unitToNoteItem } from "../../utils/NoteItemMapper"

const GALAXY_SIZE: number = 360
const GALAXY_CENTER: number = GALAXY_SIZE / 2
const UNIVERSE_WIDTH: number = 360
const UNIVERSE_HEIGHT: number = 520
const MIN_ZOOM: number = 0.75
const MAX_ZOOM: number = 3
const ZOOM_STEP: number = 0.25

function pctText(value: number): string {
  return Math.round(value * 100).toString() + "%"
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value))
}

function stableHash(value: string): number {
  let hash: number = 17
  let index: number = 0
  while (index < value.length) {
    hash = (hash * 31 + value.charCodeAt(index)) % 2147483647
    index++
  }
  return Math.abs(hash)
}

function paletteColor(seed: number, offset: number): string {
  const colors: string[] = [
    "#F6C56D", "#F08A5D", "#D96C75", "#9DD8FF",
    "#6FE7D2", "#A99BFF", "#E8D8A8", "#7FB8FF",
    "#C786F0", "#8BE09B", "#D9A27E", "#8C9EFF",
  ]
  return colors[Math.abs(seed + offset) % colors.length]
}

function planetVariant(id: string): number {
  return stableHash(id) % 6
}

function planetBaseColor(id: string): string {
  return paletteColor(stableHash(id), 0)
}

function planetAccentColor(id: string): string {
  return paletteColor(stableHash(id), 5)
}

function planetLabel(planet: PlanetNode): string {
  const title: string = planet.note.title.trim()
  if (title.length > 0) {
    return title
  }
  const type: string = planet.type.trim()
  return type.length > 0 ? type : "笔记"
}

@Component
export struct ReviewGraphView {
  @StorageProp("notesVersion") @Watch("onNotesVersionChange") notesVersion: number = 0
  @State vm: KnowledgeGalaxyViewModel = new KnowledgeGalaxyViewModel()
  @State selectedSubject: string = ""
  @State zoom: number = 1
  @State orbitOffset: number = 0
  @State selectedNote: NoteItem | null = null
  @State selectedUnit: KnowledgeUnit | null = null
  private timerId: number = -1
  onGoAI: () => void = (): void => {}

  aboutToAppear(): void {
    this.reloadGalaxy(false)
  }

  aboutToDisappear(): void {
    this.stopRotation()
  }

  onNotesVersionChange(): void {
    this.reloadGalaxy(true)
  }

  private reloadGalaxy(keepSelection: boolean): void {
    this.vm.load(getContext(this)).then((ok: boolean): void => {
      if (!ok) {
        try { promptAction.showToast({ message: "知识星系加载失败", duration: 1500 }) } catch (_e) {}
        this.stopRotation()
        return
      }
      if (!keepSelection || !this.hasSubject(this.selectedSubject)) {
        this.selectedSubject = ""
        this.zoom = 1
      }
      if (this.selectedSubject.length > 0 && this.selectedNote === null) {
        this.startRotation()
      } else {
        this.stopRotation()
      }
    })
  }

  private hasSubject(subject: string): boolean {
    if (subject.length === 0) {
      return true
    }
    for (const system of this.vm.systems) {
      if (system.subject === subject) {
        return true
      }
    }
    return false
  }

  private enterSubject(subject: string): void {
    animateTo({ duration: 240, curve: Curve.FastOutSlowIn }, (): void => {
      this.selectedSubject = subject
      this.zoom = 1
      this.orbitOffset = 0
      this.startRotation()
    })
  }

  private leaveSubject(): void {
    this.stopRotation()
    animateTo({ duration: 220, curve: Curve.FastOutSlowIn }, (): void => {
      this.selectedSubject = ""
      this.zoom = 1
      this.orbitOffset = 0
      this.selectedNote = null
      this.selectedUnit = null
    })
  }

  private startRotation(): void {
    if (this.timerId !== -1 || this.selectedSubject.length === 0 || this.selectedNote !== null) {
      return
    }
    this.timerId = setInterval((): void => {
      this.orbitOffset = (this.orbitOffset + 2.2) % 360
    }, 800)
  }

  private stopRotation(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  private openPlanet = (planet: PlanetNode): void => {
    this.stopRotation()
    this.selectedNote = planet.note
    this.selectedUnit = planet.unit
    this.vm.loadNote(getContext(this), planet.id).then((unit: KnowledgeUnit | null): void => {
      if (this.selectedNote !== null && this.selectedNote.rawId === planet.id) {
        this.selectedUnit = unit
      }
    })
  }

  private closeDetail = (): void => {
    this.selectedNote = null
    this.selectedUnit = null
    this.startRotation()
  }

  private handleSaved = (unit: KnowledgeUnit): void => {
    this.selectedNote = unitToNoteItem(unit)
    this.selectedUnit = unit
    this.reloadGalaxy(true)
  }

  private deleteNote = async (id: string): Promise<void> => {
    const ok: boolean = await this.vm.deleteNote(getContext(this), id)
    if (ok) {
      this.selectedNote = null
      this.selectedUnit = null
      const v: number = AppStorage.get<number>("notesVersion") ?? 0
      AppStorage.setOrCreate("notesVersion", v + 1)
      try { promptAction.showToast({ message: "已删除笔记", duration: 1200 }) } catch (_e) {}
    } else {
      try { promptAction.showToast({ message: "删除笔记失败", duration: 1500 }) } catch (_e) {}
    }
  }

  private activeSystem(): SubjectSystem | null {
    for (const system of this.vm.systems) {
      if (system.subject === this.selectedSubject) {
        return system
      }
    }
    return null
  }

  private zoomIn(): void {
    animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, (): void => {
      this.zoom = clamp(Math.round((this.zoom + ZOOM_STEP) * 100) / 100, MIN_ZOOM, MAX_ZOOM)
    })
  }

  private zoomOut(): void {
    animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, (): void => {
      this.zoom = clamp(Math.round((this.zoom - ZOOM_STEP) * 100) / 100, MIN_ZOOM, MAX_ZOOM)
    })
  }

  private resetZoom(): void {
    animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, (): void => {
      this.zoom = 1
    })
  }

  build() {
    Stack() {
      Column() {
        if (this.vm.systems.length === 0) {
          this.EmptyState()
        } else if (this.selectedSubject.length === 0) {
          SubjectUniverseView({
            systems: this.vm.systems,
            totalCount: this.vm.totalCount,
            avgMastery: this.vm.avgMastery,
            zoom: this.zoom,
            onSelectSubject: (subject: string): void => this.enterSubject(subject),
            onSelectPlanet: this.openPlanet,
            onZoomIn: (): void => this.zoomIn(),
            onZoomOut: (): void => this.zoomOut(),
            onResetZoom: (): void => this.resetZoom(),
          })
        } else {
          this.SubjectHeader()
          SubjectGalaxyView({
            system: this.activeSystem(),
            zoom: this.zoom,
            orbitOffset: this.orbitOffset,
            onSelectPlanet: this.openPlanet,
            onZoomIn: (): void => this.zoomIn(),
            onZoomOut: (): void => this.zoomOut(),
            onResetZoom: (): void => this.resetZoom(),
          })
        }
      }
      .width("100%")
      .layoutWeight(1)
      .backgroundColor(BG_DARK)

      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote!,
          unit: this.selectedUnit,
          units: this.vm.units,
          onClose: this.closeDetail,
          onDelete: this.deleteNote,
          onSaved: this.handleSaved,
        })
      }
    }
    .width("100%")
    .layoutWeight(1)
  }

  @Builder
  SubjectHeader() {
    Row() {
      Stack() {
        AppIcon({ name: "chevron-right", iconSize: 18, color: TEXT, strokeWidth: 1.8 })
          .rotate({ angle: 180 })
      }
      .width(38)
      .height(38)
      .borderRadius(R_FULL)
      .backgroundColor(GLASS_10)
      .onClick((): void => this.leaveSubject())

      Column() {
        Text(this.selectedSubject)
          .fontSize(F_LG)
          .fontWeight(W_BOLD)
          .fontColor(TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width("100%")
        Text("轨道代表章节，行星代表笔记")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .maxLines(1)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .margin({ left: S_3 })
      .alignItems(HorizontalAlign.Start)
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: S_2, bottom: S_2 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  EmptyState() {
    Column() {
      Blank()
      Stack() {
        Circle({ width: 150, height: 150 })
          .fill(MINT)
          .opacity(0.08)
          .shadow({ radius: 30, color: MINT, offsetX: 0, offsetY: 0 })
        Circle({ width: 94, height: 94 })
          .fill("#16FFFFFF")
          .stroke(MINT)
          .strokeWidth(1)
        AppIcon({ name: "ai", iconSize: 32, color: MINT, strokeWidth: 1.8 })
      }
      .width(174)
      .height(174)

      Text("还没有知识星系")
        .fontSize(F_LG)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)
        .margin({ top: S_4 })

      Text("打开 AI 捕获第一条笔记，它会按学科和章节进入星系。")
        .fontSize(F_SM)
        .fontColor(TEXT_3)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .width("78%")
        .margin({ top: S_2, bottom: S_4 })

      Button("打开 AI")
        .fontSize(F_SM)
        .fontWeight(W_SEMIBOLD)
        .fontColor(BG_DARK)
        .height(42)
        .padding({ left: 22, right: 22 })
        .borderRadius(R_FULL)
        .backgroundColor(MINT)
        .onClick((): void => this.onGoAI())

      Blank()
    }
    .width("100%")
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
struct SubjectUniverseView {
  @Prop systems: SubjectSystem[] = []
  @Prop totalCount: number = 0
  @Prop avgMastery: number = 0
  @Prop zoom: number = 1
  onSelectSubject: (subject: string) => void = (_subject: string): void => {}
  onSelectPlanet: (planet: PlanetNode) => void = (_planet: PlanetNode): void => {}
  onZoomIn: () => void = (): void => {}
  onZoomOut: () => void = (): void => {}
  onResetZoom: () => void = (): void => {}

  build() {
    Scroll() {
      Column() {
        Stack() {
          Image($r("app.media.galaxy_overview_bg"))
            .width("100%")
            .height("100%")
            .objectFit(ImageFit.Cover)
            .scale({ x: this.backgroundScale(), y: this.backgroundScale() })
          Row()
            .width("100%")
            .height("100%")
            .backgroundColor("#A004070D")
          this.NebulaTrails()
          this.StarDust()
          ForEach(this.systems,
            (system: SubjectSystem): void => {
              this.SubjectSystemNode(system)
            },
            (system: SubjectSystem): string => system.subject
          )
        }
        .width(UNIVERSE_WIDTH)
        .height(UNIVERSE_HEIGHT)
        .clip(true)
        .alignSelf(ItemAlign.Center)
        .margin({ top: S_2 })

        this.ZoomControls()

        Row() {
          this.StatPill(this.systems.length.toString() + " 学科", "分组")
          this.StatPill(this.totalCount.toString() + " 笔记", "总量")
          this.StatPill(pctText(this.avgMastery), "掌握")
        }
        .width("100%")
        .padding({ left: S_5, right: S_5 })
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: S_2 })

        Text(this.zoomHint())
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .width("100%")
          .textAlign(TextAlign.Center)
          .margin({ top: S_4, bottom: 90 })
      }
      .width("100%")
    }
    .layoutWeight(1)
    .width("100%")
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  SubjectSystemNode(system: SubjectSystem) {
    Stack() {
      if (this.showOrbitHints()) {
        ForEach(system.orbits,
          (orbit: ChapterOrbit, orbitIndex: number): void => {
            this.OverviewOrbit(system, orbit, orbitIndex)
          },
          (orbit: ChapterOrbit): string => system.subject + "_" + orbit.chapter + "_overview_orbit"
        )
      }

      Ellipse()
        .width(system.size * this.nodeScale() * 2.9)
        .height(system.size * this.nodeScale() * 0.86)
        .stroke(system.color)
        .strokeWidth(0.45)
        .opacity(0.20)
        .rotate({ angle: -18 })

      Ellipse()
        .width(system.size * this.nodeScale() * 3.55)
        .height(system.size * this.nodeScale() * 1.04)
        .stroke(system.color)
        .strokeWidth(0.45)
        .opacity(0.08 + system.mastery * 0.07)
        .rotate({ angle: 8 })

      Ellipse()
        .width(system.size * this.nodeScale() * 2.08)
        .height(system.size * this.nodeScale() * 0.58)
        .stroke(MINT)
        .strokeWidth(0.35)
        .opacity(0.11)
        .rotate({ angle: 22 })

      Circle({ width: system.size * this.nodeScale() + 62, height: system.size * this.nodeScale() + 62 })
        .fill(system.color)
        .opacity(0.035)

      Circle({ width: system.size * this.nodeScale() + 38, height: system.size * this.nodeScale() + 38 })
        .fill(system.color)
        .opacity(0.055)

      Circle({ width: system.size * this.nodeScale(), height: system.size * this.nodeScale() })
        .fill(system.color)
        .opacity(0.18)

      Circle({ width: system.size * this.nodeScale() * 0.54, height: system.size * this.nodeScale() * 0.54 })
        .fill("#D8FFF3")
        .opacity(0.42)
        .stroke(system.color)
        .strokeWidth(0.7)

      this.SolarStar(system.color, system.size * this.nodeScale() * 0.62, 0.76)

      this.SatelliteDot(system.color, system.size * 1.42, system.size * 0.46, 5, 0.68)
      this.SatelliteDot(MINT, system.size * 0.55, system.size * 1.18, 4, 0.54)
      this.SatelliteDot(TEXT_2, system.size * 1.24, system.size * 1.34, 3, 0.46)

      if (system.count >= 4) {
        this.SatelliteDot(system.color, system.size * 0.78, system.size * 0.34, 3, 0.46)
      }

      if (system.count >= 10) {
        this.SatelliteDot(MINT, system.size * 1.68, system.size * 1.02, 4, 0.50)
      }

      if (system.count >= 18) {
        this.SatelliteDot(TEXT_2, system.size * 0.22, system.size * 0.70, 3, 0.42)
      }

      if (this.showPlanets()) {
        ForEach(system.orbits,
          (orbit: ChapterOrbit, orbitIndex: number): void => {
            ForEach(orbit.planets.slice(0, this.maxOverviewPlanets(orbitIndex)),
              (planet: PlanetNode, planetIndex: number): void => {
                this.OverviewPlanet(system, orbitIndex, planet, planetIndex)
              },
              (planet: PlanetNode): string => system.subject + "_" + planet.id + "_overview_planet"
            )
          },
          (orbit: ChapterOrbit): string => system.subject + "_" + orbit.chapter + "_overview_planets"
        )
      }

      Column() {
        Text(system.subject)
          .fontSize(F_XS)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(118)
          .textAlign(TextAlign.Center)
        Text(system.count.toString() + " 条 · " + pctText(system.mastery))
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Center)
      .translate({ y: system.size * 0.74 })
    }
    .width(system.size + 122)
    .height(system.size + 118)
    .alignContent(Alignment.Center)
    .position({ x: system.x, y: system.y })
    .onClick((): void => this.onSelectSubject(system.subject))
  }

  @Builder
  StarDust() {
    Circle({ width: 2, height: 2 }).fill(TEXT_2).opacity(0.28).position({ x: 24, y: 32 })
    Circle({ width: 1, height: 1 }).fill(TEXT_2).opacity(0.22).position({ x: 78, y: 84 })
    Circle({ width: 2, height: 2 }).fill(MINT).opacity(0.30).position({ x: 304, y: 58 })
    Circle({ width: 1, height: 1 }).fill(TEXT_2).opacity(0.18).position({ x: 328, y: 146 })
    Circle({ width: 2, height: 2 }).fill(TEXT_2).opacity(0.22).position({ x: 42, y: 254 })
    Circle({ width: 1, height: 1 }).fill(MINT).opacity(0.26).position({ x: 188, y: 310 })
    Circle({ width: 2, height: 2 }).fill(TEXT_2).opacity(0.20).position({ x: 278, y: 382 })
    Circle({ width: 1, height: 1 }).fill(TEXT_2).opacity(0.20).position({ x: 96, y: 452 })
    Circle({ width: 2, height: 2 }).fill("#DAB7FF").opacity(0.22).position({ x: 318, y: 474 })
    Circle({ width: 1, height: 1 }).fill(MINT).opacity(0.24).position({ x: 158, y: 492 })
  }

  @Builder
  NebulaTrails() {
    Ellipse()
      .width(this.sceneSize(420))
      .height(this.sceneSize(138))
      .stroke(MINT)
      .strokeWidth(0.35)
      .opacity(0.16)
      .rotate({ angle: -22 })
      .position({ x: this.sceneX(-32, 420), y: this.sceneY(90, 138) })
    Ellipse()
      .width(this.sceneSize(520))
      .height(this.sceneSize(178))
      .stroke("#9BE7FF")
      .strokeWidth(0.3)
      .opacity(0.09)
      .rotate({ angle: -27 })
      .position({ x: this.sceneX(-92, 520), y: this.sceneY(162, 178) })
    Ellipse()
      .width(this.sceneSize(300))
      .height(this.sceneSize(86))
      .stroke("#C8B6FF")
      .strokeWidth(0.35)
      .opacity(0.08)
      .rotate({ angle: 18 })
      .position({ x: this.sceneX(118, 300), y: this.sceneY(330, 86) })
    Row()
      .width(this.sceneSize(162))
      .height(1)
      .backgroundColor(MINT)
      .opacity(0.10)
      .rotate({ angle: -31 })
      .position({ x: this.sceneX(18, 162), y: this.sceneY(424, 1) })
    Row()
      .width(this.sceneSize(96))
      .height(1)
      .backgroundColor("#DAB7FF")
      .opacity(0.10)
      .rotate({ angle: 24 })
      .position({ x: this.sceneX(234, 96), y: this.sceneY(82, 1) })
  }

  @Builder
  OverviewOrbit(system: SubjectSystem, orbit: ChapterOrbit, orbitIndex: number) {
    Ellipse()
      .width(this.overviewOrbitWidth(system, orbitIndex))
      .height(this.overviewOrbitHeight(system, orbitIndex))
      .stroke(orbitIndex % 2 === 0 ? system.color : MINT)
      .strokeWidth(0.35)
      .opacity(this.orbitOpacity())
      .rotate({ angle: orbit.tilt })
  }

  @Builder
  OverviewPlanet(system: SubjectSystem, orbitIndex: number, planet: PlanetNode, planetIndex: number) {
    Column() {
      Stack() {
        Circle({ width: this.overviewPlanetSize(planet) + 10, height: this.overviewPlanetSize(planet) + 10 })
          .fill(planetBaseColor(planet.id))
          .opacity(0.08)
        this.SolarPlanet(planet, this.overviewPlanetSize(planet), 0.74)
      }
      .width(this.overviewPlanetSize(planet) * 1.72)
      .height(this.overviewPlanetSize(planet) * 1.34)
      .alignContent(Alignment.Center)
      .scale({ x: this.overviewPlanetVisualScale(), y: this.overviewPlanetVisualScale() })

      if (this.showOverviewPlanetLabels()) {
        Text(planetLabel(planet))
          .fontSize(F_XS)
          .fontColor("#BEEBFAFF")
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(this.overviewPlanetFrameWidth(planet))
          .height(16)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.overviewPlanetFrameWidth(planet))
    .height(this.overviewPlanetFrameHeight(planet))
    .alignItems(HorizontalAlign.Center)
    .position({ x: this.overviewPlanetX(system, orbitIndex, planetIndex), y: this.overviewPlanetY(system, orbitIndex, planetIndex) })
    .onClick((): void => this.onSelectPlanet(planet))
  }

  @Builder
  SatelliteDot(color: string, x: number, y: number, sizeValue: number, alpha: number) {
    Circle({ width: sizeValue + 6, height: sizeValue + 6 })
      .fill(color)
      .opacity(alpha * 0.12)
      .position({ x: x, y: y })
    Circle({ width: sizeValue, height: sizeValue })
      .fill(color)
      .opacity(alpha)
      .position({ x: x + 3, y: y + 3 })
  }

  @Builder
  SolarPlanet(planet: PlanetNode, sizeValue: number, alpha: number) {
    Stack() {
      if (planetVariant(planet.id) === 2) {
        Ellipse()
          .width(sizeValue * 1.65)
          .height(sizeValue * 0.56)
          .stroke(planetAccentColor(planet.id))
          .strokeWidth(Math.max(1, sizeValue * 0.08))
          .opacity(alpha * 0.60)
          .rotate({ angle: -18 })
      }

      Circle({ width: sizeValue, height: sizeValue })
        .fill(planetBaseColor(planet.id))
        .opacity(alpha)

      if (planetVariant(planet.id) === 1) {
        Ellipse().width(sizeValue * 0.82).height(sizeValue * 0.14).fill(planetAccentColor(planet.id)).opacity(alpha * 0.42).position({ x: sizeValue * 0.09, y: sizeValue * 0.26 })
        Ellipse().width(sizeValue * 0.74).height(sizeValue * 0.12).fill("#FFF4C7").opacity(alpha * 0.28).position({ x: sizeValue * 0.13, y: sizeValue * 0.50 })
      } else if (planetVariant(planet.id) === 3) {
        Circle({ width: sizeValue * 0.34, height: sizeValue * 0.34 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.46).position({ x: sizeValue * 0.18, y: sizeValue * 0.18 })
        Circle({ width: sizeValue * 0.22, height: sizeValue * 0.22 }).fill("#E7FFF8").opacity(alpha * 0.30).position({ x: sizeValue * 0.58, y: sizeValue * 0.50 })
      } else if (planetVariant(planet.id) === 4) {
        Circle({ width: sizeValue * 0.18, height: sizeValue * 0.18 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.54).position({ x: sizeValue * 0.20, y: sizeValue * 0.30 })
        Circle({ width: sizeValue * 0.14, height: sizeValue * 0.14 }).fill("#FFF1C1").opacity(alpha * 0.32).position({ x: sizeValue * 0.60, y: sizeValue * 0.22 })
        Circle({ width: sizeValue * 0.12, height: sizeValue * 0.12 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.34).position({ x: sizeValue * 0.52, y: sizeValue * 0.66 })
      } else {
        Circle({ width: sizeValue * 0.28, height: sizeValue * 0.28 }).fill("#FFFFFF").opacity(alpha * 0.18).position({ x: sizeValue * 0.18, y: sizeValue * 0.16 })
      }
    }
    .width(sizeValue * 1.7)
    .height(sizeValue * 1.3)
    .alignContent(Alignment.Center)
  }

  @Builder
  SolarStar(color: string, sizeValue: number, alpha: number) {
    Stack() {
      Circle({ width: sizeValue * 1.36, height: sizeValue * 1.36 })
        .fill(color)
        .opacity(alpha * 0.16)
      Circle({ width: sizeValue, height: sizeValue })
        .fill(color)
        .opacity(alpha * 0.72)
      Circle({ width: sizeValue * 0.62, height: sizeValue * 0.62 })
        .fill("#FFF7B8")
        .opacity(alpha * 0.70)
      Circle({ width: sizeValue * 0.24, height: sizeValue * 0.24 })
        .fill("#FFFFFF")
        .opacity(alpha * 0.48)
        .position({ x: sizeValue * 0.42, y: sizeValue * 0.36 })
    }
    .width(sizeValue * 1.36)
    .height(sizeValue * 1.36)
    .alignContent(Alignment.Center)
  }

  @Builder
  ZoomControls() {
    Row({ space: 8 }) {
      this.ZoomButton("-", (): void => this.onZoomOut())
      this.ZoomButton(Math.round(this.zoom * 100).toString() + "%", (): void => this.onResetZoom(), 56)
      this.ZoomButton("+", (): void => this.onZoomIn())
    }
    .alignSelf(ItemAlign.Center)
    .margin({ top: S_2, bottom: S_2 })
  }

  @Builder
  ZoomButton(label: string, action: () => void, widthValue: number = 38) {
    Text(label)
      .fontSize(F_SM)
      .fontWeight(W_SEMIBOLD)
      .fontColor(TEXT_2)
      .width(widthValue)
      .height(34)
      .textAlign(TextAlign.Center)
      .borderRadius(R_FULL)
      .backgroundColor(GLASS_10)
      .border({ width: 0.5, color: BORDER })
      .onClick((): void => action())
  }

  @Builder
  StatPill(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(F_BASE)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)
      Text(label)
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .margin({ top: 2 })
    }
    .width(96)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(R_MD)
    .backgroundColor(BG_CARD)
    .border({ width: 0.5, color: BORDER })
  }

  private showOrbitHints(): boolean {
    return this.zoom >= 1.1
  }

  private showPlanets(): boolean {
    return this.zoom >= 1.35
  }

  private showOverviewPlanetLabels(): boolean {
    return this.zoom >= 1.9
  }

  private nodeScale(): number {
    return clamp(0.52 + this.zoom * 0.34, 0.70, 1.62)
  }

  private backgroundScale(): number {
    return clamp(1 + Math.max(0, this.zoom - 1) * 0.38, 1, 1.76)
  }

  private sceneSize(value: number): number {
    return value * this.backgroundScale()
  }

  private sceneX(x: number, widthValue: number): number {
    const scaledWidth: number = this.sceneSize(widthValue)
    const center: number = x + widthValue / 2
    const scaledCenter: number = UNIVERSE_WIDTH / 2 + (center - UNIVERSE_WIDTH / 2) * this.backgroundScale()
    return scaledCenter - scaledWidth / 2
  }

  private sceneY(y: number, heightValue: number): number {
    const scaledHeight: number = this.sceneSize(heightValue)
    const center: number = y + heightValue / 2
    const scaledCenter: number = UNIVERSE_HEIGHT / 2 + (center - UNIVERSE_HEIGHT / 2) * this.backgroundScale()
    return scaledCenter - scaledHeight / 2
  }

  private orbitOpacity(): number {
    return clamp((this.zoom - 1.05) * 0.46, 0.04, 0.28)
  }

  private zoomHint(): string {
    if (this.zoom < 1.1) {
      return "点击学科星系进入详情，放大后逐步显示章节轨道"
    }
    if (this.zoom < 1.35) {
      return "章节轨道已显现，继续放大可看到笔记行星"
    }
    return "行星代表笔记，点击行星可打开详情"
  }

  private maxOverviewPlanets(orbitIndex: number): number {
    if (this.zoom < 1.5) {
      return orbitIndex < 2 ? 3 : 2
    }
    if (this.zoom < 1.9) {
      return orbitIndex < 3 ? 5 : 3
    }
    if (this.zoom < 2.2) {
      return orbitIndex < 4 ? 7 : 4
    }
    return orbitIndex < 4 ? 9 : 5
  }

  private overviewOrbitWidth(system: SubjectSystem, orbitIndex: number): number {
    return (system.size * 1.65 + orbitIndex * 14) * this.nodeScale()
  }

  private overviewOrbitHeight(system: SubjectSystem, orbitIndex: number): number {
    return (system.size * 0.54 + orbitIndex * 5) * this.nodeScale()
  }

  private overviewPlanetSize(planet: PlanetNode): number {
    return clamp(planet.size * 0.42, 7, 22)
  }

  private overviewPlanetVisualScale(): number {
    return clamp(this.zoom, 0.75, 3)
  }

  private overviewPlanetFrameWidth(planet: PlanetNode): number {
    const visualWidth: number = this.overviewPlanetSize(planet) * this.overviewPlanetVisualScale() * 1.9
    return this.showOverviewPlanetLabels() ? Math.max(58, visualWidth) : visualWidth
  }

  private overviewPlanetFrameHeight(planet: PlanetNode): number {
    return this.overviewPlanetSize(planet) * this.overviewPlanetVisualScale() * 1.34 + (this.showOverviewPlanetLabels() ? 16 : 0)
  }

  private overviewPlanetX(system: SubjectSystem, orbitIndex: number, planetIndex: number): number {
    const frame: number = system.size + 122
    const angle: number = (planetIndex * 62 + orbitIndex * 37 + 18) * Math.PI / 180
    const radiusX: number = this.overviewOrbitWidth(system, orbitIndex) / 2
    const planet: PlanetNode = system.orbits[orbitIndex].planets[planetIndex]
    return frame / 2 + Math.cos(angle) * radiusX - this.overviewPlanetFrameWidth(planet) / 2
  }

  private overviewPlanetY(system: SubjectSystem, orbitIndex: number, planetIndex: number): number {
    const frame: number = system.size + 118
    const angle: number = (planetIndex * 62 + orbitIndex * 37 + 18) * Math.PI / 180
    const radiusY: number = this.overviewOrbitHeight(system, orbitIndex) / 2
    const planet: PlanetNode = system.orbits[orbitIndex].planets[planetIndex]
    return frame / 2 + Math.sin(angle) * radiusY - this.overviewPlanetFrameHeight(planet) / 2
  }

}

@Component
struct SubjectGalaxyView {
  @Prop system: SubjectSystem | null = null
  @Prop zoom: number = 1
  @Prop orbitOffset: number = 0
  onSelectPlanet: (planet: PlanetNode) => void = (_planet: PlanetNode): void => {}
  onZoomIn: () => void = (): void => {}
  onZoomOut: () => void = (): void => {}
  onResetZoom: () => void = (): void => {}

  build() {
    Scroll() {
      Column() {
        if (this.system !== null) {
          Stack() {
            Image($r("app.media.galaxy_detail_bg"))
              .width("100%")
              .height("100%")
              .objectFit(ImageFit.Cover)
              .opacity(0.72)
              .scale({ x: this.detailBackgroundScale(), y: this.detailBackgroundScale() })
            Row()
              .width("100%")
              .height("100%")
              .backgroundColor("#9A03070E")
            this.DetailNebulaTrails(this.system!)
            this.StarDust()

            ForEach(this.system!.orbits,
              (orbit: ChapterOrbit): void => {
                this.ChapterOrbitRing(orbit)
              },
              (orbit: ChapterOrbit): string => orbit.chapter
            )

            this.CenterStar(this.system!)

            ForEach(this.system!.orbits,
              (orbit: ChapterOrbit): void => {
                ForEach(orbit.planets,
                  (planet: PlanetNode): void => {
                    this.Planet(orbit, planet)
                  },
                  (planet: PlanetNode): string => orbit.chapter + "_" + planet.id
                )
              },
              (orbit: ChapterOrbit): string => orbit.chapter + "_planets"
            )
          }
          .width(GALAXY_SIZE)
          .height(GALAXY_SIZE)
          .alignSelf(ItemAlign.Center)
          .margin({ top: S_2 })
          .clip(true)

          this.ZoomControls()
          this.SubjectSummary(this.system!)
        }
        Blank().height(96)
      }
      .width("100%")
    }
    .layoutWeight(1)
    .width("100%")
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ChapterOrbitRing(orbit: ChapterOrbit) {
    Ellipse()
      .width(orbit.radiusX * 2 * this.zoom)
      .height(orbit.radiusY * 2 * this.zoom)
      .stroke(this.orbitStrokeColor(orbit))
      .strokeWidth(0.8)
      .opacity(0.20 + Math.min(0.18, orbit.mastery * 0.16))
      .rotate({ angle: orbit.tilt })

    Ellipse()
      .width(orbit.radiusX * 2 * this.zoom + 18)
      .height(orbit.radiusY * 2 * this.zoom + 8)
      .stroke(this.orbitStrokeColor(orbit))
      .strokeWidth(0.35)
      .opacity(0.08)
      .rotate({ angle: orbit.tilt + 2 })

    Text(orbit.chapter)
      .fontSize(F_XS)
      .fontWeight(W_SEMIBOLD)
      .fontColor("#CCECF7FF")
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width(96)
      .height(22)
      .textAlign(TextAlign.Center)
      .borderRadius(R_FULL)
      .backgroundColor("#3008121C")
      .border({ width: 0.5, color: "#3A9BE7FF" })
      .position({ x: this.orbitLabelX(orbit), y: this.orbitLabelY(orbit) })
  }

  @Builder
  CenterStar(system: SubjectSystem) {
    Circle({ width: this.centerStarGlowSize(96), height: this.centerStarGlowSize(96) })
      .fill(system.color)
      .opacity(this.centerStarGlowOpacity(0.045))

    Circle({ width: this.centerStarGlowSize(68), height: this.centerStarGlowSize(68) })
      .fill(system.color)
      .opacity(this.centerStarGlowOpacity(0.10))

    Circle({ width: this.centerStarGlowSize(38), height: this.centerStarGlowSize(38) })
      .fill("#E7FFF8")
      .opacity(this.centerStarGlowOpacity(0.18))

    this.SolarStar(system.color, 46 * this.centerStarScale(), 0.96)
  }

  @Builder
  Planet(orbit: ChapterOrbit, planet: PlanetNode) {
    Column() {
      Stack() {
        Circle({ width: this.planetSize(planet) + 20, height: this.planetSize(planet) + 20 })
          .fill(planetBaseColor(planet.id))
          .opacity(0.045)
        Circle({ width: this.planetSize(planet) + 10, height: this.planetSize(planet) + 10 })
          .fill(planetAccentColor(planet.id))
          .opacity(0.08)
        this.SolarPlanet(planet, this.planetSize(planet), planet.alpha)
      }
      .width(this.planetSize(planet) * 1.72)
      .height(this.planetSize(planet) * 1.34)
      .alignContent(Alignment.Center)
      .scale({ x: this.planetVisualScale(), y: this.planetVisualScale() })

      Text(planetLabel(planet))
        .fontSize(F_XS)
        .fontColor("#C6ECF8FF")
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(this.planetFrameWidth(planet))
        .height(18)
        .textAlign(TextAlign.Center)
    }
    .width(this.planetFrameWidth(planet))
    .height(this.planetFrameHeight(planet))
    .alignItems(HorizontalAlign.Center)
    .position({ x: this.planetX(orbit, planet), y: this.planetY(orbit, planet) })
    .onClick((): void => this.onSelectPlanet(planet))
  }

  @Builder
  ZoomControls() {
    Row({ space: 8 }) {
      this.ZoomButton("-", (): void => this.onZoomOut())
      this.ZoomButton(Math.round(this.zoom * 100).toString() + "%", (): void => this.onResetZoom(), 56)
      this.ZoomButton("+", (): void => this.onZoomIn())
    }
    .alignSelf(ItemAlign.Center)
    .margin({ top: S_2, bottom: S_3 })
  }

  @Builder
  ZoomButton(label: string, action: () => void, widthValue: number = 38) {
    Text(label)
      .fontSize(F_SM)
      .fontWeight(W_SEMIBOLD)
      .fontColor(TEXT_2)
      .width(widthValue)
      .height(34)
      .textAlign(TextAlign.Center)
      .borderRadius(R_FULL)
      .backgroundColor(GLASS_10)
      .border({ width: 0.5, color: BORDER })
      .onClick((): void => action())
  }

  @Builder
  SubjectSummary(system: SubjectSystem) {
    Column() {
      Row() {
        Text(system.subject + " 星系")
          .fontSize(F_BASE)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
        Blank()
        Text(system.orbits.length.toString() + " 章 · " + system.count.toString() + " 笔记")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
      }
      .width("100%")

      Stack({ alignContent: Alignment.Start }) {
        Row().width("100%").height(7).borderRadius(R_FULL).backgroundColor(GLASS_10)
        Row()
          .width(pctText(system.mastery))
          .height(7)
          .borderRadius(R_FULL)
          .backgroundColor(system.color)
      }
      .width("100%")
      .height(7)
      .margin({ top: S_3, bottom: S_3 })

      Text("轨道代表章节，颜色代表笔记类型，大小随掌握度和复习次数变化。")
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .lineHeight(18)
        .width("100%")
    }
    .width("90%")
    .alignSelf(ItemAlign.Center)
    .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .border({ width: 0.5, color: BORDER })
  }

  @Builder
  StarDust() {
    Circle({ width: 2, height: 2 }).fill(TEXT_2).opacity(0.28).position({ x: 28, y: 28 })
    Circle({ width: 1, height: 1 }).fill(TEXT_2).opacity(0.24).position({ x: 94, y: 70 })
    Circle({ width: 2, height: 2 }).fill(MINT).opacity(0.30).position({ x: 292, y: 34 })
    Circle({ width: 1, height: 1 }).fill(TEXT_2).opacity(0.20).position({ x: 326, y: 118 })
    Circle({ width: 2, height: 2 }).fill(MINT).opacity(0.22).position({ x: 314, y: 188 })
    Circle({ width: 2, height: 2 }).fill(TEXT_2).opacity(0.20).position({ x: 42, y: 278 })
    Circle({ width: 1, height: 1 }).fill("#DAB7FF").opacity(0.24).position({ x: 132, y: 322 })
    Circle({ width: 2, height: 2 }).fill(TEXT_2).opacity(0.22).position({ x: 204, y: 304 })
  }

  @Builder
  DetailNebulaTrails(system: SubjectSystem) {
    Ellipse()
      .width(380 * this.detailBackgroundScale())
      .height(118 * this.detailBackgroundScale())
      .stroke(system.color)
      .strokeWidth(0.35)
      .opacity(0.10)
      .rotate({ angle: -20 })
      .position({ x: -22, y: 74 })
    Ellipse()
      .width(430 * this.detailBackgroundScale())
      .height(146 * this.detailBackgroundScale())
      .stroke(MINT)
      .strokeWidth(0.3)
      .opacity(0.08)
      .rotate({ angle: -28 })
      .position({ x: -58, y: 142 })
    Ellipse()
      .width(250 * this.detailBackgroundScale())
      .height(72 * this.detailBackgroundScale())
      .stroke("#C8B6FF")
      .strokeWidth(0.3)
      .opacity(0.07)
      .rotate({ angle: 18 })
      .position({ x: 126, y: 250 })
    Row()
      .width(120 * this.detailBackgroundScale())
      .height(1)
      .backgroundColor(system.color)
      .opacity(0.08)
      .rotate({ angle: 28 })
      .position({ x: 212, y: 58 })
    Row()
      .width(154 * this.detailBackgroundScale())
      .height(1)
      .backgroundColor(MINT)
      .opacity(0.08)
      .rotate({ angle: -34 })
      .position({ x: 16, y: 316 })
  }

  @Builder
  SolarPlanet(planet: PlanetNode, sizeValue: number, alpha: number) {
    Stack() {
      if (planetVariant(planet.id) === 2) {
        Ellipse()
          .width(sizeValue * 1.68)
          .height(sizeValue * 0.58)
          .stroke(planetAccentColor(planet.id))
          .strokeWidth(Math.max(1, sizeValue * 0.08))
          .opacity(alpha * 0.62)
          .rotate({ angle: -18 })
      }

      Circle({ width: sizeValue, height: sizeValue })
        .fill(planetBaseColor(planet.id))
        .opacity(alpha)

      if (planetVariant(planet.id) === 1) {
        Ellipse().width(sizeValue * 0.84).height(sizeValue * 0.14).fill(planetAccentColor(planet.id)).opacity(alpha * 0.44).position({ x: sizeValue * 0.08, y: sizeValue * 0.25 })
        Ellipse().width(sizeValue * 0.76).height(sizeValue * 0.12).fill("#FFF4C7").opacity(alpha * 0.30).position({ x: sizeValue * 0.12, y: sizeValue * 0.50 })
        Ellipse().width(sizeValue * 0.68).height(sizeValue * 0.10).fill(planetAccentColor(planet.id)).opacity(alpha * 0.25).position({ x: sizeValue * 0.16, y: sizeValue * 0.66 })
      } else if (planetVariant(planet.id) === 3) {
        Circle({ width: sizeValue * 0.34, height: sizeValue * 0.34 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.48).position({ x: sizeValue * 0.18, y: sizeValue * 0.18 })
        Circle({ width: sizeValue * 0.22, height: sizeValue * 0.22 }).fill("#E7FFF8").opacity(alpha * 0.30).position({ x: sizeValue * 0.58, y: sizeValue * 0.50 })
      } else if (planetVariant(planet.id) === 4) {
        Circle({ width: sizeValue * 0.18, height: sizeValue * 0.18 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.54).position({ x: sizeValue * 0.20, y: sizeValue * 0.30 })
        Circle({ width: sizeValue * 0.14, height: sizeValue * 0.14 }).fill("#FFF1C1").opacity(alpha * 0.32).position({ x: sizeValue * 0.60, y: sizeValue * 0.22 })
        Circle({ width: sizeValue * 0.12, height: sizeValue * 0.12 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.34).position({ x: sizeValue * 0.52, y: sizeValue * 0.66 })
      } else if (planetVariant(planet.id) === 5) {
        Ellipse().width(sizeValue * 0.72).height(sizeValue * 0.16).fill("#FFFFFF").opacity(alpha * 0.18).position({ x: sizeValue * 0.14, y: sizeValue * 0.36 })
        Circle({ width: sizeValue * 0.20, height: sizeValue * 0.20 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.30).position({ x: sizeValue * 0.56, y: sizeValue * 0.58 })
      } else {
        Circle({ width: sizeValue * 0.28, height: sizeValue * 0.28 }).fill("#FFFFFF").opacity(alpha * 0.18).position({ x: sizeValue * 0.18, y: sizeValue * 0.16 })
        Circle({ width: sizeValue * 0.20, height: sizeValue * 0.20 }).fill(planetAccentColor(planet.id)).opacity(alpha * 0.28).position({ x: sizeValue * 0.54, y: sizeValue * 0.58 })
      }
    }
    .width(sizeValue * 1.72)
    .height(sizeValue * 1.34)
    .alignContent(Alignment.Center)
  }

  @Builder
  SolarStar(color: string, sizeValue: number, alpha: number) {
    Stack() {
      Circle({ width: sizeValue * 1.52, height: sizeValue * 1.52 })
        .fill(color)
        .opacity(alpha * 0.13)
      Circle({ width: sizeValue * 1.18, height: sizeValue * 1.18 })
        .fill(color)
        .opacity(alpha * 0.30)
      Circle({ width: sizeValue, height: sizeValue })
        .fill(color)
        .opacity(alpha * 0.70)
      Circle({ width: sizeValue * 0.58, height: sizeValue * 0.58 })
        .fill("#FFF7B8")
        .opacity(alpha * 0.76)
      Circle({ width: sizeValue * 0.22, height: sizeValue * 0.22 })
        .fill("#FFFFFF")
        .opacity(alpha * 0.50)
        .position({ x: sizeValue * 0.48, y: sizeValue * 0.42 })
    }
    .width(sizeValue * 1.52)
    .height(sizeValue * 1.52)
    .alignContent(Alignment.Center)
  }

  private detailBackgroundScale(): number {
    return clamp(1 + Math.max(0, this.zoom - 1) * 0.28, 1, 1.56)
  }

  private centerStarScale(): number {
    return clamp(0.62 + this.zoom * 0.58, 0.95, 2.45)
  }

  private centerStarGlowSize(sizeValue: number): number {
    return sizeValue * this.centerStarScale()
  }

  private centerStarGlowOpacity(baseOpacity: number): number {
    return clamp(baseOpacity + Math.max(0, this.zoom - 1) * 0.045, baseOpacity, baseOpacity + 0.10)
  }

  private orbitStrokeColor(orbit: ChapterOrbit): string {
    if (orbit.mastery >= 0.72) {
      return MINT
    }
    if (orbit.mastery >= 0.42) {
      return "#9BE7FF"
    }
    return "#C8B6FF"
  }

  private orbitLabelX(orbit: ChapterOrbit): number {
    return clamp(GALAXY_CENTER + (orbit.labelX - GALAXY_CENTER) * this.zoom - 48, 4, GALAXY_SIZE - 100)
  }

  private orbitLabelY(orbit: ChapterOrbit): number {
    return clamp(GALAXY_CENTER + (orbit.labelY - GALAXY_CENTER) * this.zoom - 12, 4, GALAXY_SIZE - 28)
  }

  private planetAngle(planet: PlanetNode): number {
    return (planet.angle + this.orbitOffset * planet.speed) % 360
  }

  private planetScale(planet: PlanetNode): number {
    const radians: number = this.planetAngle(planet) * Math.PI / 180
    return 0.86 + (Math.sin(radians) + 1) * 0.09
  }

  private planetSize(planet: PlanetNode): number {
    return clamp(planet.size * this.planetScale(planet) * 0.78, 12, 42)
  }

  private planetVisualScale(): number {
    return clamp(this.zoom, 0.75, 3)
  }

  private planetFrameWidth(planet: PlanetNode): number {
    return Math.max(54, this.planetSize(planet) * this.planetVisualScale() * 1.9)
  }

  private planetFrameHeight(planet: PlanetNode): number {
    return this.planetSize(planet) * this.planetVisualScale() * 1.34 + 18
  }

  private planetCenterX(orbit: ChapterOrbit, planet: PlanetNode): number {
    const radians: number = this.planetAngle(planet) * Math.PI / 180
    const tilt: number = orbit.tilt * Math.PI / 180
    const x: number = Math.cos(radians) * orbit.radiusX * this.zoom
    const y: number = Math.sin(radians) * orbit.radiusY * this.zoom
    return GALAXY_CENTER + x * Math.cos(tilt) - y * Math.sin(tilt)
  }

  private planetCenterY(orbit: ChapterOrbit, planet: PlanetNode): number {
    const radians: number = this.planetAngle(planet) * Math.PI / 180
    const tilt: number = orbit.tilt * Math.PI / 180
    const x: number = Math.cos(radians) * orbit.radiusX * this.zoom
    const y: number = Math.sin(radians) * orbit.radiusY * this.zoom
    return GALAXY_CENTER + x * Math.sin(tilt) + y * Math.cos(tilt)
  }

  private planetX(orbit: ChapterOrbit, planet: PlanetNode): number {
    return this.planetCenterX(orbit, planet) - this.planetFrameWidth(planet) / 2
  }

  private planetY(orbit: ChapterOrbit, planet: PlanetNode): number {
    return this.planetCenterY(orbit, planet) - this.planetFrameHeight(planet) / 2
  }
}
