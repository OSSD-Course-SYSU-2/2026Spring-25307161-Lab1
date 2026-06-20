import router from '@ohos.router';
import { Task } from '../entryability/Task';
import reminderAgentManager from '@ohos.reminderAgentManager';
import {
  CONTINUE_SECONDS,
  CONTINUE_NOTES,
  CONTINUE_PAGE,
  CONTINUE_TASK_ID
} from '../entryability/EntryAbility';
import mediaquery from '@ohos.mediaquery';
import display from '@ohos.display';

function genId(): number {
  return new Date().getTime();
}

function parseHourMinute(timeStr: string): number[] {
  const parts = timeStr.split(':');
  const h = parts.length > 0 ? parseInt(parts[0]) : 0;
  const min = parts.length > 1 ? parseInt(parts[1]) : 0;
  return [isNaN(h) ? 0 : h, isNaN(min) ? 0 : min];
}

async function registerReminder(title: string, timeStr: string): Promise<number> {
  try {
    const hm = parseHourMinute(timeStr);
    const hour = hm[0]; const minute = hm[1];
    const now = new Date(); const target = new Date();
    target.setHours(hour, minute, 0, 0);
    let diffSeconds = Math.floor((target.getTime() - now.getTime()) / 1000);
    if (diffSeconds <= 0) diffSeconds += 24 * 60 * 60;
    const reminder: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: diffSeconds,
      title: '智学日程提醒',
      content: `任务【${title}】即将开始`,
      expiredContent: `任务【${title}】已开始`,
      notificationId: genId() % 100000,
      actionButton: [{ title: '查看', type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE }],
      wantAgent: { pkgName: 'com.example.entry', abilityName: 'EntryAbility' },
      ringDuration: 0, snoozeTimes: 0, timeInterval: 0,
    };
    return await reminderAgentManager.publishReminder(reminder);
  } catch (e) {
    console.error('registerReminder error:', e);
    return -1;
  }
}

async function cancelReminder(reminderId: number): Promise<void> {
  if (reminderId < 0) return;
  try { await reminderAgentManager.cancelReminder(reminderId); } catch (e) {}
}

@Entry
@Component
struct TaskDetailPage {
  @State task: Task | null = null;
  @State title: string = '';
  @State taskType: string = 'daily';
  @State focusMinutes: number = 25;
  @State seconds: number = 25 * 60;
  @State running: boolean = false;
  @State lockMode: boolean = false;
  @State finished: boolean = false;

  // 笔记分类：学习类用 studyNotes，日常类用 thoughtNotes
  @State studyNotes: string = '';      // 学习笔记
  @State thoughtNotes: string = '';    // 记录想法
  @State attachedFiles: string[] = []; // 导入的资料文件名列表（模拟）

  // 提醒
  @State reminderEnabled: boolean = false;
  @State reminderTime: string = '09:00';
  @State showReminderPicker: boolean = false;
  @State reminderHour: number = 9;
  @State reminderMinute: number = 0;

  // 断点（同 ToDoListPage，在 aboutToAppear 里动态创建）
  @State currentBp: string = 'sm';
  private bpListenerLg: mediaquery.MediaQueryListener | null = null;

  // 流转恢复
  @StorageProp(CONTINUE_SECONDS) continueSeconds: number = -1;
  @StorageProp(CONTINUE_NOTES)   continueNotes: string = '';

  private timer: number = -1;
  private currentReminderId: number = -1;

  // 是否学习类任务
  private isStudyTask(): boolean {
    return this.taskType === 'practice' || this.taskType === 'word' || this.taskType === 'review';
  }

  aboutToAppear(): void {
    // 用窗口像素宽度直接计算 vp 判断断点
    try {
      const dm = display.getDefaultDisplaySync();
      const widthVp = dm.width / dm.densityPixels;
      if (widthVp >= 840) {
        this.currentBp = 'lg';
      } else if (widthVp < 200) {
        this.currentBp = 'xs';
      } else {
        this.currentBp = 'sm';
      }
    } catch (e) {
      this.currentBp = 'sm';
    }
    // 注册监听处理运行时变化
    this.bpListenerLg = mediaquery.matchMediaSync('(min-width: 840vp)');
    this.bpListenerLg.on('change', (r: mediaquery.MediaQueryResult) => {
      this.currentBp = r.matches ? 'lg' : 'sm';
    });

    try {
      const params = router.getParams();
      if (params) {
        const t = params as Task;
        this.task = t;
        this.title = t.title !== undefined ? t.title : '';
        this.taskType = t.taskType !== undefined ? t.taskType : 'daily';
        this.focusMinutes = (t.duration !== undefined && t.duration > 0) ? t.duration : 25;
        this.seconds = this.focusMinutes * 60;
        this.currentReminderId = t.reminderId !== undefined ? t.reminderId : -1;
        this.reminderEnabled = this.currentReminderId >= 0;
        this.reminderTime = t.startTime !== undefined ? t.startTime : '09:00';
        const hm = parseHourMinute(this.reminderTime);
        this.reminderHour = hm[0];
        this.reminderMinute = hm[1];
        // 根据笔记类型加载内容
        if (this.isStudyTask()) {
          this.studyNotes = t.notes !== undefined ? t.notes : '';
        } else {
          this.thoughtNotes = t.notes !== undefined ? t.notes : '';
        }
      }
    } catch (e) {
      console.error('aboutToAppear error:', e);
    }

    // ── 流转恢复：用对端保存的计时进度和笔记覆盖 ──────
    try {
      if (this.continueSeconds >= 0) {
        this.seconds = this.continueSeconds;
        // 清除避免重复恢复
        AppStorage.SetOrCreate(CONTINUE_SECONDS, -1);
      }
      if (this.continueNotes !== '') {
        if (this.isStudyTask()) {
          this.studyNotes = this.continueNotes;
        } else {
          this.thoughtNotes = this.continueNotes;
        }
        AppStorage.SetOrCreate(CONTINUE_NOTES, '');
      }
    } catch (e) {
      console.error('流转恢复error:', e);
    }
  }

  aboutToDisappear(): void {
    this.stopTimer();
    try {
      if (this.bpListenerLg) this.bpListenerLg.off('change');
    } catch (e) {}
  }

  private startTimer(): void {
    this.stopTimer();
    this.timer = setInterval(() => {
      if (this.seconds > 0) {
        this.seconds--;
        // 每5秒实时保存计时进度到流转状态
        if (this.seconds % 5 === 0) {
          AppStorage.SetOrCreate(CONTINUE_SECONDS, this.seconds);
          const currentNotes = this.isStudyTask() ? this.studyNotes : this.thoughtNotes;
          AppStorage.SetOrCreate(CONTINUE_NOTES, currentNotes);
        }
      } else {
        this.stopTimer();
        this.running = false;
        this.finished = true;
        AppStorage.SetOrCreate(CONTINUE_SECONDS, -1);
      }
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timer !== -1) {
      try { clearInterval(this.timer); } catch (e) {}
      this.timer = -1;
    }
  }

  private formatTime(s: number): string {
    const m = Math.floor(s / 60).toString().padStart(2, '0');
    const sec = (s % 60).toString().padStart(2, '0');
    return `${m}:${sec}`;
  }

  private resetTimer(): void {
    this.stopTimer(); this.running = false;
    this.finished = false; this.seconds = this.focusMinutes * 60;
  }

  private async enableReminder(): Promise<void> {
    const timeStr = `${this.reminderHour.toString().padStart(2,'0')}:${this.reminderMinute.toString().padStart(2,'0')}`;
    this.reminderTime = timeStr;
    await cancelReminder(this.currentReminderId);
    const newId = await registerReminder(this.title, timeStr);
    this.currentReminderId = newId;
    this.reminderEnabled = newId >= 0;
    if (this.task) this.task.reminderId = newId;
    this.showReminderPicker = false;
  }

  private async disableReminder(): Promise<void> {
    await cancelReminder(this.currentReminderId);
    this.currentReminderId = -1;
    this.reminderEnabled = false;
    if (this.task) this.task.reminderId = -1;
  }

  // 模拟导入文件（实际项目可接入文件选择器）
  private simulateImportFile(): void {
    const mockFiles = ['高数笔记.pdf', '线代公式.docx', '英语单词表.xlsx', '大物实验报告.pdf'];
    const picked = mockFiles[this.attachedFiles.length % mockFiles.length];
    this.attachedFiles = [...this.attachedFiles, picked];
  }

  private saveAndBack(): void {
    // 离开详情页时清理流转状态
    try {
      AppStorage.SetOrCreate(CONTINUE_SECONDS, -1);
      AppStorage.SetOrCreate(CONTINUE_NOTES, '');
      AppStorage.SetOrCreate(CONTINUE_PAGE, 'list');
    } catch (e) {}
    if (this.task) {
      this.task.title = this.title;
      this.task.notes = this.isStudyTask() ? this.studyNotes : this.thoughtNotes;
      this.task.duration = this.focusMinutes;
      this.task.reminderId = this.currentReminderId;
    }
    try { router.back(); } catch (e) {}
  }

  private getTaskLabel(t: string): string {
    if (t === 'daily')    return '日常';
    if (t === 'practice') return '刷题';
    if (t === 'word')     return '单词';
    if (t === 'review')   return '复习';
    return '日常';
  }

  build() {
    Column() {
      if (this.lockMode) {
        this.buildLockScreen();
      } else if (this.currentBp === 'lg') {
        // 平板：左右分栏布局
        this.buildTabletScreen();
      } else {
        // 手机/折叠屏：单列滚动
        this.buildNormalScreen();
      }
    }
    .width('100%').height('100%');
  }

  @Builder
  buildLockScreen() {
    Column({ space: 0 }) {
      Text(this.finished ? '🎉 专注完成！' : '🔒 专注模式中')
        .fontSize(20)
        .fontColor(this.finished ? '#52c41a' : 'rgba(255,255,255,0.85)')
        .margin({ top: 80 });
      Text(this.formatTime(this.seconds))
        .fontSize(72).fontWeight(FontWeight.Bold)
        .fontColor(this.finished ? '#52c41a' : Color.White)
        .letterSpacing(4).margin({ top: 32 });
      Text(this.title)
        .fontSize(18).fontColor('rgba(255,255,255,0.7)').margin({ top: 16 })
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 32, right: 32 });
      Stack({ alignContent: Alignment.Start }) {
        Row().width(280).height(6).backgroundColor('rgba(255,255,255,0.2)').borderRadius(3);
        Row()
          .width(this.focusMinutes > 0
            ? `${Math.round((1 - this.seconds / (this.focusMinutes * 60)) * 280)}px` : '0px')
          .height(6).backgroundColor(this.finished ? '#52c41a' : '#ff6b35').borderRadius(3);
      }.width(280).margin({ top: 32 });
      Text(`已专注 ${Math.round((this.focusMinutes * 60 - this.seconds) / 60)} 分钟`)
        .fontSize(13).fontColor('rgba(255,255,255,0.5)').margin({ top: 10 });

      // 锁机模式下的笔记（根据分类显示不同标题）
      Text(this.isStudyTask() ? '📝 学习笔记' : '💭 记录想法')
        .fontSize(14).fontColor('rgba(255,255,255,0.6)')
        .alignSelf(ItemAlign.Start).padding({ left: 32 }).margin({ top: 36 });
      TextArea({
        text: this.isStudyTask() ? this.studyNotes : this.thoughtNotes,
        placeholder: this.isStudyTask() ? '记录知识点、公式、解题思路…' : '记录当下的想法和感受…'
      })
        .width('85%').height(120)
        .backgroundColor('rgba(255,255,255,0.1)').borderRadius(12)
        .fontColor(Color.White).placeholderColor('rgba(255,255,255,0.3)')
        .fontSize(14).margin({ top: 8 })
        .onChange((v: string) => {
          if (this.isStudyTask()) { this.studyNotes = v; }
          else { this.thoughtNotes = v; }
        });

      Blank();
      Row({ space: 16 }) {
        if (!this.finished) {
          Button('结束专注')
            .width(140).height(48)
            .backgroundColor('rgba(255,255,255,0.15)').fontColor(Color.White).borderRadius(24)
            .onClick(() => { this.stopTimer(); this.running = false; this.lockMode = false; });
        }
        Button(this.finished ? '完成，返回' : '保存并退出')
          .width(140).height(48)
          .backgroundColor(this.finished ? '#52c41a' : '#ff6b35')
          .fontColor(Color.White).borderRadius(24)
          .onClick(() => { this.lockMode = false; this.saveAndBack(); });
      }.margin({ bottom: 48 });
    }
    .width('100%').height('100%').backgroundColor('#1a1a2e')
    .justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Center);
  }

  @Builder
  buildNormalScreen() {
    Column() {
      // 顶部导航
      Row() {
        Button({ type: ButtonType.Normal }) {
          Text('‹ 返回').fontSize(16).fontColor('#ff6b35');
        }
        .backgroundColor(Color.Transparent).height(40)
        .padding({ left: 4, right: 12 })
        .onClick(() => { try { router.back(); } catch (e) {} });
        Text('任务详情')
          .fontSize(18).fontWeight(FontWeight.Medium).fontColor('#1a1a1a')
          .layoutWeight(1).textAlign(TextAlign.Center);
        Row().width(80);
      }
      .width('100%').height(56).padding({ left: 8, right: 16 }).backgroundColor(Color.White);

      Divider().strokeWidth(0.5).color('#f0f0f0');

      Scroll() {
        Column({ space: 0 }) {

          // ── Section: 任务信息 ──────────────────────────
          Column({ space: 16 }) {
            Text('任务标题').fontSize(13).fontColor('#8c8c8c').fontWeight(FontWeight.Medium);
            TextInput({ text: this.title, placeholder: '输入任务名称' })
              .height(44).backgroundColor('#f5f7fa').borderRadius(8)
              .padding({ left: 12, right: 12 }).fontSize(15)
              .onChange((v: string) => { this.title = v; });
            if (this.task) {
              Row({ space: 8 }) {
                Text(this.getTaskLabel(this.taskType))
                  .fontSize(12).fontColor('#096dd9').backgroundColor('#e6f7ff')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                Text(`${this.task.startTime} ~ ${this.task.endTime}`)
                  .fontSize(12).fontColor('#595959').backgroundColor('#f5f5f5')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                Text(`${this.task.duration}min`)
                  .fontSize(12).fontColor('#722ed1').backgroundColor('#f9f0ff')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                // 笔记模式标签
                Text(this.isStudyTask() ? '📝 学习笔记模式' : '💭 记录想法模式')
                  .fontSize(11)
                  .fontColor(this.isStudyTask() ? '#722ed1' : '#08979c')
                  .backgroundColor(this.isStudyTask() ? '#f9f0ff' : '#e6fffb')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
              }
            }
          }
          .width('100%').padding(16).backgroundColor(Color.White)
          .alignItems(HorizontalAlign.Start).margin({ top: 8 });

          // ── Section: 笔记（根据任务类型显示不同内容）──
          if (this.isStudyTask()) {
            // 学习类：学习笔记 + 导入资料
            Column({ space: 14 }) {
              // 学习笔记
              Column({ space: 8 }) {
                Row() {
                  Text('📝 学习笔记').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1a1a1a');
                  Blank();
                  Text('支持记录知识点、公式、题解').fontSize(11).fontColor('#8c8c8c');
                }
                TextArea({ text: this.studyNotes, placeholder: '记录知识点、公式、解题思路、易错点…' })
                  .width('100%').height(160).backgroundColor('#f5f7fa')
                  .borderRadius(8).fontSize(14).fontColor('#1a1a1a')
                  .onChange((v: string) => { this.studyNotes = v; });
              }.alignItems(HorizontalAlign.Start);

              Divider().strokeWidth(0.5).color('#f0f0f0');

              // 导入资料
              Column({ space: 10 }) {
                Row() {
                  Text('📎 学习资料').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1a1a1a');
                  Blank();
                  Button('+ 导入资料')
                    .height(32).fontSize(13)
                    .backgroundColor('#f9f0ff').fontColor('#722ed1')
                    .borderRadius(16).padding({ left: 12, right: 12 })
                    .onClick(() => { this.simulateImportFile(); });
                }

                if (this.attachedFiles.length === 0) {
                  Row() {
                    Text('暂无资料，点击右上角导入').fontSize(13).fontColor('#bfbfbf');
                  }
                  .width('100%')
                  .padding({ top: 16, bottom: 16 })
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor('#fafafa').borderRadius(8);
                } else {
                  Column({ space: 8 }) {
                    ForEach(this.attachedFiles, (fileName: string, fileIdx: number) => {
                      Row({ space: 10 }) {
                        Text(this.getFileIcon(fileName)).fontSize(20);
                        Column({ space: 2 }) {
                          Text(fileName)
                            .fontSize(14).fontColor('#1a1a1a')
                            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
                          Text('已导入').fontSize(11).fontColor('#52c41a');
                        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                        Text('✕').fontSize(16).fontColor('#bfbfbf')
                          .onClick(() => {
                            const newFiles = this.attachedFiles.filter((f, i) => i !== fileIdx);
                            this.attachedFiles = newFiles;
                          });
                      }
                      .width('100%')
                      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                      .backgroundColor('#fafafa').borderRadius(8);
                    }, (fileName: string) => fileName)
                  }
                }
              }.alignItems(HorizontalAlign.Start);
            }
            .width('100%').padding(16).backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Start).margin({ top: 8 });

          } else {
            // 日常类：记录想法
            Column({ space: 10 }) {
              Row() {
                Text('💭 记录想法').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1a1a1a');
                Blank();
                Text('记录你的日常感悟').fontSize(11).fontColor('#8c8c8c');
              }
              TextArea({ text: this.thoughtNotes, placeholder: '今天有什么想法、感受或者值得记录的事情…' })
                .width('100%').height(200).backgroundColor('#f5f7fa')
                .borderRadius(8).fontSize(14).fontColor('#1a1a1a')
                .onChange((v: string) => { this.thoughtNotes = v; });
            }
            .width('100%').padding(16).backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Start).margin({ top: 8 });
          }

          // ── Section: 闹钟提醒 ──────────────────────────
          Column({ space: 14 }) {
            Text('闹钟提醒').fontSize(13).fontColor('#8c8c8c').fontWeight(FontWeight.Medium);
            Row() {
              Column({ space: 3 }) {
                Text(this.reminderEnabled ? '🔔 提醒已开启' : '🔕 提醒未开启')
                  .fontSize(15).fontColor('#1a1a1a');
                Text(this.reminderEnabled ? `提醒时间：${this.reminderTime}` : '点击右侧开关设置提醒')
                  .fontSize(12).fontColor('#8c8c8c');
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Toggle({ type: ToggleType.Switch, isOn: this.reminderEnabled })
                .selectedColor('#ff6b35')
                .onChange((v: boolean) => {
                  if (v) { this.showReminderPicker = true; }
                  else { this.disableReminder(); }
                });
            }.width('100%');

            if (this.showReminderPicker || this.reminderEnabled) {
              Column({ space: 12 }) {
                Text('选择提醒时间').fontSize(13).fontColor('#8c8c8c');
                Row({ space: 12 }) {
                  Column({ space: 6 }) {
                    Text('时').fontSize(12).fontColor('#8c8c8c');
                    Row({ space: 8 }) {
                      Button('－').width(32).height(32).fontSize(16)
                        .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                        .onClick(() => { if (this.reminderHour > 0) this.reminderHour--; });
                      Text(this.reminderHour.toString().padStart(2,'0'))
                        .fontSize(20).fontWeight(FontWeight.Bold).width(40).textAlign(TextAlign.Center);
                      Button('＋').width(32).height(32).fontSize(16)
                        .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                        .onClick(() => { if (this.reminderHour < 23) this.reminderHour++; });
                    }
                  }.alignItems(HorizontalAlign.Center);
                  Text(':').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
                  Column({ space: 6 }) {
                    Text('分').fontSize(12).fontColor('#8c8c8c');
                    Row({ space: 8 }) {
                      Button('－').width(32).height(32).fontSize(16)
                        .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                        .onClick(() => { if (this.reminderMinute >= 5) this.reminderMinute -= 5; });
                      Text(this.reminderMinute.toString().padStart(2,'0'))
                        .fontSize(20).fontWeight(FontWeight.Bold).width(40).textAlign(TextAlign.Center);
                      Button('＋').width(32).height(32).fontSize(16)
                        .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                        .onClick(() => { if (this.reminderMinute <= 54) this.reminderMinute += 5; });
                    }
                  }.alignItems(HorizontalAlign.Center);
                }
                .width('100%').justifyContent(FlexAlign.Center);
                Row({ space: 8 }) {
                  ForEach(['07:00','08:00','09:00','12:00','19:00','21:00'], (t: string) => {
                    Text(t)
                      .fontSize(12)
                      .fontColor(this.reminderTime === t ? Color.White : '#595959')
                      .backgroundColor(this.reminderTime === t ? '#ff6b35' : '#f5f5f5')
                      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                      .borderRadius(14)
                      .onClick(() => {
                        const hm = parseHourMinute(t);
                        this.reminderHour = hm[0]; this.reminderMinute = hm[1]; this.reminderTime = t;
                      });
                  })
                }
                Button('确认设置提醒')
                  .width('100%').height(44)
                  .backgroundColor('#ff6b35').fontColor(Color.White).borderRadius(22)
                  .onClick(() => { this.enableReminder(); });
              }
              .width('100%').padding(12).backgroundColor('#fafafa').borderRadius(10);
            }
          }
          .width('100%').padding(16).backgroundColor(Color.White)
          .alignItems(HorizontalAlign.Start).margin({ top: 8 });

          // ── Section: 专注计时 ──────────────────────────
          Column({ space: 16 }) {
            Text('专注计时').fontSize(13).fontColor('#8c8c8c').fontWeight(FontWeight.Medium);
            Text(this.formatTime(this.seconds))
              .fontSize(56).fontWeight(FontWeight.Bold)
              .fontColor(this.running ? '#ff6b35' : '#1a1a1a')
              .width('100%').textAlign(TextAlign.Center);
            Row() {
              Text('时长 (分钟)').fontSize(14).fontColor('#8c8c8c').layoutWeight(1);
              Row({ space: 0 }) {
                Button('－').width(36).height(36).fontSize(18)
                  .backgroundColor('#f5f5f5').fontColor(this.running ? '#d9d9d9' : '#1a1a1a').borderRadius(18)
                  .onClick(() => {
                    if (!this.running && this.focusMinutes > 5) {
                      this.focusMinutes--; this.seconds = this.focusMinutes * 60;
                    }
                  });
                Text(this.focusMinutes.toString())
                  .width(48).fontSize(16).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center);
                Button('＋').width(36).height(36).fontSize(18)
                  .backgroundColor('#f5f5f5').fontColor(this.running ? '#d9d9d9' : '#1a1a1a').borderRadius(18)
                  .onClick(() => {
                    if (!this.running && this.focusMinutes < 120) {
                      this.focusMinutes++; this.seconds = this.focusMinutes * 60;
                    }
                  });
              }
            }
            Row({ space: 8 }) {
              ForEach([15, 25, 45, 60], (min: number) => {
                Button(`${min}min`)
                  .height(32).fontSize(13)
                  .backgroundColor(this.focusMinutes === min ? '#ff6b35' : '#f5f5f5')
                  .fontColor(this.focusMinutes === min ? Color.White : '#595959')
                  .borderRadius(16).padding({ left: 12, right: 12 })
                  .onClick(() => {
                    if (!this.running) { this.focusMinutes = min; this.seconds = min * 60; }
                  });
              })
            }
            Row({ space: 12 }) {
              Button(this.running ? '⏸ 暂停' : '▶ 开始')
                .layoutWeight(1).height(48).fontSize(15)
                .backgroundColor(this.running ? '#faad14' : '#ff6b35')
                .fontColor(Color.White).borderRadius(24)
                .onClick(() => {
                  if (this.running) { this.stopTimer(); this.running = false; }
                  else { this.running = true; this.startTimer(); }
                });
              Button('↺ 重置').width(80).height(48).fontSize(15)
                .backgroundColor('#f5f5f5').fontColor('#595959').borderRadius(24)
                .onClick(() => { this.resetTimer(); });
            }
            Button('🔒  锁机专注')
              .width('100%').height(48).fontSize(15)
              .backgroundColor('#1a1a2e').fontColor(Color.White).borderRadius(24)
              .onClick(() => {
                this.stopTimer(); this.running = true;
                this.lockMode = true; this.startTimer();
              });
          }
          .width('100%').padding(16).backgroundColor(Color.White)
          .alignItems(HorizontalAlign.Start).margin({ top: 8 });

          Row().height(32);
        }.width('100%');
      }
      .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring);

      // 底部操作栏
      Row({ space: 12 }) {
        Button('放弃更改')
          .layoutWeight(1).height(48).backgroundColor('#f5f5f5')
          .fontColor('#595959').borderRadius(24)
          .onClick(() => { try { router.back(); } catch (e) {} });
        Button('保存并返回')
          .layoutWeight(2).height(48).backgroundColor('#ff6b35')
          .fontColor(Color.White).fontSize(15).borderRadius(24)
          .onClick(() => { this.saveAndBack(); });
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      .backgroundColor(Color.White);
    }
    .width('100%').height('100%').backgroundColor('#f5f7fa');
  }

  // ══════════════════════════════════════════════
  // 平板布局：左右分栏
  // 左栏：任务信息 + 专注计时
  // 右栏：笔记 + 学习资料 + 闹钟提醒
  // ══════════════════════════════════════════════
  @Builder
  buildTabletScreen() {
    Column() {
      // 顶部导航栏
      Row() {
        Button({ type: ButtonType.Normal }) {
          Text('‹ 返回').fontSize(16).fontColor('#ff6b35');
        }
        .backgroundColor(Color.Transparent).height(40)
        .padding({ left: 4, right: 12 })
        .onClick(() => { try { router.back(); } catch (e) {} });

        Text('任务详情')
          .fontSize(20).fontWeight(FontWeight.Medium).fontColor('#1a1a1a')
          .layoutWeight(1).textAlign(TextAlign.Center);

        // 平板右上角直接显示保存按钮
        Button('保存并返回')
          .height(36).backgroundColor('#ff6b35')
          .fontColor(Color.White).fontSize(14).borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onClick(() => { this.saveAndBack(); });
      }
      .width('100%').height(56)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White);

      Divider().strokeWidth(0.5).color('#f0f0f0');

      // 左右分栏主体
      Row() {
        // ── 左栏：任务信息 + 专注计时 ──────────────
        Scroll() {
          Column({ space: 0 }) {
            // 任务信息
            Column({ space: 16 }) {
              Text('任务标题').fontSize(13).fontColor('#8c8c8c').fontWeight(FontWeight.Medium);
              TextInput({ text: this.title, placeholder: '输入任务名称' })
                .height(44).backgroundColor('#f5f7fa').borderRadius(8)
                .padding({ left: 12, right: 12 }).fontSize(15)
                .onChange((v: string) => { this.title = v; });
              if (this.task) {
                Row({ space: 8 }) {
                  Text(this.getTaskLabel(this.taskType))
                    .fontSize(12).fontColor('#096dd9').backgroundColor('#e6f7ff')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                  Text(`${this.task.startTime} ~ ${this.task.endTime}`)
                    .fontSize(12).fontColor('#595959').backgroundColor('#f5f5f5')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                  Text(`${this.task.duration}min`)
                    .fontSize(12).fontColor('#722ed1').backgroundColor('#f9f0ff')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                  Text(this.isStudyTask() ? '📝 学习笔记模式' : '💭 记录想法模式')
                    .fontSize(11)
                    .fontColor(this.isStudyTask() ? '#722ed1' : '#08979c')
                    .backgroundColor(this.isStudyTask() ? '#f9f0ff' : '#e6fffb')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6);
                }
              }
            }
            .width('100%').padding(20).backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Start).margin({ top: 8, left: 8, right: 4 })
            .borderRadius(12);

            // 专注计时
            Column({ space: 16 }) {
              Text('专注计时').fontSize(13).fontColor('#8c8c8c').fontWeight(FontWeight.Medium);

              Text(this.formatTime(this.seconds))
                .fontSize(64).fontWeight(FontWeight.Bold)
                .fontColor(this.running ? '#ff6b35' : '#1a1a1a')
                .width('100%').textAlign(TextAlign.Center);

              Row() {
                Text('时长 (分钟)').fontSize(14).fontColor('#8c8c8c').layoutWeight(1);
                Row({ space: 0 }) {
                  Button('－').width(36).height(36).fontSize(18)
                    .backgroundColor('#f5f5f5')
                    .fontColor(this.running ? '#d9d9d9' : '#1a1a1a').borderRadius(18)
                    .onClick(() => {
                      if (!this.running && this.focusMinutes > 5) {
                        this.focusMinutes--; this.seconds = this.focusMinutes * 60;
                      }
                    });
                  Text(this.focusMinutes.toString())
                    .width(48).fontSize(16).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center);
                  Button('＋').width(36).height(36).fontSize(18)
                    .backgroundColor('#f5f5f5')
                    .fontColor(this.running ? '#d9d9d9' : '#1a1a1a').borderRadius(18)
                    .onClick(() => {
                      if (!this.running && this.focusMinutes < 120) {
                        this.focusMinutes++; this.seconds = this.focusMinutes * 60;
                      }
                    });
                }
              }

              Row({ space: 8 }) {
                ForEach([15, 25, 45, 60], (min: number) => {
                  Button(`${min}min`)
                    .height(32).fontSize(13)
                    .backgroundColor(this.focusMinutes === min ? '#ff6b35' : '#f5f5f5')
                    .fontColor(this.focusMinutes === min ? Color.White : '#595959')
                    .borderRadius(16).padding({ left: 12, right: 12 })
                    .onClick(() => {
                      if (!this.running) { this.focusMinutes = min; this.seconds = min * 60; }
                    });
                })
              }

              Row({ space: 12 }) {
                Button(this.running ? '⏸ 暂停' : '▶ 开始')
                  .layoutWeight(1).height(48).fontSize(15)
                  .backgroundColor(this.running ? '#faad14' : '#ff6b35')
                  .fontColor(Color.White).borderRadius(24)
                  .onClick(() => {
                    if (this.running) { this.stopTimer(); this.running = false; }
                    else { this.running = true; this.startTimer(); }
                  });
                Button('↺ 重置').width(80).height(48).fontSize(15)
                  .backgroundColor('#f5f5f5').fontColor('#595959').borderRadius(24)
                  .onClick(() => { this.resetTimer(); });
              }

              Button('🔒  锁机专注')
                .width('100%').height(48).fontSize(15)
                .backgroundColor('#1a1a2e').fontColor(Color.White).borderRadius(24)
                .onClick(() => {
                  this.stopTimer(); this.running = true;
                  this.lockMode = true; this.startTimer();
                });
            }
            .width('100%').padding(20).backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 8, left: 8, right: 4, bottom: 8 })
            .borderRadius(12);
          }
          .width('100%');
        }
        .layoutWeight(1).height('100%').scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);

        // 分割线
        Divider().vertical(true).strokeWidth(1).color('#f0f0f0').height('100%');

        // ── 右栏：笔记 + 资料 + 闹钟 ──────────────
        Scroll() {
          Column({ space: 0 }) {
            // 笔记区（根据任务类型切换）
            if (this.isStudyTask()) {
              Column({ space: 14 }) {
                // 学习笔记
                Column({ space: 8 }) {
                  Row() {
                    Text('📝 学习笔记').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1a1a1a');
                    Blank();
                    Text('记录知识点、公式、题解').fontSize(11).fontColor('#8c8c8c');
                  }
                  TextArea({ text: this.studyNotes, placeholder: '记录知识点、公式、解题思路、易错点…' })
                    .width('100%').height(200).backgroundColor('#f5f7fa')
                    .borderRadius(8).fontSize(14).fontColor('#1a1a1a')
                    .onChange((v: string) => { this.studyNotes = v; });
                }.alignItems(HorizontalAlign.Start);

                Divider().strokeWidth(0.5).color('#f0f0f0');

                // 学习资料
                Column({ space: 10 }) {
                  Row() {
                    Text('📎 学习资料').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1a1a1a');
                    Blank();
                    Button('+ 导入资料')
                      .height(32).fontSize(13)
                      .backgroundColor('#f9f0ff').fontColor('#722ed1')
                      .borderRadius(16).padding({ left: 12, right: 12 })
                      .onClick(() => { this.simulateImportFile(); });
                  }
                  if (this.attachedFiles.length === 0) {
                    Row() {
                      Text('暂无资料，点击右上角导入').fontSize(13).fontColor('#bfbfbf');
                    }
                    .width('100%').padding({ top: 16, bottom: 16 })
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor('#fafafa').borderRadius(8);
                  } else {
                    Column({ space: 8 }) {
                      ForEach(this.attachedFiles, (fileName: string, fileIdx: number) => {
                        Row({ space: 10 }) {
                          Text(this.getFileIcon(fileName)).fontSize(20);
                          Column({ space: 2 }) {
                            Text(fileName).fontSize(14).fontColor('#1a1a1a')
                              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
                            Text('已导入').fontSize(11).fontColor('#52c41a');
                          }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                          Text('✕').fontSize(16).fontColor('#bfbfbf')
                            .onClick(() => {
                              const newFiles = this.attachedFiles.filter((f, i) => i !== fileIdx);
                              this.attachedFiles = newFiles;
                            });
                        }
                        .width('100%')
                        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                        .backgroundColor('#fafafa').borderRadius(8);
                      }, (fileName: string) => fileName)
                    }
                  }
                }.alignItems(HorizontalAlign.Start);
              }
              .width('100%').padding(20).backgroundColor(Color.White)
              .alignItems(HorizontalAlign.Start)
              .margin({ top: 8, left: 4, right: 8 }).borderRadius(12);
            } else {
              Column({ space: 10 }) {
                Row() {
                  Text('💭 记录想法').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#1a1a1a');
                  Blank();
                  Text('记录你的日常感悟').fontSize(11).fontColor('#8c8c8c');
                }
                TextArea({ text: this.thoughtNotes, placeholder: '今天有什么想法、感受或者值得记录的事情…' })
                  .width('100%').height(240).backgroundColor('#f5f7fa')
                  .borderRadius(8).fontSize(14).fontColor('#1a1a1a')
                  .onChange((v: string) => { this.thoughtNotes = v; });
              }
              .width('100%').padding(20).backgroundColor(Color.White)
              .alignItems(HorizontalAlign.Start)
              .margin({ top: 8, left: 4, right: 8 }).borderRadius(12);
            }

            // 闹钟提醒
            Column({ space: 14 }) {
              Text('闹钟提醒').fontSize(13).fontColor('#8c8c8c').fontWeight(FontWeight.Medium);
              Row() {
                Column({ space: 3 }) {
                  Text(this.reminderEnabled ? '🔔 提醒已开启' : '🔕 提醒未开启')
                    .fontSize(15).fontColor('#1a1a1a');
                  Text(this.reminderEnabled ? `提醒时间：${this.reminderTime}` : '点击右侧开关设置提醒')
                    .fontSize(12).fontColor('#8c8c8c');
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Toggle({ type: ToggleType.Switch, isOn: this.reminderEnabled })
                  .selectedColor('#ff6b35')
                  .onChange((v: boolean) => {
                    if (v) { this.showReminderPicker = true; }
                    else { this.disableReminder(); }
                  });
              }.width('100%');

              if (this.showReminderPicker || this.reminderEnabled) {
                Column({ space: 12 }) {
                  Text('选择提醒时间').fontSize(13).fontColor('#8c8c8c');
                  Row({ space: 12 }) {
                    Column({ space: 6 }) {
                      Text('时').fontSize(12).fontColor('#8c8c8c');
                      Row({ space: 8 }) {
                        Button('－').width(32).height(32).fontSize(16)
                          .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                          .onClick(() => { if (this.reminderHour > 0) this.reminderHour--; });
                        Text(this.reminderHour.toString().padStart(2,'0'))
                          .fontSize(20).fontWeight(FontWeight.Bold).width(40).textAlign(TextAlign.Center);
                        Button('＋').width(32).height(32).fontSize(16)
                          .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                          .onClick(() => { if (this.reminderHour < 23) this.reminderHour++; });
                      }
                    }.alignItems(HorizontalAlign.Center);
                    Text(':').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
                    Column({ space: 6 }) {
                      Text('分').fontSize(12).fontColor('#8c8c8c');
                      Row({ space: 8 }) {
                        Button('－').width(32).height(32).fontSize(16)
                          .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                          .onClick(() => { if (this.reminderMinute >= 5) this.reminderMinute -= 5; });
                        Text(this.reminderMinute.toString().padStart(2,'0'))
                          .fontSize(20).fontWeight(FontWeight.Bold).width(40).textAlign(TextAlign.Center);
                        Button('＋').width(32).height(32).fontSize(16)
                          .backgroundColor('#f5f5f5').fontColor('#1a1a1a').borderRadius(16)
                          .onClick(() => { if (this.reminderMinute <= 54) this.reminderMinute += 5; });
                      }
                    }.alignItems(HorizontalAlign.Center);
                  }.width('100%').justifyContent(FlexAlign.Center);

                  Row({ space: 8 }) {
                    ForEach(['07:00','08:00','09:00','12:00','19:00','21:00'], (t: string) => {
                      Text(t)
                        .fontSize(12)
                        .fontColor(this.reminderTime === t ? Color.White : '#595959')
                        .backgroundColor(this.reminderTime === t ? '#ff6b35' : '#f5f5f5')
                        .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(14)
                        .onClick(() => {
                          const hm = parseHourMinute(t);
                          this.reminderHour = hm[0]; this.reminderMinute = hm[1]; this.reminderTime = t;
                        });
                    })
                  }
                  Button('确认设置提醒')
                    .width('100%').height(44)
                    .backgroundColor('#ff6b35').fontColor(Color.White).borderRadius(22)
                    .onClick(() => { this.enableReminder(); });
                }
                .width('100%').padding(12).backgroundColor('#fafafa').borderRadius(10);
              }
            }
            .width('100%').padding(20).backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 8, left: 4, right: 8, bottom: 8 }).borderRadius(12);
          }
          .width('100%');
        }
        .layoutWeight(1).height('100%').scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);
      }
      .layoutWeight(1).width('100%');
    }
    .width('100%').height('100%').backgroundColor('#f5f7fa');
  }

  // 根据文件名返回对应图标
  private getFileIcon(fileName: string): string {
    if (fileName.endsWith('.pdf'))  return '📄';
    if (fileName.endsWith('.docx')) return '📝';
    if (fileName.endsWith('.xlsx')) return '📊';
    if (fileName.endsWith('.pptx')) return '📑';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) return '🖼';
    return '📎';
  }
}
