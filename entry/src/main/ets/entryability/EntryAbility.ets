import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BreakpointSystem } from '../common/BreakpointSystem';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

// 流转状态 key 常量
export const CONTINUE_TAB_INDEX = 'continueTabIndex';
export const CONTINUE_TASK_ID  = 'continueTaskId';
export const CONTINUE_SECONDS  = 'continueSeconds';
export const CONTINUE_NOTES    = 'continueNotes';
export const CONTINUE_PAGE     = 'continuePage'; // 'list' | 'detail'

export default class EntryAbility extends UIAbility {
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');

    // 接续启动：从 want 里读出源端保存的状态，写入 AppStorage 供页面读取
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      try {
        const params = want.parameters;
        if (params) {
          const tabIndex = params[CONTINUE_TAB_INDEX];
          const taskId   = params[CONTINUE_TASK_ID];
          const seconds  = params[CONTINUE_SECONDS];
          const notes    = params[CONTINUE_NOTES];
          const page     = params[CONTINUE_PAGE];

          if (tabIndex !== undefined) {
            AppStorage.SetOrCreate(CONTINUE_TAB_INDEX, tabIndex as number);
          }
          if (taskId !== undefined) {
            AppStorage.SetOrCreate(CONTINUE_TASK_ID, taskId as number);
          }
          if (seconds !== undefined) {
            AppStorage.SetOrCreate(CONTINUE_SECONDS, seconds as number);
          }
          if (notes !== undefined) {
            AppStorage.SetOrCreate(CONTINUE_NOTES, notes as string);
          }
          if (page !== undefined) {
            AppStorage.SetOrCreate(CONTINUE_PAGE, page as string);
          }
        }
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'onCreate continuation restore error: %{public}s', JSON.stringify(e));
      }
    }
  }

  // ── 流转核心：源端设备触发，保存当前状态到 wantParam ──
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, 'onContinue called');
    try {
      // 读取 AppStorage 中页面实时保存的流转数据
      const tabIndex = AppStorage.Get<number>(CONTINUE_TAB_INDEX);
      const taskId   = AppStorage.Get<number>(CONTINUE_TASK_ID);
      const seconds  = AppStorage.Get<number>(CONTINUE_SECONDS);
      const notes    = AppStorage.Get<string>(CONTINUE_NOTES);
      const page     = AppStorage.Get<string>(CONTINUE_PAGE);

      if (tabIndex !== undefined) wantParam[CONTINUE_TAB_INDEX] = tabIndex;
      if (taskId   !== undefined) wantParam[CONTINUE_TASK_ID]   = taskId;
      if (seconds  !== undefined) wantParam[CONTINUE_SECONDS]   = seconds;
      if (notes    !== undefined) wantParam[CONTINUE_NOTES]     = notes;
      if (page     !== undefined) wantParam[CONTINUE_PAGE]      = page;

      hilog.info(DOMAIN, TAG, 'onContinue saved: tab=%{public}s page=%{public}s',
        String(tabIndex), String(page));
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'onContinue error: %{public}s', JSON.stringify(e));
      return AbilityConstant.OnContinueResult.REJECT;
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  // ── 对端设备热启动时（App 已在后台）恢复状态 ──────────
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant');
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      try {
        const params = want.parameters;
        if (params) {
          const tabIndex = params[CONTINUE_TAB_INDEX];
          const taskId   = params[CONTINUE_TASK_ID];
          const seconds  = params[CONTINUE_SECONDS];
          const notes    = params[CONTINUE_NOTES];
          const page     = params[CONTINUE_PAGE];

          if (tabIndex !== undefined) AppStorage.SetOrCreate(CONTINUE_TAB_INDEX, tabIndex as number);
          if (taskId   !== undefined) AppStorage.SetOrCreate(CONTINUE_TASK_ID,   taskId as number);
          if (seconds  !== undefined) AppStorage.SetOrCreate(CONTINUE_SECONDS,   seconds as number);
          if (notes    !== undefined) AppStorage.SetOrCreate(CONTINUE_NOTES,     notes as string);
          if (page     !== undefined) AppStorage.SetOrCreate(CONTINUE_PAGE,      page as string);
        }
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'onNewWant error: %{public}s', JSON.stringify(e));
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
    this.breakpointSystem.unregister();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');
    this.breakpointSystem.register();

    windowStage.loadContent('pages/ToDoListPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent success');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }
}
