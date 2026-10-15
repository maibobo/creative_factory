# SV环境与检查组件

基本TB、轻量SV、完整SV或UVM按功能规模和既有环境选择，不按文件数判断质量。完整SV可包含tb_top、interface、test/激励、driver/BFM、monitor、RM、checker/scoreboard、coverage及env/config；只保留有实际职责的组件。

| 组件 | 负责内容 | 常见问题 |
|---|---|---|
| tb_top/interface | 连接DUT、时钟复位、信号方向及采样/驱动边界 | 同一信号多处驱动，驱动和采样竞态 |
| test/激励 | 当前测试点的事务、约束、模式和错误注入 | 不检查randomize结果，激励未真正到达 |
| driver/BFM | 将事务落实到协议，处理握手和复位 | 用待发送对象冒充已完成事务 |
| monitor | 从实际接口采样并重建事务 | 看错接口、漏尾拍、对象发布后继续修改 |
| RM | 按功能语义计算预期事务/状态 | 复制DUT控制逻辑导致共同错误；未定义复位行为 |
| checker/scoreboard | 周期协议或端到端比较、顺序/ID匹配、残留检查 | 只数完成数量、不比数据；未知响应或剩余事务未报错 |
| coverage | 记录真实发生的功能场景 | 从刺激意图采样，前件从未发生却声称已覆盖 |
| env/config | 组件连接与当前配置 | 默认配置与本次DUT参数不一致 |

## 采样与数据所有权

同步接口使用明确的driver/monitor采样时序；采用原SV规范的clocking block时，从对应clocking成员读写，不混用pin读值形成不同时间快照。单一驱动者原则同样适用于基本TB。异步复位单独说明采样和线程恢复策略。

monitor发布的transaction是实际观察快照。需要缓存或修改的消费者应复制；不要共享可变对象导致历史数据被覆盖。顺序协议可用队列，乱序协议按有效ID匹配；合法的ID复用与顺序约束按具体协议定义，不将所有相同ID简单视为重复错误。

## 检查与结束

周期检查可覆盖反压稳定性、控制X/Z、握手顺序、响应时间和复位后状态。SVA明确时钟、复位条件及有界时限，关键蕴含配合触发覆盖，避免前件没有发生时误判覆盖完成。

端到端检查比较实际有效字节、地址、长度、ID和错误语义，按功能需要选取。测试结束需确认刺激完成、在途事务归零、比较队列清空、checker无失败；watchdog是异常退出，不是正常完成条件。复位中断事务时，各组件按同一已确认语义清理。

UVM环境再应用factory、build/connect/run/check/report、objection和TLM规则。轻量SV不强制使用这些类库机制。原规则中的UVM报告宏仅适用于已加载UVM的环境，普通TB可用一致的自检结果与退出方式。

依据：[SV/UVM规范](../../sources/rules/02_SystemVerilog_UVM验证代码规范.md)的SV-IF、UVM-AGT、UVM-TLM、SV-SVA、SV-COV、UVM-DONE；[最小UVM示例](../../examples/sv_uvm_minimal/README.md)；[Host观察模型案例](../../sources/cases/CASE-006.md)。示例本轮未重新编译运行。
