import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { LlmConfig, DatabaseHelper } from 'common';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // ��ʼ�� LLM ����(�־û� API key/endpoint/model)
    LlmConfig.getInstance().init(this.context);
    // 初始化数据库
    DatabaseHelper.init(this.context).catch((e: Error) => {
      hilog.error(DOMAIN, 'testTag', 'DB init failed: %{public}s', e.message);
    });
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // ����ʽ״̬��:app �������쵽 status bar ����,status bar ����͸��
    // �Ӿ�Ч��:ϵͳʱ��/����/�ź�/wifi ���� app ������,�� app �޷��ν�
    windowStage.getMainWindow().then((win: window.Window) => {
      // 1. ����ʽȫ��(app �������쵽 status bar ����)
      win.setWindowLayoutFullScreen(true);
      // 2. ״̬������͸��(�� app ����͸����,�� status bar ��Ϊһ��)
      win.setSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#FFFFFFFF'  // ��ɫ����(������ɫ app ����)
      });
      // 3. ��ȡ״̬���߶Ȳ����� AppStorage,��ҳ��������ƫ�Ʊ����ص�
      try {
        const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate('statusBarHeight', px2vp(avoidArea.topRect.height));
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', 'Failed to get statusBarHeight. Cause: %{public}s', JSON.stringify(e));
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to set immersive status bar. Cause: %{public}s', JSON.stringify(err));
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}