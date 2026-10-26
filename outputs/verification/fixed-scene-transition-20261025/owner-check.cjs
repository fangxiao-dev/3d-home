const {chromium}=require('C:/Users/Xiao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const out=path.resolve('outputs/verification/fixed-scene-transition-20261025/owner-check');fs.mkdirSync(out,{recursive:true});
const receipt=()=>JSON.parse(fs.readFileSync('work/scene-v2-build-receipt.json','utf8').trim());
const assert=(v,m)=>{if(!v)throw Error(m)},delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 const r={started_at:new Date().toISOString(),scope:'Root independent headless Chrome actual interaction smoke; visible Windows Computer Use blocked on URL confidence',runner_sha256:crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex'),build:receipt(),packs:[],errors:[]};fs.copyFileSync(__filename,path.join(out,'runner.cjs'));
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const context=await browser.newContext({viewport:{width:1366,height:768}}),page=await context.newPage(),cdp=await context.newCDPSession(page);
 page.on('pageerror',e=>r.errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')r.errors.push(m.text())});page.on('response',x=>{if(x.url().endsWith('.pck'))r.packs.push(x.url())});
 const read=async()=>JSON.parse((await cdp.send('Runtime.evaluate',{expression:'JSON.stringify({state:window.__playroom||null,dom:{locked:!!document.pointerLockElement,hidden:document.hidden,focused:document.hasFocus(),activation:navigator.userActivation.isActive},frames:window.__navigation_frames||[],canvas:(()=>{const c=document.querySelector("canvas");if(!c)return null;const b=c.getBoundingClientRect();return {x:b.x,y:b.y,width:b.width,height:b.height}})()})',returnByValue:true,userGesture:false})).result.value);
 async function until(predicate,timeout=30000){const deadline=Date.now()+timeout;while(Date.now()<deadline){const s=await read();if(predicate(s))return s;await delay(75)}throw Error('State wait timed out')}
 async function clickStart(){const a=await read(),b=a.state.resume_button,v=a.state.viewport,c=a.canvas;const x=c.x+(b[0]+b[2]/2)*c.width/v[0],y=c.y+(b[1]+b[3]/2)*c.height/v[1];await page.mouse.move(x,y);await page.mouse.click(x,y);await until(s=>s.dom.locked&&s.state.navigation_active);return {x,y}}
 try{
  assert(r.build.pack==='scene-4315d056df83.pck','Unexpected candidate');
  await page.goto('http://127.0.0.1:8767/?test&owner-fixed-transition=4315d056df83');r.url=page.url();
  r.initial=await until(s=>s.state?.frame_samples>=60,90000);assert(!r.initial.dom.locked&&!r.initial.state.navigation_active,'Initial input must be inactive');
  const point=await clickStart();r.entered=await read();const startT=r.entered.frames.at(-1).t;
  await page.keyboard.press('f');r.seated=await until(s=>s.state.mode==='SEATED');assert(!r.seated.dom.locked,'Seated cursor not released');
  r.entry_trace=r.seated.frames.filter(f=>f.t>=startT);const cut=r.entry_trace.findIndex(f=>f.fixed_camera),sit=r.entry_trace.findIndex(f=>f.animation==='SitDown');
  assert(cut>=0&&r.entry_trace[cut].transition_phase==='black'&&r.entry_trace[cut].fade_alpha===1,'Camera cut not fully covered');assert(sit>cut&&r.entry_trace[sit].fade_alpha===0&&r.entry_trace[sit].transition_phase==='none','Sit began before reveal');
  await page.screenshot({path:path.join(out,'seated.png')});await delay(6500);r.before_escape=await read();assert(!r.before_escape.dom.activation,'Activation did not expire');
  await page.keyboard.down('Escape');r.returned=await until(s=>s.state.mode==='EXPLORE'&&s.state.navigation_active&&!s.state.camera_blending&&s.dom.locked);
  await page.keyboard.down('Escape');await delay(250);r.held_repeat=await read();assert(r.held_repeat.dom.locked&&r.held_repeat.state.navigation_active,'Same Esc paused after return');
  await page.keyboard.up('Escape');await page.mouse.move(point.x+100,point.y);await delay(150);const a=await read();await page.mouse.move(point.x+200,point.y);await delay(200);r.turned=await read();r.angle=r.turned.state.camera_yaw-a.state.camera_yaw;assert(Math.abs(r.angle+Math.PI/15)<.006,'Returned mouse mapping failed');
  const pos=r.turned.state;await page.keyboard.down('ArrowDown');await delay(200);await page.keyboard.up('ArrowDown');await delay(150);r.moved=await read();assert(Math.hypot(r.moved.state.x-pos.x,r.moved.state.z-pos.z)>.12,'Returned walking failed');
  await page.screenshot({path:path.join(out,'returned-active.png')});await page.keyboard.press('Escape');r.paused=await until(s=>!s.dom.locked&&!s.state.navigation_active);await page.screenshot({path:path.join(out,'outer-paused.png')});
  await clickStart();r.resumed=await read();assert(r.resumed.dom.locked&&r.resumed.state.navigation_active,'Continue failed');await page.keyboard.press('Escape');
  assert(r.packs.some(x=>x.endsWith('/'+r.build.pack)),'Actual PCK request missing');assert(r.errors.length===0,'Unexpected browser error');r.pass=true;
 }catch(e){r.pass=false;r.failure=String(e);r.failure_state=await read().catch(()=>null);await page.screenshot({path:path.join(out,'failure.png')}).catch(()=>{})}
 finally{r.ending_build=receipt();r.version_consistent=JSON.stringify(r.build)===JSON.stringify(r.ending_build);r.pass=r.pass&&r.version_consistent;r.finished_at=new Date().toISOString();await context.close();await browser.close();fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(r,null,2));console.log(JSON.stringify({pass:r.pass,failure:r.failure,angle:r.angle,errors:r.errors,version_consistent:r.version_consistent}));if(!r.pass)process.exitCode=1}
})();
