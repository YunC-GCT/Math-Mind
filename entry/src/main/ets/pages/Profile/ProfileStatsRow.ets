import { S_4 } from "common"
import { StatsBox } from "../../atoms/StatsBox"

@Component
export struct ProfileStatsRow {
  @Prop notes: number = 0
  @Prop avg: number = 0
  @Prop today: number = 0

  build() {
    Row() {
      StatsBox({ value: this.notes + "", label: "\u7b14\u8bb0" })
      StatsBox({ value: this.avg + "%", label: "\u638c\u63e1\u7387" })
      StatsBox({ value: this.today + "", label: "\u4eca\u65e5\u65b0\u589e" })
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, bottom: S_4 })
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}