import { Task } from '../entryability/Task';
import router from '@ohos.router';

@Entry
@Component
struct ToDoListPage {
  // 🔥 1. 全量定制化任务数据（完全匹配你的分类要求）
  @State taskList: Task[] = [
    // ---- 日常代办 (daily) ----
    new Task({ id: 1, title: "晨读英语", taskType: 'daily', startTime: "07:00", endTime: "07:30", duration: 30, isCompleted: false }),
    new Task({ id: 101, title: "晨跑5公里", taskType: 'daily', startTime: "06:30", endTime: "07:10", duration: 40, isCompleted: false }),
    new Task({ id: 102, title: "去食堂吃早餐", taskType: 'daily', startTime: "07:30", endTime: "08:00", duration: 30, isCompleted: false }),
    new Task({ id: 103, title: "参加志愿活动", taskType: 'daily', startTime: "09:00", endTime: "11:00", duration: 120, isCompleted: false }),
    new Task({ id: 104, title: "去图书馆占座", taskType: 'daily', startTime: "13:00", endTime: "13:30", duration: 30, isCompleted: false }),
    new Task({ id: 105, title: "取快递/外卖", taskType: 'daily', startTime: "17:00", endTime: "17:45", duration: 45, isCompleted: false }),
    new Task({ id: 106, title: "参加社团讲座", taskType: 'daily', startTime: "19:00", endTime: "20:30", duration: 90, isCompleted: false }),
    new Task({ id: 107, title: "回宿舍洗衣服", taskType: 'daily', startTime: "21:00", endTime: "22:00", duration: 60, isCompleted: false }),

    // ---- 刷题代办 (practice) ----
    new Task({ id: 2, title: "算法刷题", taskType: 'practice', startTime: "14:00", endTime: "15:30", duration: 90, isCompleted: false }),
    new Task({ id: 201, title: "高数习题集(上)", taskType: 'practice', startTime: "10:00", endTime: "11:30", duration: 90, isCompleted: false }),
    new Task({ id: 202, title: "线性代数习题", taskType: 'practice', startTime: "15:00", endTime: "16:30", duration: 90, isCompleted: false }),
    new Task({ id: 203, title: "大学物理(大物)", taskType: 'practice', startTime: "08:30", endTime: "10:00", duration: 90, isCompleted: false }),
    new Task({ id: 204, title: "电路分析基础", taskType: 'practice', startTime: "19:00", endTime: "20:30", duration: 90, isCompleted: false }),
    new Task({ id: 205, title: "C语言程序设计", taskType: 'practice', startTime: "16:00", endTime: "17:30", duration: 90, isCompleted: false }),
    new Task({ id: 206, title: "离散数学刷题", taskType: 'practice', startTime: "13:00", endTime: "14:30", duration: 90, isCompleted: false }),

    // ---- 单词代办 (word) ----
    new Task({ id: 3, title: "单词背诵", taskType: 'word', startTime: "20:00", endTime: "20:45", duration: 45, isCompleted: false }),
    new Task({ id: 301, title: "四六级核心词(abandon)", taskType: 'word', startTime: "07:00", endTime: "07:45", duration: 45, isCompleted: false }),
    new Task({ id: 302, title: "四六级高频词(accept)", taskType: 'word', startTime: "12:00", endTime: "12:45", duration: 45, isCompleted: false }),
    new Task({ id: 303, title: "四六级词汇(access)", taskType: 'word', startTime: "18:00", endTime: "18:45", duration: 45, isCompleted: false }),
    new Task({ id: 304, title: "考研词汇(ache)", taskType: 'word', startTime: "21:00", endTime: "21:45", duration: 45, isCompleted: false }),
    new Task({ id: 305, title: "雅思词汇(acid)", taskType: 'word', startTime: "10:00", endTime: "10:45", duration: 45, isCompleted: false }),

    // ---- 复习代办 (review) ----
    new Task({ id: 4, title: "高数复习", taskType: 'review', startTime: "19:00", endTime: "20:00", duration: 60, isCompleted: false }),
    new Task({ id: 401, title: "专业课巩固", taskType: 'review', startTime: "14:00", endTime: "15:30", duration: 90, isCompleted: false }),
    new Task({ id: 402, title: "英语听力复盘", taskType: 'review', startTime: "17:00", endTime: "18:00", duration: 60, isCompleted: false }),
    new Task({ id: 403, title: "大物公式回顾", taskType: 'review', startTime: "09:00", endTime: "10:30", duration: 90, isCompleted: false }),
    new Task({ id: 404, title: "C++进阶复习", taskType: 'review', startTime: "16:00", endTime: "17:30", duration: 90, isCompleted: false }),
    new Task({ id: 405, title: "毛概知识点复习", taskType: 'review', startTime: "20:00", endTime: "21:30", duration: 90, isCompleted: false })
  ];

  @StorageProp('studyPoints') studyPoints: number = 0;
  @StorageProp('checkInDays') checkInDays: number = 0;
  @StorageProp('lastCheckDate') lastCheckDate: number = 0;
  @State currentTabIndex: number = 0; // 当前选中Tab索引

  // 标签映射
  private getTaskLabel(taskType: string): string {
    const labelMap: Record<string, string> = {
      'daily': "日常",
      'word': "单词",
      'practice': "刷题",
      'review': "复习"
    };
    return labelMap[taskType] || "日常";
  }

  // 积分更新
  private updatePoints(task: Task): void {
    try {
      const today = new Date().setHours(0, 0, 0, 0);
      if (this.lastCheckDate !== today) {
        this.checkInDays += 1;
        this.studyPoints += 20;
        this.lastCheckDate = today;
      }
      this.studyPoints += task.taskType === 'daily' ? 5 : 10;
    } catch (e) {
      console.error('Update points error:', e);
    }
  }

  build() {
    Column() {
      // 🔥 2. 移除顶部标题，只保留积分/打卡栏
      Row() {
        // Text("我的学习待办") -> 已按要求删除
        //   .fontSize(26)
        //   .fontWeight(FontWeight.Bold);

        Blank()

        Text(`积分: ${this.studyPoints}`)
          .fontSize(16)
          .backgroundColor('#fff1f0')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(6);

        Text(`打卡: ${this.checkInDays}天`)
          .fontSize(16)
          .backgroundColor('#e6f7ff')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(6)
          .margin({ left: 6 });
      }
      .width('100%')
      .margin({ top: 16, bottom: 12, left: 16, right: 16 });

      // 🔥 3. Tab分类栏（核心：多分类切换）
      Tabs({
        index: this.currentTabIndex,
        controller: new TabsController()
      }) {
        ForEach(this.getTaskLabels(), (tab: string, index: number) => {
          TabContent() {
            List({ space: 12 }) {
              // 遍历过滤后的任务
              ForEach(this.getFilteredTasksByType(index), (task: Task) => {
                ListItem() {
                  Row() {
                    Toggle({ type: ToggleType.Checkbox, isOn: task.isCompleted })
                      .size({ width: 22, height: 22 })
                      .onChange(() => {
                        task.isCompleted = !task.isCompleted;
                        if (task.isCompleted) {
                          this.updatePoints(task);
                        }
                        // 触发刷新
                        this.taskList = [...this.taskList];
                      });

                    Column({ space: 4 }) {
                      Text(task.title)
                        .fontSize(17)
                        .fontWeight(FontWeight.Bold)
                        .decoration({
                          type: task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None
                        });

                      Row() {
                        Text(this.getTaskLabel(task.taskType))
                          .fontSize(12)
                          .backgroundColor('#e6f7ff')
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .borderRadius(4);

                        Text(`${task.startTime} ~ ${task.endTime}`)
                          .fontSize(12)
                          .fontColor('#666')
                          .margin({ left: 6 });
                      }
                    }
                    .layoutWeight(1)
                    .margin({ left: 10 });
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#fff')
                  .borderRadius(10)
                  .onClick(() => {
                    try {
                      router.pushUrl({
                        url: 'pages/TaskDetailPage',
                        params: task
                      });
                    } catch (e) {
                      console.error('Router error:', e);
                    }
                  });
                }
              }, (task: Task) => task.id.toString())
            }
            .width('100%')
            .height('100%')
            .padding({ left: 16, right: 16 });
          }
          .tabBar(tab)
        })
      }
      .barMode(BarMode.Scrollable)
      .barHeight(40)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa');
  }

  // 辅助方法：生成Tab标签列表
  private getTaskLabels(): string[] {
    return ["全部", "日常", "刷题", "单词", "复习"];
  }

  // 辅助方法：根据当前Tab索引筛选任务
  private getFilteredTasksByType(tabIndex: number): Task[] {
    if (tabIndex === 0) {
      return this.taskList; // 全部显示
    }
    const typeMap: Record<number, string> = {
      1: 'daily',
      2: 'practice',
      3: 'word',
      4: 'review'
    };
    const targetType = typeMap[tabIndex];
    return this.taskList.filter(task => task.taskType === targetType);
  }
}