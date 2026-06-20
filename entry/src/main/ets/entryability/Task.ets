export class TaskParams {
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

  // 序列化为 JSON 字符串（用于 Preferences 存储）
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      title: this.title,
      taskType: this.taskType,
      startTime: this.startTime,
      endTime: this.endTime,
      duration: this.duration,
      isCompleted: this.isCompleted,
      notes: this.notes,
      dateStr: this.dateStr,
      reminderId: this.reminderId,
      startDate: this.startDate,
      endDate: this.endDate
    });
  }

  // 从 JSON 对象还原 Task（用于 Preferences 读取）
  static fromObj(obj: Record<string, Object>): Task {
    const p = new TaskParams();
    p.id           = obj['id']          as number  ?? 0;
    p.title        = obj['title']       as string  ?? '';
    p.taskType     = obj['taskType']    as string  ?? 'daily';
    p.startTime    = obj['startTime']   as string  ?? '00:00';
    p.endTime      = obj['endTime']     as string  ?? '00:00';
    p.duration     = obj['duration']    as number  ?? 30;
    p.isCompleted  = obj['isCompleted'] as boolean ?? false;
    p.notes        = obj['notes']       as string  ?? '';
    p.dateStr      = obj['dateStr']     as string  ?? '';
    p.reminderId   = obj['reminderId']  as number  ?? -1;
    p.startDate    = obj['startDate']   as string  ?? '';
    p.endDate      = obj['endDate']     as string  ?? '';
    return new Task(p);
  }
}
