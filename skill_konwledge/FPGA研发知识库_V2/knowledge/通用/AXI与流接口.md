# AXI与流接口

适用于实际采用AXI4、AXI4-Lite或AXI4-Stream的模块。先确认协议类型、位宽、ID、burst能力及实际IP限制；AXI4-Lite不套用AXI4的burst和ID场景。

## 握手与事务

每个通道独立用 `VALID && READY` 判断接受。发送方不能等READY才首次提出VALID；VALID提出后，未被接受的有效载荷和控制信息需按协议保持。地址计数、数据指针、剩余拍数应由对应握手事件推进，不能只看VALID。

AXI写地址AW和写数据W独立接受，不假定同拍握手；分别记录完成状态，再按协议处理B响应。读地址AR与R响应分开计数。响应可能有延迟，检查BRESP/RRESP、ID与事务归属，不能只检查“有返回”。

## 按配置选取的测试场景

| 项目 | 技术关注点 | 用例思路 |
|---|---|---|
| burst、len、size | AXI4的AxLEN编码为拍数减一；AxSIZE表示每拍字节数的2次幂编码；可用长度受burst类型及IP限制 | 最小/最大支持长度、连续burst、地址推进、首尾拍 |
| 4KB与对齐 | AXI burst不得跨4KB边界；检查地址、拍宽、非对齐支持和拆分逻辑 | 边界前结束、下一事务从边界开始；不支持输入的拒绝/报错按规格检查 |
| outstanding与ID | 发出但未完成的事务数、计数归还时机及顺序约束 | 达到配置上限、响应延迟、同ID与不同ID、允许的乱序响应 |
| AW/W独立性 | 接受次序可不同，W数据与事务关联必须正确 | AW先到、W先到、分别反压、B延迟 |
| 超时 | AXI握手本身不替项目定义超时和取消策略 | 按规格持续不响应，检查超时报错、资源清理及恢复；不擅自撤销已接受事务 |
| QoS | 是否使用AxQOS及其对当前仲裁器的实际作用 | 只有规格定义优先或带宽行为时才检查；字段有值不等于提供时延保证 |
| response与异常 | 错误码、未知/重复响应、错误后指针和状态 | 注入允许模拟的错误，核对错误保持、计数及后续事务 |

“不支持某特性”不等于随意施加非法总线激励：分别区分上游输入检查测试与协议合法的压力测试。

## Stream与尾拍

TVALID/TREADY握手时采样TDATA及适用的TKEEP/TLAST等边带。反压期间保持当前拍；按有效字节而非固定总线宽度比较数据。TKEEP的稀疏模式是否支持取决于本项目接口/IP，不能把某个DMA仅允许低位连续有效的约定提升为所有AXI-Stream规则。

LocalLink的REM/SOF/EOF与AXI-Stream的TKEEP/TLAST不同。适配层应明确转换公式、首尾拍和空帧语义，尤其不能将“最后有效字节数减一”的历史REM解释套到未确认的接口。

依据：[AXI规范文字副本](../../sources/vendor/IHI0022E.md)的Single interface requirements、AXI4 burst、QoS章节；[AXI-Stream规范](../../sources/vendor/IHI0051A.md)的Handshake与Byte qualifiers章节；[跨IP检查表](../../sources/history/05_跨IP_集成检查表.md)。官方副本为历史版本，具体IP能力以本项目配置及对应产品指南为准。
