/**
 * 任务模型（严格符合 DevEco 6.1.0 规范）
 * 禁用：Partial、对象字面量作为类型
 * 启用：显式字段 + 接口定义
 */
export interface TaskOptions {
  id: number;
  title: string;
  taskType?: 'daily' | 'word' | 'practice' | 'review';
  startTime?: string;
  endTime?: string;
  duration?: number;
  isCompleted?: boolean;
  icon?: string;
  notes?: string;
}

export class Task {
  // 强类型必选字段
  public id: number;
  public title: string;
  public taskType: 'daily' | 'word' | 'practice' | 'review';
  public startTime: string;
  public endTime: string;
  public duration: number;

  // 可选字段
  public isCompleted: boolean;
  public icon: string;
  public notes: string;

  constructor(options: TaskOptions) {
    this.id = options.id;
    this.title = options.title;
    this.taskType = options.taskType ?? 'daily';
    this.startTime = options.startTime ?? '00:00';
    this.endTime = options.endTime ?? '00:00';
    this.duration = options.duration ?? 25;
    this.isCompleted = options.isCompleted ?? false;
    this.icon = options.icon ?? '';
    this.notes = options.notes ?? '';
  }
}