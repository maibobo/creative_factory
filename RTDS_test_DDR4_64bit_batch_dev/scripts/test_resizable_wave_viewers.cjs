const {chromium}=require(process.env.WAVE_PLAYWRIGHT || '../evidence/viewer_test_tools/playwright/driver/package');
const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url'),assert=require('assert');
const out=path.resolve(__dirname,'../evidence/local_wave_sessions');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});const report=[];
 try{for(const name of ['1g','tx','rx_fifo','ring','axi','axi_tail','regs']){
  const page=await browser.newPage({viewport:{width:1440,height:900}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.route(/^https?:/,r=>r.abort());await page.goto(pathToFileURL(path.join(out,name,name+'_viewer.html')).href);await page.waitForFunction(()=>!!window.WAVE_TEST);
  const initialLayout=await page.evaluate(()=>({panes:WAVE_TEST.state.panes,ratio:document.getElementById('signalsPane').getBoundingClientRect().width/(document.getElementById('signalsPane').getBoundingClientRect().width+document.getElementById('wavePane').getBoundingClientRect().width),font:getComputedStyle(document.querySelector('.signal-row')).fontSize}));
  assert.deepStrictEqual(initialLayout.panes,[true,true,false],name+' default two-pane layout');
  assert(Math.abs(initialLayout.ratio-.14)<.01,name+' default signal/wave ratio');
  assert.equal(initialLayout.font,'14px',name+' larger signal font');
  const info=await page.evaluate(()=>{const {DATA,state}=WAVE_TEST;return {all:DATA.signals.length,shown:state.visible.length,hiddenOk:state.visible.every(i=>!DATA.signals[i].standardInternal&&!DATA.signals[i].testbenchAlias),connections:DATA.signals.filter(s=>s.connections?.length).length}});
  assert(info.hiddenOk);assert(!/PASS|离线|本机重跑/.test(await page.locator('header').innerText()));
  assert(await page.locator('.signal-name').evaluateAll(es=>es.every(e=>!e.textContent.includes('/'))));
  await page.locator('#names').selectOption('full');assert(await page.locator('.signal-name').first().innerText().then(t=>t.startsWith('/')));await page.locator('#names').selectOption('short');
  await page.locator('#group').selectOption('all');assert.equal(await page.evaluate(()=>WAVE_TEST.state.visible.length),info.all);await page.locator('#group').selectOption('business');
  for(const viewport of [{width:1440,height:900},{width:1024,height:720}]){
   await page.setViewportSize(viewport);
   for(const mask of [7,3,5,6,1,2,4]){
    await page.locator('#resetLayout').click();const toggles=['showSignals','showWave','showCode'];await page.locator('#showCode').check();for(let i=0;i<3;i++)if(!(mask&(1<<i)))await page.locator('#'+toggles[i]).uncheck();
    const dims=await page.evaluate(()=>({panes:['signalsPane','wavePane','codePane'].map(id=>{const e=document.getElementById(id),r=e.getBoundingClientRect();return {visible:getComputedStyle(e).display!=='none',w:r.width,right:r.right,bottom:r.bottom}}),width:innerWidth,height:innerHeight}));
    dims.panes.forEach((p,i)=>{assert.equal(p.visible,!!(mask&(1<<i)));if(p.visible){assert(p.right<=dims.width+1);assert(p.bottom<=dims.height-24);assert(p.w>20)}});
    if(mask===1||mask===2||mask===4)assert(await page.locator('#'+toggles[Math.log2(mask)]).isDisabled());
    for(const sep of await page.locator('.splitter').all()){
     const box=await sep.boundingBox();const pair=(await sep.getAttribute('data-pair')).split(',').map(Number);const ids=['signalsPane','wavePane','codePane'];const before=await page.locator('#'+ids[pair[0]]).boundingBox();
     await page.mouse.move(box.x+3,box.y+70);await page.mouse.down();await page.mouse.move(box.x-70,box.y+70,{steps:5});await page.mouse.up();const after=await page.locator('#'+ids[pair[0]]).boundingBox();assert(after.width<before.width-20);
    }
   }
  }
  await page.locator('#resetLayout').click();await page.setViewportSize({width:1440,height:900});await page.locator('#group').selectOption('all');
  await page.locator('#names').selectOption('full');
  await page.evaluate(()=>{WAVE_TEST.state.weights=[.12,.58,.30];WAVE_TEST.layout()});
  const signalTrackBox=await page.locator('#signalTrack').boundingBox(),signalThumbBox=await page.locator('#signalThumb').boundingBox();
  assert(signalThumbBox.width<signalTrackBox.width,name+' signal names have horizontal range');
  assert(Math.abs(signalTrackBox.y-(await page.locator('#timeTrack').boundingBox()).y)<1,name+' top bars aligned');
  await page.mouse.move(signalThumbBox.x+signalThumbBox.width/2,signalThumbBox.y+signalThumbBox.height/2);await page.mouse.down();
  await page.mouse.move(signalThumbBox.x+signalThumbBox.width/2+70,signalThumbBox.y+signalThumbBox.height/2,{steps:6});await page.mouse.up();
  assert(await page.locator('#signalScroll').evaluate(e=>e.scrollLeft>0),name+' signal horizontal scrollbar drag');
  assert.equal(await page.evaluate(()=>WAVE_TEST.state.scroll),0,name+' signal horizontal drag keeps rows stationary');
  await page.locator('#signalTrack').focus();await page.keyboard.press('Home');
  assert.equal(await page.locator('#signalScroll').evaluate(e=>e.scrollLeft),0,name+' signal horizontal Home');
  for(const topFraction of [0,.48,1]){
   await page.evaluate(f=>{const e=document.getElementById('signalScroll');WAVE_TEST.scrollTo((e.scrollHeight-e.clientHeight)*f)},topFraction);
   await page.waitForTimeout(40);
   const alignment=await page.evaluate(()=>{
    const signal=document.getElementById('signalScroll'),wave=document.getElementById('waveScroll'),plot=document.getElementById('plot');
    const row=document.querySelector('.signal-row'),plotRect=plot.getBoundingClientRect(),rowRect=row.getBoundingClientRect();
    const index=Number(row.dataset.index),position=WAVE_TEST.state.visible.indexOf(index);
    return {sameTop:Math.abs(signal.getBoundingClientRect().top-plotRect.top)<1,sameHeight:Math.abs(signal.clientHeight-wave.clientHeight)<1,sameScroll:Math.abs(signal.scrollTop-wave.scrollTop)<1,rowOffset:Math.abs(rowRect.top-(plotRect.top+position*30-WAVE_TEST.state.scroll))};
   });
   assert(alignment.sameTop&&alignment.sameHeight&&alignment.sameScroll&&alignment.rowOffset<1,name+' signal/wave row alignment at '+topFraction);
  }
  await page.evaluate(()=>WAVE_TEST.scrollTo(0));await page.locator('#names').selectOption('short');await page.locator('#resetLayout').click();
  // Real wheel input in the plot must move its scrollbar and signal rows together.
  await page.locator('#plot').hover();await page.mouse.wheel(0,220);await page.waitForFunction(()=>document.getElementById('waveScroll').scrollTop>0);
  assert(await page.evaluate(()=>document.getElementById('waveScroll').scrollTop===document.getElementById('signalScroll').scrollTop));
  await page.locator('#showCode').check();
  const longest=await page.evaluate(()=>WAVE_TEST.DATA.sources.reduce((b,s,i,a)=>s.text.length>a[b].text.length?i:b,0));await page.locator('#fileSelect').selectOption(String(longest));
  const top=await page.locator('#waveScroll').evaluate(e=>e.scrollTop);await page.locator('#code').hover();await page.mouse.wheel(0,220);await page.waitForFunction(()=>document.getElementById('code').scrollTop>0);assert.equal(await page.locator('#waveScroll').evaluate(e=>e.scrollTop),top);
  for(const [id,rail] of [['waveScroll','waveRail'],['code','codeRail']]){
   await page.locator('#'+id).evaluate(e=>e.scrollTop=0);const box=await page.locator('#'+rail+' .vthumb').boundingBox();await page.mouse.move(box.x+box.width/2,box.y+box.height/2);await page.mouse.down();await page.mouse.move(box.x+box.width/2,box.y+box.height/2+130,{steps:8});await page.mouse.up();
   assert(await page.locator('#'+id).evaluate(e=>e.scrollTop>0),name+' scrollbar drag '+rail);
  }
  if(info.connections){await page.evaluate(()=>{const i=WAVE_TEST.DATA.signals.findIndex(s=>s.connections?.length);WAVE_TEST.select(i)});await page.locator('#connection').click();assert((await page.locator('#sourceInfo').innerText()).includes('←'));assert(await page.evaluate(()=>{const s=WAVE_TEST.DATA.signals[WAVE_TEST.state.selected];return !s.standardInternal&&s.connections.every(c=>WAVE_TEST.DATA.sources[c.source].text.split(/\r?\n/)[c.line-1].includes('.'+c.port))}));}
  await page.locator('#zin').click();assert(await page.evaluate(()=>WAVE_TEST.state.end-WAVE_TEST.state.start<WAVE_TEST.DATA.end));
  const beforeShift=await page.evaluate(()=>({start:WAVE_TEST.state.start,scroll:WAVE_TEST.state.scroll}));
  await page.locator('#plot').hover();await page.keyboard.down('Shift');await page.mouse.wheel(0,220);await page.keyboard.up('Shift');
  await page.waitForFunction(start=>WAVE_TEST.state.start>start,beforeShift.start);
  assert.equal(await page.evaluate(()=>WAVE_TEST.state.scroll),beforeShift.scroll,name+' Shift+wheel preserves vertical position');
  await page.evaluate(()=>WAVE_TEST.setRange(0,WAVE_TEST.DATA.end*.5));
  const trackBox=await page.locator('#timeTrack').boundingBox(),thumbBox=await page.locator('#timeThumb').boundingBox();
  assert(thumbBox.width<trackBox.width,name+' horizontal scrollbar represents zoom');
  await page.mouse.move(thumbBox.x+thumbBox.width/2,thumbBox.y+thumbBox.height/2);await page.mouse.down();
  await page.mouse.move(thumbBox.x+thumbBox.width/2+80,thumbBox.y+thumbBox.height/2,{steps:6});await page.mouse.up();
  assert(await page.evaluate(()=>WAVE_TEST.state.start>0),name+' horizontal scrollbar drag');
  await page.locator('#timeTrack').focus();await page.keyboard.press('Home');assert.equal(await page.evaluate(()=>WAVE_TEST.state.start),0);
  await page.locator('#full').click();
  const documentedRange={ring:[824,854],axi:[3218,3290],regs:[128,190]}[name];
  if(documentedRange){
   await page.locator('#start').fill(String(documentedRange[0]));await page.locator('#end').fill(String(documentedRange[1]));await page.locator('#range').click();
   const actual=await page.evaluate(()=>[WAVE_TEST.state.start*WAVE_TEST.DATA.tickNs,WAVE_TEST.state.end*WAVE_TEST.DATA.tickNs]);
   assert(Math.abs(actual[0]-documentedRange[0])<.001&&Math.abs(actual[1]-documentedRange[1])<.001,name+' documented time range');
   await page.locator('#full').click();
  }
  await page.locator('#helpButton').click();assert(await page.locator('#help').isVisible());await page.locator('#closeHelp').click();assert.deepEqual(errors,[]);
  report.push({case:name,status:'PASS',...info,checks:['default 14/86 signal/wave layout with code hidden and 14px signal names','7 pane combinations at 2 viewport sizes','drag each splitter','independent wheel and vertical scrollbar drags','signal horizontal scrollbar drag and keyboard','signal/wave row alignment at top/middle/bottom','Shift+wheel horizontal pan without vertical movement','time horizontal scrollbar drag and keyboard','short/full names','standard internals hidden with parent connections retained','all signals recoverable','connection source line','time zoom',...(documentedRange?['documented ns range jump']:[]),'compact header and help'],pageErrors:errors});console.log('PASS '+name);await page.close();
 }}finally{await browser.close()}
 fs.writeFileSync(path.join(out,'resizable_viewer_test_results.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
})().catch(e=>{console.error(e);process.exit(1)});
