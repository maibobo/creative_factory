> 本包离线整理副本，整理日期：2026-10-13。依据用户已确认采用的项目规范保留规则编号；不作为已核实的厂商原文制度。历史工具版本、标准映射及来源标签沿用原稿，未在本轮重新验证。FPGA适用范围以[规则适用说明](../../knowledge/规范/规则适用说明.md)为准。

# SystemVerilog/UVM 验证代码规范

版本：1.0.0  
当前可执行基线：Synopsys VCS Q-2020.03-SP2-7、UVM 1.2  
标准映射：IEEE 1800-2023、IEEE 1800.2-2020

## 1. 范围与依据

本文件只适用于验证代码：testbench 顶层、interface、package、class、sequence、UVM component、SVA、功能覆盖率、参考模型和 DPI 适配层。它独立于 ASIC Verilog RTL 规范，不能作为在 ASIC RTL 中使用 SystemVerilog 语法的许可。

规则级别沿用 M1、M2、R。每条规则还带有来源标签：

- `SV-STD`：SystemVerilog 语言语义，以 [IEEE 1800-2023](https://standards.ieee.org/ieee/1800/7743/) 为当前参考。
- `UVM-STD`：标准 UVM API 与行为，以 [IEEE 1800.2-2020](https://standards.ieee.org/ieee/62530-2/11429/1800.2/7567/) 为映射目标。
- `UVM-REC`：由 [Accellera UVM 1.2 User Guide](https://www.accellera.org/images/downloads/standards/uvm/uvm_users_guide_1.2.pdf) 等官方方法学资料支持的实践。
- `TEAM`：本项目为可维护性、可移植性和当前工具兼容性作出的约定。

Accellera 下载页把 UVM 1.2 和 IEEE 1800.2 参考实现分开发布，因此“当前运行 UVM 1.2”与“向 1800.2-2020 对齐”是两个不同概念。本规范只使用 VCS 2020/UVM 1.2 已支持的 API 编写示例；迁移时再采用新参考实现功能。

## 2. 兼容性基线

| 层次 | 当前项目基线 | 现代参考 | 处理原则 |
|---|---|---|---|
| 仿真器 | VCS Q-2020.03-SP2-7 | 项目后续批准版本 | 示例必须先在当前版本通过；新语法需兼容性试验 |
| UVM 库 | UVM 1.2 | IEEE 1800.2-2020 对应参考实现 | 不调用只存在于新实现的 API |
| SV 语言 | 当前 VCS 支持的 SystemVerilog | IEEE 1800-2023 | 标准合法但当前工具不支持时隔离并记录 waiver |
| UVM API | UVM 1.2 公共 API | IEEE 1800.2 公共 API | 新代码不依赖实现内部符号或供应商扩展 |

`accellera-official/uvm-core` 对 API 标有 `@uvm-ieee`、`@uvm-contrib`、`@uvm-accellera`、`@uvm-compat` 等类别。只有标准公共 API 具有跨实现可移植性；其他类别必须隔离在适配层并有兼容性测试。

## 3. 文件、package 与编译边界

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-ORG-001` | M1/TEAM | interface、module、program、checker/bind 单元放在 package 外；class、typedef、enum、参数化验证类型放在 package 内。 |
| `SV-ORG-002` | M2/TEAM | 一个公共 class 一个 `.svh` 文件。文件名与 class 名一致并使用小写下划线。只在所属 package 中 `include`。 |
| `SV-ORG-003` | M1/TEAM | 编译 package 文件，不要再把已由 package `include` 的 class 文件单独加入 filelist，避免重复定义。 |
| `SV-ORG-004` | M1/SV-STD | package 先定义基础类型/config/item，再依次包含 agent、env、sequence、test；依赖方向只能从上层指向已定义的下层类型。 |
| `SV-ORG-005` | M2/TEAM | 推荐按 `types/config/items`、`agent/env`、`sequences/tests` 分层 package；大型项目不得形成互相 import 的 package 环。 |
| `SV-ORG-006` | M1/TEAM | filelist、宏、include 路径、UVM 库版本和顶层必须进入版本控制；不得依赖用户 shell 中未记录的隐式设置。 |
| `SV-ORG-007` | M2/TEAM | package 外使用选择性 `import pkg::type_name`；testbench 顶层可为简洁使用 `import pkg::*`，设计/公共 VIP 不滥用通配 import。 |

推荐后缀：`_pkg`、`_if`、`_cfg`、`_item`、`_seq`、`_sequencer`、`_driver`、`_monitor`、`_agent`、`_env`、`_scoreboard`、`_coverage`、`_test`。报告 ID 使用稳定的大写路径式名称，例如 `DEMO/SCOREBOARD/MISMATCH`。

## 4. 类型、数据与类设计

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-TYPE-001` | M1/SV-STD | 协议字段使用明确宽度的 `bit`/`logic`；需要观察 X/Z 的接口采样和断言使用四态类型，纯算法或已知二态数据可用 `bit`。 |
| `SV-TYPE-002` | M2/SV-STD | 用 `enum` 表达有限状态/操作码，用 `struct` 聚合固定值类型；不要用裸整数承载多个含义。 |
| `SV-TYPE-003` | M1/TEAM | transaction 发布后视为不可变快照。生产者不得复用并修改已经发布的对象；消费者要长期保存时必须 `clone()` 或 `copy()`。 |
| `SV-TYPE-004` | M1/TEAM | 同一个可变对象句柄不得同时交给两个拥有者。mailbox/TLM 传递时明确所有权，广播对象按只读快照处理。 |
| `SV-TYPE-005` | M2/TEAM | 大 transaction 优先显式实现 `do_copy`、`do_compare`、`do_print`/`convert2string`；避免大量 field automation macro 带来的性能和语义不透明。 |
| `SV-TYPE-006` | M1/SV-STD | 覆盖父类虚方法时签名必须一致并使用 `virtual`；构造函数调用 `super.new`，不得在构造函数中消耗仿真时间。 |

## 5. Factory、构造和组件层次

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-FAC-001` | M1/UVM-STD | 所有需要 factory override 的 object/component 使用对应 `uvm_object_utils` 或 `uvm_component_utils` 注册。参数化类型使用参数化宏。 |
| `UVM-FAC-002` | M1/UVM-REC | factory 管理的 object/component 通过 `type_id::create` 构造；TLM port/export、covergroup 和不参与替换的局部辅助对象使用 `new`。 |
| `UVM-FAC-003` | M2/TEAM | component 构造函数只保存 name/parent 并创建必须在构造期存在的端口；子组件在 `build_phase` 创建，连接在 `connect_phase` 完成。 |
| `UVM-FAC-004` | M1/UVM-REC | 重写标准 phase 时默认先调用 `super.<phase>(phase)`；只有确认父类为空且项目明确允许时才能省略。 |
| `UVM-FAC-005` | M2/TEAM | override 在 test 的 build 早期、被替换对象创建之前设置；使用类型 override 优先于易受层次名影响的实例 override。 |
| `UVM-FAC-006` | M1/TEAM | 禁止通过 `new` 绕过 factory 后又声称该对象可由测试替换。 |

## 6. 配置与 virtual interface

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-CFG-001` | M1/TEAM | 相关配置聚合为强类型 `<agent>_cfg`/`<env>_cfg` 对象；不要把大量标量键散落在 config_db。 |
| `UVM-CFG-002` | M1/UVM-REC | virtual interface 和必需配置的 `get()` 必须检查返回值；缺失、类型错误或 `$cast` 失败立即 `uvm_fatal`。 |
| `UVM-CFG-003` | M1/TEAM | `set()` 使用最窄且稳定的层次范围。禁止无边界 `"*"`；只有项目顶层向明确子树广播公共只读配置且有评审依据时允许受限通配。 |
| `UVM-CFG-004` | M2/TEAM | build 结束后配置视为只读。组件缓存已获取的 config/vif；run 热路径中禁止重复查询 config_db。 |
| `UVM-CFG-005` | M1/TEAM | driver 和 monitor 使用带 modport 的 virtual interface；若 VCS 兼容问题迫使使用完整 interface 类型，必须有工具版本 waiver。 |
| `UVM-CFG-006` | M2/TEAM | config 对象包含 active/passive、超时、协议参数等环境策略；test 设置策略，agent/component 执行策略。 |

## 7. Interface、clocking block 与信号所有权

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-IF-001` | M1/SV-STD | 每个同步接口定义独立的 driver clocking block 和 monitor clocking block；推荐 `default input #1step output #0`。 |
| `SV-IF-002` | M1/TEAM | driver 在 `@(vif.drv_cb)` 上驱动并只访问 `drv_cb` 成员；monitor 在 `@(vif.mon_cb)` 上采样并只访问 `mon_cb` 成员。 |
| `SV-IF-003` | M1/TEAM | 每个 testbench 驱动信号只有一个 owner。禁止 test、sequence、driver 和顶层 initial 块同时驱动同一协议信号。 |
| `SV-IF-004` | M1/SV-STD | DUT、driver、monitor 通过不同 modport 限定方向；不得用层次引用绕过 modport 访问不属于自己的信号。 |
| `SV-IF-005` | M2/TEAM | 异步复位可作为 clocking block 之外的唯一常见采样例外，但必须在 interface 中集中处理并说明竞态规避方式。 |
| `SV-IF-006` | M1/TEAM | 禁止在 class 中用 XMR 直接访问 DUT 信号。内部观察点通过 interface、bind checker 或批准的 backdoor adapter 暴露。 |

## 8. Phase 与 objection

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-PHS-001` | M1/UVM-REC | 结构创建放在 build，TLM 连接放在 connect，运行时行为放在 run；检查残留放在 check，摘要放在 report。 |
| `UVM-PHS-002` | M1/TEAM | 默认只由 test 或根 virtual sequence 管理 run objection。driver、monitor、scoreboard 和后台线程不得自行持有 objection。 |
| `UVM-PHS-003` | M1/UVM-REC | `raise_objection` 与 `drop_objection` 必须成对且异常路径也能释放；禁止在 forever 循环中持有 objection。 |
| `UVM-PHS-004` | M1/TEAM | 禁止依赖隐藏的 `default_sequence` 启动测试。test 显式创建并 `start()` 根 sequence/virtual sequence。 |
| `UVM-PHS-005` | M2/TEAM | drain time 只用于确有尾部协议活动且有上界的场景；常规完成条件使用 in-flight 计数和 scoreboard 空闲状态。 |
| `UVM-PHS-006` | M1/TEAM | component 不调用 `$finish`。结束由 objection、完成条件和全局 watchdog 共同控制。 |

## 9. Sequence 与随机化

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-SEQ-001` | M1/UVM-REC | 显式使用 `start_item`、检查 `randomize()`、再 `finish_item`；禁止 `uvm_do*` 宏隐藏创建、随机化和发送步骤。 |
| `UVM-SEQ-002` | M1/SV-STD | 每次随机化必须检查返回值。禁止把 `randomize()` 放在可被编译选项移除的 `assert(...)` 语句中。 |
| `UVM-SEQ-003` | M2/TEAM | sequence 生成协议级意图，不直接驱动 pin、不访问 monitor 内部队列，也不承担 scoreboard 检查。 |
| `UVM-SEQ-004` | M2/SV-STD | 一个 constraint block 只表达一个目的；默认约束使用 `soft`，测试意图用 inline hard constraint 覆盖。 |
| `UVM-SEQ-005` | M1/SV-STD | constraint 调用的函数必须纯净、零时间且无随机副作用；派生字段在 `post_randomize()` 计算。 |
| `UVM-SEQ-006` | M2/SV-STD | 动态数组先约束 size 再约束元素；谨慎使用 `solve before`，只在需要控制分布时使用；避免巨大 `randc` 和非线性约束。 |
| `UVM-SEQ-007` | M1/TEAM | 回归记录测试名、仿真器版本、UVM 版本、编译选项和随机种子。同一工具链/配置/种子必须可重放，不承诺跨供应商位级相同。 |

## 10. Driver、monitor 与 agent

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-AGT-001` | M1/UVM-REC | driver 对每个 `get_next_item()` 恰好调用一次 `item_done()`；复位、超时和错误路径也不能破坏配对。 |
| `UVM-AGT-002` | M1/TEAM | driver 只驱动接口，不写 scoreboard 预期结果，不把待驱动 transaction 当作已观察事实发布。 |
| `UVM-AGT-003` | M1/UVM-REC | monitor 只依据接口实际采样重建 transaction，不读取 sequence/driver 的对象或私有状态。 |
| `UVM-AGT-004` | M1/TEAM | monitor 每次发布新快照，发布后不再修改。需要跨周期组包时使用私有工作对象，完成后 clone/create 再发布。 |
| `UVM-AGT-005` | M1/UVM-REC | passive agent 不创建 sequencer/driver，但 monitor 始终存在；active/passive 由 config 控制。 |
| `UVM-AGT-006` | M2/TEAM | 协议超时按接口时钟周期计数，并报告 transaction、接口状态和周期数；不要散布难以缩放的绝对时间延时。 |
| `UVM-AGT-007` | M1/TEAM | 复位期间 driver 回到协议空闲值，monitor 清理或明确标记未完成事务；复位策略必须与 scoreboard 一致。 |

## 11. TLM、参考模型与 scoreboard

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-TLM-001` | M1/UVM-STD | 跨组件数据使用标准 TLM port/export/imp/FIFO；禁止 sibling 之间直接调用私有方法或读取内部队列。 |
| `UVM-TLM-002` | M1/UVM-STD | analysis `write()` 必须零时间且轻量，不能 wait、阻塞 mailbox、等待事件或执行大规模算法。重任务放入 analysis FIFO 后由 task 消费。 |
| `UVM-TLM-003` | M1/TEAM | analysis port 是广播。发布者保持对象不可变；任一消费者若缓存或修改必须先 clone。 |
| `UVM-TLM-004` | M1/TEAM | scoreboard 只消费 monitor transaction，不直接窥探 pin，也不使用 driver transaction 代替实际响应。 |
| `UVM-TLM-005` | M1/TEAM | 顺序协议使用队列；乱序协议使用唯一 ID/标签关联。重复 ID、未知响应、超时和残留项都必须报错。 |
| `UVM-TLM-006` | M1/TEAM | `check_phase` 检查期望队列、in-flight、未匹配响应和错误计数；不能仅依赖 run_phase 中没报错。 |
| `UVM-TLM-007` | M2/TEAM | 参考模型与 DUT 共享的只应是协议/算法规格，不应复制 RTL 控制结构；关键算法应有独立单元测试或已验证模型来源。 |

## 12. SVA

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-SVA-001` | M1/SV-STD | 并发断言放在 interface、module、checker 或 bind 文件中，不放在 class 方法内；每个 property、assert 和 cover 都有稳定名称。 |
| `SV-SVA-002` | M1/SV-STD | 每个 property 明确时钟事件和 `disable iff` 复位条件；多时钟 property 必须经过专门评审。 |
| `SV-SVA-003` | M1/TEAM | 协议时限使用有界区间；无界 eventually 只能在形式验证且有公平性假设的专用环境中使用。 |
| `SV-SVA-004` | M1/TEAM | 对控制、握手、选择和关键数据使用 `$isunknown` 检查；复位释放后的 X/Z 必须通过稳定报告 ID 报错。 |
| `SV-SVA-005` | M2/TEAM | 关键 implication 同时增加 antecedent cover，防止“前件从未发生”的空洞通过。 |
| `SV-SVA-006` | M2/TEAM | assertion action block 使用 `uvm_error/uvm_fatal` 或项目适配宏统一进报告系统，不散落 `$display`。 |
| `SV-SVA-007` | M1/TEAM | bind 的层次目标、参数和内部观察点必须稳定；断言不得驱动 DUT 或改变仿真行为。 |

## 13. 功能覆盖率

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-COV-001` | M1/TEAM | 功能覆盖率从 monitor 发布的有效、完成 transaction 采样，不从 driver 意图采样。 |
| `SV-COV-002` | M1/SV-STD | 一个 covergroup 只选择一种采样方式：构造事件采样或显式 `sample()`，不得重复采样。 |
| `SV-COV-003` | M2/SV-STD | 可复用组件的 covergroup 设置 `option.per_instance = 1`，实例名包含 agent/端口上下文。 |
| `SV-COV-004` | M2/TEAM | 关键范围显式定义 bins；控制 auto-bin 数量和 cross 规模，使用 `ignore_bins` 排除规格不适用组合。 |
| `SV-COV-005` | M1/TEAM | `illegal_bins` 只用于覆盖模型诊断，不能替代 protocol checker、assertion 或 scoreboard。 |
| `SV-COV-006` | M1/TEAM | 覆盖率目标必须可追溯到验证计划；达到百分比不等于功能通过，waiver 需要说明不可达原因和证明。 |

## 14. 并发、时间与资源生命周期

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-CON-001` | M1/SV-STD | function 必须零时间；可能等待时钟、事件、mailbox 或延时的代码必须是 task。 |
| `SV-CON-002` | M1/TEAM | 禁止 `#0` 解决竞态，禁止零时间 forever 循环。使用 clocking block、NBA、事件或明确同步原语。 |
| `SV-CON-003` | M1/SV-STD | 每个 `fork` 都有清晰终止机制：`join`、`join_any` 后 `disable fork`，或受控后台进程；不得遗留无法停止的线程。 |
| `SV-CON-004` | M1/SV-STD | 循环中 fork 的索引/临时量声明为 automatic 或在每次迭代复制，防止所有线程引用同一变量。 |
| `SV-CON-005` | M1/TEAM | 可变共享状态采用单写者、TLM、mailbox 或 semaphore；不要依靠仿真调度顺序获得“看起来正确”的互斥。 |
| `SV-CON-006` | M2/TEAM | 协议超时以周期为单位；绝对时间仅用于 testbench 顶层全局 watchdog，并与 timescale 明确关联。 |
| `SV-CON-007` | M1/TEAM | 不依赖 phase kill 自动完成文件关闭、DPI 释放或数据落盘；需要清理的资源使用显式生命周期管理。 |

## 15. 日志、错误和测试完成

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `UVM-RPT-001` | M1/UVM-REC | class/UVM 环境使用 `uvm_info/warning/error/fatal`，不使用 `$display` 作为正式结果通道。 |
| `UVM-RPT-002` | M1/TEAM | 缺失 vif/config、无法恢复的类型错误用 fatal；功能不匹配用 error；可恢复异常用 warning；普通事务日志放在 HIGH/DEBUG verbosity。 |
| `UVM-RPT-003` | M2/TEAM | 每类报告使用稳定 ID，消息包含 component full name、transaction ID/内容、期望/实际值和时间/周期上下文。 |
| `UVM-RPT-004` | M1/TEAM | 不得用 report catcher 或全局 action 静默吞掉 error/fatal。降级必须精确到 ID、记录原因并纳入 waiver。 |
| `UVM-DONE-001` | M1/TEAM | PASS 条件同时满足：stimulus 完成、无 in-flight、scoreboard/参考模型队列为空、无 UVM_ERROR/UVM_FATAL、关键 checker 未失败。 |
| `UVM-DONE-002` | M1/TEAM | test 在所有完成条件满足后 drop objection；全局 watchdog 超时必须 fatal 并打印残留状态。 |
| `UVM-DONE-003` | M1/TEAM | `check_phase` 做残留检查，`report_phase` 输出机器可识别的 `TEST PASS` 或 `TEST FAIL`；不能仅凭进程退出码或最后一行普通日志判断。 |

## 16. DPI、供应商扩展与可移植性

| 编号 | 级别/来源 | 规则 |
|---|---|---|
| `SV-PORT-001` | M1/TEAM | 新代码只依赖公开标准 API；UVM 内部字段、未文档化方法和供应商私有类禁止直接使用。 |
| `SV-PORT-002` | M1/TEAM | DPI、PLI/VPI、供应商扩展和非标准波形控制集中在 adapter/package，不传播到 sequence、agent 和 scoreboard。 |
| `SV-PORT-003` | M2/TEAM | UVM 库版本固定并进入构建记录；升级到 IEEE 1800.2 参考实现时先跑编译矩阵和基准回归，再启用新 API。 |
| `SV-PORT-004` | M1/TEAM | DPI C 接口使用明确宽度、方向和所有权；字符串/数组生命周期、线程安全和错误码必须文档化。 |
| `SV-PORT-005` | M2/TEAM | 同一 VIP 至少维护当前 VCS 基线的 smoke test；宣称跨工具可移植前必须在对应工具实际编译运行。 |

## 17. 最小标准流程

1. testbench 顶层产生 clock/reset，把带 modport 的 virtual interface 通过精确 config_db 路径交给 test。
2. test 构造强类型 config，设置 agent/scoreboard，创建 env，显式启动 root sequence，并独占 objection。
3. driver 通过 driver clocking block 驱动；monitor 通过 monitor clocking block重建实际 transaction。
4. monitor analysis port 广播只读快照；scoreboard 和 coverage 分别消费，`write()` 保持零时间。
5. interface/checker 中的 SVA 检查周期级协议；scoreboard 检查端到端数据。
6. stimulus 完成后等待 scoreboard 完成和队列清空，再 drop objection；check/report 给出最终结果，全局 watchdog 防止挂死。

可执行参考见 [最小UVM示例](../../examples/sv_uvm_minimal/README.md)。该示例刻意不使用 `uvm_do*`、`default_sequence`、无边界 config_db 通配、class XMR 或 component `$finish`。
