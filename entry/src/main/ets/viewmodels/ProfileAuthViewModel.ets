import { preferences } from "@kit.ArkData"

const STORE_NAME: string = "profile_auth"
const KEY_LOGGED_IN: string = "logged_in"
const KEY_ACCOUNT: string = "account"
const KEY_DISPLAY_NAME: string = "display_name"
const MOCK_HUAWEI_ACCOUNT: string = "huawei.user@mathmind.local"
const MOCK_HUAWEI_DISPLAY_NAME: string = "华为用户"

@Observed
export class ProfileAuthViewModel {
  loggedIn: boolean = false
  account: string = ""
  displayName: string = "未登录"
  loading: boolean = false

  private store: preferences.Preferences | null = null

  async load(context: Context): Promise<boolean> {
    try {
      const s: preferences.Preferences = await this.ensureStore(context)
      this.loggedIn = await s.get(KEY_LOGGED_IN, false) as boolean
      this.account = await s.get(KEY_ACCOUNT, "") as string
      this.displayName = await s.get(KEY_DISPLAY_NAME, "") as string
      if (!this.loggedIn || this.displayName.length === 0) {
        this.loggedIn = false
        this.displayName = "未登录"
      }
      return true
    } catch (_e) {
      this.loggedIn = false
      this.displayName = "未登录"
      return false
    }
  }

  canLoginWithHuawei(): boolean {
    return !this.loading
  }

  async loginWithHuaweiMock(context: Context): Promise<boolean> {
    if (!this.canLoginWithHuawei()) {
      return false
    }
    this.loading = true
    try {
      const s: preferences.Preferences = await this.ensureStore(context)
      await s.put(KEY_LOGGED_IN, true)
      await s.put(KEY_ACCOUNT, MOCK_HUAWEI_ACCOUNT)
      await s.put(KEY_DISPLAY_NAME, MOCK_HUAWEI_DISPLAY_NAME)
      await s.flush()
      this.loggedIn = true
      this.account = MOCK_HUAWEI_ACCOUNT
      this.displayName = MOCK_HUAWEI_DISPLAY_NAME
      return true
    } catch (_e) {
      return false
    } finally {
      this.loading = false
    }
  }

  async logout(context: Context): Promise<boolean> {
    this.loading = true
    try {
      const s: preferences.Preferences = await this.ensureStore(context)
      await s.put(KEY_LOGGED_IN, false)
      await s.delete(KEY_ACCOUNT)
      await s.delete(KEY_DISPLAY_NAME)
      await s.flush()
      this.loggedIn = false
      this.account = ""
      this.displayName = "未登录"
      return true
    } catch (_e) {
      return false
    } finally {
      this.loading = false
    }
  }

  initial(): string {
    if (!this.loggedIn || this.displayName.length === 0) {
      return "M"
    }
    return this.displayName.substring(0, 1).toUpperCase()
  }

  subtitle(): string {
    if (!this.loggedIn) {
      return "登录后查看学习档案"
    }
    return "华为账号 · 已登录"
  }

  private async ensureStore(context: Context): Promise<preferences.Preferences> {
    if (this.store === null) {
      this.store = await preferences.getPreferences(context, STORE_NAME)
    }
    return this.store
  }
}
