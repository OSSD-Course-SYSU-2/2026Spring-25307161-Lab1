// Task.ets
// 1. 先定义构造函数参数的接口类型（解决报错的核心）
interface TaskOptions {
    id: number;
    title: string;
    isCompleted: boolean;
    icon: string;
    // 可选的新增字段（兼容旧数据）
    taskType?: 'daily' | 'word' | 'practice' | 'review';
    startTime?: string;
    endTime?: string;
    duration?: number;
    score?: number;
    note?: string;
    createDate?: string;
}
export class Task {
    id: number; // 任务ID
    title: string; // 任务标题
    isCompleted: boolean; // 完成状态
    icon: string; // 图标资源
    // 新增字段（带默认值）
    taskType: 'daily' | 'word' | 'practice' | 'review' = 'daily'; // 任务类型
    startTime: string = ''; // 开始时间(HH:mm)
    endTime: string = ''; // 结束时间(HH:mm)
    duration: number = 0; // 持续时长(分钟)
    score: number = 0; // 积分
    note: string = ''; // 笔记
    createDate: string = ''; // 创建日期(YYYY-MM-DD)
    // 构造函数（兼容旧数据结构）
    constructor(options: TaskOptions) {
        // 必填字段
        this.id = options.id;
        this.title = options.title;
        this.isCompleted = options.isCompleted;
        this.icon = options.icon;
        // 新增字段处理（有值用传入值，无值用默认值）
        this.taskType = options.taskType ?? 'daily';
        this.startTime = options.startTime ?? '';
        this.endTime = options.endTime ?? '';
        this.duration = options.duration ?? 0;
        this.score = options.score ?? 0;
        this.note = options.note ?? '';
        this.createDate = options.createDate || this.getCurrentDate();
    }
    // 辅助方法：生成当前日期(YYYY-MM-DD)
    private getCurrentDate(): string {
        const now = new Date();
        const year = now.getFullYear();
        const month = `${now.getMonth() + 1}`.padStart(2, '0');
        const day = `${now.getDate()}`.padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
}
