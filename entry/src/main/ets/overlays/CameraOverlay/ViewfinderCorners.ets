import { MINT, S_1, S_4, S_6 } from "common"

@Component
export struct ViewfinderCorners {
  build() {
    Column() {
      Stack() {
        this.TopLeftCorner()
        this.TopRightCorner()
        this.BottomLeftCorner()
        this.BottomRightCorner()
      }
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
    .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
  }

  @Builder
  TopLeftCorner() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.HorizontalLine()
      this.VerticalLine()
    }
    .width(S_6)
    .height(S_6)
    .position({ x: 0, y: 0 })
  }

  @Builder
  TopRightCorner() {
    Stack({ alignContent: Alignment.TopEnd }) {
      this.HorizontalLine()
      this.VerticalLine()
    }
    .width(S_6)
    .height(S_6)
    .position({ x: "100%", y: 0 })
    .markAnchor({ x: S_6, y: 0 })
  }

  @Builder
  BottomLeftCorner() {
    Stack({ alignContent: Alignment.BottomStart }) {
      this.HorizontalLine()
      this.VerticalLine()
    }
    .width(S_6)
    .height(S_6)
    .position({ x: 0, y: "100%" })
    .markAnchor({ x: 0, y: S_6 })
  }

  @Builder
  BottomRightCorner() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      this.HorizontalLine()
      this.VerticalLine()
    }
    .width(S_6)
    .height(S_6)
    .position({ x: "100%", y: "100%" })
    .markAnchor({ x: S_6, y: S_6 })
  }

  @Builder
  HorizontalLine() {
    Row()
      .width(S_6)
      .height(S_1 / 2)
      .backgroundColor(MINT)
  }

  @Builder
  VerticalLine() {
    Column()
      .width(S_1 / 2)
      .height(S_6)
      .backgroundColor(MINT)
  }
}
