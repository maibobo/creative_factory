// Reproducible, local-only screenshots of real VCD data rendered by the offline viewer.
const {chromium}=require(process.env.WAVE_PLAYWRIGHT || '../evidence/viewer_test_tools/playwright/driver/package');
const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url'),assert=require('assert');
const root=path.resolve(__dirname,'..');
const out=path.join(root,'evidence','local_wave_sessions','word_wave_captures');
fs.mkdirSync(out,{recursive:true});

// A captioned view may select a small, ordered subset of the complete viewer inventory.
// Names are full VCD paths after prefixing the case testbench. "top/" means testbench scope.
const shots=[
 {case:'ring',section:1,key:'ring_01_pair',range:[34,96],cursor:50,caption:'两个32-bit字拼成64-bit写拍；接受、成功响应和used_bytes分开看。',
  signals:['bus/frame_data','bus/frame_valid','bus/frame_ready','U_DUT/half_data','U_DUT/half_valid','U_DUT/pair_start','bus/fdma_waddr','bus/fdma_wdata','bus/fdma_wstrb','bus/fdma_wareq','bus/fdma_waccept','bus/fdma_wdone','bus/fdma_werror','U_DUT/write_success','U_DUT/used_bytes']},
 {case:'ring',section:2,key:'ring_02_publish_ack',range:[824,854],cursor:838,caption:'窗口tick后才push；ready_blocks和队头更新，cpu_ack随后pop。',
  signals:['U_DUT/tick','U_DUT/seal_pending','U_DUT/seal_done','U_DUT/push_block','U_DUT/queued','bus/ready_blocks','bus/head_addr','bus/head_len','bus/head_seq','bus/irq','bus/cpu_ack','bus/irq_clear','U_DUT/pop_block','U_DUT/read_block']},
 {case:'ring',section:3,key:'ring_03_tail',range:[1628,1695],cursor:1638,caption:'奇数尾字只使能WSTRB低4位；响应后used_bytes增加4。',
  signals:['bus/frame_data','bus/frame_valid','U_DUT/half_data','U_DUT/half_valid','U_DUT/tail_start','bus/fdma_waddr','bus/fdma_wdata','bus/fdma_wstrb','bus/fdma_wareq','bus/fdma_waccept','bus/fdma_wdone','U_DUT/write_success','U_DUT/used_bytes','bus/head_len','bus/head_seq']},
 {case:'ring',section:4,key:'ring_04a_wrap_last',range:[6470,6510],cursor:6482,caption:'第7块发布，观察head_seq=7以及写块指针回到0。',
  signals:['U_DUT/write_block','U_DUT/read_block','U_DUT/push_block','U_DUT/queued','bus/ready_blocks','bus/head_addr','bus/head_len','bus/head_seq','bus/irq','bus/cpu_ack','U_DUT/pop_block']},
 {case:'ring',section:4,key:'ring_04b_wrap_first',range:[7225,7265],cursor:7238,caption:'下一块seq=8重新使用基地址0x00100000，构成回绕对照。',
  signals:['U_DUT/write_block','U_DUT/read_block','U_DUT/push_block','U_DUT/queued','bus/ready_blocks','bus/head_addr','bus/head_len','bus/head_seq','bus/irq','bus/cpu_ack','U_DUT/pop_block']},
 {case:'ring',section:5,key:'ring_05_full_reject',range:[25672,25710],cursor:25698,caption:'队列8块全满时仍可take_word，但reject_word计丢弃；旧head不动。',
  signals:['bus/frame_data','bus/frame_valid','bus/frame_ready','U_DUT/take_word','U_DUT/reject_word','U_DUT/queued','bus/ready_blocks','bus/dropped_frames','bus/head_addr','bus/head_seq','U_DUT/write_block','U_DUT/read_block']},
 {case:'ring',section:5,key:'ring_05_pop_eight',range:[25730,25860],cursor:25738,caption:'连续CPU确认使队列8到0，队头地址与序号逐次推进。',
  signals:['bus/cpu_ack','bus/irq_clear','U_DUT/pop_block','U_DUT/queued','bus/ready_blocks','bus/head_addr','bus/head_len','bus/head_seq','U_DUT/read_block','bus/irq']},
 {case:'ring',section:5,key:'ring_05_delayed',range:[26420,26455],cursor:26434,caption:'封存请求已到，但写响应尚未到；ready_blocks保持0。',
  signals:['top/response_delay','U_DUT/tick','U_DUT/seal_pending','U_DUT/write_curr_st','bus/fdma_wbusy','bus/fdma_wdone','U_DUT/write_success','U_DUT/used_bytes','U_DUT/push_block','bus/ready_blocks']},
 {case:'ring',section:5,key:'ring_05_delayed_release',range:[27090,27125],cursor:27114,caption:'fdma_wdone成功后used_bytes和push_block出现，才发布队头。',
  signals:['U_DUT/seal_pending','U_DUT/write_curr_st','bus/fdma_wbusy','bus/fdma_wdone','bus/fdma_werror','U_DUT/write_success','U_DUT/used_bytes','U_DUT/push_block','bus/ready_blocks','bus/head_len','bus/head_seq']},
 {case:'ring',section:6,key:'ring_06_error',range:[27135,27200],cursor:27194,caption:'注入写错误，write_failure和丢弃计数跳变，队列不发布。',
  signals:['top/inject_error','bus/frame_data','bus/frame_valid','bus/fdma_wdone','bus/fdma_werror','U_DUT/write_failure','U_DUT/dropped_frames','U_DUT/used_bytes','U_DUT/push_block','bus/ready_blocks','bus/head_seq']},
 {case:'ring',section:6,key:'ring_06_recovery',range:[28830,28895],cursor:28882,caption:'错误解除后的低4字节尾拍成功，seq=33正常发布。',
  signals:['top/inject_error','bus/fdma_wdata','bus/fdma_wstrb','bus/fdma_wdone','bus/fdma_werror','U_DUT/write_success','U_DUT/used_bytes','U_DUT/push_block','bus/ready_blocks','bus/head_len','bus/head_seq']},
 {case:'axi',section:1,key:'axi_01a_aw_backpressure',range:[40,100],cursor:74,caption:'AWVALID先出现，AWREADY延后；74ns才完成地址握手。',
  signals:['bus/fdma_wareq','bus/fdma_waddr','bus/fdma_wsize','top/allow_aw','bus/M_AXI_AWADDR','bus/M_AXI_AWLEN','bus/M_AXI_AWVALID','bus/M_AXI_AWREADY','bus/M_AXI_WVALID','bus/M_AXI_WREADY','U_DUT/aw_pending','U_DUT/w_pending']},
 {case:'axi',section:1,key:'axi_01b_wlast_b',range:[210,300],cursor:234,caption:'WLAST在WREADY低期间保持；B响应后才给fdma_wdone。',
  signals:['top/allow_w','top/allow_b','bus/M_AXI_WDATA','bus/M_AXI_WSTRB','bus/M_AXI_WLAST','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BRESP','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wbusy','bus/fdma_wdone','bus/fdma_werror']},
 {case:'axi',section:2,key:'axi_02a_eight_writes',range:[40,2035],cursor:822,caption:'八个相隔256KiB的AW地址与对应写完成；逐个查看地址总线。',
  signals:['bus/fdma_wareq','bus/fdma_waddr','bus/M_AXI_AWADDR','bus/M_AXI_AWLEN','bus/M_AXI_AWVALID','bus/M_AXI_AWREADY','bus/M_AXI_WLAST','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wdone','U_DUT/wa']},
 {case:'axi',section:2,key:'axi_02b_eight_reads',range:[2038,3220],cursor:2178,caption:'八个AR地址分别读回；RLAST接受与fdma_rvalid对应。',
  signals:['bus/fdma_rareq','bus/fdma_raddr','bus/M_AXI_ARADDR','bus/M_AXI_ARLEN','bus/M_AXI_ARVALID','bus/M_AXI_ARREADY','bus/M_AXI_RDATA','bus/M_AXI_RLAST','bus/M_AXI_RVALID','bus/M_AXI_RREADY','bus/fdma_rvalid','U_DUT/ra']},
 {case:'axi',section:3,key:'axi_03a_split_first',range:[3218,3300],cursor:3242,caption:'0x00180FF8只余8字节，首段AWLEN=0；W末拍甚至早于AW握手。',
  signals:['bus/fdma_wareq','bus/fdma_waddr','bus/fdma_wsize','U_DUT/wleft','bus/M_AXI_AWADDR','bus/M_AXI_AWLEN','bus/M_AXI_AWVALID','bus/M_AXI_AWREADY','bus/M_AXI_WLAST','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wdone']},
 {case:'axi',section:3,key:'axi_03b_split_middle',range:[5858,6030],cursor:5994,caption:'第二段256拍收束在B响应，下一段AW地址与LEN随后出现。',
  signals:['U_DUT/wleft','U_DUT/wa','bus/M_AXI_AWADDR','bus/M_AXI_AWLEN','bus/M_AXI_AWVALID','bus/M_AXI_AWREADY','bus/M_AXI_WLAST','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wdone']},
 {case:'axi',section:3,key:'axi_03c_split_last',range:[8700,8860],cursor:8846,caption:'第四段AWLEN=6即7拍；前三段B不完成整个FDMA请求，最后一段才done。',
  signals:['U_DUT/wleft','U_DUT/wa','bus/M_AXI_AWADDR','bus/M_AXI_AWLEN','bus/M_AXI_AWVALID','bus/M_AXI_AWREADY','bus/M_AXI_WLAST','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wdone']},
 {case:'axi',section:3,key:'axi_03d_read_last',range:[12980,13060],cursor:13054,caption:'读侧最后7拍的RLAST，RDATA结束在{123,519}。',
  signals:['bus/M_AXI_ARADDR','bus/M_AXI_ARLEN','bus/M_AXI_ARVALID','bus/M_AXI_ARREADY','bus/M_AXI_RDATA','bus/M_AXI_RLAST','bus/M_AXI_RVALID','bus/M_AXI_RREADY','bus/fdma_rvalid','bus/fdma_rbusy','U_DUT/rleft','U_DUT/ra']},
 {case:'axi',section:4,key:'axi_04_bresp_error',range:[13280,13316],cursor:13310,caption:'总线BRESP=2的B握手同时触发fdma_wdone与fdma_werror。',
  signals:['bus/inject_error','top/ram_bresp','bus/M_AXI_WLAST','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BRESP','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wbusy','bus/fdma_wdone','bus/fdma_werror']},
 {case:'regs',section:1,key:'regs_01_read_fixed',range:[30,126],cursor:122,caption:'AR/R译码读出版本、参数和三个固定队头输入。',
  signals:['bus/araddr','bus/arvalid','bus/arready','U_DUT/slv_reg_rden','bus/rdata','bus/rvalid','bus/rready','U_DUT/RX_READY_BLOCKS','U_DUT/RX_HEAD_SEQ','U_DUT/RX_DROPPED_FRAMES']},
 {case:'regs',section:2,key:'regs_02_first_start',range:[128,190],cursor:170,caption:'地址和长度写入后，CPU_WR_DONE上升沿只产生一拍start。',
  signals:['bus/awaddr','bus/wdata','bus/wstrb','bus/awvalid','bus/wvalid','bus/awready','bus/wready','bus/command_addr','bus/command_len','U_DUT/slv_reg_wren','U_DUT/CPU_WR_DONE','U_DUT/CPU_WR_DONE_d','U_DUT/CPU_WR_DONE_pos','bus/start','top/starts']},
 {case:'regs',section:3,key:'regs_03_busy_repeat',range:[194,270],cursor:226,caption:'忙位已为1时仍有写握手，但start和参数不再次更新；读回旧值。',
  signals:['bus/awaddr','bus/wdata','bus/awvalid','bus/wvalid','bus/awready','bus/wready','U_DUT/slv_reg_wren','U_DUT/CPU_WR_DONE','U_DUT/CPU_WR_DONE_pos','bus/start','top/starts','bus/command_addr','bus/command_len','bus/araddr','bus/rdata','bus/rvalid']},
 {case:'regs',section:4,key:'regs_04_done_restart',range:[272,314],cursor:306,caption:'done清忙后第二次写0x20=1，再次出现单拍start。',
  signals:['bus/done','U_DUT/CPU_WR_DONE','U_DUT/CPU_WR_DONE_d','U_DUT/CPU_WR_DONE_pos','bus/start','top/starts','bus/araddr','bus/rdata','bus/awaddr','bus/wdata','U_DUT/slv_reg_wren']},
 {case:'regs',section:5,key:'regs_05_ack_strobe',range:[330,406],cursor:398,caption:'两次有效ACK后，WSTRB=E的第三次写有握手却不产生ACK。',
  signals:['bus/awaddr','bus/wdata','bus/wstrb','bus/awvalid','bus/wvalid','bus/awready','bus/wready','U_DUT/slv_reg_wren','bus/bvalid','bus/ack','top/acks','U_DUT/CPU_REC_STATE']},
 {case:'1g',section:1,key:'1g_01_invalid',range:[810,850],cursor:826,caption:'Byte1=0与11两次有效输入均被译码过滤，配置请求不启动。',
  signals:['bus/cfg_byte','bus/cfg_byte_valid','U_DUT/decode_valid','U_DUT/decoded_duty','U_DUT/decoded_vin','U_DUT/cfg_req','bus/configured_id','bus/configured','bus/tx_valid']},
 {case:'1g',section:2,key:'1g_02_config_cdc',range:[5928,6190],cursor:6128,caption:'首次合法编号1锁存48bit参数；用户域确认后源域才置configured。',
  signals:['bus/cfg_byte','bus/cfg_byte_valid','U_DUT/decode_valid','U_DUT/cfg_hold','U_DUT/cfg_req','U_DUT/req_sync','U_DUT/cfg_user','U_DUT/cfg_ack','U_DUT/ack_sync','bus/configured_id','bus/configured']},
 {case:'1g',section:3,key:'1g_03_first_frame',range:[8090,8230],cursor:8176,caption:'周期机会触发FIRST/LAST两拍；SOF/EOF、REM和载荷逐拍对应。',
  signals:['U_DUT/period_tick','U_DUT/tx_curr_st','bus/tx_ready','bus/tx_valid','bus/tx_sof','bus/tx_eof','bus/tx_rem','bus/tx_data','top/completed_frames']},
 {case:'1g',section:4,key:'1g_04_stall_skip',range:[14140,16230],cursor:16208,caption:'首拍长期反压期间状态保持FIRST，下一次周期tick只增加跳过计数。',
  signals:['bus/tx_ready','bus/tx_valid','bus/tx_sof','bus/tx_eof','bus/tx_rem','bus/tx_data','U_DUT/tx_curr_st','U_DUT/period_tick','bus/skipped_periods']},
 {case:'1g',section:4,key:'1g_04_release',range:[18970,19070],cursor:19024,caption:'ready恢复才由FIRST转LAST；再次撤销ready后尾拍保持。',
  signals:['bus/tx_ready','bus/tx_valid','bus/tx_sof','bus/tx_eof','bus/tx_rem','bus/tx_data','U_DUT/tx_curr_st','bus/skipped_periods']},
 {case:'1g',section:5,key:'1g_05_link_recovery',range:[21940,26320],cursor:25296,caption:'链路低电平清发送态、参数仍锁存；重连先arm再等下一周期机会。',
  signals:['bus/channel_up','bus/user_reset','U_DUT/cfg_user','U_DUT/cfg_ack','bus/configured','U_DUT/arm_count','U_DUT/period_tick','U_DUT/tx_curr_st','bus/tx_valid','bus/tx_sof','bus/tx_eof']},
 {case:'tx',section:1,key:'tx_01_single',range:[250,365],cursor:323.2,caption:'一次16Byte FDMA读取写FIFO，10G域以SOF/EOF两拍送出。',
  signals:['bus/limit','bus/raddr','bus/rareq','bus/rbusy','bus/rvalid','bus/rready','bus/rdata','U_DUT/fifo_wr_en','U_DUT/fifo_wr_cnt','U_DUT/fifo_rd_en','bus/valid','bus/ready','bus/sof','bus/eof','bus/rem','bus/tx_data','top/received']},
 {case:'tx',section:2,key:'tx_02_near_full',range:[6650,6740],cursor:6718,caption:'FIFO达到504拍，prog_full阻止新读突发并保留8拍余量。',
  signals:['bus/raddr','bus/rareq','bus/rvalid','bus/rready','U_DUT/rd_data_hs','U_DUT/fifo_wr_cnt','U_DUT/fifo_almost_full','U_DUT/fifo_write_ready','U_DUT/fifo_overflow','top/peak_words','bus/valid','bus/ready']},
 {case:'tx',section:3,key:'tx_03_drain_resume',range:[19820,19945],cursor:19866,caption:'消费者恢复握手后FIFO水位下降，近满解除并重新发读请求。',
  signals:['bus/ready','bus/valid','bus/sof','bus/eof','bus/tx_data','U_DUT/fifo_rd_en','U_DUT/fifo_wr_cnt','U_DUT/fifo_almost_full','U_DUT/fifo_write_ready','bus/rareq','bus/raddr','top/received']},
 {case:'rx_fifo',section:1,key:'rx_fifo_01_fill',range:[288,520],cursor:508.8,caption:'接收域连续有效字写入FIFO，目的域先看到FWFT队头；近满先于满。',
  signals:['bus/rx_data','bus/rx_valid','bus/rx_sof','bus/rx_eof','bus/rx_ready','U_DUT/fifo_write','U_DUT/almost_full_user','U_DUT/full_user','bus/fifo_almost_full','bus/fifo_full','bus/frame_data','bus/frame_valid','bus/frame_ready']},
 {case:'rx_fifo',section:2,key:'rx_fifo_02_drop',range:[580,630],cursor:598.4,caption:'已满仍出现有效字100；不写FIFO，丢失计数经跨域后对外加一。',
  signals:['bus/rx_data','bus/rx_valid','bus/rx_ready','U_DUT/full_user','U_DUT/fifo_write','U_DUT/drop_bin','bus/dropped_frames','bus/fifo_full','bus/frame_valid','bus/frame_data']},
 {case:'rx_fifo',section:3,key:'rx_fifo_03_drain',range:[675,755],cursor:706,caption:'frame_ready使读侧逐拍出队，满标志释放，已存17字按序流出。',
  signals:['bus/frame_ready','bus/frame_valid','bus/frame_data','U_DUT/fifo_read','U_DUT/full_user','bus/fifo_full','bus/fifo_almost_full','bus/dropped_frames','top/received']},
 {case:'rx_fifo',section:3,key:'rx_fifo_03_resume',range:[744,790],cursor:752,caption:'FIFO释放容量后新字99再次写入并最终从读侧输出。',
  signals:['bus/rx_data','bus/rx_valid','U_DUT/fifo_write','U_DUT/full_user','bus/frame_ready','bus/frame_valid','bus/frame_data','bus/dropped_frames','top/received','bus/length_error']},
 {case:'axi_tail',section:1,key:'axi_tail_01_full',range:[40,175],cursor:166,caption:'先用FF全字节写入0x12345678_12345678并等待B响应。',
  signals:['bus/fdma_waddr','bus/fdma_wdata','bus/fdma_wstrb','bus/fdma_wareq','bus/M_AXI_AWADDR','bus/M_AXI_AWLEN','bus/M_AXI_WDATA','bus/M_AXI_WSTRB','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/fdma_wdone']},
 {case:'axi_tail',section:2,key:'axi_tail_02_partial',range:[176,300],cursor:234,caption:'同址以0F写DEADBEEF低四字节；WSTRB穿过桥并在B后完成。',
  signals:['bus/fdma_waddr','bus/fdma_wdata','bus/fdma_wstrb','bus/fdma_wareq','bus/M_AXI_AWADDR','bus/M_AXI_WDATA','bus/M_AXI_WSTRB','bus/M_AXI_WVALID','bus/M_AXI_WREADY','bus/M_AXI_BVALID','bus/M_AXI_BREADY','bus/M_AXI_BRESP','bus/fdma_wdone','bus/fdma_werror']},
 {case:'axi_tail',section:3,key:'axi_tail_03_readback',range:[300,326],cursor:318,caption:'读回同一地址为0x12345678_DEADBEEF，高32位保留，低32位更新。',
  signals:['bus/fdma_raddr','bus/fdma_rareq','bus/M_AXI_ARADDR','bus/M_AXI_ARLEN','bus/M_AXI_ARVALID','bus/M_AXI_ARREADY','bus/M_AXI_RDATA','bus/M_AXI_RLAST','bus/M_AXI_RVALID','bus/M_AXI_RREADY','bus/fdma_rdata','bus/fdma_rvalid']}
];

function fullPath(caseName,short){
  if(short.startsWith('top/'))return '/tb_rtds_'+caseName+'/'+short.slice(4);
  return '/tb_rtds_'+caseName+'/'+short;
}

(async()=>{
  const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
  const manifest=[];
  try{
    for(const caseName of ['ring','axi','regs','1g','tx','rx_fifo','axi_tail']){
      const page=await browser.newPage({viewport:{width:1600,height:730},deviceScaleFactor:1});
      const errors=[];page.on('pageerror',e=>errors.push(e.message));
      await page.route(/^https?:/,r=>r.abort());
      await page.goto(pathToFileURL(path.join(root,'evidence','local_wave_sessions',caseName,caseName+'_viewer.html')).href);
      await page.waitForFunction(()=>!!window.WAVE_TEST);
      for(const shot of shots.filter(x=>x.case===caseName)){
        const paths=shot.signals.map(s=>fullPath(caseName,s));
        const detail=await page.evaluate(({paths,range,cursor})=>{
          const {DATA,state,layout,select,setRange,scrollTo}=WAVE_TEST;
          const indices=paths.map(p=>DATA.signals.findIndex(s=>s.path===p));
          if(indices.some(i=>i<0))throw Error('Missing signal paths: '+paths.filter((_,j)=>indices[j]<0).join(', '));
          state.panes=[true,true,false];state.weights=[.37,.63,0];
          document.getElementById('names').value='full';
          state.visible=indices;
          for(const id of ['signalSpacer','waveSpacer'])document.getElementById(id).style.height=indices.length*30+'px';
          layout();scrollTo(0);select(indices[0]);
          state.cursor=Math.round(cursor/DATA.tickNs);
          setRange(range[0]/DATA.tickNs,range[1]/DATA.tickNs);
          const transitions=indices.map(i=>({path:DATA.signals[i].path,count:(DATA.events[DATA.signals[i].code]||[]).filter(e=>e[0]*DATA.tickNs>=range[0]&&e[0]*DATA.tickNs<=range[1]).length}));
          return {actualRange:[state.start*DATA.tickNs,state.end*DATA.tickNs],transitions};
        },{paths,range:shot.range,cursor:shot.cursor});
        assert(Math.abs(detail.actualRange[0]-shot.range[0])<.001&&Math.abs(detail.actualRange[1]-shot.range[1])<.001,shot.key+' range');
        assert(detail.transitions.some(t=>t.count>0),shot.key+' contains no waveform changes');
        await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
        const filename=shot.key+'.png';
        await page.screenshot({path:path.join(out,filename)});
        manifest.push({case:caseName,section:shot.section,key:shot.key,rangeNs:shot.range,cursorNs:shot.cursor,caption:shot.caption,file:filename,signals:paths,transitions:detail.transitions});
        console.log(filename+' '+shot.range.join('–')+' ns; '+detail.transitions.reduce((n,x)=>n+x.count,0)+' changes');
      }
      assert.deepStrictEqual(errors,[],caseName+' browser errors');
      await page.close();
    }
  }finally{await browser.close()}
  fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2),'utf8');
  console.log('captured '+manifest.length+' figures');
})().catch(e=>{console.error(e);process.exit(1)});
