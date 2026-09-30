const {chromium}=require(process.env.WAVE_PLAYWRIGHT || '../evidence/viewer_test_tools/playwright/driver/package');
const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url'),assert=require('assert');
const out=path.resolve(__dirname,'../evidence/local_wave_sessions');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});const report=[];
 try{for(const name of ['1g','tx','rx_fifo','ring','axi','axi_tail','regs']){
  const page=await browser.newPage({viewport:{width:1440,height:900}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.route(/^https?:/,r=>r.abort());await page.goto(pathToFileURL(path.join(out,name,name+'_viewer.html')).href);await page.waitForFunction(()=>!!window.WAVE_TEST);
  const info=await page.evaluate(()=>{const {DATA,state}=WAVE_TEST;return {all:DATA.signals.length,shown:state.visible.length,hiddenOk:state.visible.every(i=>!DATA.signals[i].standardInternal&&!DATA.signals[i].testbenchAlias),connections:DATA.signals.filter(s=>s.connections?.length).length}});
  assert(info.hiddenOk);assert(!/PASS|离线|本机重跑/.test(await page.locator('header').innerText()));
  assert(await page.locator('.signal-name').evaluateAll(es=>es.every(e=>!e.textContent.includes('/'))));
  await page.locator('#names').selectOption('full');assert(await page.locator('.signal-name').first().innerText().then(t=>t.startsWith('/')));await page.locator('#names').selectOption('short');
  await page.locator('#group').selectOption('all');assert.equal(await page.evaluate(()=>WAVE_TEST.state.visible.length),info.all);await page.locator('#group').selectOption('business');
  for(const viewport of [{width:1440,height:900},{width:1024,height:720}]){
   await page.setViewportSize(viewport);
   for(const mask of [7,3,5,6,1,2,4]){
    await page.locator('#resetLayout').click();const toggles=['showSignals','showWave','showCode'];for(let i=0;i<3;i++)if(!(mask&(1<<i)))await page.locator('#'+toggles[i]).uncheck();
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
  // Real wheel input in the plot must move its scrollbar and signal rows together.
  await page.locator('#plot').hover();await page.mouse.wheel(0,220);await page.waitForFunction(()=>document.getElementById('waveScroll').scrollTop>0);
  assert(await page.evaluate(()=>document.getElementById('waveScroll').scrollTop===document.getElementById('signalScroll').scrollTop));
  const longest=await page.evaluate(()=>WAVE_TEST.DATA.sources.reduce((b,s,i,a)=>s.text.length>a[b].text.length?i:b,0));await page.locator('#fileSelect').selectOption(String(longest));
  const top=await page.locator('#waveScroll').evaluate(e=>e.scrollTop);await page.locator('#code').hover();await page.mouse.wheel(0,220);await page.waitForFunction(()=>document.getElementById('code').scrollTop>0);assert.equal(await page.locator('#waveScroll').evaluate(e=>e.scrollTop),top);
  for(const [id,rail] of [['waveScroll','waveRail'],['code','codeRail']]){
   await page.locator('#'+id).evaluate(e=>e.scrollTop=0);const box=await page.locator('#'+rail+' .vthumb').boundingBox();await page.mouse.move(box.x+box.width/2,box.y+box.height/2);await page.mouse.down();await page.mouse.move(box.x+box.width/2,box.y+box.height/2+130,{steps:8});await page.mouse.up();
   assert(await page.locator('#'+id).evaluate(e=>e.scrollTop>0),name+' scrollbar drag '+rail);
  }
  if(info.connections){await page.evaluate(()=>{const i=WAVE_TEST.DATA.signals.findIndex(s=>s.connections?.length);WAVE_TEST.select(i)});await page.locator('#connection').click();assert((await page.locator('#sourceInfo').innerText()).includes('←'));assert(await page.evaluate(()=>{const s=WAVE_TEST.DATA.signals[WAVE_TEST.state.selected];return !s.standardInternal&&s.connections.every(c=>WAVE_TEST.DATA.sources[c.source].text.split(/\r?\n/)[c.line-1].includes('.'+c.port))}));}
  await page.locator('#zin').click();assert(await page.evaluate(()=>WAVE_TEST.state.end-WAVE_TEST.state.start<WAVE_TEST.DATA.end));await page.locator('#full').click();
  const documentedRange={ring:[824,854],axi:[3218,3290],regs:[128,190]}[name];
  if(documentedRange){
   await page.locator('#start').fill(String(documentedRange[0]));await page.locator('#end').fill(String(documentedRange[1]));await page.locator('#range').click();
   const actual=await page.evaluate(()=>[WAVE_TEST.state.start*WAVE_TEST.DATA.tickNs,WAVE_TEST.state.end*WAVE_TEST.DATA.tickNs]);
   assert(Math.abs(actual[0]-documentedRange[0])<.001&&Math.abs(actual[1]-documentedRange[1])<.001,name+' documented time range');
   await page.locator('#full').click();
  }
  await page.locator('#helpButton').click();assert(await page.locator('#help').isVisible());await page.locator('#closeHelp').click();assert.deepEqual(errors,[]);
  report.push({case:name,status:'PASS',...info,checks:['7 pane combinations at 2 viewport sizes','drag each splitter','independent wheel and scrollbar drags','short/full names','standard internals hidden with parent connections retained','all signals recoverable','connection source line','time zoom',...(documentedRange?['documented ns range jump']:[]),'compact header and help'],pageErrors:errors});console.log('PASS '+name);await page.close();
 }}finally{await browser.close()}
 fs.writeFileSync(path.join(out,'resizable_viewer_test_results.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
})().catch(e=>{console.error(e);process.exit(1)});
