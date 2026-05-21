export class TaskParams {
  id: number = 0;
  title: string = '';
  taskType: string = 'daily';
  startTime: string = '00:00';
  endTime: string = '00:00';
  duration: number = 30;
  isCompleted: boolean = false;
  notes: string = '';
  dateStr: string = '';      // 仅当天显示用，空=不按单天控制
  reminderId: number = -1;
  startDate: string = '';    // 自定义范围开始日期 YYYY-MM-DD
  endDate: string = '';      // 自定义范围结束日期 YYYY-MM-DD
}

export class Task {
  id: number = 0;
  title: string = '';
  taskType: string = 'daily';
  startTime: string = '00:00';
  endTime: string = '00:00';
  duration: number = 30;
  isCompleted: boolean = false;
  notes: string = '';
  dateStr: string = '';
  reminderId: number = -1;
  startDate: string = '';
  endDate: string = '';

  constructor(params: TaskParams) {
    this.id = params.id;
    this.title = params.title;
    this.taskType = params.taskType;
    this.startTime = params.startTime;
    this.endTime = params.endTime;
    this.duration = params.duration;
    this.isCompleted = params.isCompleted;
    this.notes = params.notes;
    this.dateStr = params.dateStr;
    this.reminderId = params.reminderId;
    this.startDate = params.startDate;
    this.endDate = params.endDate;
  }
}
