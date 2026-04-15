import type { BusinessError } from "@ohos:base";
import hilog from "@ohos:hilog";
import UIAbility from "@ohos:app.ability.UIAbility";
import window from "@ohos:window";
export default class EntryAbility extends UIAbility {
    onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
        windowStage.loadContent('pages/ToDoListPage', (err: BusinessError, data) => {
            if (err.code) {
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            // Immersive Adaptation
            this.immersionFuc(windowStage);
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }
    /**
     * Page immersion.
     */
    immersionFuc(windowStage: window.WindowStage): void {
        try {
            let windowClass: window.Window = windowStage.getMainWindowSync();
            windowClass.setWindowLayoutFullScreen(true).catch((err: BusinessError) => {
                hilog.error(0x0000, 'testTag', '%{public}s', `SetWindowLayoutFullScreen failed. Cause code: ${err.code}, message: ${err.message}`);
            });
            let navigationBarArea: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
            let area: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
            AppStorage.setOrCreate<number>('naviIndicatorHeight', windowClass.getUIContext().px2vp(navigationBarArea.bottomRect.height));
            AppStorage.setOrCreate<number>('statusBarHeight', windowClass.getUIContext().px2vp(area.topRect.height));
            AppStorage.setOrCreate<window.Window>('windowClass', windowClass);
        }
        catch (err) {
            hilog.error(0x0000, 'testTag', '%{public}s', `immersionFuc failed, error code=${err.code}, message=${err.message}`);
        }
    }
}
