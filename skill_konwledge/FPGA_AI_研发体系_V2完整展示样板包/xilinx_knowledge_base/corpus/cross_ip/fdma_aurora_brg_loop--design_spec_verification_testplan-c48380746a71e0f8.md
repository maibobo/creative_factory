# fdma_aurora_brg_loop--design_spec_verification_testplan

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\fdma_aurora_brg_loop--design_spec_verification_testplan.md`
- SHA-256: `c48380746a71e0f808d08d19b6adfde7c55b05ed6fc53a9420597193f561ac04`
- Extractor: `text`
- Tags: `aurora, fdma, pcie, testplan`
- Duplicate sources:
  - none

# fdma_aurora_brg_aurora_loop 设计规格-验证测试点分解-测试用例

> 版本: v1.0 | 日期: 2026-06-18

---

## 1. 设计规格摘要

### 1.1 系统架构

```
FDMA读从机 → [brg_tx: FDMA读引擎 → TX AFIFO → Aurora TX LL引擎] → Aurora 64B66B核 → GT自环回
                                                                                              ↓
FDMA写从机 ← [brg_rx: FDMA写引擎 ← RX AFIFO ← Aurora RX LL引擎] ← Aurora 64B66B核 ← GT自环回
```

### 1.2 关键设计参数

| 参数 | TX桥 | RX桥 |
|------|------|------|
| 测试空间 | 4KB (0x000~0xFFF) | 4KB (0x000~0xFFF) |
| FDMA突发长度 | 512B (64字×64bit) | 512B (64字×64bit) |
| 帧长度 | 1536B (192字×64bit) | — |
| AFIFO深度 | 512 | 2048 |
| AFIFO位宽 | 64bit | 64bit |
| AFIFO读模式 | FWFT | FWFT |
| PROG_FULL_THRESH | 448 (512-64) | 2032 (2048-16) |
| PROG_EMPTY_THRESH | 10 | 10 |
| 写时钟域 | fdma_clk | user_clk |
| 读时钟域 | user_clk | fdma_clk |

### 1.3 状态机定义

**TX桥 FDMA读引擎 (fdma_clk域):**

```
RD_IDLE ──[channel_up_fdma && ~fifo_almost_full && burst_cnt<9]──→ RD_REQ
RD_REQ  ──[fdma_rbusy]──→ RD_DATA
RD_DATA ──[rd_burst_done]──→ RD_WAIT
RD_WAIT ──[~fdma_rbusy]──→ RD_IDLE
```

**TX桥 Aurora发送引擎 (user_clk域):**

```
TX_IDLE ──[channel_up && ~fifo_empty]──→ TX_SOF
TX_SOF  ──[tx_dst_rdy]──→ TX_DATA
TX_DATA ──[wr_burst_done]──→ TX_IDLE
```

**RX桥 FDMA写引擎 (fdma_clk域):**

```
WR_IDLE ──[channel_up_fdma && ~fifo_empty]──→ WR_REQ
WR_REQ  ──[fdma_wbusy]──→ WR_DATA
WR_DATA ──[wr_burst_done]──→ WR_WAIT
WR_WAIT ──[~fdma_wbusy]──→ WR_IDLE
```

### 1.4 关键设计约束与已知限制

| 编号 | 约束/限制 | 来源 | 验证风险 |
|------|----------|------|---------|
| L1 | `rx_dst_rdy = 1'b1` 恒为1，RX侧无反压能力 | brg_rx设计 | RX FIFO满时丢数据 |
| L2 | `tx_rem = 3'b111` 硬编码，仅支持8字节对齐帧 | brg_tx设计 | 非对齐帧无法正确传输 |
| L3 | `burst_cnt < 9` 硬编码上限 | brg_tx设计 | 超过9突发后TX停止 |
| L4 | FDMA突发长度512B硬编码 | brg_tx/rx设计 | 不可配置 |
| L5 | TEST_MEM_SIZE=4KB硬编码 | brg_tx/rx设计 | 不可配置 |
| L6 | `fdma_rready = ~fifo_almost_full` 反压条件 | brg_tx设计 | FIFO近满时才反压 |
| L7 | `fifo_wr_en = rx_src_rdy && !fifo_full` RX FIFO满时丢弃数据 | brg_rx设计 | 数据丢失无恢复机制 |
| L8 | 地址回绕条件: `addr + 512 >= 4096` | brg_tx/rx设计 | 回绕后首笔数据正确性 |
| L9 | `wdata_hold` 寄存器跨突发边界行为 | brg_rx设计 | 突发边界处数据正确性 |
| L10 | CDC同步: `channel_up` 通过2级触发器同步到fdma_clk域 | cdc_sync | 同步延迟2~3拍 |

---

## 2. 当前TB覆盖分析

### 2.1 当前TB配置

| 项目 | 值 |
|------|-----|
| TB文件 | tb_fdma_aurora_brg_aurora_loop_bp.sv |
| 帧数 | 3 |
| 帧长 | 1536B (3突发/帧) |
| 总突发数 | 9 |
| 总数据量 | 4.5KB |
| 数据pattern | `(frame_id<<32) \| word_idx` |
| 读侧反压 | 概率<2%，持续1~4拍 |
| 写侧反压 | 概率<2%，持续1~4拍 |
| 突发间延迟 | 概率<3%，持续1~8拍 |
| 比对策略 | LL层 + FDMA层 + 逐边界调试队列 |

### 2.2 覆盖缺口

| 类别 | 已覆盖 | 未覆盖 | 覆盖率 |
|------|--------|--------|--------|
| 基础数据通路 | 简单递增pattern | 全0/全1/随机/棋盘格 | 20% |
| FIFO边界 | 正常水位(隐式) | 近满/溢出/下溢/复位 | 10% |
| 地址回绕 | 非刻意触发1次 | 精确回绕/多次回绕/一致性 | 15% |
| 反压 | 极低概率随机 | 持续反压/双侧反压/FIFO水位峰值 | 10% |
| 链路异常 | 无 | channel_up断言/恢复/热复位 | 0% |
| CDC | 隐式通过 | 频率比/同步延迟显式验证 | 10% |
| 协议状态机 | 隐式覆盖 | 边界条件/非法转换 | 20% |

---

## 3. 测试点分解

### 3.1 测试点总表

按优先级P0(必须) > P1(重要) > P2(一般)排列。

#### 3.1.1 A类: FIFO边界验证

| ID | 测试点 | 验证目标 | 优先级 | 关联约束 |
|----|--------|---------|--------|---------|
| A1 | TX FIFO近满→FDMA读反压 | `fifo_almost_full`拉高→`rready=0`→FDMA读暂停→水位下降→恢复 | P0 | L6 |
| A2 | TX FIFO溢出 | 写入速率持续大于读出速率→`fifo_overflow`触发 | P0 | — |
| A3 | RX FIFO满→数据丢弃 | `fifo_full=1`时`fifo_wr_en=0`→Aurora RX数据被丢弃→overflow计数 | P0 | L7 |
| A4 | RX FIFO满→FDMA写反压 | RX FIFO水位上升→FDMA写侧能否及时消费 | P0 | L1,L7 |
| A5 | TX FIFO空→Aurora TX暂停 | `fifo_empty=1`→`tx_src_rdy=0`→Aurora侧等待 | P1 | — |
| A6 | RX FIFO空→FDMA写暂停 | `fifo_empty=1`→`wdata_hold_valid=0`→FDMA写等待 | P1 | — |
| A7 | FIFO复位后状态 | `fifo_rst`后empty/full/counter归零，overflow/underflow清零 | P1 | — |
| A8 | FIFO wr/rd_rst_busy保护 | 复位释放后busy期间实际wr_en/rd_en=0 | P2 | — |
| A9 | TX FIFO水位峰值 | 读快写慢时FIFO水位最高值 | P2 | — |
| A10 | RX FIFO水位峰值 | 写快读慢时FIFO水位最高值 | P2 | — |

#### 3.1.2 B类: 地址回绕验证

| ID | 测试点 | 验证目标 | 优先级 | 关联约束 |
|----|--------|---------|--------|---------|
| B1 | TX读地址精确回绕 | 8个突发后(4KB)第9个突发rd_addr=0x0000 | P0 | L8 |
| B2 | RX写地址精确回绕 | 同B1，wr_addr回绕 | P0 | L8 |
| B3 | TX/RX地址一致性 | 环回场景下每个突发两侧地址完全一致 | P0 | L8 |
| B4 | 回绕后首笔数据正确性 | 回绕后第一个数据字与预期匹配 | P0 | L8 |
| B5 | 多次回绕稳定性 | 连续超过2×TEST_MEM_SIZE数据量 | P1 | L8 |
| B6 | 回绕时FIFO水位 | 回绕瞬间TX/RX FIFO水位是否异常 | P2 | — |

#### 3.1.3 C类: 反压验证

| ID | 测试点 | 验证目标 | 优先级 | 关联约束 |
|----|--------|---------|--------|---------|
| C1 | FDMA读侧持续反压 | `rready`随机拉低50%概率，数据无丢失 | P0 | L6 |
| C2 | FDMA写侧持续反压 | `wready`随机拉低50%概率，数据无丢失 | P0 | L1 |
| C3 | 双侧同时反压 | 读写侧同时施加反压，FIFO水位达到峰值但不溢出 | P0 | L1,L6 |
| C4 | burst_cnt上限 | 发送超过9个突发，第10个被阻塞 | P0 | L3 |
| C5 | wdata_hold跨突发边界 | 突发最后一字握手后valid=0，下突发首字重新装载 | P1 | L9 |
| C6 | 突发间长延迟 | rbusy/wbusy在突发间持续100+拍 | P1 | — |
| C7 | 反压解除后数据恢复 | 反压期间FIFO水位上升，解除后水位下降，数据完整 | P1 | — |

#### 3.1.4 D类: 链路异常与恢复

| ID | 测试点 | 验证目标 | 优先级 | 关联约束 |
|----|--------|---------|--------|---------|
| D1 | channel_up断言→状态机回IDLE | 链路断开后TX/RX状态机回到IDLE | P0 | — |
| D2 | channel_up恢复→自动重传 | 链路恢复后自动重新开始传输 | P0 | — |
| D3 | FDMA热复位 | 运行中拉低fdma_rstn后释放，FIFO清空，状态机回IDLE | P1 | — |
| D4 | channel_up CDC同步延迟 | channel_up与channel_up_fdma延迟2~3拍 | P2 | L10 |
| D5 | user_rstn断言期间行为 | Aurora复位期间FDMA侧行为 | P2 | — |

#### 3.1.5 E类: 数据完整性

| ID | 测试点 | 验证目标 | 优先级 | 关联约束 |
|----|--------|---------|--------|---------|
| E1 | 全零数据 | 发送64'h0，接收一致 | P1 | — |
| E2 | 全一数据 | 发送64'hFFFF_FFFF_FFFF_FFFF，接收一致 | P1 | — |
| E3 | 随机数据 | $urandom填充，接收一致 | P1 | — |
| E4 | 棋盘格 | 0x5555.../0xAAAA...交替，接收一致 | P2 | — |
| E5 | SOF/EOF标记位置 | tx_sof在帧首拍、tx_eof在帧尾拍 | P1 | — |
| E6 | 单突发帧 | 帧长=512B(1突发)，端到端正确 | P2 | — |
| E7 | 大帧(6突发) | 帧长=3072B(6突发)，端到端正确 | P2 | — |

#### 3.1.6 F类: 跨时钟域

| ID | 测试点 | 验证目标 | 优先级 | 关联约束 |
|----|--------|---------|--------|---------|
| F1 | TX AFIFO CDC长时间稳定性 | fdma_clk写/user_clk读，长时间无亚稳态 | P2 | — |
| F2 | RX AFIFO CDC长时间稳定性 | user_clk写/fdma_clk读 | P2 | — |
| F3 | 不同频率比 | fdma_clk:user_clk = 1:1 / 2:1 / 1:2 | P2 | — |

---

## 4. 测试用例定义

### 4.1 用例编号规则

```
TC_<类别>_<序号>
类别: FIFO / ADDR / BP / LINK / DATA / CDC
```

### 4.2 用例详细定义

---

#### TC_FIFO_01: TX FIFO近满反压验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | A1 |
| **前置条件** | channel_up=1, FDMA读从机就绪 |
| **测试步骤** | 1. 连续发送20帧(60突发)，无突发间延迟<br>2. 监测TX FIFO `fifo_almost_full`和`fifo_wr_cnt`<br>3. 监测`fdma_rready`拉低时刻和持续时间<br>4. 监测`fifo_overflow`计数 |
| **预期结果** | 1. `fifo_almost_full`至少触发1次<br>2. `rready=0`期间FDMA读暂停，无数据丢失<br>3. `fifo_overflow=0`<br>4. FDMA读数据与写数据完全一致 |
| **通过标准** | 无数据丢失，无FIFO溢出，反压正确生效 |
| **TB改造需求** | NUM_FRAMES≥20，突发间延迟=0，增加fifo_almost_full/rready监测断言 |

---

#### TC_FIFO_02: TX FIFO溢出验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | A2 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 通过force Aurora `tx_dst_rdy=0`阻止TX FIFO读出<br>2. FDMA读侧持续写入512+个数据字<br>3. 监测`fifo_overflow`信号<br>4. 释放`tx_dst_rdy`，观察恢复行为 |
| **预期结果** | 1. TX FIFO满后`fifo_overflow`触发<br>2. 释放后FIFO正常排空<br>3. overflow后数据有丢失（设计限制，非bug） |
| **通过标准** | `fifo_overflow`信号正确触发，恢复后FIFO正常工作 |
| **TB改造需求** | 增加`force tx_dst_rdy=0`的task，增加overflow监测 |

---

#### TC_FIFO_03: RX FIFO满数据丢弃验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | A3, A4 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 通过force FDMA写从机`wbusy=1`阻止RX FIFO读出<br>2. Aurora RX持续送入数据直到RX FIFO满<br>3. 监测`fifo_full`、`fifo_overflow`、`fifo_wr_cnt`<br>4. 释放`wbusy`，观察恢复行为 |
| **预期结果** | 1. RX FIFO满后`fifo_full=1`<br>2. `fifo_wr_en=0`（`rx_src_rdy && !fifo_full`）<br>3. `fifo_overflow`触发（若写入使能和满在同一拍）<br>4. 数据有丢失（设计限制L7） |
| **通过标准** | RX FIFO满时正确丢弃数据（overflow信号触发），恢复后正常工作 |
| **TB改造需求** | 增加`force wbusy=1`的task，增加RX FIFO满监测 |

---

#### TC_FIFO_04: TX/RX FIFO空暂停验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | A5, A6 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 发送1帧数据，观察TX FIFO从空→有数据→空的完整周期<br>2. 观察TX FIFO空时`tx_src_rdy=0`<br>3. 观察RX FIFO空时`wdata_hold_valid=0`、`fdma_wvalid=0`<br>4. 数据到达后信号恢复 |
| **预期结果** | 1. FIFO空时对应侧暂停<br>2. 数据到达后自动恢复<br>3. 无数据丢失 |
| **通过标准** | FIFO空时正确暂停，恢复后数据完整 |
| **TB改造需求** | 增加FIFO empty时刻的断言检查 |

---

#### TC_FIFO_05: FIFO复位后状态验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | A7, A8 |
| **前置条件** | channel_up=1, FIFO中有数据 |
| **测试步骤** | 1. 传输若干帧后，拉低`fdma_rstn`或`user_rstn`<br>2. 检查FIFO empty/full/counter状态<br>3. 检查`wr_rst_busy`/`rd_rst_busy`期间无实际读写<br>4. 复位释放后恢复传输 |
| **预期结果** | 1. 复位后`fifo_empty=1`, `fifo_full=0`, `fifo_wr_cnt=0`, `fifo_rd_cnt=0`<br>2. `rst_busy`期间`wr_en=0`, `rd_en=0`<br>3. 复位释放后FIFO正常工作 |
| **通过标准** | FIFO复位后状态正确，busy保护生效 |
| **TB改造需求** | 增加中途复位task，增加rst_busy监测 |

---

#### TC_ADDR_01: TX/RX地址精确回绕验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | B1, B2, B3, B4 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 发送9个突发(4.5KB)，覆盖完整4KB地址空间+回绕后1个突发<br>2. 逐突发记录TX `rd_addr`和RX `wr_addr`<br>3. 验证第9个突发地址为0x0000<br>4. 验证回绕后首笔数据正确<br>5. 比对TX/RX地址序列一致性 |
| **预期结果** | 1. TX地址序列: 0x000, 0x200, 0x400, ..., 0xE00, **0x000**<br>2. RX地址序列与TX完全一致<br>3. 回绕后首笔数据为预期值<br>4. FDMA读数据与写数据完全一致 |
| **通过标准** | 地址回绕位置正确，回绕后数据正确，TX/RX地址一致 |
| **TB改造需求** | 增加逐突发地址记录和比对task |

---

#### TC_ADDR_02: 多次回绕稳定性验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | B5 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 发送30帧(90突发)，覆盖3次以上地址回绕<br>2. 逐突发验证地址序列<br>3. 每次回绕后验证首笔数据正确性 |
| **预期结果** | 1. 地址每8个突发回绕一次<br>2. 每次回绕后首笔数据正确<br>3. 端到端数据完整 |
| **通过标准** | 多次回绕后地址和数据均正确 |
| **TB改造需求** | NUM_FRAMES≥30，增加回绕次数统计 |

---

#### TC_BP_01: FDMA读侧持续反压验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | C1 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 配置读侧反压概率50%: `rready`每拍50%概率拉低<br>2. 发送10帧(30突发)<br>3. 监测TX FIFO水位波动<br>4. 监测`fifo_overflow` |
| **预期结果** | 1. TX FIFO水位周期性上升和下降<br>2. 无FIFO溢出<br>3. 端到端数据完整 |
| **通过标准** | 反压下数据无丢失，FIFO水位可控 |
| **TB改造需求** | 反压概率参数化(当前<2%→50%)，增加FIFO水位监测 |

---

#### TC_BP_02: FDMA写侧持续反压验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | C2 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 配置写侧反压概率50%: `wready`每拍50%概率拉低<br>2. 发送10帧(30突发)<br>3. 监测RX FIFO水位上升<br>4. 监测`fifo_full`和`fifo_overflow` |
| **预期结果** | 1. RX FIFO水位因反压上升<br>2. 由于`rx_dst_rdy=1`(L1)，若水位达到满则数据丢弃<br>3. 若FIFO深度(2048)足够容纳反压期间积压数据，则无丢失 |
| **通过标准** | 反压下若FIFO不溢出则数据完整；若溢出则overflow信号正确触发 |
| **TB改造需求** | 写侧反压概率参数化，增加RX FIFO水位和overflow监测 |

---

#### TC_BP_03: 双侧同时反压验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | C3 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 读写侧同时施加50%反压<br>2. 发送10帧(30突发)<br>3. 监测TX/RX FIFO水位峰值<br>4. 监测两侧overflow |
| **预期结果** | 1. TX FIFO: 读侧反压→写入暂停，水位不超限<br>2. RX FIFO: 写侧反压→水位上升，可能接近满<br>3. 数据完整或overflow正确报告 |
| **通过标准** | 双侧反压下系统不挂死，数据完整或丢失可观测 |
| **TB改造需求** | 双侧反压同时使能，增加水位峰值记录 |

---

#### TC_BP_04: burst_cnt上限验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | C4 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 发送4帧(12突发)，超过burst_cnt<9的限制<br>2. 监测`burst_cnt`值和`rd_state`<br>3. 观察第10个突发是否被阻塞 |
| **预期结果** | 1. burst_cnt达到9后，`rd_state`停在RD_IDLE<br>2. TX不再发起新的FDMA读请求<br>3. 已发送的9个突发数据正确到达RX侧 |
| **通过标准** | burst_cnt上限正确生效，已发数据完整 |
| **TB改造需求** | NUM_FRAMES≥4，增加burst_cnt监测断言 |

---

#### TC_BP_05: wdata_hold跨突发边界验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | C5 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 发送3帧(9突发)，写侧无反压<br>2. 在每个突发边界处检查`wdata_hold_valid`<br>3. 验证最后一字握手后`wdata_hold_valid=0`<br>4. 验证下突发首字从FIFO重新装载 |
| **预期结果** | 1. 突发最后一字: `w_last_hs`→`wdata_hold_valid=0`<br>2. 下突发首字: `fifo_rd_en`→`wdata_hold_valid=1`<br>3. 无跨突发数据残留 |
| **通过标准** | wdata_hold在突发边界处行为正确 |
| **TB改造需求** | 增加wdata_hold_valid在突发边界的波形断言 |

---

#### TC_LINK_01: channel_up断言与恢复验证

| 项目 | 内容 |
|------|------|
| **优先级** | P0 |
| **测试点** | D1, D2 |
| **前置条件** | channel_up=1, 正在传输数据 |
| **测试步骤** | 1. 发送2帧后，force `channel_up=0`<br>2. 观察TX/RX状态机回到IDLE<br>3. 等待1000个user_clk周期<br>4. 释放force，channel_up恢复<br>5. 观察TX/RX自动恢复传输<br>6. 发送额外2帧验证恢复后正确性 |
| **预期结果** | 1. channel_up=0后: TX `tx_state=TX_IDLE`, RX `wr_state=WR_IDLE`<br>2. channel_up恢复后: 自动重新开始传输<br>3. 恢复后数据正确 |
| **通过标准** | 链路断开/恢复后状态机行为正确，恢复后数据完整 |
| **TB改造需求** | 增加`force channel_up=0`/释放的task |

---

#### TC_LINK_02: FDMA热复位验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | D3 |
| **前置条件** | channel_up=1, 正在传输数据 |
| **测试步骤** | 1. 发送2帧后，拉低`fdma_rstn`持续100ns<br>2. 观察TX/RX FIFO复位<br>3. 观察状态机回到IDLE<br>4. 释放`fdma_rstn`<br>5. 等待`channel_up_fdma`重新同步<br>6. 发送额外2帧验证恢复 |
| **预期结果** | 1. `fdma_rstn=0`后: FIFO清空，状态机回IDLE<br>2. 释放后: `channel_up_fdma`经2~3拍同步后拉高<br>3. 恢复后数据正确 |
| **通过标准** | 热复位后系统正确恢复 |
| **TB改造需求** | 增加中途fdma_rstn拉低的task |

---

#### TC_DATA_01: 多pattern数据完整性验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | E1, E2, E3, E4 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 分别用以下pattern发送3帧数据:<br>a) 全零: 64'h0<br>b) 全一: 64'hFFFF_FFFF_FFFF_FFFF<br>c) 随机: $urandom<br>d) 棋盘格: 奇数字0x5555..., 偶数字0xAAAA... |
| **预期结果** | 每种pattern下FDMA读数据与写数据完全一致 |
| **通过标准** | 4种pattern全部通过 |
| **TB改造需求** | 数据pattern参数化，支持pattern选择 |

---

#### TC_DATA_02: SOF/EOF标记与帧长验证

| 项目 | 内容 |
|------|------|
| **优先级** | P1 |
| **测试点** | E5, E6, E7 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 1. 发送标准3突发帧(1536B)，检查SOF/EOF位置<br>2. 发送1突发帧(512B)，检查SOF/EOF位置<br>3. 发送6突发帧(3072B)，检查SOF/EOF位置 |
| **预期结果** | 1. SOF在每帧第1个字<br>2. EOF在每帧最后1个字<br>3. tx_word_cnt与帧长匹配 |
| **通过标准** | SOF/EOF位置正确，不同帧长下计数器正确 |
| **TB改造需求** | 帧长参数化，增加SOF/EOF监测断言 |

---

#### TC_CDC_01: 不同频率比验证

| 项目 | 内容 |
|------|------|
| **优先级** | P2 |
| **测试点** | F3 |
| **前置条件** | channel_up=1 |
| **测试步骤** | 分别在以下频率比下发送3帧数据:<br>a) fdma_clk:user_clk = 250:156.25 (默认1.6:1)<br>b) fdma_clk:user_clk = 200:200 (1:1)<br>c) fdma_clk:user_clk = 300:150 (2:1) |
| **预期结果** | 每种频率比下端到端数据完整 |
| **通过标准** | 3种频率比全部通过 |
| **TB改造需求** | 时钟周期参数化 |

---

## 5. 用例-测试点-设计约束对照矩阵

| 用例编号 | 覆盖测试点 | 关联设计约束 | 优先级 |
|---------|-----------|-------------|--------|
| TC_FIFO_01 | A1 | L6 | P0 |
| TC_FIFO_02 | A2 | — | P0 |
| TC_FIFO_03 | A3,A4 | L1,L7 | P0 |
| TC_FIFO_04 | A5,A6 | — | P1 |
| TC_FIFO_05 | A7,A8 | — | P1 |
| TC_ADDR_01 | B1,B2,B3,B4 | L8 | P0 |
| TC_ADDR_02 | B5 | L8 | P1 |
| TC_BP_01 | C1 | L6 | P0 |
| TC_BP_02 | C2 | L1 | P0 |
| TC_BP_03 | C3 | L1,L6 | P0 |
| TC_BP_04 | C4 | L3 | P0 |
| TC_BP_05 | C5 | L9 | P1 |
| TC_LINK_01 | D1,D2 | — | P0 |
| TC_LINK_02 | D3 | — | P1 |
| TC_DATA_01 | E1,E2,E3,E4 | — | P1 |
| TC_DATA_02 | E5,E6,E7 | L2 | P1 |
| TC_CDC_01 | F3 | — | P2 |

---

## 6. 历史Bug→测试用例映射

| 历史Bug | 根因 | 修复方式 | 回归测试用例 |
|---------|------|---------|-------------|
| rd_word_cnt=63卡死 | RD_REQ→RD_DATA过渡时第一个rvalid被意外计数 | `fifo_wr_en`条件修改 | TC_BP_01, TC_BP_05 |
| TX FIFO写使能在RD_REQ时误触发 | `fifo_wr_en`条件不够严格 | 修改为`fdma_rvalid && fdma_rready` | TC_FIFO_02 |
| Aurora 1200us不拉起channel_up | 初始化参数为硅片设计，仿真时间不够 | 添加SIMULATION参数加速 | TC_LINK_01, TC_LINK_02 |
| rx_dst_rdy恒1丢数据风险 | 无反压保护，FIFO满时数据丢弃 | 设计限制，需验证边界 | TC_FIFO_03, TC_BP_02 |
| burst_cnt<9硬编码限制 | 只允许9个突发 | 设计限制，需验证上限行为 | TC_BP_04 |
| fifo_almost_empty导致1字滞留 | TX_IDLE条件用almost_empty，阈值10导致最后一字无法触发 | 改为`~fifo_empty` | TC_FIFO_04 |

---

## 7. TB改造需求汇总

为支持上述用例，需对TB进行以下改造：

### 7.1 参数化改造

| 改造项 | 当前值 | 目标 |
|--------|--------|------|
| NUM_FRAMES_TO_TEST | 3 | 参数化，默认3，可设1~100 |
| AURORA_FRAME_BYTES | 1536 | 参数化，支持512/1024/1536/2048/3072/4096 |
| TEST_MEM_SIZE_BYTES | 4096 | 参数化，支持2048/4096/8192/16384 |
| 读侧反压概率 | <2% | 参数化bp_rd_prob，0~100% |
| 写侧反压概率 | <2% | 参数化bp_wr_prob，0~100% |
| 数据pattern | 固定 | 参数化: INC/ZERO/ONE/RANDOM/CHECKER |
| FDMA_CLK_PERIOD | 4.0ns | 参数化 |
| USER_CLK_PERIOD | 由Aurora核决定 | 不可配置(核内部产生) |

### 7.2 新增Task

| Task名称 | 功能 | 服务用例 |
|----------|------|---------|
| `apply_rd_backpressure(prob)` | 按概率施加读侧反压 | TC_BP_01, TC_BP_03 |
| `apply_wr_backpressure(prob)` | 按概率施加写侧反压 | TC_BP_02, TC_BP_03 |
| `force_channel_down(duration)` | 强制channel_up=0指定时间 | TC_LINK_01 |
| `apply_fdma_reset(duration)` | 拉低fdma_rstn指定时间 | TC_LINK_02 |
| `force_tx_dst_rdy_down()` | 阻止TX FIFO读出 | TC_FIFO_02 |
| `force_wbusy_high()` | 阻止RX FIFO读出 | TC_FIFO_03 |
| `check_fifo_status()` | 断言FIFO状态(empty/full/counter) | TC_FIFO_05 |
| `record_burst_addrs()` | 逐突发记录TX/RX地址 | TC_ADDR_01, TC_ADDR_02 |
| `check_sof_eof()` | 断言SOF/EOF位置 | TC_DATA_02 |

### 7.3 新增监测

| 监测项 | 信号 | 服务用例 |
|--------|------|---------|
| TX FIFO水位峰值 | `fifo_wr_cnt` | TC_FIFO_01, TC_BP_01 |
| RX FIFO水位峰值 | `fifo_wr_cnt` | TC_FIFO_03, TC_BP_02 |
| burst_cnt值 | `burst_cnt` | TC_BP_04 |
| wdata_hold_valid边界 | `wdata_hold_valid` | TC_BP_05 |
| 逐突发地址 | `rd_addr`/`wr_addr` | TC_ADDR_01, TC_ADDR_02 |
| SOF/EOF位置 | `tx_sof`/`tx_eof` | TC_DATA_02 |

---

## 8. 执行优先级建议

### 第一轮: P0用例 (必须通过)

```
TC_FIFO_01 → TC_FIFO_02 → TC_FIFO_03 → TC_ADDR_01 → TC_BP_01 → TC_BP_02 → TC_BP_03 → TC_BP_04 → TC_LINK_01
```

**理由**: FIFO溢出和地址回绕是历史bug高发区；反压是实际场景必遇；链路中断是可靠性基础。

### 第二轮: P1用例 (重要补充)

```
TC_FIFO_04 → TC_FIFO_05 → TC_ADDR_02 → TC_BP_05 → TC_LINK_02 → TC_DATA_01 → TC_DATA_02
```

### 第三轮: P2用例 (完善覆盖)

```
TC_CDC_01
```

---

## 9. 通过标准汇总

| 类别 | 通过标准 |
|------|---------|
| 数据完整性 | FDMA读数据队列与写数据队列完全一致(长度+内容) |
| FIFO行为 | overflow/underflow信号在预期条件下触发，非预期条件下不触发 |
| 地址回绕 | 回绕位置精确，回绕后首笔数据正确，TX/RX地址一致 |
| 反压 | 反压下系统不挂死，FIFO不溢出(或溢出可观测)，数据完整 |
| 链路异常 | 断开/恢复后状态机行为正确，恢复后数据正确 |
| 协议合规 | SOF/EOF位置正确，状态机转换合规 |
