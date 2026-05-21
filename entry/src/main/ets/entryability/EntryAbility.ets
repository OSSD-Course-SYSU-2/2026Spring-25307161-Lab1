/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'smartStudyStore';

export default class EntryAbility extends UIAbility {

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // ✅ 从 Preferences 读取持久化数据，写入 AppStorage 供页面使用
    this.initAppStorage();

    windowStage.loadContent('pages/ToDoListPage', (err: BusinessError, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      this.immersionFuc(windowStage);
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  /**
   * 初始化 AppStorage：从 Preferences 读取积分/打卡数据
   */
  private initAppStorage(): void {
    try {
      preferences.getPreferences(this.context, PREF_NAME, (err, pref) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 'getPreferences failed: %{public}s', JSON.stringify(err));
          // 读取失败时使用默认值，保证页面正常运行
          AppStorage.setOrCreate<number>('studyPoints', 0);
          AppStorage.setOrCreate<number>('checkInDays', 0);
          AppStorage.setOrCreate<number>('lastCheckDate', 0);
          return;
        }

        const points = pref.getSync('studyPoints', 0) as number;
        const days = pref.getSync('checkInDays', 0) as number;
        const lastDate = pref.getSync('lastCheckDate', 0) as number;

        AppStorage.setOrCreate<number>('studyPoints', points);
        AppStorage.setOrCreate<number>('checkInDays', days);
        AppStorage.setOrCreate<number>('lastCheckDate', lastDate);

        hilog.info(0x0000, 'testTag', 'AppStorage init: points=%{public}d, days=%{public}d', points, days);
      });
    } catch (e) {
      hilog.error(0x0000, 'testTag', 'initAppStorage error: %{public}s', JSON.stringify(e));
      AppStorage.setOrCreate<number>('studyPoints', 0);
      AppStorage.setOrCreate<number>('checkInDays', 0);
      AppStorage.setOrCreate<number>('lastCheckDate', 0);
    }
  }

  /**
   * 应用退出前将 AppStorage 数据持久化写回 Preferences
   */
  onBackground(): void {
    this.saveAppStorage();
  }

  onDestroy(): void {
    this.saveAppStorage();
  }

  private saveAppStorage(): void {
    try {
      preferences.getPreferences(this.context, PREF_NAME, (err, pref) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 'saveAppStorage getPreferences failed: %{public}s', JSON.stringify(err));
          return;
        }
        const points = AppStorage.get<number>('studyPoints') ?? 0;
        const days = AppStorage.get<number>('checkInDays') ?? 0;
        const lastDate = AppStorage.get<number>('lastCheckDate') ?? 0;

        pref.putSync('studyPoints', points);
        pref.putSync('checkInDays', days);
        pref.putSync('lastCheckDate', lastDate);
        pref.flush((flushErr) => {
          if (flushErr) {
            hilog.error(0x0000, 'testTag', 'pref flush failed: %{public}s', JSON.stringify(flushErr));
          }
        });
      });
    } catch (e) {
      hilog.error(0x0000, 'testTag', 'saveAppStorage error: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 沉浸式适配
   */
  immersionFuc(windowStage: window.WindowStage): void {
    try {
      let windowClass: window.Window = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true).catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag', '%{public}s',
          `SetWindowLayoutFullScreen failed. Cause code: ${err.code}, message: ${err.message}`);
      });
      let navigationBarArea: window.AvoidArea =
        windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      let area: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      AppStorage.setOrCreate<number>('naviIndicatorHeight',
        windowClass.getUIContext().px2vp(navigationBarArea.bottomRect.height));
      AppStorage.setOrCreate<number>('statusBarHeight', windowClass.getUIContext().px2vp(area.topRect.height));
      AppStorage.setOrCreate<window.Window>('windowClass', windowClass);
    } catch (err) {
      hilog.error(0x0000, 'testTag', '%{public}s',
        `immersionFuc failed, error code=${err.code}, message=${err.message}`);
    }
  }
}
