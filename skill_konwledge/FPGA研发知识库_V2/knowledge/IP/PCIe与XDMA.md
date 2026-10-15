# PCIe与XDMA

适用于已有XDMA Endpoint、Root Port/TPI和DMA集成经验。链路代际与宽度、用户接口、BAR、描述符、地址窗口和中断配置均按当前工程确认；example默认值不是项目定值。

## 路径与完成语义

H2C、C2H分别画出Host数据源/接收模型、Root Port、Endpoint、卡侧AXI与目标存储器。检查描述符位置、长度单位、地址对齐、响应码和数据内容。卡侧AXI完成、DMA状态完成、Host内存可见、IRQ发出及软件ISR是不同观察层级。

历史Root Port的DATA_STORE用于Host发起读取的数据源，C2H没有自动写回该数组。对应工程增加CQ Host-memory sink按地址与有效字节接收，再做比较。这个案例说明应检查模型真实行为，不能假定所有RP模型都具有相同缺陷或必须加同名组件。

## 验证场景

先验证链路及配置，再按当前支持能力测试H2C/C2H、单次及连续事务、双向流量、反压、长度边界、错误response、超时和复位。IRQ检查req、实际IP确认以及软件层边界；read-to-clear检查新事件与清除竞争。

已支持多描述符时检查每次启动的计数与状态语义，避免把重新计数误认为全局单调计数。总线场景读取[AXI主题](../通用/AXI与流接口.md)。

历史`RTDS_test-1ch`记录为Gen3 x2、64-bit/250MHz及512B闭环；这些值只属于该记录。Aurora侧LocalLink BFM通过不能扩展为真实Aurora PHY通过；MSI发送确认不能扩展为操作系统ISR已执行。

依据：[PCIe历史配置和验证层级](../../sources/history/02_PCIe_XDMA_工程速查.md)、[Host模型案例](../../sources/cases/CASE-006.md)、[接口映射案例](../../sources/cases/CASE-002.md)。本轮没有重跑该工程；当前版本产品指南、驱动与模型需随实际项目补齐。
