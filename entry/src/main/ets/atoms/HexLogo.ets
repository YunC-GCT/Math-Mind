/**
 * MathMind 6 杈瑰舰 Logo 鈥?32脳32 娴┖鏃嬭浆 4s 寰幆
 *
 * 澶栧叚杈瑰舰 (strokeWidth 1.5) + 鍐呴儴 M 瀛椾竴绗旂敾 (strokeWidth 2)
 * 棰滆壊 #5BE3B0 涓婚钖勮嵎缁? 鏃犲～鍏? 鍦嗚绔偣 + 鍦嗚杩炴帴
 *
 * 鍔ㄧ敾 4s 寰幆:
 *   0%   rotate 0   ty  0
 *   30%  rotate 5掳  ty -1.5
 *   60%  rotate -3掳 ty  1
 *   100% rotate 0   ty  0
 *
 * 閾惧紡 setTimeout: 0鈫?0% (1200ms) + 30%鈫?0% (1200ms) + 60%鈫?00% (1600ms) = 4000ms
 *
 * ArkTS 1.1 strict 闄愬埗: struct 鍐呯鏅€氭柟娉? 鍏ㄩ儴鍔ㄧ敾閫昏緫鏀?aboutToAppear 鍐?
 * 鐢?let 澹版槑 + 绔嬪嵆鍒濆鍖栫┖鍑芥暟 + 鍚庣画璧嬪€? 閬垮厤 const 闂寘 TDZ
 */


@Component
export struct HexLogo {
  // 鐘舵€佸悕閬垮紑 ImageAttribute.rotate/translate (閬垮厤璺?base type 鏂规硶绛惧悕鍐茬獊)
  @State rotDeg: number = 0;
  @State ty: number = 0;
  private timer: number = -1;
  // 閾惧紡 setTimeout 寰幆闇€瑕侀棴鍖呭紩鐢? 浣?let 闂寘浜掔浉寮曠敤鍦?ArkTS 1.1 strict
  // 鍙兘瑙﹀彂 TDZ 缂栬瘧閿欒. 鏀圭敤 struct 瀛楁 (瀛楁璧嬪€煎悗璋冪敤鍚堟硶).
  private startCycle: () => void = (): void => { return; };

  aboutToAppear(): void {
    this.startCycle = (): void => {
      // 0% 鈫?30%: rotate 0鈫?掳, ty 0鈫?1.5
      animateTo({ duration: 1200, curve: Curve.EaseInOut }, () => {
        this.rotDeg = 5;
        this.ty = -1.5;
      });
      // 30% 鈫?60%: rotate 5掳鈫?3掳, ty -1.5鈫?
      this.timer = setTimeout(() => {
        animateTo({ duration: 1200, curve: Curve.EaseInOut }, () => {
          this.rotDeg = -3;
          this.ty = 1;
        });
        // 60% 鈫?100%: rotate -3掳鈫?, ty 1鈫?
        this.timer = setTimeout(() => {
          animateTo({ duration: 1600, curve: Curve.EaseInOut }, () => {
            this.rotDeg = 0;
            this.ty = 0;
          });
          // 100% 鍥炲埌 0%, 鍚姩涓嬩竴涓?4s 寰幆
          this.timer = setTimeout(() => { this.startCycle(); }, 1600);
        }, 1200);
      }, 1200);
    };
    this.startCycle();
  }

  aboutToDisappear(): void {
    clearTimeout(this.timer);
  }

  build() {
    Image($r('app.media.ic_brand_hex'))
      .width(32).height(32)
      // SVG 宸茬‖缂栫爜 stroke="#5BE3B0" + fill="none", Image.fillColor 鍦?ArkUI 1.1 鍙兘瑕嗙洊 SVG fill
      // 鍒?fillColor 璁?SVG fill="none" 鐢熸晥, 6 杈瑰舰淇濇寔绌哄績绾挎潯 (涓嶅彉鎴愬疄蹇?
      // Image.rotate 鎺ュ彈 RotateOptions { angle: number } 瀵硅薄, 涓嶆帴鍙?number 鐩存帴
      .rotate({ angle: this.rotDeg })
      .translate({ y: this.ty });
  }
}
