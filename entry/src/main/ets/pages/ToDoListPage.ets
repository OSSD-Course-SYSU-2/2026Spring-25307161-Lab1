import { Task, TaskParams } from '../entryability/Task';
import router from '@ohos.router';
import reminderAgentManager from '@ohos.reminderAgentManager';

function getTodayStr(): string {
  const d = new Date();
  const y = d.getFullYear().toString();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function genId(): number {
  return new Date().getTime();
}

// 判断今天是否在 startDate ~ endDate 范围内
// dateStr='' 表示永久固定，始终显示
// dateStr='YYYY-MM-DD' 表示仅当天
// startDate/endDate 表示日期范围
function isTaskVisibleToday(task: Task, today: string): boolean {
  if (task.startDate !== '' && task.endDate !== '') {
    return today >= task.startDate && today <= task.endDate;
  }
  if (task.dateStr === '') return true;   // 永久固定
  return task.dateStr === today;           // 仅当天
}

function buildTask(
  id: number, title: string, taskType: string,
  startTime: string, endTime: string,
  duration: number, isCompleted: boolean,
  notes: string, dateStr: string,
  reminderId: number,
  startDate: string, endDate: string
): Task {
  const p = new TaskParams();
  p.id = id; p.title = title; p.taskType = taskType;
  p.startTime = startTime; p.endTime = endTime;
  p.duration = duration; p.isCompleted = isCompleted;
  p.notes = notes; p.dateStr = dateStr; p.reminderId = reminderId;
  p.startDate = startDate; p.endDate = endDate;
  return new Task(p);
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
struct ToDoListPage {
  @State taskList: Task[] = [
    // dateStr='' startDate='' endDate='' → 永久固定任务
    buildTask(1,   "晨读英语",     'daily',    "07:00","07:30", 30,  false,'','',-1,'',''),
    buildTask(101, "晨跑5公里",    'daily',    "06:30","07:10", 40,  false,'','',-1,'',''),
    buildTask(102, "去食堂吃早餐", 'daily',    "07:30","08:00", 30,  false,'','',-1,'',''),
    buildTask(103, "参加志愿活动", 'daily',    "09:00","11:00", 120, false,'','',-1,'',''),
    buildTask(104, "去图书馆占座", 'daily',    "13:00","13:30", 30,  false,'','',-1,'',''),
    buildTask(105, "取快递/外卖",  'daily',    "17:00","17:45", 45,  false,'','',-1,'',''),
    buildTask(106, "参加社团讲座", 'daily',    "19:00","20:30", 90,  false,'','',-1,'',''),
    buildTask(107, "回宿舍洗衣服", 'daily',    "21:00","22:00", 60,  false,'','',-1,'',''),
    buildTask(2,   "算法刷题",       'practice',"14:00","15:30", 90, false,'','',-1,'',''),
    buildTask(201, "高数习题集(上)", 'practice',"10:00","11:30", 90, false,'','',-1,'',''),
    buildTask(202, "线性代数习题",   'practice',"15:00","16:30", 90, false,'','',-1,'',''),
    buildTask(203, "大学物理(大物)", 'practice',"08:30","10:00", 90, false,'','',-1,'',''),
    buildTask(204, "电路分析基础",   'practice',"19:00","20:30", 90, false,'','',-1,'',''),
    buildTask(205, "C语言程序设计",  'practice',"16:00","17:30", 90, false,'','',-1,'',''),
    buildTask(206, "离散数学刷题",   'practice',"13:00","14:30", 90, false,'','',-1,'',''),
    buildTask(3,   "单词背诵",              'word',"20:00","20:45", 45, false,'','',-1,'',''),
    buildTask(301, "四六级核心词(abandon)", 'word',"07:00","07:45", 45, false,'','',-1,'',''),
    buildTask(302, "四六级高频词(accept)",  'word',"12:00","12:45", 45, false,'','',-1,'',''),
    buildTask(303, "四六级词汇(access)",    'word',"18:00","18:45", 45, false,'','',-1,'',''),
    buildTask(304, "考研词汇(ache)",        'word',"21:00","21:45", 45, false,'','',-1,'',''),
    buildTask(305, "雅思词汇(acid)",        'word',"10:00","10:45", 45, false,'','',-1,'',''),
    buildTask(4,   "高数复习",       'review',"19:00","20:00", 60, false,'','',-1,'',''),
    buildTask(401, "专业课巩固",     'review',"14:00","15:30", 90, false,'','',-1,'',''),
    buildTask(402, "英语听力复盘",   'review',"17:00","18:00", 60, false,'','',-1,'',''),
    buildTask(403, "大物公式回顾",   'review',"09:00","10:30", 90, false,'','',-1,'',''),
    buildTask(404, "C++进阶复习",    'review',"16:00","17:30", 90, false,'','',-1,'',''),
    buildTask(405, "毛概知识点复习", 'review',"20:00","21:30", 90, false,'','',-1,'',''),
  ];

  @StorageProp('studyPoints') studyPoints: number = 0;
  @StorageProp('checkInDays') checkInDays: number = 0;
  @StorageProp('lastCheckDate') lastCheckDate: number = 0;

  @State currentTabIndex: number = 0;
  @State filteredList: Task[] = [];
  @State showAddDialog: boolean = false;
  @State deleteMode: boolean = false;
  @State showDeleteConfirm: boolean = false;
  @State pendingDeleteId: number = -1;

  // 新增表单
  @State newTitle: string = '';
  @State newType: string = 'daily';
  @State newStartTime: string = '09:00';
  @State newEndTime: string = '10:00';
  @State newDuration: number = 60;
  @State newEnableReminder: boolean = true;

  // 存在时间设置
  // 0=仅今天，1=永久，2=自定义日期范围
  @State newRepeatMode: number = 0;
  @State newRangeStart: string = getTodayStr();
  @State newRangeEnd: string = getTodayStr();

  private readonly TAB_LABELS: string[] = ["全部","日常","刷题","单词","复习"];
  private readonly TAB_TYPES: (string | null)[] = [null,'daily','practice','word','review'];
  private readonly today: string = getTodayStr();

  private getTaskLabel(t: string): string {
    if (t === 'daily')    return '日常';
    if (t === 'practice') return '刷题';
    if (t === 'word')     return '单词';
    if (t === 'review')   return '复习';
    return '日常';
  }

  private getTagBgColor(t: string): string {
    if (t === 'daily')    return '#fff7e6';
    if (t === 'practice') return '#e6f7ff';
    if (t === 'word')     return '#f6ffed';
    if (t === 'review')   return '#fff0f6';
    return '#f5f5f5';
  }

  private getTagTextColor(t: string): string {
    if (t === 'daily')    return '#d46b08';
    if (t === 'practice') return '#096dd9';
    if (t === 'word')     return '#389e0d';
    if (t === 'review')   return '#c41d7f';
    return '#595959';
  }

  private isStudyTask(taskType: string): boolean {
    return taskType === 'practice' || taskType === 'word' || taskType === 'review';
  }

  // 获取任务的存在类型描述
  private getTaskRangeLabel(task: Task): string {
    if (task.startDate !== '' && task.endDate !== '') {
      return `${task.startDate} 至 ${task.endDate}`;
    }
    if (task.dateStr === '') return '永久';
    return '仅今日';
  }

  private refreshFilteredList(): void {
    let list = this.taskList.filter(t => isTaskVisibleToday(t, this.today));
    const targetType = this.TAB_TYPES[this.currentTabIndex];
    if (targetType !== null) {
      list = list.filter(t => t.taskType === targetType);
    }
    this.filteredList = list;
  }

  private updatePoints(task: Task): void {
    try {
      const today = new Date().setHours(0, 0, 0, 0);
      if (this.lastCheckDate !== today) {
        AppStorage.SetOrCreate('checkInDays', this.checkInDays + 1);
        AppStorage.SetOrCreate('studyPoints', this.studyPoints + 20);
        AppStorage.SetOrCreate('lastCheckDate', today);
      }
      AppStorage.SetOrCreate('studyPoints', this.studyPoints + (task.taskType === 'daily' ? 5 : 10));
    } catch (e) {
      console.error('updatePoints error:', e);
    }
  }

  private async addTask(): Promise<void> {
    if (this.newTitle.trim() === '') return;
    let rid = -1;
    if (this.newEnableReminder) {
      rid = await registerReminder(this.newTitle.trim(), this.newStartTime);
    }

    let dateStr = '';
    let startDate = '';
    let endDate = '';

    if (this.newRepeatMode === 0) {
      // 仅今天
      dateStr = this.today;
    } else if (this.newRepeatMode === 1) {
      // 永久固定：dateStr='' startDate='' endDate=''
      dateStr = '';
    } else {
      // 自定义日期范围
      startDate = this.newRangeStart;
      endDate = this.newRangeEnd;
    }

    const t = buildTask(
      genId(), this.newTitle.trim(), this.newType,
      this.newStartTime, this.newEndTime, this.newDuration,
      false, '', dateStr, rid, startDate, endDate
    );
    this.taskList = [...this.taskList, t];
    this.refreshFilteredList();

    // 重置表单
    this.newTitle = ''; this.newType = 'daily';
    this.newStartTime = '09:00'; this.newEndTime = '10:00';
    this.newDuration = 60; this.newEnableReminder = true;
    this.newRepeatMode = 0;
    this.newRangeStart = this.today; this.newRangeEnd = this.today;
    this.showAddDialog = false;
  }

  private confirmDelete(taskId: number): void {
    this.pendingDeleteId = taskId;
    this.showDeleteConfirm = true;
  }

  private async doDelete(): Promise<void> {
    const task = this.taskList.find(t => t.id === this.pendingDeleteId);
    if (task && task.reminderId >= 0) {
      await cancelReminder(task.reminderId);
    }
    this.taskList = this.taskList.filter(t => t.id !== this.pendingDeleteId);
    this.refreshFilteredList();
    this.showDeleteConfirm = false;
    this.pendingDeleteId = -1;
  }

  aboutToAppear(): void {
    try {
      const pts = AppStorage.Get<number>('studyPoints');
      AppStorage.SetOrCreate('studyPoints', pts !== undefined ? pts : 0);
      const days = AppStorage.Get<number>('checkInDays');
      AppStorage.SetOrCreate('checkInDays', days !== undefined ? days : 0);
      const date = AppStorage.Get<number>('lastCheckDate');
      AppStorage.SetOrCreate('lastCheckDate', date !== undefined ? date : 0);
    } catch (e) {
      console.error('AppStorage init error:', e);
    }
    this.refreshFilteredList();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部安全区域
        Row().width('100%').height(44);

        // 顶部栏
        Row() {
          Text('智学日程').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
          Blank();
          Text(this.deleteMode ? '✓ 完成' : '管理')
            .fontSize(14)
            .fontColor(this.deleteMode ? '#ff4d4f' : '#595959')
            .backgroundColor(this.deleteMode ? '#fff1f0' : '#f5f5f5')
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .borderRadius(14).margin({ right: 8 })
            .onClick(() => { this.deleteMode = !this.deleteMode; });
          Row({ space: 6 }) {
            Text(`🏆 ${this.studyPoints} 分`)
              .fontSize(13).fontColor('#d46b08').backgroundColor('#fff7e6')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(12);
            Text(`📅 打卡 ${this.checkInDays} 天`)
              .fontSize(13).fontColor('#096dd9').backgroundColor('#e6f7ff')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(12);
          }
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 10 });

        // 管理模式提示
        if (this.deleteMode) {
          Row() {
            Text('🗑  管理模式：点击红色删除按钮可删除任意任务')
              .fontSize(12).fontColor('#ff4d4f');
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .backgroundColor('#fff1f0');
        }

        // 日期 + 进度
        Row() {
          Text(`📆 ${this.today}`).fontSize(13).fontColor('#8c8c8c');
          Blank();
          Text(`完成 ${this.filteredList.filter(t => t.isCompleted).length} / ${this.filteredList.length}`)
            .fontSize(13).fontColor('#8c8c8c');
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 4 });

        Stack({ alignContent: Alignment.Start }) {
          Row().width('100%').height(4).backgroundColor('#f0f0f0').borderRadius(2);
          Row()
            .width(this.filteredList.length > 0
              ? `${Math.round(this.filteredList.filter(t => t.isCompleted).length / this.filteredList.length * 100)}%`
              : '0%')
            .height(4).backgroundColor('#ff6b35').borderRadius(2);
        }
        .width('100%').padding({ left: 16, right: 16 }).margin({ bottom: 4 });

        // Tab
        Tabs({ index: this.currentTabIndex }) {
          ForEach(this.TAB_LABELS, (label: string, idx: number) => {
            TabContent() {
              if (this.filteredList.length === 0) {
                Column({ space: 12 }) {
                  Text('🎉').fontSize(40);
                  Text('今日没有待办任务').fontSize(15).fontColor('#bfbfbf');
                  Text('点击右下角 + 新增').fontSize(13).fontColor('#d9d9d9');
                }
                .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
              } else {
                List({ space: 10 }) {
                  ForEach(this.filteredList, (task: Task) => {
                    ListItem() {
                      Row() {
                        // 删除模式：所有任务都显示删除按钮
                        if (this.deleteMode) {
                          Column() {
                            Text('删除')
                              .fontSize(13).fontColor(Color.White)
                              .backgroundColor('#ff4d4f')
                              .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                              .borderRadius(8);
                          }
                          .margin({ right: 10 })
                          .onClick(() => { this.confirmDelete(task.id); });
                        } else {
                          Toggle({ type: ToggleType.Checkbox, isOn: task.isCompleted })
                            .size({ width: 22, height: 22 })
                            .selectedColor('#ff6b35')
                            .onChange(() => {
                              const i = this.taskList.findIndex(t => t.id === task.id);
                              if (i >= 0) {
                                this.taskList[i].isCompleted = !this.taskList[i].isCompleted;
                                if (this.taskList[i].isCompleted) this.updatePoints(this.taskList[i]);
                                this.taskList = [...this.taskList];
                                this.refreshFilteredList();
                              }
                            });
                        }

                        Column({ space: 5 }) {
                          Row({ space: 6 }) {
                            Text(task.title)
                              .fontSize(16).fontWeight(FontWeight.Medium)
                              .fontColor(task.isCompleted ? '#bfbfbf' : '#1a1a1a')
                              .decoration({
                                type: task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None,
                                color: '#bfbfbf'
                              })
                              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                              .layoutWeight(1);
                            if (task.reminderId >= 0) { Text('🔔').fontSize(12); }
                            if (this.isStudyTask(task.taskType)) {
                              Text('📝').fontSize(12).fontColor('#722ed1');
                            } else {
                              Text('💭').fontSize(12).fontColor('#08979c');
                            }
                          }.width('100%');

                          Row({ space: 6 }) {
                            Text(this.getTaskLabel(task.taskType))
                              .fontSize(11)
                              .fontColor(this.getTagTextColor(task.taskType))
                              .backgroundColor(this.getTagBgColor(task.taskType))
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4);
                            Text(`${task.startTime} ~ ${task.endTime}`)
                              .fontSize(12).fontColor('#8c8c8c');
                            Text(`${task.duration}min`)
                              .fontSize(11).fontColor('#b37feb').backgroundColor('#f9f0ff')
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4);
                            // 存在时间标签
                            Text(this.getTaskRangeLabel(task))
                              .fontSize(10).fontColor('#8c8c8c').backgroundColor('#f5f5f5')
                              .padding({ left: 5, right: 5, top: 2, bottom: 2 }).borderRadius(4);
                          }
                        }
                        .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 });

                        Text('›').fontSize(20).fontColor('#d9d9d9')
                          .visibility(this.deleteMode ? Visibility.Hidden : Visibility.Visible);
                      }
                      .width('100%')
                      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
                      .backgroundColor(task.isCompleted ? '#fafafa' : Color.White)
                      .borderRadius(12)
                      .opacity(task.isCompleted ? 0.7 : 1.0)
                      .onClick(() => {
                        if (this.deleteMode) return;
                        try {
                          router.pushUrl({ url: 'pages/TaskDetailPage', params: task });
                        } catch (e) { console.error('Router error:', e); }
                      });
                    }
                  }, (task: Task) => `${task.id}_${task.isCompleted}_${task.reminderId}`)
                }
                .width('100%').height('100%')
                .padding({ left: 16, right: 16, top: 4, bottom: 80 });
              }
            }
            .tabBar(this.buildTabBar(label, idx))
          })
        }
        .barMode(BarMode.Scrollable).barHeight(44).barBackgroundColor(Color.White)
        .width('100%').layoutWeight(1)
        .onChange((index: number) => {
          this.currentTabIndex = index;
          this.refreshFilteredList();
        });
      }
      .width('100%').height('100%').backgroundColor('#f5f7fa');

      // 删除确认弹窗遮罩
      if (this.showDeleteConfirm) {
        Column()
          .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => { this.showDeleteConfirm = false; this.pendingDeleteId = -1; });
      }

      // 删除确认弹窗
      if (this.showDeleteConfirm) {
        Column({ space: 20 }) {
          Text('确认删除').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
          Text('删除后无法恢复，相关提醒也会同步取消')
            .fontSize(14).fontColor('#8c8c8c').textAlign(TextAlign.Center);
          Row({ space: 16 }) {
            Button('取消')
              .layoutWeight(1).height(44).backgroundColor('#f5f5f5').fontColor('#595959').borderRadius(22)
              .onClick(() => { this.showDeleteConfirm = false; this.pendingDeleteId = -1; });
            Button('确认删除')
              .layoutWeight(1).height(44).backgroundColor('#ff4d4f').fontColor(Color.White).borderRadius(22)
              .onClick(() => { this.doDelete(); });
          }.width('100%');
        }
        .width('80%').padding(24).backgroundColor(Color.White).borderRadius(16)
        .position({ x: '10%', y: '38%' });
      }

      // 新增弹窗遮罩
      if (this.showAddDialog) {
        Column()
          .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.45)')
          .onClick(() => { this.showAddDialog = false; });
      }

      // 新增弹窗
      if (this.showAddDialog) {
        Column({ space: 0 }) {
          Row() {
            Text('新增待办').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
            Blank();
            Text('✕').fontSize(18).fontColor('#8c8c8c').onClick(() => { this.showAddDialog = false; });
          }
          .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 16 });

          Divider().strokeWidth(0.5).color('#f0f0f0');

          Scroll() {
            Column({ space: 16 }) {

              // 任务名称
              Column({ space: 6 }) {
                Text('任务名称').fontSize(13).fontColor('#8c8c8c');
                TextInput({ text: this.newTitle, placeholder: '请输入任务名称' })
                  .height(44).backgroundColor('#f5f7fa').borderRadius(8).fontSize(15)
                  .onChange((v: string) => { this.newTitle = v; });
              }.alignItems(HorizontalAlign.Start);

              // 任务分类
              Column({ space: 6 }) {
                Text('任务分类').fontSize(13).fontColor('#8c8c8c');
                Row({ space: 8 }) {
                  ForEach(['daily','practice','word','review'], (type: string) => {
                    Text(this.getTaskLabel(type))
                      .fontSize(14)
                      .fontColor(this.newType === type ? Color.White : this.getTagTextColor(type))
                      .backgroundColor(this.newType === type ? '#ff6b35' : this.getTagBgColor(type))
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(20)
                      .onClick(() => { this.newType = type; });
                  })
                }
              }.alignItems(HorizontalAlign.Start);

              // 时间
              Row({ space: 12 }) {
                Column({ space: 6 }) {
                  Text('开始时间').fontSize(13).fontColor('#8c8c8c');
                  TextInput({ text: this.newStartTime, placeholder: '09:00' })
                    .height(44).backgroundColor('#f5f7fa').borderRadius(8).fontSize(15)
                    .onChange((v: string) => { this.newStartTime = v; });
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Column({ space: 6 }) {
                  Text('结束时间').fontSize(13).fontColor('#8c8c8c');
                  TextInput({ text: this.newEndTime, placeholder: '10:00' })
                    .height(44).backgroundColor('#f5f7fa').borderRadius(8).fontSize(15)
                    .onChange((v: string) => { this.newEndTime = v; });
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              }

              // 时长
              Column({ space: 6 }) {
                Text(`时长：${this.newDuration} 分钟`).fontSize(13).fontColor('#8c8c8c');
                Row({ space: 8 }) {
                  ForEach([15, 30, 45, 60, 90, 120], (min: number) => {
                    Text(`${min}`)
                      .fontSize(13)
                      .fontColor(this.newDuration === min ? Color.White : '#595959')
                      .backgroundColor(this.newDuration === min ? '#ff6b35' : '#f5f5f5')
                      .padding({ left: 12, right: 12, top: 7, bottom: 7 }).borderRadius(16)
                      .onClick(() => { this.newDuration = min; });
                  })
                }
              }.alignItems(HorizontalAlign.Start);

              // ── 存在时间设置 ──────────────────────────
              Column({ space: 10 }) {
                Text('任务存在时间').fontSize(13).fontColor('#8c8c8c');

                // 三种模式选择
                Row({ space: 8 }) {
                  Text('仅今天')
                    .fontSize(13)
                    .fontColor(this.newRepeatMode === 0 ? Color.White : '#595959')
                    .backgroundColor(this.newRepeatMode === 0 ? '#ff6b35' : '#f5f5f5')
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(20)
                    .onClick(() => { this.newRepeatMode = 0; });
                  Text('永久固定')
                    .fontSize(13)
                    .fontColor(this.newRepeatMode === 1 ? Color.White : '#595959')
                    .backgroundColor(this.newRepeatMode === 1 ? '#ff6b35' : '#f5f5f5')
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(20)
                    .onClick(() => { this.newRepeatMode = 1; });
                  Text('自定义范围')
                    .fontSize(13)
                    .fontColor(this.newRepeatMode === 2 ? Color.White : '#595959')
                    .backgroundColor(this.newRepeatMode === 2 ? '#ff6b35' : '#f5f5f5')
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(20)
                    .onClick(() => { this.newRepeatMode = 2; });
                }

                // 模式说明
                if (this.newRepeatMode === 0) {
                  Text('仅在今天（${this.today}）显示，明天自动消失')
                    .fontSize(12).fontColor('#8c8c8c');
                } else if (this.newRepeatMode === 1) {
                  Text('每天都会显示，直到手动删除')
                    .fontSize(12).fontColor('#8c8c8c');
                } else {
                  // 自定义日期范围输入
                  Column({ space: 8 }) {
                    Text('格式：YYYY-MM-DD，例如 2026-06-01').fontSize(11).fontColor('#bfbfbf');
                    Row({ space: 12 }) {
                      Column({ space: 4 }) {
                        Text('开始日期').fontSize(12).fontColor('#8c8c8c');
                        TextInput({ text: this.newRangeStart, placeholder: '2026-05-20' })
                          .height(40).backgroundColor('#f5f7fa').borderRadius(8).fontSize(14)
                          .onChange((v: string) => { this.newRangeStart = v; });
                      }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                      Text('→').fontSize(16).fontColor('#8c8c8c').margin({ top: 18 });
                      Column({ space: 4 }) {
                        Text('结束日期').fontSize(12).fontColor('#8c8c8c');
                        TextInput({ text: this.newRangeEnd, placeholder: '2026-06-20' })
                          .height(40).backgroundColor('#f5f7fa').borderRadius(8).fontSize(14)
                          .onChange((v: string) => { this.newRangeEnd = v; });
                      }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                    }
                  }.alignItems(HorizontalAlign.Start);
                }
              }.alignItems(HorizontalAlign.Start);

              // 闹钟提醒
              Row() {
                Column({ space: 3 }) {
                  Text('开启闹钟提醒').fontSize(15).fontColor('#1a1a1a');
                  Text('任务开始时振动+通知提醒').fontSize(12).fontColor('#8c8c8c');
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Toggle({ type: ToggleType.Switch, isOn: this.newEnableReminder })
                  .selectedColor('#ff6b35')
                  .onChange((v: boolean) => { this.newEnableReminder = v; });
              }.width('100%').padding({ left: 4, right: 4 });

            }
            .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 16 });
          }
          .layoutWeight(1).scrollBar(BarState.Off);

          Button('添加任务')
            .width('90%').height(48)
            .backgroundColor(this.newTitle.trim() !== '' ? '#ff6b35' : '#d9d9d9')
            .fontColor(Color.White).fontSize(16).borderRadius(24).margin({ bottom: 24 })
            .onClick(() => { this.addTask(); });
        }
        .width('100%').height('75%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 20, topRight: 20 })
        .position({ x: 0, y: '25%' });
      }

      // 新增按钮
      if (!this.deleteMode) {
        Button('+')
          .width(56).height(56).fontSize(28)
          .fontColor(Color.White).backgroundColor('#ff6b35')
          .borderRadius(28).margin({ right: 24, bottom: 32 })
          .onClick(() => { this.showAddDialog = true; });
      }
    }
    .width('100%').height('100%');
  }

  @Builder
  buildTabBar(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#ff6b35' : '#595959')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 });
      Row()
        .width(this.currentTabIndex === index ? 24 : 0)
        .height(3).backgroundColor('#ff6b35').borderRadius(2).margin({ bottom: 4 });
    }
    .alignItems(HorizontalAlign.Center);
  }
}
