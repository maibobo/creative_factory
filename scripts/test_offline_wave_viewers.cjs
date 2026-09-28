// Local headless functional tests only. No screenshots, network, or user-browser control.
const {chromium}=require('C:/Users/MaiBo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url'),assert=require('assert');
const root=path.resolve(__dirname,'..'),out=path.join(root,'evidence','local_wave_sessions');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const report=[];
 try{
  for(const name of ['1g','tx','rx_fifo','ring','axi','axi_tail','regs']){
   const page=await browser.newPage({viewport:{width:1600,height:960}}),errors=[];
   page.on('pageerror',e=>errors.push(e.message));
   await page.route('http://**',route=>route.abort());await page.route('https://**',route=>route.abort());
   await page.goto(pathToFileURL(path.join(out,name,name+'_viewer.html')).href,{waitUntil:'load'});
   await page.waitForFunction(()=>!!window.WAVE_TEST);
   const initial=await page.evaluate(()=>{
    const {DATA,state}=WAVE_TEST;
    const wrong=DATA.signals.filter(s=>s.source!=null&&s.line&& !DATA.sources[s.source].text.split(/\r?\n/)[s.line-1]?.includes(s.lookup));
    return {signals:DATA.signals.length,visible:state.visible.length,sourceLines:document.querySelectorAll('#code .line').length,badSourceLines:wrong.map(s=>s.path),end:state.end};
   });
   assert.equal(initial.signals,initial.visible);assert(initial.sourceLines>10);assert.deepEqual(initial.badSourceLines,[]);
   for(const viewport of [{width:1600,height:960},{width:1280,height:720}]){
    await page.setViewportSize(viewport);
    const longest=await page.evaluate(()=>WAVE_TEST.DATA.sources.reduce((best,s,i,a)=>s.text.length>a[best].text.length?i:best,0));
    await page.locator('#fileSelect').selectOption(String(longest));
    await page.evaluate(()=>{document.getElementById('scroll').scrollTop=0;document.getElementById('code').scrollTop=0});
    const boxes=await page.evaluate(()=>{const w=document.getElementById('scroll'),c=document.getElementById('code');return {waveBottom:w.getBoundingClientRect().bottom,codeBottom:c.getBoundingClientRect().bottom,waveScrollable:w.scrollHeight>w.clientHeight,codeScrollable:c.scrollHeight>c.clientHeight,rail:w.offsetWidth-w.clientWidth}});
    assert(boxes.waveBottom<=viewport.height-30&&boxes.codeBottom<=viewport.height-30);assert(boxes.waveScrollable&&boxes.codeScrollable);assert(boxes.rail>=16);
    await page.locator('#plot').hover();await page.mouse.wheel(0,220);
    await page.waitForFunction(()=>document.getElementById('scroll').scrollTop>0);
    assert.equal(await page.locator('#code').evaluate(e=>e.scrollTop),0);
    const waveTop=await page.locator('#scroll').evaluate(e=>e.scrollTop);
    await page.locator('#code').hover();await page.mouse.wheel(0,220);
    await page.waitForFunction(()=>document.getElementById('code').scrollTop>0);
    assert.equal(await page.locator('#scroll').evaluate(e=>e.scrollTop),waveTop);
    // Drag each actual right-hand scrollbar, not a synthetic scrollTop setter.
    for(const id of ['scroll','code']){
     await page.locator('#'+id).evaluate(e=>e.scrollTop=0);
     const box=await page.locator('#'+id).boundingBox();
     await page.mouse.move(box.x+box.width-9,box.y+12);await page.mouse.down();await page.mouse.move(box.x+box.width-9,box.y+135,{steps:8});await page.mouse.up();
     console.log('SCROLL_DRAG',name,viewport.width,id,await page.locator('#'+id).evaluate(e=>({top:e.scrollTop,height:e.clientHeight,total:e.scrollHeight})));
     await page.waitForFunction(id=>document.getElementById(id).scrollTop>0,id,{timeout:5000});
    }
   }
   await page.setViewportSize({width:1600,height:960});
   await page.evaluate(()=>{document.getElementById('scroll').scrollTop=0});
   await page.locator('#zin').click();assert(await page.evaluate(()=>WAVE_TEST.state.end-WAVE_TEST.state.start<WAVE_TEST.DATA.end));
   await page.locator('#full').click();assert.equal(await page.evaluate(()=>WAVE_TEST.state.end),initial.end);
   await page.locator('#filter').fill('/U_DUT/');assert(await page.evaluate(()=>WAVE_TEST.state.visible.length>0&&WAVE_TEST.state.visible.every(i=>WAVE_TEST.DATA.signals[i].path.includes('/U_DUT/'))));
   await page.locator('#rows .signal-row').first().click();assert(await page.evaluate(()=>WAVE_TEST.DATA.signals[WAVE_TEST.state.selected].path.includes('/U_DUT/')));
   await page.locator('#plot').click({position:{x:150,y:15}});assert(await page.evaluate(()=>WAVE_TEST.state.cursor>0));
   const sourcePosition=await page.locator('#code').evaluate(e=>{e.scrollTop=120;return e.scrollTop});
   await page.locator('#plot').click({position:{x:170,y:15}});assert.equal(await page.locator('#code').evaluate(e=>e.scrollTop),sourcePosition);
   await page.evaluate(()=>{const i=WAVE_TEST.DATA.signals.findIndex(s=>s.width===1&&s.code!=null&&WAVE_TEST.DATA.events[s.code].length>10);WAVE_TEST.select(i);WAVE_TEST.state.cursor=0});
   await page.locator('#nextChange').click();assert(await page.evaluate(()=>WAVE_TEST.state.cursor>0&&WAVE_TEST.state.end-WAVE_TEST.state.start<=200/WAVE_TEST.DATA.tickNs));
   await page.locator('#filter').fill('');await page.locator('#core').check();assert(await page.evaluate(()=>WAVE_TEST.state.visible.every(i=>WAVE_TEST.DATA.signals[i].core)));
   await page.locator('#core').uncheck();assert.equal(await page.evaluate(()=>WAVE_TEST.state.visible.length),initial.signals);
   await page.locator('#group').selectOption('bus');assert(await page.evaluate(()=>WAVE_TEST.state.visible.length>0&&WAVE_TEST.state.visible.every(i=>WAVE_TEST.DATA.signals[i].path.split('/')[2]==='bus')));
   await page.locator('#group').selectOption('all');assert.equal(await page.evaluate(()=>WAVE_TEST.state.visible.length),initial.signals);
   await page.locator('#fileSelect').selectOption('0');assert(await page.evaluate(()=>WAVE_TEST.state.file===0));
   await page.locator('#helpButton').click();assert(await page.locator('#help').isVisible());
   assert.deepEqual(errors,[]);report.push({case:name,status:'PASS',signals:initial.signals,sourceMappings:'all mapped line references valid',checks:['load','full signal list','source panel','independent mouse-wheel scroll','both scrollbar thumb drags','bounded panes at 1600x960 and 1280x720','preserve code position on cursor movement','next change','zoom','filter','signal selection','cursor','core filter','file selection','help'],pageErrors:errors});
   await page.close();
   console.log('VIEWER_PASS '+name);
  }
 }finally{await browser.close()}
 fs.writeFileSync(path.join(out,'viewer_test_results.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
})().catch(e=>{console.error(e);process.exit(1)});
