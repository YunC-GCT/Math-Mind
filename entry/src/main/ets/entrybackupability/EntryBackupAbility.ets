/**
 * EntryBackupAbility.ets — 应用数据备份/恢复扩展
 *
 * 路径: entry/src/main/ets/entrybackupability/EntryBackupAbility.ets
 * 职责: 实现 BackupExtensionAbility，定义 onBackup() / onRestore() 回调。
 *       HarmonyOS 在云端备份/恢复应用数据时调用本类。
 * 依赖: @kit.PerformanceAnalysisKit (hilog)、@kit.CoreFileKit (BackupExtensionAbility)
 *
 * 触发场景:
 *   - 用户在系统设置中触发"应用数据备份" → onBackup()
 *   - 用户在新设备上恢复备份 → onRestore(bundleVersion)
 *
 * 当前实现: 空实现 (await Promise.resolve()) + hilog 打点
 *   - 后续可在此处把 RDB 数据导出到备份目录
 *   - 实际生产需要根据 bundleVersion 做兼容性处理
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    hilog.info(DOMAIN, 'testTag', 'onBackup ok');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, 'testTag', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}