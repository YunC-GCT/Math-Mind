import { COMMON_TAG } from 'common/src/main/ets/Index';
import { AGENTS_VERSION } from 'agents/src/main/ets/Index';

@Entry
@Component
struct Index {
  @State clicked: boolean = false;
  build() {
    RelativeContainer() {
      Text(this.clicked ? `${COMMON_TAG} | ${AGENTS_VERSION} (clicked!)` : `${COMMON_TAG} | ${AGENTS_VERSION}`)
        .id('HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.clicked = !this.clicked;  // 翻转状态,触发重渲染
        })
    }
    .height('100%')
    .width('100%')
  }
}