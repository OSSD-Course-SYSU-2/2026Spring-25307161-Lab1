# SmartStudy Schedule · 智学日程

> A HarmonyOS App for college students — task management, focus timer & study notes, all in one.  
> Built upon Huawei's official Codelab To-Do List sample with extensive feature enhancements.

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0+-red?logo=huawei)](https://developer.huawei.com)
[![ArkTS](https://img.shields.io/badge/Language-ArkTS-blue)](https://developer.huawei.com/consumer/cn/arkts/)
[![DevEco Studio](https://img.shields.io/badge/IDE-DevEco%20Studio%206.0-brightgreen)](https://developer.huawei.com/consumer/cn/deveco-studio/)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange)](LICENSE)

---

## 📖 Overview

**SmartStudy Schedule** is a HarmonyOS-native App deeply customized for college students' daily academic life.  
Starting from Huawei's official Codelab To-Do List template, the project delivers a complete redesign and feature expansion covering multi-category task management, flexible scheduling, focus timer with lock-screen mode, smart note system, alarm reminders, and a gamified points system.

---

## 🖼 Screenshots

<table>
  <tr>
    <td align="center">
      <img src="screenshots/device/screenshots/home.png" width="220" alt="Task List Home"/>
      <br/><sub><b>Home · Multi-category Task List</b></sub>
    </td>
    <td align="center">
      <img src="screenshots/device/screenshots/delete.png" width="220" alt="Delete Mode"/>
      <br/><sub><b>Manage Mode · Delete Any Task</b></sub>
    </td>
    <td align="center">
      <img src="screenshots/device/screenshots/add.png" width="220" alt="Add Task Dialog"/>
      <br/><sub><b>Add Task · Full Configuration</b></sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="screenshots/device/screenshots/daily_detail.png" width="220" alt="Daily Task Detail"/>
      <br/><sub><b>Daily Task · Record Thoughts</b></sub>
    </td>
    <td align="center">
      <img src="screenshots/device/screenshots/study_detail.png" width="220" alt="Study Task Detail"/>
      <br/><sub><b>Study Task · Notes + Materials</b></sub>
    </td>
    <td align="center">
      <img src="screenshots/device/screenshots/focus.png" width="220" alt="Focus Lock Mode"/>
      <br/><sub><b>Lock-Screen Focus Mode</b></sub>
    </td>
  </tr>
</table>

---

## ✨ Key Features

### 1. Multi-Category Task Management

Tasks are organized into four categories: **Daily / Practice / Vocabulary / Review**, switchable via a top Tab bar. Each category comes pre-loaded with student-oriented tasks (morning run, math exercises, CET-6 vocabulary, course review, etc.).

<table>
  <tr>
    <td align="center">
      <img src="screenshots/device/screenshots/home.png" width="220" alt="Home"/>
      <br/><sub>▲ Home page with Tab switching and real-time progress bar</sub>
    </td>
    <td align="center">
      <img src="screenshots/device/screenshots/delete.png" width="220" alt="Delete Mode"/>
      <br/><sub>▲ Manage mode — delete any task with confirmation dialog</sub>
    </td>
  </tr>
</table>

---

### 2. Custom Task Creation · Flexible Scheduling

Tap the **+** button to open the bottom sheet panel. Configure:

- Task name, category, start/end time, duration
- **Task Visibility — 3 modes:**
  - 📅 **Today Only** — disappears automatically the next day
  - 🔁 **Permanent** — shown every day until manually deleted
  - 📆 **Custom Date Range** — specify start and end dates, ideal for exam prep or short-term plans

<div align="center">
  <img src="screenshots/device/screenshots/add.png" width="260" alt="Add Task"/>
  <br/>
  <sub>▲ Add Task panel — category, time, duration, schedule mode & alarm in one place</sub>
</div>

---

### 3. Task Deletion Management

Enter **Manage Mode** via the top-right button. A red banner appears and all task cards show a red **Delete** button. A confirmation dialog prevents accidental deletion. Associated reminders are cancelled automatically upon deletion.

---

### 4. Smart Notes · Adapts to Task Type

The note interface automatically switches based on task category:

| Task Type | Note Mode | Features |
|-----------|-----------|---------|
| Practice / Vocabulary / Review | 📝 Study Note Mode | Study notes + 📎 Learning materials import |
| Daily | 💭 Thought Journal Mode | Diary-style free writing |

<table>
  <tr>
    <td align="center">
      <img src="screenshots/device/screenshots/daily_detail.png" width="220" alt="Daily Detail"/>
      <br/><sub>▲ Daily task — "Record Thoughts" journal mode</sub>
    </td>
    <td align="center">
      <img src="screenshots/device/screenshots/study_detail.png" width="220" alt="Study Detail"/>
      <br/><sub>▲ Study task — notes + learning materials import</sub>
    </td>
  </tr>
</table>

---

### 5. Focus Timer · Immersive Lock-Screen Mode

<div align="center">
  <img src="screenshots/device/screenshots/focus.png" width="260" alt="Focus Mode"/>
  <br/>
  <sub>▲ Lock-screen focus mode — full-screen dark UI, progress bar, in-session note taking</sub>
</div>

- Quick-select durations: 15 / 25 / 45 / 60 min
- Custom duration with ＋/－ controls
- **🔒 Lock-Screen Focus** — blocks distractions with a full-screen dark interface
- Supports in-session note taking without exiting focus mode

---

### 6. Alarm Reminders · Vibration + Notification

Powered by HarmonyOS `reminderAgentManager` (agent-based reminders):

- **Remains effective even after the App is closed**
- Vibration + notification dual alert
- Configurable reminder time per task (minute-level precision)
- Quick preset times available (07:00, 08:00, 09:00, etc.)
- Alarm is automatically cancelled when the task is deleted

---

### 7. Points & Check-in System

| Action | Points Awarded |
|--------|---------------|
| Complete a daily task | +5 pts |
| Complete a study task | +10 pts |
| First check-in of the day | +20 pts |

Points and check-in streak are displayed in real time. Data is persisted via `AppStorage`.

---

## 🛠 Tech Stack

| Technology | Details |
|------------|---------|
| **Language** | ArkTS (HarmonyOS Declarative Syntax) |
| **IDE** | DevEco Studio 6.0+ |
| **Target OS** | HarmonyOS 5.0+ |
| **UI Paradigm** | Declarative UI — `@Component` / `@Entry` / `@Builder` |
| **State Management** | `@State` / `@StorageProp` / `AppStorage` |
| **Navigation** | `@ohos.router` |
| **Reminders** | `@ohos.reminderAgentManager` (background-safe) |
| **Persistence** | `AppStorage.SetOrCreate` |

---

## 📁 Project Structure

```
entry/src/main/ets/
├── entryability/
│   ├── EntryAbility.ets      # App entry point, AppStorage initialization
│   └── Task.ets              # Task data model (Task / TaskParams)
└── pages/
    ├── ToDoListPage.ets      # Home: categories, add/delete, points, progress
    └── TaskDetailPage.ets    # Detail: notes, alarm, focus timer, lock-screen
```

---

## 🚀 Getting Started

```bash
# 1. Install DevEco Studio 6.0+
# 2. Clone the repository
git clone https://github.com/OSSD-Course-SYSU-2/2026Spring-25307161-Lab1.git
# 3. Open in DevEco Studio, connect emulator or physical device
# 4. Press Shift + F10 to run, allow permissions on first launch
```

> **Required Permissions:**
> - `ohos.permission.PUBLISH_AGENT_REMINDER`
> - `ohos.permission.VIBRATE`

---

## 🔄 Improvements over Original Codelab

| Feature | Original Codelab | SmartStudy Schedule |
|---------|-----------------|---------------------|
| Task categories | None | 4 categories + Tab switching |
| Add custom tasks | None | Bottom sheet with full config |
| Delete tasks | None | Manage mode, all tasks deletable |
| Task schedule modes | None | Today / Permanent / Custom range |
| Notes | None | Study notes + Daily journal (auto-switch) |
| Learning materials | None | File import per study task |
| Focus timer | None | Countdown + lock-screen immersive mode |
| Alarm reminders | None | Vibration + notification, background-safe |
| Points system | None | Task completion rewards + daily check-in |
| UI Design | Basic list | Progress bar, color tags, animated Tab, orange theme |

---

## 👨‍💻 Developer

| Field | Info |
|-------|------|
| Student ID | 25307161 |
| Course | Open Source Software Development · 2026 Spring |
| University | Sun Yat-sen University (SYSU) |
| Base Project | [HarmonyOS Official Codelab · To-Do List](https://developer.huawei.com/consumer/cn/codelabsPortal/carddetails/tutorials_Next-GettingStarted-ArkTS-todo) |

---

<div align="center">
  <sub>Built with ❤️ on HarmonyOS · ArkTS</sub>
</div>
