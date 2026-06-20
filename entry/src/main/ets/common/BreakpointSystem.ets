import mediaquery from '@ohos.mediaquery';

export class BreakpointSystem {
  private xsListener: mediaquery.MediaQueryListener =
    mediaquery.matchMediaSync('(max-width: 199vp)');
  private smListener: mediaquery.MediaQueryListener =
    mediaquery.matchMediaSync('(min-width: 200vp) and (max-width: 599vp)');
  private mdListener: mediaquery.MediaQueryListener =
    mediaquery.matchMediaSync('(min-width: 600vp) and (max-width: 839vp)');
  private lgListener: mediaquery.MediaQueryListener =
    mediaquery.matchMediaSync('(min-width: 840vp)');

  private onXsChange = (result: mediaquery.MediaQueryResult) => {
    if (result.matches) AppStorage.SetOrCreate('currentBp', 'xs');
  };
  private onSmChange = (result: mediaquery.MediaQueryResult) => {
    if (result.matches) AppStorage.SetOrCreate('currentBp', 'sm');
  };
  private onMdChange = (result: mediaquery.MediaQueryResult) => {
    if (result.matches) AppStorage.SetOrCreate('currentBp', 'md');
  };
  private onLgChange = (result: mediaquery.MediaQueryResult) => {
    if (result.matches) AppStorage.SetOrCreate('currentBp', 'lg');
  };

  register(): void {
    // ✅ 先同步初始化当前断点，再注册监听
    // 确保页面第一帧渲染时断点值已经正确
    if (this.xsListener.matches) {
      AppStorage.SetOrCreate('currentBp', 'xs');
    } else if (this.lgListener.matches) {
      AppStorage.SetOrCreate('currentBp', 'lg');
    } else if (this.mdListener.matches) {
      AppStorage.SetOrCreate('currentBp', 'md');
    } else {
      AppStorage.SetOrCreate('currentBp', 'sm');
    }

    // 再注册动态变化监听（处理折叠/旋转等运行时变化）
    this.xsListener.on('change', this.onXsChange);
    this.smListener.on('change', this.onSmChange);
    this.mdListener.on('change', this.onMdChange);
    this.lgListener.on('change', this.onLgChange);
  }

  unregister(): void {
    this.xsListener.off('change', this.onXsChange);
    this.smListener.off('change', this.onSmChange);
    this.mdListener.off('change', this.onMdChange);
    this.lgListener.off('change', this.onLgChange);
  }
}
