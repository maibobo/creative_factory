"""Design-grounded explanations for every signal and figure in the seven VCD views.

This is intentionally hand-reviewed: a signal's meaning is not inferred from its name.
The Word builder asserts that each selected signal has a role and each image has a note.
"""

ROLES = {
    # FDMA writer, shared by ring and axi_tail.
    "fdma_waddr": "本次 FDMA 写事务的字节地址；环形块地址由写指针与已提交长度形成。",
    "fdma_wdata": "交给 FDMA 的 64bit 写拍数据；是否写入由接受、B 响应和 WSTRB 分别决定。",
    "fdma_wstrb": "8 个字节写使能，FF 为全拍，0F 只更新低四字节。",
    "fdma_wareq": "写地址/拍数请求，需等 fdma_wbusy 确认接受。",
    "fdma_wbusy": "FDMA 已接事务且尚未完成响应，不能等同于写成功。",
    "fdma_waccept": "一个 FDMA 数据拍实际被接受的事件；早于最终 B 响应。",
    "fdma_wdone": "整笔 FDMA 写在最终 B 响应后完成的脉冲。",
    "fdma_werror": "最终写响应错误汇总；与 done 同看才能决定是否提交长度。",
    "fdma_wsize": "FDMA 请求的 64bit 拍数，不是字节数。",
    "fdma_raddr": "FDMA 读事务的字节地址。",
    "fdma_rareq": "FDMA 读请求；桥/存储侧接受后才进入数据阶段。",
    "fdma_rbusy": "FDMA 读事务从接受到结束的占用状态。",
    "fdma_rvalid": "本桥历史接口的已接受读拍脉冲，须与 AXI RVALID/RREADY 区分。",
    "fdma_rdata": "返回 FDMA 侧的 64bit 读数据。",
    "frame_valid": "当前流数据有效；是否前进还需看 frame_ready。",
    "frame_ready": "当前流消费者允许前进；本身不说明数据已经存储。",
    "frame_data": "当前流中的 64bit 数据拍。",
    "dropped_frames": "累计无法存储的有效 32bit 字数；名称沿用 frames，但单位不是整帧。",
    "inject_error": "测试台注错开关，用于区分预期错误路径和偶发故障。",
    "rx_valid": "10G 输入当前 64bit 拍有效。",
    "rx_data": "10G 输入的原始 64bit 拍；后续 writer 才取低 32bit。",
    "rx_sof": "线路帧首拍标记；当前 RX FIFO 不据此封块。",
    "rx_eof": "线路帧末拍标记；当前 RX FIFO 不据此判长度。",
    "rx_ready": "线路侧常高的接口 ready，不能据此断言 FIFO 仍有空位。",
    "length_error": "兼容旧接口的长度错误位；V2.01 固定为 0。",
    "fifo_write": "源域真正允许写入异步 FIFO 的条件。",
    "fifo_read": "目的域 frame_valid 与 frame_ready 同时成立的读使能。",
    "full_user": "源时钟域 FIFO 满标志，直接门控写入。",
    "almost_full_user": "源时钟域 FIFO 接近满标志。",
    "fifo_full": "跨到目的域后的满状态；相比 full_user 有同步延时。",
    "fifo_almost_full": "近满状态；RX 为目的域观测，TX 为写端预取阈值。",
    "received": "测试台已验收拍数，只有真正数据握手才递增。",
    # AXI five-channel boundary.
    "M_AXI_AWADDR": "AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。",
    "M_AXI_AWLEN": "AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。",
    "M_AXI_AWVALID": "桥的写地址有效请求；反压期间必须保持地址和长度。",
    "M_AXI_AWREADY": "下游写地址接受能力；与 AWVALID 同时成立才握手。",
    "M_AXI_WDATA": "AXI 写数据，只有被 WREADY 接受且 WSTRB 允许的字节才有效。",
    "M_AXI_WSTRB": "AXI 每字节写使能，核对 FDMA WSTRB 是否透传。",
    "M_AXI_WLAST": "本段突发最后一个 W 拍标志；不是最终 B 响应。",
    "M_AXI_WVALID": "桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。",
    "M_AXI_WREADY": "下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。",
    "M_AXI_BRESP": "AXI 写响应码；0 为 OKAY，2 为 SLVERR。",
    "M_AXI_BVALID": "下游写响应有效。",
    "M_AXI_BREADY": "桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。",
    "M_AXI_ARADDR": "AXI 读地址；用于核对高地址与跨 4KiB 拆分。",
    "M_AXI_ARLEN": "AXI 读突发长度减一。",
    "M_AXI_ARVALID": "桥发出的读地址有效请求。",
    "M_AXI_ARREADY": "下游读地址接受能力。",
    "M_AXI_RDATA": "AXI 返回的 64bit 数据；只有 RVALID/RREADY 握手才计拍。",
    "M_AXI_RLAST": "当前 AXI 读突发的最后一拍。",
    "M_AXI_RVALID": "下游当前读拍有效。",
    "M_AXI_RREADY": "桥当前可以接受读拍。",
    # AXI-Lite boundary.
    "araddr": "CPU AXI-Lite 读寄存器地址。",
    "arvalid": "CPU 读地址有效。",
    "arready": "寄存器从端读地址接受。",
    "rdata": "寄存器读回值，须在 RVALID/RREADY 有效时解释。",
    "rvalid": "寄存器读数据有效，或 TX 场景 FDMA 返回拍有效。",
    "rready": "读数据消费者可接受，或 TX 场景 FIFO 可接收。",
    "awaddr": "CPU AXI-Lite 写寄存器地址。",
    "awvalid": "CPU AXI-Lite 写地址有效。",
    "awready": "寄存器从端写地址接受。",
    "wdata": "CPU AXI-Lite 写数据。",
    "wstrb": "CPU AXI-Lite 每字节写使能，bit0 决定 0x14 ACK 是否生效。",
    "wvalid": "CPU AXI-Lite 写数据有效。",
    "wready": "寄存器从端写数据接受。",
    "bvalid": "寄存器写响应有效；不等于业务动作已经执行。",
    # 1G output and configuration.
    "cfg_byte": "下行 16Byte 帧 Byte1 的编号，只有 1～10 合法。",
    "cfg_byte_valid": "Byte1 首次实际接受事件，用于触发一次配置。",
    "decode_valid": "编号组合译码合法标志；非法值即使 valid 也不得锁存。",
    "decoded_duty": "编号表给出的 16bit 占空比定点参数。",
    "decoded_vin": "编号表给出的 32bit Vin 定点参数，单位为电压×2²⁰。",
    "cfg_hold": "源域保持的 {Vin,duty} 48bit 邮箱数据。",
    "cfg_req": "首次合法配置已提交的源域锁存标志。",
    "req_sync": "标准 CDC 到目的域的完整配置请求边界。",
    "cfg_user": "用户域原子接收的 48bit 配置值。",
    "cfg_ack": "目的域已锁存完整配置的标志。",
    "ack_sync": "标准 CDC 返回源域的配置接受确认。",
    "configured_id": "源域锁存的首次合法编号；后续合法输入不覆盖。",
    "configured": "源域收到目的域确认后的配置完成状态。",
    "period_tick": "用户域 63 拍周期产生的一次发送机会。",
    "tx_curr_st": "1G 两拍发送状态：0 空闲、1 首拍、2 末拍。",
    "tx_ready": "1G 对端可接受；仅在 tx_valid 同时有效时推进状态。",
    "tx_valid": "1G 当前待发拍有效；反压时随状态保持。",
    "tx_sof": "1G 当前 FIRST 拍的帧首标志。",
    "tx_eof": "1G 当前 LAST 拍的帧尾标志。",
    "tx_rem": "1G 当前拍有效字节数减一：首拍 3、末拍 1。",
    "tx_data": "当前 1G/10G 用户接口送出的数据拍，需结合 valid/ready 判断接受。",
    "skipped_periods": "1G 忙时到来的周期机会累计数，不是待补发队列长度。",
    "channel_up": "用户域链路可用状态；掉线中止未完成发送。",
    "user_reset": "1G 用户接口复位，中止发送而不清首次锁存配置。",
    "arm_count": "1G 恢复后等待四个用户沿的计数，防止立即重放旧事件。",
    "completed_frames": "1G 测试台完整接受两拍后累计的帧数。",
    # TX bridge.
    "limit": "本次 TX 测试允许的 16Byte 帧数。",
    "raddr": "TX 桥给 FDMA 的字节读地址，每帧递进 16Byte。",
    "rareq": "TX 桥的 FDMA 读请求；近满时不再启动新的突发。",
    "rbusy": "FDMA 从端已接受读请求并正在给数。",
    "rdata": "FDMA 从端提供的 64bit 数据拍。",
    "fifo_wr_en": "FDMA 数据握手后送入 TX FIFO 的写使能。",
    "fifo_rd_en": "10G 发送拍真正握手后的 FIFO 读使能。",
    "fifo_wr_cnt": "TX FIFO 写域所见占用拍数，用于 504 阈值节流。",
    "fifo_write_ready": "TX FIFO 写侧可继续接收数据，近满时拉低。",
    "fifo_overflow": "TX FIFO 溢出标志，测试中应保持 0。",
    "rd_data_hs": "TX FDMA 有效数据被桥接受的握手事件。",
    "peak_words": "测试台记录的 TX FIFO 最大占用拍数。",
    "ready": "10G 用户侧消费者放行信号；与 valid 同时为 1 才完成发送。",
    "valid": "10G 当前输出拍有效；停顿时负载必须保持。",
    "sof": "10G 当前拍为 16Byte 帧的首拍。",
    "eof": "10G 当前拍为 16Byte 帧的末拍。",
    "rem": "10G 当前 64bit 拍有效字节数减一；本测试两拍均为 7。",
}

CASE_ROLES = {
    "ring": {
        "half_data": "待配对的第一个有效低 32bit 字；高 32bit 输入被丢弃。",
        "half_valid": "已有半个 64bit 写拍，等下一有效字或窗口尾封存。",
        "pair_start": "第二个 32bit 字到达，触发 FF 全拍组装。",
        "tail_start": "封存时只有一个 32bit 字，触发 0F 尾拍。",
        "used_bytes": "当前写块中已经得到成功 B 响应的有效字节数。",
        "write_success": "写状态在 RESPONSE 且 fdma_wdone、无错。",
        "write_failure": "写状态在 RESPONSE 且 fdma_wdone、有错。",
        "write_curr_st": "writer 的请求、数据、等待响应状态。",
        "take_word": "本拍有效输入进入 writer 业务判断。",
        "reject_word": "本拍无法归属可写块而计丢弃。",
        "tick": "缩短到 800ns 的测试窗口到点信号。",
        "seal_pending": "窗口需封存，但可能仍等在途 B 响应。",
        "seal_done": "当前封存条件已处理完成。",
        "push_block": "把成功封存的块元数据压入待 CPU 处理队列。",
        "pop_block": "cpu_ack 且队列非空时的出队条件。",
        "queued": "尚未收到 CPU 确认的块数量，范围 0～8。",
        "ready_blocks": "对 CPU 显示的待处理块数量。",
        "write_block": "下一个可写环槽指针，满队时不能覆盖旧槽。",
        "read_block": "最老未确认队头的环槽指针。",
        "head_addr": "CPU 当前应读的最老块 DDR 首地址。",
        "head_len": "当前队头已成功提交的有效字节数。",
        "head_seq": "当前队头的发布序号，用于识别回绕后的新块。",
        "irq": "有待处理队头的通知状态；与队列所有权不同。",
        "cpu_ack": "CPU 已处理当前队头后的单拍释放确认。",
        "irq_clear": "只清通知位，不移动队列读指针。",
        "response_delay": "测试台故意延迟 FDMA B 响应的配置值。",
        "frame_data": "上游输入的 64bit 原拍，writer 仅取其低 32bit。",
        "frame_ready": "writer 接收流接口状态；即使满队也可能接收后计丢弃。",
    },
    "axi": {
        "aw_pending": "桥仍待下游接受的 AW 地址事务。",
        "w_pending": "桥仍待下游接受的 W 数据事务。",
        "wa": "拆分后的下一写段 AXI 地址。",
        "ra": "拆分后的下一读段 AXI 地址。",
        "wleft": "整个 FDMA 写请求尚未完成的拍数。",
        "rleft": "整个 FDMA 读请求尚未完成的拍数。",
        "allow_aw": "测试台人为允许 AWREADY 的门控。",
        "allow_w": "测试台人为允许 WREADY 的门控。",
        "allow_b": "测试台人为允许 B 响应的门控。",
        "ram_bresp": "行为 RAM 原始 B 响应，用来辨认注错来自测试台。",
        "fdma_waddr": "整个 FDMA 写请求起始地址，桥据此拆成 AXI 段。",
        "fdma_raddr": "整个 FDMA 读请求起始地址，桥据此拆成 AXI 段。",
    },
    "regs": {
        "slv_reg_rden": "AXI-Lite 读地址被采样后触发寄存器译码。",
        "slv_reg_wren": "AXI-Lite 写地址和数据均可接受的寄存器写条件。",
        "CPU_WR_DONE": "0x20 提交后的忙/门铃保持位，直到 done 事件清零。",
        "CPU_WR_DONE_d": "忙位延迟一拍，用于边沿检测。",
        "CPU_WR_DONE_pos": "忙位 0→1 时的一拍上升沿脉冲。",
        "CPU_REC_STATE": "0x14 写 1 且 WSTRB[0] 有效时形成的单拍 ACK 源。",
        "RX_READY_BLOCKS": "测试台固定接入的队列数量，用于读寄存器译码检查。",
        "RX_HEAD_SEQ": "测试台固定接入的队头序号，用于读寄存器译码检查。",
        "RX_DROPPED_FRAMES": "测试台固定接入的丢字数，用于读寄存器译码检查。",
        "command_addr": "忙位未置起时允许锁存的 CPU 下行地址。",
        "command_len": "忙位未置起时允许锁存的 CPU 下行长度。",
        "done": "测试台模拟的下行业务完成事件，用来清忙位。",
        "start": "CPU_WR_DONE 上升沿转换出的单拍下行启动脉冲。",
        "starts": "测试台已看到的 start 脉冲次数。",
        "ack": "寄存器模块导出的单拍 CPU 接收确认。",
        "acks": "测试台已看到的 ACK 脉冲次数。",
    },
    "tx": {
        "rvalid": "FDMA 从端当前读数据拍有效。",
        "rready": "TX 桥/写 FIFO 可以接受 FDMA 数据拍。",
        "tx_data": "10G LocalLink 输出 64bit 数据拍。",
    },
    "rx_fifo": {
        "drop_bin": "接收源域统计的已丢有效字数，经计数 CDC 后对外显示。",
        "frame_data": "异步 FIFO 的 64bit FWFT 队头，frame_ready 握手后才前进。",
        "frame_ready": "DDR 域消费者放行；与 frame_valid 一起形成 fifo_read。",
    },
}


def signal_role(case, path):
    name = path.rsplit("/", 1)[-1]
    return CASE_ROLES.get(case, {}).get(name, ROLES.get(name))


# (RTL / stimulus cause, interpretation and proof boundary). The accompanying
# per-signal table below each image covers every selected signal, including
# useful non-changing controls such as REM and WSTRB.
FIGURE_NOTES = {
    "ring_01_pair": (
        "writer 在第一个有效输入后锁存 half_data/half_valid，第二个有效输入产生 pair_start；64bit 写拍按 {后字低32,先字低32} 组装，WSTRB=FF。数据拍被 fdma_waccept 接受后仍须等待最终 fdma_wdone 且无错。",
        "50ns 的写请求与 70ns 的数据接受只说明传输已进入 FDMA；86ns 成功响应才令 write_success 为 1，90ns used_bytes 增 8。把源数据高 32bit 和实际 fdma_wdata 对比，可见高半原始噪声未进入 DDR。"),
    "ring_02_publish_ack": (
        "tick 发起封存，seal_pending/seal_done 负责把已经得到成功写响应的长度发布成 push_block；queued/ready_blocks 是同一队列的内部数和对外数，head_addr/len/seq 从当前 read_block 指向的队头读出。",
        "838ns 队列从 0 到 1 且 IRQ 置位。846ns cpu_ack 与 irq_clear 同时被测试台拉高，pop_block 因队列非空成立；850ns 读指针/数量才更新。此图单独不能分离两个输入的功能，须对照 RTL 分支。"),
    "ring_03_tail": (
        "窗口末仍有 half_valid 时，tail_start 生成只有低 4Byte 有效的 FDMA 写；低半为 half_data，高半即使在 WDATA 上有值也被 WSTRB=0F 屏蔽。",
        "1638ns 地址位于本块首写拍之后，1674ns 成功响应后 used_bytes 从 8 增到 12；随后 head_len=12。长度按有效 4Byte 增长，不按 64bit 总线宽度补齐到 16。"),
    "ring_04a_wrap_last": (
        "write_block 是下次写入环槽，read_block 是最老待处理环槽；序号与槽号分离，物理槽只有 0～7。",
        "本图第 7 块的 head_seq=7、地址为 0x002C0000，发布后 write_block 回 0；此时并不是回写旧队头，需与下一图 seq=8 对照。"),
    "ring_04b_wrap_first": (
        "新的发布序号继续递增，但写槽按 8 个槽取模，地址从 0x002C0000 回到 0x00100000。",
        "head_seq=8 与基地址重用同时出现，说明回绕后的块是新版本；测试台逐块核对数据与序号，截图本身只展示边界两例。"),
    "ring_05_full_reject": (
        "queued=8 表示所有环槽仍归 CPU 所有，不能用 write_block 覆盖；take_word 表示流输入被看到，reject_word 表示本拍无法存储。",
        "满队仍可能 frame_ready=1，两个输入字 999/1000 分别使 dropped_frames 增 1；head_addr/head_seq 不跳，说明旧队头未被替换。dropped_frames 的计量单位是低 32bit 字。"),
    "ring_05_pop_eight": (
        "pop_block 的组合条件是 cpu_ack && queued!=0；采样沿后 read_block 加一、queued 减一，head_* 切换到下一块。irq_clear 同拍出现只是测试台 ack() 的驱动方式。",
        "八次 ACK 使 ready_blocks 8→0，head_seq 顺次推进 24～31，末次读指针 7→0。中间尚有块时 irq 保持；清空后队头输出归零，CPU 才能安全重用释放的槽。"),
    "ring_05_delayed": (
        "测试台把 response_delay 增到 300，tick 到点只使 seal_pending 置位；write_curr_st 仍在 RESPONSE 且 fdma_wbusy=1，代表在途写还未拿到 B 响应。",
        "26434ns 即使封存请求已经存在，used_bytes/ready_blocks 仍为 0 且 push_block 不发生。这样避免 CPU 提前读到尚未确认写入 DDR 的队头。"),
    "ring_05_delayed_release": (
        "writer 的 write_success 只在 RESPONSE 状态收到 fdma_wdone 且 fdma_werror=0 时成立；随后用于增加 used_bytes，封存逻辑才允许 push_block。",
        "27106ns 成功响应，27110ns 长度增加并发出 push，27114ns ready_blocks/head_len 可见更新。这个顺序对应测试台 EARLY_PUBLISH 检查；仅凭 seal_pending 高电平不能认为块已发布。"),
    "ring_06_error": (
        "inject_error 令 FDMA 模型在 B 完成时带 fdma_werror；write_failure 分支记丢字，但不增加 used_bytes、不发布出错块。",
        "27190ns done/error 同时为 1，27194ns dropped_frames 从 2 到 4，ready_blocks 保持 0。计数加 2 因本事务含两个有效低 32bit 字，并非两帧。"),
    "ring_06_recovery": (
        "解除注错后，下一窗口的单字尾拍用 WSTRB=0F 提交；只有成功 B 响应才增加有效长度并入队。",
        "28874ns 写成功，28882ns 新 head_len=4、head_seq=33、ready_blocks=1。出错块未消耗发布序号，恢复数据可正常成为下一个队头。"),
    "axi_01a_aw_backpressure": (
        "CONV_DMA 对 AW 与 W 分别记录 pending；测试台 allow_aw 拉低使 AWREADY 不成立，此时 AWVALID/AWADDR/AWLEN 按 AXI 规则保持。",
        "50ns AWVALID 已有，70ns 才放行 AWREADY，74ns 采样沿接受地址。W 通道可独立运行，所以不能拿 WVALID 变化替代 AW 握手。"),
    "axi_01b_wlast_b": (
        "最后 W 拍的 WLAST 与数据、WSTRB 在 WREADY 低时一起保持；写事务需要 BVALID/BREADY 再结算。",
        "218ns WLAST 已出现但未接受，234ns 才完成末拍握手；290ns B 响应后 fdma_wdone 才出现。把 WLAST 高电平当成写完成会提前约 56ns。"),
    "axi_02a_eight_writes": (
        "每个 16 拍 FDMA 写按 0x40000Byte 步进到一个不同块，桥的 wa 与 AWADDR 对应，AWLEN=0x0F。B 响应后才给上层 done。",
        "从 0x00100000 到 0x002C0000 的八个 AW 地址都在 4MiB 行为 RAM 范围内。宽时间图用于查地址序列；每拍数据是否正确由测试台逐字比较。"),
    "axi_02b_eight_reads": (
        "FDMA 读请求进入 AR 通道，ARADDR/ARLEN 建立 16 拍读；RVALID/RREADY 才消耗数据，RLAST 标记该段末拍。",
        "八个高地址各有末拍与 fdma_rvalid 接受事件，末值从 {0,15} 到 {7,15}；测试台比较每个 beat，排除高地址截断后别名的可能。"),
    "axi_03a_split_first": (
        "起址 0x00180FF8 离下一个 4KiB 边界只有 8Byte，burst_beats 先限制为 1；AWLEN=0。AW/W 独立，允许 W 先握手。",
        "3234ns 首段末 W 拍已接受，3242ns AW 才接受，3266ns B 才结算；桥不能因为 WLAST 早到就结束整个 520 拍 FDMA 请求。"),
    "axi_03b_split_middle": (
        "跨边界后的段受 AXI 256 拍上限约束，AWLEN=0xFF；wleft 在每段 B 完成后扣除该段拍数，wa 指向下一段。",
        "第二段 256 拍在 5878ns 收到 WLAST、5994ns B 完成；随后第三段地址 0x00181800 发出。此图说明 B 与下一段启动的先后，不代表整个请求已 done。"),
    "axi_03c_split_last": (
        "前面 1+256+256 拍完成后剩 7 拍，末段 AWLEN=6；只有最后一段 B 完成才上报 fdma_wdone。",
        "8742ns 末段 AW 接受、8810ns 最后 W 拍接受、8846ns B 结算。前三段 B 没有产生整个 FDMA 请求完成脉冲。"),
    "axi_03d_read_last": (
        "读侧也按 4KiB/256 拍分段，rleft 与 ra 标识剩余数量及下一段地址；RVALID/RREADY 才是读拍接受。",
        "最后 ARLEN=6，13054ns 接受 RLAST，末拍 RDATA 对应 {123,519}；这与写侧 1+256+256+7 的 520 拍总量相配。"),
    "axi_04_bresp_error": (
        "测试台 inject_error 在 AXI B 边界把原始 RAM 的 OKAY 改成可见 SLVERR=2；桥只在 B 握手时汇总错误。",
        "13310ns BVALID/BREADY 与 BRESP=2 同时有效，fdma_wdone 与 fdma_werror 一起脉冲。这是有意错误传播测试，不是该用例未通过。"),
    "regs_01_read_fixed": (
        "AXI-Lite AR 握手触发 slv_reg_rden，RDATA/RVALID 由 INFO_EXCH 地址译码形成；队头相关 RX_* 在本测试中为固定测试输入。",
        "0x00/04/08 读版本和参数，0x30/34/38 读 1/7/9；截图证明寄存器读回，但不代表 ring 实时队头与 regs 在同一个仿真中联动。"),
    "regs_02_first_start": (
        "0x24/0x28 写地址和长度，0x20 写 1 使 CPU_WR_DONE 上升；延迟位 CPU_WR_DONE_d 构成 CPU_WR_DONE_pos 单拍边沿，输出 start。",
        "170ns start 出现、174ns 撤销，starts 计数加 1。command_addr 初始已是 0x8000，这次写相同值不引起数据线变化，但写握手确实发生。"),
    "regs_03_busy_repeat": (
        "忙位 CPU_WR_DONE 已为 1 时，寄存器写通道仍正常回应，但修改命令地址/长度和再次 start 被 !CPU_WR_DONE 条件屏蔽。",
        "0x20 重写、0x24/0x28 改写均有 slv_reg_wren；start/starts 不再变，随后读回仍为 0x8000/16。由此可以区分业务门控与 AXI 无握手。"),
    "regs_04_done_restart": (
        "测试台 done 模拟上一下行业务完成，RTL 清 CPU_WR_DONE；延迟位再清后，新一次 0x20=1 才能制造第二个上升沿。",
        "278ns 忙位清零，306ns start 再次高一拍，starts 由 1 到 2。done 是测试激励，不是这一短图对真实 FDMA 完成链的证明。"),
    "regs_05_ack_strobe": (
        "0x14 ACK 写条件含 slv_reg_wren、WDATA[0] 和 WSTRB[0]；CPU_REC_STATE/bus.ack 是单拍脉冲，测试台 acks 只在采到脉冲后增长。",
        "前两次 WSTRB 允许最低字节，各产生一次 ACK；第三次 WSTRB=E 虽有写握手/B 响应，却没有 ACK。它是 ring 的 cpu_ack 脉冲源局部测试，不是两份 VCD 的跨模块联动记录。"),
    "1g_01_invalid": (
        "cfg_byte_valid 说明测试台实际提交了 Byte1；组合译码仅允许编号 1～10，非法 0/11 对应 decode_valid=0。首次配置锁存条件同时要求合法和 !cfg_req。",
        "两个输入脉冲后 cfg_req/configured_id/configured/tx_valid 都未被激活；平直的零值是预期负例，不能因为没有发送就忽略输入 valid 已发生。"),
    "1g_02_config_cdc": (
        "5938ns 编号 1 合法，5942ns 源域 cfg_hold={0x00500000,0x0BB8} 与 cfg_req 锁存；标准 CDC 只作为 48bit 邮箱边界观察。目的域 cfg_user/cfg_ack 在 6128ns 同时取得配置。",
        "源域返回 ack_sync 后 6178ns 才 configured=1；configured_id 先变是源域已接受编号，不说明用户域已经取得参数。后续重复编号不能覆盖 cfg_hold。"),
    "1g_03_first_frame": (
        "period_tick 到来后，状态 IDLE→FIRST→LAST；FIRST 的 SOF/REM=3 对应4有效字节，LAST 的 EOF/REM=1 对应2有效字节。每次转换需 tx_valid&&tx_ready。",
        "首拍数据 B80B0000，尾拍 50000000 组合为 duty=0x0BB8、Vin=0x00500000 的六字节小端载荷；末拍接受后 completed_frames 才加一。"),
    "1g_04_stall_skip": (
        "FIRST 状态遇 tx_ready=0 时必须保持 tx_valid、tx_sof、tx_data 和 tx_rem；period_tick 不取消已发起的拍。忙时 tick 只更新 skipped_periods。",
        "14192ns 进入 FIRST 后到 16208ns 再遇周期机会，skipped_periods 从 0 到 1，当前首拍未被替换。长窗口横轴用于比较两次机会，不适合逐沿读数据细节。"),
    "1g_04_release": (
        "18992ns ready 放行首拍，19024ns 状态转 LAST；测试台同拍再次压低 ready，所以尾拍的 valid/EOF/REM/数据继续稳定等待。",
        "这个局部图把先前的跳过机会与实际在途帧分开：跳过计数不清零也不会补发旧机会，状态只因当前拍握手推进。"),
    "1g_05_link_recovery": (
        "channel_up 低时发送态与 arm_count 清零，但 cfg_user/cfg_ack/configured 不随线路掉线清除；周期计时仍在用户域，掉线期间的 tick 不排队。",
        "25168ns 重连后 arm_count 用四个用户沿升到4，之后才允许下一周期机会启动新帧。波形证明业务 RTL 的停发/恢复，不表示真实 Aurora GT 完成物理重建。"),
    "tx_01_single": (
        "FDMA 读请求按 16Byte 帧地址发出，rvalid&&rready 才写入异步 FIFO；用户域仅在 valid&&ready 时用 fifo_rd_en 出队，SOF/EOF 标出两拍边界。",
        "第一帧两拍低序号为 0、1，rem 恒7，测试台 received 到2。FDMA 输入和 10G 输出存在跨域延迟，不应按同纳秒逐线对齐。"),
    "tx_02_near_full": (
        "TX FIFO 深度512，近满阈值504；fifo_almost_full 拉高让 fifo_write_ready=0，抑制后续读突发或数据握手，预留8拍给在途数据。",
        "6718ns 水位504且峰值随后记录504，fifo_overflow 保持0。单独一图说明阈值触发，不足以说明全部600拍无丢失，需看最终测试台序号比较。"),
    "tx_03_drain_resume": (
        "消费者 ready 恢复后 fifo_rd_en 连续出现，received 随 SOF/EOF 成对增加；水位下降解除近满，桥再次拉起 rareq 补读。",
        "19866ns 附近近满解除，19874ns 新读请求出现；后续反压与补读会交替。valid 无 ready 的拍由测试台 held_payload 检查数据和标志保持。"),
    "rx_fifo_01_fill": (
        "rx_valid 且源域未满才产生 fifo_write；FIFO 以 FWFT 在目的域预先展示队头，frame_ready=0 时不前进。SOF/EOF 是兼容端口，不参与入队筛选。",
        "低32bit 0～16 连续入队；源域近满/满先变化，目的域同步输出稍后变化。rx_ready 恒1 不保证无丢失，所以要同时看 full_user 和 fifo_write。"),
    "rx_fifo_02_drop": (
        "已满时 rx_valid 仍是一个实际线路拍，但 fifo_write 被 full_user 禁止；源域 drop_bin 按有效字加一，再经标准计数 CDC 到 dropped_frames。",
        "值100没有进入 FIFO，598.4ns 源计数加一、614ns 目的域计数加一，旧 frame_data 保持；不能把这个跨域延时误认为第二次丢字。"),
    "rx_fifo_03_drain": (
        "frame_ready=1 后，与 frame_valid 形成 fifo_read；FWFT 队头每次成功消费才换下一字。读出给写端释放空间，满状态跨域更新存在延时。",
        "received 按低32bit 0～16 顺序增加到17，丢失计数保持1。截图里先看到 full_user 下降、后见目的域 fifo_full 下降是设计预期。"),
    "rx_fifo_03_resume": (
        "容量恢复后新输入99通过 fifo_write 写入，之后 frame_data 再显示同一64bit原拍；length_error 因本设计不按线路帧长检查而固定为0。",
        "786ns 读侧出现99，790ns received=18；先前满时的100没有混入输出。完整高32bit 随机值也被测试台逐拍比较。"),
    "axi_tail_01_full": (
        "在地址 0x002FFFF8 先以 fdma_wstrb=FF 写 0x12345678_12345678；CONV_DMA 让 WSTRB/WDATA 到 AXI 边界，行为 RAM 对所有8Byte建立初值。",
        "WVALID/WREADY 只说明数据拍接受，166ns B 响应后 fdma_wdone 才确认完成。后图必须以此初值为基线判断高半是否被错误覆盖。"),
    "axi_tail_02_partial": (
        "同址第二次给 WDATA=0xDEADBEEF_DEADBEEF，但 WSTRB=0F 只允许低4Byte；RAM 依据 strobes 而非 WDATA 数值决定逐字节写入。",
        "FDMA/AXI 两侧 WSTRB 同为0F，234ns W 拍接受，290ns B 后 done 且无错。高32bit WDATA 看似 DEADBEEF，实际应保持第一次的 12345678。"),
    "axi_tail_03_readback": (
        "AR 请求同址的单个64bit拍，RVALID/RREADY/RLAST 共同确认读回；fdma_rvalid 是桥的已接受拍脉冲。",
        "318ns RDATA=0x12345678_DEADBEEF，同一字中高半保留、低半更新；测试台完整64bit比较 PASS，证明桥加行为 RAM 的按字节写路径。"),
}

