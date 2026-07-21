import { TEXT_3, F_LG, W_BOLD } from "common"

@Component
export struct ReviewGraphView {
  build() {
    Column() {
      Blank()
      Text("设计中")
        .fontSize(F_LG)
        .fontWeight(W_BOLD)
        .fontColor(TEXT_3)
      Blank()
    }
    .width("100%")
    .layoutWeight(1)
  }
}
