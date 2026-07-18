// ============================================================================
//  overlays/NoteDetailOverlay/NoteIconButton.ets - compact overlay icon button
// ============================================================================

import { GLASS_10, TEXT_2, R_MD } from 'common'
import { AppIcon } from '../../shared/components/AppIcon'

@Component
export struct NoteIconButton {
  @Prop name: string = 'edit'
  @Prop color: ResourceColor = TEXT_2
  @Prop bgColor: ResourceColor = GLASS_10
  @Prop boxSize: number = 36
  @Prop iconSize: number = 16
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      AppIcon({ name: this.name, iconSize: this.iconSize, color: this.color })
    }
    .width(this.boxSize)
    .height(this.boxSize)
    .borderRadius(R_MD + 2)
    .backgroundColor(this.bgColor)
    .alignContent(Alignment.Center)
    .onClick((): void => this.onTap())
  }
}
