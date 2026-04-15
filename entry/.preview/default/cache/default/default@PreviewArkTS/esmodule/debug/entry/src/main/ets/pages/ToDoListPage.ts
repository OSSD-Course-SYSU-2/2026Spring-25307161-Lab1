if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ToDoListPage_Params {
    taskList?: Task[];
    typeLabels?: Record<string, string>;
}
import { Task } from "@bundle:com.huawei.todolist/entry/ets/entryability/Task";
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
class ToDoListPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__taskList = new ObservedPropertyObjectPU([
            new Task({
                id: 1,
                title: "晨读英语",
                isCompleted: false,
                icon: "book.svg",
                taskType: "daily",
                startTime: "07:00",
                endTime: "07:30",
                duration: 30
            }),
            new Task({
                id: 2,
                title: "算法刷题",
                isCompleted: true,
                icon: "code.svg",
                taskType: "practice",
                startTime: "14:00",
                endTime: "15:30",
                duration: 90
            }),
            new Task({
                id: 3,
                title: "单词记忆",
                isCompleted: false,
                icon: "word.svg",
                taskType: "word",
                startTime: "20:00",
                endTime: "20:45",
                duration: 45
            })
        ], this, "taskList");
        this.typeLabels = {
            'daily': '日常',
            'word': '单词',
            'practice': '刷题',
            'review': '复习'
        };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ToDoListPage_Params) {
        if (params.taskList !== undefined) {
            this.taskList = params.taskList;
        }
        if (params.typeLabels !== undefined) {
            this.typeLabels = params.typeLabels;
        }
    }
    updateStateVars(params: ToDoListPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__taskList.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__taskList.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __taskList: ObservedPropertyObjectPU<Task[]>;
    get taskList() {
        return this.__taskList.get();
    }
    set taskList(newValue: Task[]) {
        this.__taskList.set(newValue);
    }
    private typeLabels: Record<string, string>;
    private toggleTaskStatus(index: number) {
        this.taskList[index].isCompleted = !this.taskList[index].isCompleted;
        this.taskList = [...this.taskList];
    }
    // 完全符合ArkTS规范的跳转方法，彻底消除异常警告
    private navigateToDetail(task: Task): void {
        if (!task) {
            promptAction.showToast({ message: "任务数据异常" });
            return;
        }
        try {
            const options: router.RouterOptions = {
                url: "pages/TaskDetailPage",
                params: { task: task }
            };
            router.pushUrl(options);
        }
        catch (error) {
            const errMsg = error instanceof Error ? error.message : "未知错误";
            promptAction.showToast({ message: `跳转失败: ${errMsg}` });
            console.error("Router error:", error);
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(74:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.padding(16);
            Column.backgroundColor('#f5f5f5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("我的待办");
            Text.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(75:7)", "entry");
            Text.fontSize(30);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ top: 20, bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            List.create({ space: 12 });
            List.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(80:7)", "entry");
            List.width('100%');
            List.height('100%');
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const task = _item;
                {
                    const itemCreation = (elmtId, isInitialRender) => {
                        ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                        ListItem.create(deepRenderFunction, true);
                        if (!isInitialRender) {
                            ListItem.pop();
                        }
                        ViewStackProcessor.StopGetAccessRecording();
                    };
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        ListItem.create(deepRenderFunction, true);
                        ListItem.border({ width: 1, color: '#eeeeee' });
                        ListItem.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(82:11)", "entry");
                    };
                    const deepRenderFunction = (elmtId, isInitialRender) => {
                        itemCreation(elmtId, isInitialRender);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Row.create();
                            Row.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(83:13)", "entry");
                            Row.padding(8);
                            Row.borderRadius(8);
                            Row.backgroundColor('#ffffff');
                            Row.onClick(() => this.navigateToDetail(task));
                        }, Row);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Toggle.create({ type: ToggleType.Checkbox, isOn: task.isCompleted });
                            Toggle.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(84:15)", "entry");
                            Toggle.size({ width: 24, height: 24 });
                            Toggle.onChange(() => this.toggleTaskStatus(index));
                            Toggle.margin(12);
                        }, Toggle);
                        Toggle.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(89:15)", "entry");
                            Column.layoutWeight(1);
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(task.title);
                            Text.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(90:17)", "entry");
                            Text.fontSize(18);
                            Text.fontWeight(FontWeight.Bold);
                            Text.decoration({ type: task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None });
                            Text.opacity(task.isCompleted ? 0.6 : 1);
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Row.create();
                            Row.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(96:17)", "entry");
                            Row.margin({ top: 4 });
                        }, Row);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(this.typeLabels[task.taskType]);
                            Text.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(97:19)", "entry");
                            Text.fontSize(12);
                            Text.padding(4);
                            Text.backgroundColor('#e6f7ff');
                            Text.borderRadius(4);
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(`${task.startTime} - ${task.endTime} (${task.duration}分钟)`);
                            Text.debugLine("entry/src/main/ets/pages/ToDoListPage.ets(103:19)", "entry");
                            Text.fontSize(12);
                            Text.fontColor('#666');
                            Text.margin({ left: 8 });
                        }, Text);
                        Text.pop();
                        Row.pop();
                        Column.pop();
                        Row.pop();
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, this.taskList, forEachItemGenFunction, (task: Task) => task.id.toString(), true, false);
        }, ForEach);
        ForEach.pop();
        List.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ToDoListPage";
    }
}
registerNamedRoute(() => new ToDoListPage(undefined, {}), "", { bundleName: "com.huawei.todolist", moduleName: "entry", pagePath: "pages/ToDoListPage", pageFullPath: "entry/src/main/ets/pages/ToDoListPage", integratedHsp: "false", moduleType: "followWithHap" });
