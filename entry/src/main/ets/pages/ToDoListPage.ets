import { Task, TaskParams } from '../entryability/Task';
import {
  CONTINUE_TAB_INDEX,
  CONTINUE_TASK_ID,
  CONTINUE_PAGE
} from '../entryability/EntryAbility';
import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import reminderAgentManager from '@ohos.reminderAgentManager';
import mediaquery from '@ohos.mediaquery';
import display from '@ohos.display';
import window from '@ohos.window';

// 断点类型：xs=手表，sm=手机，md=折叠屏展开，lg=平板
type BreakpointType = 'xs' | 'sm' | 'md' | 'lg';

function getTodayStr(): string {
  const d = new Date();
  const y = d.getFullYear().toString();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function genId(): number { return new Date().getTime(); }

function isTaskVisibleToday(task: Task, today: string): boolean {
  if (task.startDate !== '' && task.endDate !== '') {
    return today >= task.startDate && today <= task.endDate;
  }
  return task.dateStr === '' || task.dateStr === today;
}

function buildTask(
  id: number, title: string, taskType: string,
  startTime: string, endTime: string, duration: number,
  isCompleted: boolean, notes: string, dateStr: string,
  reminderId: number, startDate: string, endDate: string
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
  const h = parseInt(parts[0] ?? '0');
  const min = parseInt(parts[1] ?? '0');
  return [isNaN(h) ? 0 : h, isNaN(min) ? 0 : min];
}

async function registerReminder(title: string, timeStr: string): Promise<number> {
  try {
    const hm = parseHourMinute(timeStr);
    const now = new Date(); const target = new Date();
    target.setHours(hm[0], hm[1], 0, 0);
    let diff = Math.floor((target.getTime() - now.getTime()) / 1000);
    if (diff <= 0) diff += 86400;
    const r: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: diff,
      title: '智学日程提醒', content: `任务【${title}】即将开始`,
      expiredContent: `任务【${title}】已开始`,
      notificationId: genId() % 100000,
      actionButton: [{ title: '查看', type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE }],
      wantAgent: { pkgName: 'com.example.entry', abilityName: 'EntryAbility' },
      ringDuration: 0, snoozeTimes: 0, timeInterval: 0,
    };
    return await reminderAgentManager.publishReminder(r);
  } catch (e) { return -1; }
}

async function cancelReminder(id: number): Promise<void> {
  if (id < 0) return;
  try { await reminderAgentManager.cancelReminder(id); } catch (e) {}
}

@Entry
@Component
struct ToDoListPage {
  @StorageProp('studyPoints') studyPoints: number = 0;
  @StorageProp('checkInDays') checkInDays: number = 0;
  @StorageProp('lastCheckDate') lastCheckDate: number = 0;

  @State taskList: Task[] = [
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

  @State currentTabIndex: number = 0;

  // 持久化：Preferences 实例
  private pref: preferences.Preferences | null = null;
  private readonly PREF_NAME: string = 'smart_study_tasks';
  private readonly KEY_USER_TASKS: string = 'user_tasks';       // 用户新增的任务
  private readonly KEY_COMPLETED: string = 'completed_ids';     // 已完成的任务ID列表

  // 断点
  @State currentBp: BreakpointType = 'sm';
  private bpListenerXs: mediaquery.MediaQueryListener | null = null;
  private bpListenerMd: mediaquery.MediaQueryListener | null = null;
  private bpListenerLg: mediaquery.MediaQueryListener | null = null;

  // 流转恢复：从 AppStorage 读取对端保存的状态
  @StorageProp(CONTINUE_TAB_INDEX) continueTabIndex: number = -1;
  @StorageProp(CONTINUE_PAGE) continuePage: string = '';
  @StorageProp(CONTINUE_TASK_ID) continueTaskId: number = -1;
  @State filteredList: Task[] = [];
  @State showAddDialog: boolean = false;
  @State deleteMode: boolean = false;
  @State showDeleteConfirm: boolean = false;
  @State pendingDeleteId: number = -1;
  @State newTitle: string = '';
  @State newType: string = 'daily';
  @State newStartTime: string = '09:00';
  @State newEndTime: string = '10:00';
  @State newDuration: number = 60;
  @State newEnableReminder: boolean = true;
  @State newRepeatMode: number = 0;
  @State newRangeStart: string = getTodayStr();
  @State newRangeEnd: string = getTodayStr();
  // 手表计时器状态
  @State wTimerSeconds: number = 25 * 60;
  @State wTimerRunning: boolean = false;
  private wTimer: number = -1;

  private readonly TAB_LABELS: string[] = ["全部","日常","刷题","单词","复习"];
  private readonly TAB_TYPES: (string | null)[] = [null,'daily','practice','word','review'];
  private readonly today: string = getTodayStr();

  // ── 辅助方法 ──────────────────────────────────
  aboutToDisappear(): void {
    try {
      if (this.bpListenerXs) this.bpListenerXs.off('change');
      if (this.bpListenerMd) this.bpListenerMd.off('change');
      if (this.bpListenerLg) this.bpListenerLg.off('change');
    } catch (e) {}
  }

  private getTaskLabel(t: string): string {
    if (t === 'daily')    return '日常';
    if (t === 'practice') return '刷题';
    if (t === 'word')     return '单词';
    if (t === 'review')   return '复习';
    return '日常';
  }

  private getTagBg(t: string): string {
    if (t === 'daily')    return '#fff7e6';
    if (t === 'practice') return '#e6f7ff';
    if (t === 'word')     return '#f6ffed';
    if (t === 'review')   return '#fff0f6';
    return '#f5f5f5';
  }

  private getTagColor(t: string): string {
    if (t === 'daily')    return '#d46b08';
    if (t === 'practice') return '#096dd9';
    if (t === 'word')     return '#389e0d';
    if (t === 'review')   return '#c41d7f';
    return '#595959';
  }

  private isStudyTask(t: string): boolean {
    return t === 'practice' || t === 'word' || t === 'review';
  }

  private getRangeLabel(task: Task): string {
    if (task.startDate !== '' && task.endDate !== '') return `${task.startDate}~${task.endDate}`;
    return task.dateStr === '' ? '永久' : '仅今日';
  }

  private getCountByTab(idx: number): number {
    const type = this.TAB_TYPES[idx];
    let list = this.taskList.filter(t => isTaskVisibleToday(t, this.today));
    if (type !== null) list = list.filter(t => t.taskType === type);
    return list.length;
  }

  private refreshFilteredList(): void {
    let list = this.taskList.filter(t => isTaskVisibleToday(t, this.today));
    const type = this.TAB_TYPES[this.currentTabIndex];
    if (type !== null) list = list.filter(t => t.taskType === type);
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
      this.saveCompletedIds(); // 持久化完成状态
    } catch (e) {}
  }

  private async addTask(): Promise<void> {
    if (this.newTitle.trim() === '') return;
    let rid = -1;
    if (this.newEnableReminder) rid = await registerReminder(this.newTitle.trim(), this.newStartTime);
    let dateStr = ''; let startDate = ''; let endDate = '';
    if (this.newRepeatMode === 0) dateStr = this.today;
    else if (this.newRepeatMode === 2) { startDate = this.newRangeStart; endDate = this.newRangeEnd; }
    const t = buildTask(genId(), this.newTitle.trim(), this.newType,
      this.newStartTime, this.newEndTime, this.newDuration,
      false, '', dateStr, rid, startDate, endDate);
    this.taskList = [...this.taskList, t];
    this.refreshFilteredList();
    this.saveUserTasks(); // 持久化保存
    this.newTitle = ''; this.newType = 'daily'; this.newStartTime = '09:00';
    this.newEndTime = '10:00'; this.newDuration = 60; this.newEnableReminder = true;
    this.newRepeatMode = 0; this.newRangeStart = this.today; this.newRangeEnd = this.today;
    this.showAddDialog = false;
  }

  private confirmDelete(id: number): void { this.pendingDeleteId = id; this.showDeleteConfirm = true; }

  private async doDelete(): Promise<void> {
    const task = this.taskList.find(t => t.id === this.pendingDeleteId);
    if (task && task.reminderId >= 0) await cancelReminder(task.reminderId);
    this.taskList = this.taskList.filter(t => t.id !== this.pendingDeleteId);
    this.refreshFilteredList();
    this.saveUserTasks(); // 持久化
    this.saveCompletedIds();
    this.showDeleteConfirm = false; this.pendingDeleteId = -1;
  }

  // 手表计时器
  private wFormatTime(s: number): string {
    return `${Math.floor(s/60).toString().padStart(2,'0')}:${(s%60).toString().padStart(2,'0')}`;
  }

  private wStartTimer(): void {
    if (this.wTimer !== -1) { try { clearInterval(this.wTimer); } catch (e) {} }
    this.wTimer = setInterval(() => {
      if (this.wTimerSeconds > 0) { this.wTimerSeconds--; }
      else { try { clearInterval(this.wTimer); } catch (e) {} this.wTimer = -1; this.wTimerRunning = false; }
    }, 1000);
  }

  async aboutToAppear(): Promise<void> {
    // 用窗口像素宽度 + density 计算 vp，直接判断断点
    try {
      const dm = display.getDefaultDisplaySync();
      const widthPx = dm.width;
      const density = dm.densityPixels;
      const widthVp = widthPx / density;
      console.info(`[BP] width=${widthPx}px density=${density} widthVp=${widthVp}`);
      if (widthVp >= 840) {
        this.currentBp = 'lg';
      } else if (widthVp >= 600) {
        this.currentBp = 'md';
      } else if (widthVp < 280) {
        this.currentBp = 'xs';
      } else {
        this.currentBp = 'sm';
      }
      console.info(`[BP] currentBp=${this.currentBp}`);
    } catch (e) {
      console.error(`[BP] error: ${e}`);
      this.currentBp = 'sm';
    }

    // 注册窗口尺寸变化监听（折叠屏展开/收起时触发）
    try {
      window.getLastWindow(getContext(this)).then((win) => {
        win.on('windowSizeChange', (size) => {
          try {
            const dm = display.getDefaultDisplaySync();
            const wVp = size.width / dm.densityPixels;
            if (wVp >= 840) { this.currentBp = 'lg'; }
            else if (wVp >= 600) { this.currentBp = 'md'; }
            else if (wVp < 280) { this.currentBp = 'xs'; }
            else { this.currentBp = 'sm'; }
          } catch (e) {}
        });
      }).catch(() => {});
    } catch (e) {}

    // 同时保留 mediaquery 监听作为备用
    this.bpListenerLg = mediaquery.matchMediaSync('(min-width: 840vp)');
    this.bpListenerMd = mediaquery.matchMediaSync('(min-width: 600vp) and (max-width: 839vp)');
    this.bpListenerXs = mediaquery.matchMediaSync('(max-width: 279vp)');
    this.bpListenerLg.on('change', (r: mediaquery.MediaQueryResult) => {
      if (r.matches) this.currentBp = 'lg';
    });
    this.bpListenerMd.on('change', (r: mediaquery.MediaQueryResult) => {
      if (r.matches) this.currentBp = 'md';
    });
    this.bpListenerXs.on('change', (r: mediaquery.MediaQueryResult) => {
      if (r.matches) this.currentBp = 'xs';
    });

    try {
      const pts = AppStorage.Get<number>('studyPoints');
      AppStorage.SetOrCreate('studyPoints', pts !== undefined ? pts : 0);
      const days = AppStorage.Get<number>('checkInDays');
      AppStorage.SetOrCreate('checkInDays', days !== undefined ? days : 0);
      const date = AppStorage.Get<number>('lastCheckDate');
      AppStorage.SetOrCreate('lastCheckDate', date !== undefined ? date : 0);
    } catch (e) {}
    this.refreshFilteredList();

    // 初始化 Preferences 并加载持久化数据
    try {
      this.pref = await preferences.getPreferences(getContext(this), this.PREF_NAME);
      await this.loadPersistedData();
    } catch (e) {
      console.error('Preferences 初始化失败:', e);
    }

    // 流转恢复：若有对端传来的 Tab 索引，恢复到对应分类
    if (this.continueTabIndex >= 0 && this.continueTabIndex < this.TAB_LABELS.length) {
      this.currentTabIndex = this.continueTabIndex;
      this.refreshFilteredList();
      AppStorage.SetOrCreate(CONTINUE_TAB_INDEX, -1);
    }

    // 流转恢复：若对端在详情页，自动跳转到对应任务详情
    if (this.continuePage === 'detail' && this.continueTaskId >= 0) {
      const task = this.taskList.find(t => t.id === this.continueTaskId);
      if (task) {
        try {
          router.pushUrl({ url: 'pages/TaskDetailPage', params: task });
        } catch (e) {
          console.error('流转跳转详情页失败:', e);
        }
      }
      AppStorage.SetOrCreate(CONTINUE_PAGE, '');
      AppStorage.SetOrCreate(CONTINUE_TASK_ID, -1);
    }
  }

  // ── 从 Preferences 加载持久化数据 ──────────────────────
  private async loadPersistedData(): Promise<void> {
    if (!this.pref) return;
    try {
      // 1. 加载用户新增的任务
      const userTasksJson = await this.pref.get(this.KEY_USER_TASKS, '[]') as string;
      const userTasksArr = JSON.parse(userTasksJson) as Record<string, Object>[];
      const userTasks: Task[] = userTasksArr.map(obj => Task.fromObj(obj));

      // 2. 加载已完成的任务 ID 列表
      const completedJson = await this.pref.get(this.KEY_COMPLETED, '[]') as string;
      const completedIds = JSON.parse(completedJson) as number[];

      // 3. 恢复预设任务的完成状态
      const updatedPreset = this.taskList.map(t => {
        if (completedIds.includes(t.id)) {
          t.isCompleted = true;
        }
        return t;
      });

      // 4. 合并：预设任务 + 用户新增任务
      this.taskList = [...updatedPreset, ...userTasks];
      this.refreshFilteredList();
    } catch (e) {
      console.error('loadPersistedData 失败:', e);
    }
  }

  // ── 保存用户新增任务到 Preferences ──────────────────────
  private async saveUserTasks(): Promise<void> {
    if (!this.pref) return;
    try {
      // id > 100000000：由 Date.now() 生成，是用户新增的任务
      const newUserTasks = this.taskList.filter(t => t.id > 100000000);
      const jsonArr: object[] = newUserTasks.map(t => JSON.parse(t.toJSON()) as object);
      const json: string = JSON.stringify(jsonArr);
      await this.pref.put(this.KEY_USER_TASKS, json);
      await this.pref.flush();
    } catch (e) {
      console.error('saveUserTasks 失败:', e);
    }
  }

  // ── 保存已完成的任务 ID ──────────────────────────────────
  private async saveCompletedIds(): Promise<void> {
    if (!this.pref) return;
    try {
      const completedIds = this.taskList
        .filter(t => t.isCompleted)
        .map(t => t.id);
      await this.pref.put(this.KEY_COMPLETED, JSON.stringify(completedIds));
      await this.pref.flush();
    } catch (e) {
      console.error('saveCompletedIds 失败:', e);
    }
  }

  // ── 主入口 ────────────────────────────────────
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.currentBp === 'xs') {
        this.buildWearableLayout();
      } else if (this.currentBp === 'lg' || this.currentBp === 'md') {
        this.buildLargeScreenLayout();
      } else {
        this.buildPhoneLayout();
      }

      // 删除确认弹窗（手表不显示）
      if (this.showDeleteConfirm && this.currentBp !== 'xs') {
        Column()
          .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => { this.showDeleteConfirm = false; this.pendingDeleteId = -1; });
      }
      if (this.showDeleteConfirm && this.currentBp !== 'xs') {
        Column({ space: 20 }) {
          Text('确认删除').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
          Text('删除后无法恢复，提醒也会同步取消')
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

      // 新增弹窗（手表不显示）
      if (this.showAddDialog && this.currentBp !== 'xs') {
        Column()
          .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.45)')
          .onClick(() => { this.showAddDialog = false; });
      }
      if (this.showAddDialog && this.currentBp !== 'xs') {
        this.buildAddDialog();
      }

      // 新增按钮（手表不显示）
      if (!this.deleteMode && this.currentBp !== 'xs') {
        Button('+')
          .width(56).height(56).fontSize(28)
          .fontColor(Color.White).backgroundColor('#ff6b35')
          .borderRadius(28).margin({ right: 24, bottom: 32 })
          .onClick(() => { this.showAddDialog = true; });
      }
    }
    .width('100%').height('100%');
  }

  // ════════════════════════════════════════════════
  // 手表布局（xs）
  // ════════════════════════════════════════════════
  @Builder
  buildWearableLayout() {
    Column() {
      // 顶部：日期 + 积分
      Row() {
        Text(`📆 ${this.today.substring(5)}`).fontSize(11).fontColor('#8c8c8c');
        Blank();
        Text(`🏆${this.studyPoints}`).fontSize(11).fontColor('#d46b08');
      }
      .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 4 });

      // 进度
      Row() {
        Column({ space: 2 }) {
          Text(`${this.filteredList.filter(t => t.isCompleted).length}`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#ff6b35');
          Text(`/ ${this.filteredList.length} 项`).fontSize(11).fontColor('#8c8c8c');
        }.alignItems(HorizontalAlign.Center);
        Blank();
        Stack({ alignContent: Alignment.Start }) {
          Row().width(80).height(6).backgroundColor('#f0f0f0').borderRadius(3);
          Row()
            .width(this.filteredList.length > 0
              ? `${Math.round(this.filteredList.filter(t => t.isCompleted).length / this.filteredList.length * 80)}px`
              : '0px')
            .height(6).backgroundColor('#ff6b35').borderRadius(3);
        }
      }
      .width('100%').padding({ left: 12, right: 12, bottom: 6 });

      Divider().strokeWidth(0.5).color('#f0f0f0').margin({ left: 12, right: 12 });

      // 未完成任务列表
      if (this.filteredList.filter(t => !t.isCompleted).length === 0) {
        Column({ space: 6 }) {
          Text('🎉').fontSize(28);
          Text('全部完成！').fontSize(13).fontColor('#52c41a').fontWeight(FontWeight.Medium);
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
      } else {
        List({ space: 6 }) {
          ForEach(
            this.filteredList.filter(t => !t.isCompleted),
            (task: Task) => {
              ListItem() {
                Row({ space: 8 }) {
                  Toggle({ type: ToggleType.Checkbox, isOn: task.isCompleted })
                    .size({ width: 18, height: 18 }).selectedColor('#ff6b35')
                    .onChange(() => {
                      const i = this.taskList.findIndex(t => t.id === task.id);
                      if (i >= 0) {
                        this.taskList[i].isCompleted = true;
                        this.updatePoints(this.taskList[i]);
                        this.taskList = [...this.taskList];
                        this.refreshFilteredList();
                      }
                    });
                  Column({ space: 2 }) {
                    Text(task.title)
                      .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1a1a1a')
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
                    Row({ space: 4 }) {
                      Text(this.getTaskLabel(task.taskType))
                        .fontSize(10).fontColor(this.getTagColor(task.taskType))
                        .backgroundColor(this.getTagBg(task.taskType))
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(3);
                      Text(task.startTime).fontSize(10).fontColor('#8c8c8c');
                    }
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                }
                .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(Color.White).borderRadius(10);
              }
            },
            (task: Task) => `${task.id}_${task.isCompleted}`
          )
        }
        .width('100%').height('100%').layoutWeight(1)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 });
      }

      Divider().strokeWidth(0.5).color('#f0f0f0').margin({ left: 12, right: 12 });

      // 底部简单计时器
      Column({ space: 6 }) {
        Text('⏱ 专注计时').fontSize(11).fontColor('#8c8c8c');
        Text(this.wFormatTime(this.wTimerSeconds))
          .fontSize(24).fontWeight(FontWeight.Bold)
          .fontColor(this.wTimerRunning ? '#ff6b35' : '#1a1a1a');
        Row({ space: 8 }) {
          Button(this.wTimerRunning ? '暂停' : '开始')
            .height(28).fontSize(12)
            .backgroundColor(this.wTimerRunning ? '#faad14' : '#ff6b35')
            .fontColor(Color.White).borderRadius(14)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              if (this.wTimerRunning) {
                try { clearInterval(this.wTimer); } catch (e) {}
                this.wTimer = -1; this.wTimerRunning = false;
              } else {
                this.wTimerRunning = true; this.wStartTimer();
              }
            });
          Button('重置').height(28).fontSize(12)
            .backgroundColor('#f5f5f5').fontColor('#595959').borderRadius(14)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              try { clearInterval(this.wTimer); } catch (e) {}
              this.wTimer = -1; this.wTimerRunning = false; this.wTimerSeconds = 25 * 60;
            });
        }
      }
      .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%').height('100%').backgroundColor('#f5f7fa');
  }

  // ════════════════════════════════════════════════
  // 手机布局（sm）
  // ════════════════════════════════════════════════
  @Builder
  buildPhoneLayout() {
    Column() {
      Row().width('100%').height(44);
      this.buildTopBar();
      if (this.deleteMode) { this.buildDeleteBanner(); }
      this.buildProgressRow();
      Tabs({ index: this.currentTabIndex }) {
        ForEach(this.TAB_LABELS, (label: string, idx: number) => {
          TabContent() {
            if (this.filteredList.length === 0) {
              Column({ space: 12 }) {
                Text('🎉').fontSize(40);
                Text('今日没有待办任务').fontSize(15).fontColor('#bfbfbf');
                Text('点击右下角 + 新增').fontSize(13).fontColor('#d9d9d9');
              }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
            } else {
              List({ space: 10 }) {
                ForEach(this.filteredList, (task: Task) => {
                  ListItem() {
                    this.buildTaskItem(task);
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
        // 实时保存流转状态
        AppStorage.SetOrCreate(CONTINUE_TAB_INDEX, index);
        AppStorage.SetOrCreate(CONTINUE_PAGE, 'list');
      });
    }
    .width('100%').height('100%').backgroundColor('#f5f7fa');
  }

  // ════════════════════════════════════════════════
  // 大屏布局（md=折叠屏 / lg=平板）
  // ════════════════════════════════════════════════
  @Builder
  buildLargeScreenLayout() {
    Column() {
      Row().width('100%').height(44);
      this.buildTopBar();
      if (this.deleteMode) { this.buildDeleteBanner(); }
      this.buildProgressRow();

      Row() {
        // 左侧分类侧边栏
        Column({ space: 4 }) {
          Text('分类').fontSize(13).fontColor('#8c8c8c')
            .padding({ left: 16, top: 12, bottom: 4 }).alignSelf(ItemAlign.Start);
          ForEach(this.TAB_LABELS, (label: string, idx: number) => {
            Row({ space: 12 }) {
              Row().width(4).height(32)
                .backgroundColor(this.currentTabIndex === idx ? '#ff6b35' : 'transparent')
                .borderRadius(2);
              Text(label).fontSize(15)
                .fontWeight(this.currentTabIndex === idx ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentTabIndex === idx ? '#ff6b35' : '#595959')
                .layoutWeight(1);
              Text(`${this.getCountByTab(idx)}`).fontSize(12)
                .fontColor(this.currentTabIndex === idx ? '#ff6b35' : '#bfbfbf')
                .backgroundColor(this.currentTabIndex === idx ? '#fff3ee' : '#f5f5f5')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(10);
            }
            .width('100%').padding({ left: 12, right: 16, top: 10, bottom: 10 })
            .backgroundColor(this.currentTabIndex === idx ? '#fff8f5' : Color.Transparent)
            .borderRadius(10)
            .onClick(() => { this.currentTabIndex = idx; this.refreshFilteredList(); });
          })
          Blank();
          Column({ space: 6 }) {
            Divider().strokeWidth(0.5).color('#f0f0f0');
            Row({ space: 6 }) {
              Text('🏆').fontSize(16);
              Text(`${this.studyPoints} 分`).fontSize(14).fontColor('#d46b08');
            }.padding({ left: 16, top: 8 });
            Row({ space: 6 }) {
              Text('📅').fontSize(16);
              Text(`打卡 ${this.checkInDays} 天`).fontSize(14).fontColor('#096dd9');
            }.padding({ left: 16, bottom: 16 });
          }
        }
        .width(this.currentBp === 'lg' ? 220 : 180)
        .height('100%').backgroundColor(Color.White);

        Divider().vertical(true).strokeWidth(1).color('#f0f0f0').height('100%');

        // 右侧任务区
        Column() {
          if (this.filteredList.length === 0) {
            Column({ space: 12 }) {
              Text('🎉').fontSize(40);
              Text('今日没有待办任务').fontSize(15).fontColor('#bfbfbf');
              Text('点击右下角 + 新增').fontSize(13).fontColor('#d9d9d9');
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
          } else if (this.currentBp === 'lg') {
            Scroll() {
              Grid() {
                ForEach(this.filteredList, (task: Task) => {
                  GridItem() { this.buildTaskItem(task); }
                }, (task: Task) => `${task.id}_${task.isCompleted}_${task.reminderId}`)
              }
              .columnsTemplate('1fr 1fr').columnsGap(12).rowsGap(12)
              .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 80 });
            }.layoutWeight(1).scrollBar(BarState.Off);
          } else {
            List({ space: 10 }) {
              ForEach(this.filteredList, (task: Task) => {
                ListItem() { this.buildTaskItem(task); }
              }, (task: Task) => `${task.id}_${task.isCompleted}_${task.reminderId}`)
            }
            .width('100%').layoutWeight(1)
            .padding({ left: 16, right: 16, top: 4, bottom: 80 });
          }
        }.layoutWeight(1).height('100%').backgroundColor('#f5f7fa');
      }.layoutWeight(1).width('100%');
    }
    .width('100%').height('100%').backgroundColor('#f5f7fa');
  }

  // ── 共用顶部栏 ────────────────────────────────
  @Builder
  buildTopBar() {
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
      if (this.currentBp === 'sm') {
        Row({ space: 6 }) {
          Text(`🏆 ${this.studyPoints} 分`)
            .fontSize(13).fontColor('#d46b08').backgroundColor('#fff7e6')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(12);
          Text(`📅 打卡 ${this.checkInDays} 天`)
            .fontSize(13).fontColor('#096dd9').backgroundColor('#e6f7ff')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(12);
        }
      }
    }
    .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 10 });
  }

  @Builder
  buildDeleteBanner() {
    Row() {
      Text('🗑  管理模式：点击红色删除按钮可删除任意任务').fontSize(12).fontColor('#ff4d4f');
    }
    .width('100%').padding({ left: 16, right: 16, top: 6, bottom: 6 }).backgroundColor('#fff1f0');
  }

  @Builder
  buildProgressRow() {
    Row() {
      Text(`📆 ${this.today}`).fontSize(13).fontColor('#8c8c8c');
      Blank();
      Text(`完成 ${this.filteredList.filter(t => t.isCompleted).length} / ${this.filteredList.length}`)
        .fontSize(13).fontColor('#8c8c8c');
    }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 4 });
    Stack({ alignContent: Alignment.Start }) {
      Row().width('100%').height(4).backgroundColor('#f0f0f0').borderRadius(2);
      Row()
        .width(this.filteredList.length > 0
          ? `${Math.round(this.filteredList.filter(t => t.isCompleted).length / this.filteredList.length * 100)}%`
          : '0%')
        .height(4).backgroundColor('#ff6b35').borderRadius(2);
    }.width('100%').padding({ left: 16, right: 16 }).margin({ bottom: 4 });
  }


  // ── 任务卡片（列表和网格共用）────────────────
  @Builder
  buildTaskItem(task: Task) {
    Row() {
      if (this.deleteMode) {
        Column() {
          Text('删除').fontSize(13).fontColor(Color.White).backgroundColor('#ff4d4f')
            .padding({ left: 10, right: 10, top: 7, bottom: 7 }).borderRadius(8);
        }.margin({ right: 10 }).onClick(() => { this.confirmDelete(task.id); });
      } else {
        Toggle({ type: ToggleType.Checkbox, isOn: task.isCompleted })
          .size({ width: 22, height: 22 }).selectedColor('#ff6b35')
          .onChange(() => {
            const i = this.taskList.findIndex(t => t.id === task.id);
            if (i >= 0) {
              this.taskList[i].isCompleted = !this.taskList[i].isCompleted;
              if (this.taskList[i].isCompleted) this.updatePoints(this.taskList[i]);
              else this.saveCompletedIds(); // 取消完成也要保存
              this.taskList = [...this.taskList];
              this.refreshFilteredList();
            }
          });
      }
      Column({ space: 5 }) {
        Row({ space: 6 }) {
          Text(task.title).fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor(task.isCompleted ? '#bfbfbf' : '#1a1a1a')
            .decoration({
              type: task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None,
              color: '#bfbfbf'
            })
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1);
          if (task.reminderId >= 0) { Text('🔔').fontSize(12); }
          if (this.isStudyTask(task.taskType)) {
            Text('📝').fontSize(12).fontColor('#722ed1');
          } else {
            Text('💭').fontSize(12).fontColor('#08979c');
          }
        }.width('100%');
        Row({ space: 6 }) {
          Text(this.getTaskLabel(task.taskType)).fontSize(11)
            .fontColor(this.getTagColor(task.taskType))
            .backgroundColor(this.getTagBg(task.taskType))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4);
          Text(`${task.startTime} ~ ${task.endTime}`).fontSize(12).fontColor('#8c8c8c');
          Text(`${task.duration}min`).fontSize(11).fontColor('#b37feb').backgroundColor('#f9f0ff')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4);
          Text(this.getRangeLabel(task)).fontSize(10).fontColor('#8c8c8c').backgroundColor('#f5f5f5')
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
    .borderRadius(12).opacity(task.isCompleted ? 0.7 : 1.0)
    .onClick(() => {
      if (this.deleteMode) return;
      try {
        // 保存流转状态：记录当前在详情页和任务ID
        AppStorage.SetOrCreate(CONTINUE_PAGE, 'detail');
        AppStorage.SetOrCreate(CONTINUE_TASK_ID, task.id);
        router.pushUrl({ url: 'pages/TaskDetailPage', params: task });
      } catch (e) {}
    });
  }

  // ── 新增弹窗 ──────────────────────────────────
  @Builder
  buildAddDialog() {
    Column({ space: 0 }) {
      Row() {
        Text('新增待办').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
        Blank();
        Text('✕').fontSize(18).fontColor('#8c8c8c').onClick(() => { this.showAddDialog = false; });
      }.width('100%').padding({ left: 20, right: 20, top: 20, bottom: 16 });
      Divider().strokeWidth(0.5).color('#f0f0f0');
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 6 }) {
            Text('任务名称').fontSize(13).fontColor('#8c8c8c');
            TextInput({ text: this.newTitle, placeholder: '请输入任务名称' })
              .height(44).backgroundColor('#f5f7fa').borderRadius(8).fontSize(15)
              .onChange((v: string) => { this.newTitle = v; });
          }.alignItems(HorizontalAlign.Start);

          Column({ space: 6 }) {
            Text('任务分类').fontSize(13).fontColor('#8c8c8c');
            Row({ space: 8 }) {
              ForEach(['daily','practice','word','review'], (type: string) => {
                Text(this.getTaskLabel(type)).fontSize(14)
                  .fontColor(this.newType === type ? Color.White : this.getTagColor(type))
                  .backgroundColor(this.newType === type ? '#ff6b35' : this.getTagBg(type))
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(20)
                  .onClick(() => { this.newType = type; });
              })
            }
          }.alignItems(HorizontalAlign.Start);

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

          Column({ space: 6 }) {
            Text(`时长：${this.newDuration} 分钟`).fontSize(13).fontColor('#8c8c8c');
            Row({ space: 8 }) {
              ForEach([15, 30, 45, 60, 90, 120], (min: number) => {
                Text(`${min}`).fontSize(13)
                  .fontColor(this.newDuration === min ? Color.White : '#595959')
                  .backgroundColor(this.newDuration === min ? '#ff6b35' : '#f5f5f5')
                  .padding({ left: 12, right: 12, top: 7, bottom: 7 }).borderRadius(16)
                  .onClick(() => { this.newDuration = min; });
              })
            }
          }.alignItems(HorizontalAlign.Start);

          Column({ space: 10 }) {
            Text('任务存在时间').fontSize(13).fontColor('#8c8c8c');
            Row({ space: 8 }) {
              ForEach(['仅今天','永久固定','自定义范围'], (mode: string, mIdx: number) => {
                Text(mode).fontSize(13)
                  .fontColor(this.newRepeatMode === mIdx ? Color.White : '#595959')
                  .backgroundColor(this.newRepeatMode === mIdx ? '#ff6b35' : '#f5f5f5')
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(20)
                  .onClick(() => { this.newRepeatMode = mIdx; });
              })
            }
            if (this.newRepeatMode === 2) {
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
            }
          }.alignItems(HorizontalAlign.Start);

          Row() {
            Column({ space: 3 }) {
              Text('开启闹钟提醒').fontSize(15).fontColor('#1a1a1a');
              Text('任务开始时振动+通知提醒').fontSize(12).fontColor('#8c8c8c');
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            Toggle({ type: ToggleType.Switch, isOn: this.newEnableReminder })
              .selectedColor('#ff6b35').onChange((v: boolean) => { this.newEnableReminder = v; });
          }.width('100%').padding({ left: 4, right: 4 });
        }
        .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 16 });
      }.layoutWeight(1).scrollBar(BarState.Off);
      Button('添加任务').width('90%').height(48)
        .backgroundColor(this.newTitle.trim() !== '' ? '#ff6b35' : '#d9d9d9')
        .fontColor(Color.White).fontSize(16).borderRadius(24).margin({ bottom: 24 })
        .onClick(() => { this.addTask(); });
    }
    .width('100%').height('75%').backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 }).position({ x: 0, y: '25%' });
  }

  @Builder
  buildTabBar(label: string, index: number) {
    Column() {
      Text(label).fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#ff6b35' : '#595959')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 });
      Row().width(this.currentTabIndex === index ? 24 : 0)
        .height(3).backgroundColor('#ff6b35').borderRadius(2).margin({ bottom: 4 });
    }.alignItems(HorizontalAlign.Center);
  }
}
