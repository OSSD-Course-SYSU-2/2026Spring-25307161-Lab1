import router from '@ohos.router';
import { Task } from '../entryability/Task';

@Entry
@Component
struct TaskDetailPage {
  @State task: Task | null = null;
  @State title: string = "";
  @State focusMinutes: number = 25;
  @State seconds: number = 0;
  @State running: boolean = false;
  @State lockMode: boolean = false;

  private timer: number = -1;

  aboutToAppear(): void {
    try {
      let params = router.getParams();
      if (params) {
        // 这里必须使用 as 进行类型转换，不要用索引访问
        let t = params as Task;
        this.task = t;
        this.title = t.title;
        this.focusMinutes = t.duration;
        this.seconds = t.duration * 60;
      }
    } catch (e) {
      console.error('Error:', e);
    }
  }

  aboutToDisappear(): void {
    try {
      clearInterval(this.timer);
    } catch (e) {}
  }

  private formatTime(s: number): string {
    let m = Math.floor(s / 60);
    let sec = s % 60;
    return `${m.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`;
  }

  private startTimer(): void {
    if (!this.running) return;
    this.timer = setInterval(() => {
      if (this.seconds > 0) {
        this.seconds--;
      } else {
        this.running = false;
        clearInterval(this.timer);
      }
    }, 1000);
  }

  // build 方法必须返回且只能有一个根节点
  build() {
    // 唯一的根节点 Column
    Column() {
      // 根据状态决定显示哪个界面
      if (this.lockMode) {
        // 锁机模式
        Column() {
          Text("🔒 专注模式中")
            .fontSize(22)
            .fontColor(Color.White);

          Text(this.formatTime(this.seconds))
            .fontSize(60)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: 40 });

          Text(this.title)
            .fontSize(20)
            .fontColor(Color.White)
            .margin({ top: 20 });

          TextArea({ text: this.task ? this.task.notes : "" })
            .width('80%')
            .height(140)
            .backgroundColor(Color.White)
            .margin({ top: 30 })
            .onChange((value: string) => {
              if (this.task) {
                this.task.notes = value;
              }
            });

          Button("结束专注")
            .width(200)
            .height(50)
            .backgroundColor(Color.Red)
            .fontColor(Color.White)
            .margin({ top: 40 })
            .onClick(() => {
              this.lockMode = false;
              this.running = false;
              try {
                clearInterval(this.timer);
              } catch (e) {}
            });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        // 正常模式
        Column() {
          // 顶部栏
          Row() {
            Button("返回")
              .width(80)
              .height(40)
              .onClick(() => {
                router.back();
              });

            Text("任务详情")
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .textAlign(TextAlign.Center);
          }
          .width('100%')
          .padding(12);

          // 滚动内容
          Scroll() {
            Column({ space: 16 }) {
              Text("任务标题")
                .fontSize(16)
                .fontWeight(FontWeight.Medium);

              TextInput({ text: this.title })
                .width('100%')
                .height(48)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.title = value;
                  if (this.task) {
                    this.task.title = value;
                  }
                });

              Text("专注时长(分钟)")
                .fontSize(16)
                .fontWeight(FontWeight.Medium);

              Row() {
                Button("-")
                  .width(50)
                  .height(36)
                  .onClick(() => {
                    if (!this.running && this.focusMinutes > 5) {
                      this.focusMinutes--;
                      this.seconds = this.focusMinutes * 60;
                    }
                  });

                Text(this.focusMinutes.toString())
                  .width(60)
                  .fontSize(18)
                  .textAlign(TextAlign.Center);

                Button("+")
                  .width(50)
                  .height(36)
                  .onClick(() => {
                    if (!this.running) {
                      this.focusMinutes++;
                      this.seconds = this.focusMinutes * 60;
                    }
                  });
              }
              .width('100%');

              Text("专注计时")
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 20, bottom: 10 });

              Text(this.formatTime(this.seconds))
                .fontSize(46)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center)
                .margin({ bottom: 20 });

              Row({ space: 12 }) {
                Button(this.running ? "暂停" : "开始")
                  .width(120)
                  .height(44)
                  .onClick(() => {
                    if (this.running) {
                      this.running = false;
                      try { clearInterval(this.timer); } catch (e) {}
                    } else {
                      this.running = true;
                      this.startTimer();
                    }
                  });

                Button("🔒 锁机专注")
                  .width(120)
                  .height(44)
                  .backgroundColor(Color.Black)
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.lockMode = true;
                    this.running = true;
                    this.startTimer();
                  });
              }
              .width('100%')
              .justifyContent(FlexAlign.Center);

              Button("保存并返回")
                .width('100%')
                .height(48)
                .backgroundColor(Color.Green)
                .fontColor(Color.White)
                .fontSize(16)
                .margin({ top: 20 })
                .onClick(() => {
                  if (this.task) {
                    this.task.title = this.title;
                    this.task.duration = this.focusMinutes;
                  }
                  router.back();
                });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12 });
          }
          .layoutWeight(1);
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#f5f7fa');
      }
    }
    .width('100%')
    .height('100%');
  }
}