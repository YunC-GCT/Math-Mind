// skill/src/main/ets/skillability/SkillAbility.ets
// W1 块 3 之后实装:7 Intent actions 路由 + 调 common / agents 共享后端
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

export default class SkillAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.log('SkillAbility onCreate — placeholder');
    // TODO(W1 块 3): 根据 want.action 路由到对应 Agent
  }
}
