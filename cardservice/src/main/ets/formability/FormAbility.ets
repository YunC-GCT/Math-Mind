// cardservice/src/main/ets/formability/FormAbility.ets
// W1 块 3 之后实装:onAddForm / onUpdateForm 用 RDBService / APIClient 拉今日复习数据
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';

export default class FormAbility extends FormExtensionAbility {
  onAddForm(want: Object): formBindingData.FormBindingData {
    // MVP:mock 数据;W2 块 4 后接 RDBService + APIClient.cardsToday()
    const mockData = {
      title: '今日复习',
      todayCount: 5,
      totalCount: 12
    };
    return formBindingData.createFormBindingData(mockData);
  }

  onUpdateForm(formId: string): void {
    // MVP:no-op;W2 之后接 APIClient.cardsToday() 拉真数据
    console.log(`FormAbility onUpdateForm formId=${formId}`);
  }
}
