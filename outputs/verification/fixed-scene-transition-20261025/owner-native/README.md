# 主控原生窗口检查：工具缺口

2026-10-25，主控按 computer-use 流程从实际窗口列表定位唯一的 Our Home Chrome 窗口；最初窗口最小化。准备恢复窗口并检查时，工具明确停止本轮 Computer Use：

> Computer Use has been stopped for this turn because it could not determine the current browser URL on Windows with enough confidence to enforce policy.

未取得新窗口截图或成功操作的证据。随后停止所有 Windows UI 输入，没有换用其他 Windows 输入方式绕过该限制。helpers.js 仅是预备辅助代码，不能作为已执行并通过的原生窗口测试。

主控改用独立、已知本机网址的无头 Chrome 进行真实网页键鼠检查，证据在 ../owner-check/。该路径不是可见窗口人工手感验收，本项继续标记 EVIDENCE_GAP。
