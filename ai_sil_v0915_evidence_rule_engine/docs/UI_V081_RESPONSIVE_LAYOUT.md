# UI v0.8.1 — Responsive Layout

## 修复的问题

v0.8 主窗口允许缩放和最大化，但控件使用固定坐标，因此窗口扩大后右侧与底部会出现未使用的空白区域。

## v0.8.1 行为

- 处理 Win32 `WM_SIZE`。
- 左侧 195px 导航栏保持固定宽度并自动填满客户端高度。
- 220px 之后的工作区根据可用宽度整体重排/扩展。
- 顶部工程和摘要区域保持稳定。
- TestPlan / Evidence 主区吸收约 45% 的新增高度。
- Fault Matrix 吸收约 20% 的新增高度。
- 运行日志吸收剩余新增高度。
- Sidebar footer 固定在底部。
- 不修改 SIL/AI/QEMU/Rule Engine 业务路径。
