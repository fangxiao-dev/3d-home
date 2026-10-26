const {chromium}=require('C:/Users/Xiao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const out=path.resolve('outputs/verification/mouse-look-20261025/owner-check-v2');fs.mkdirSync(out,{recursive:true});
const receipt=()=>JSON.parse(fs.readFileSync('work/scene-v2-build-receipt.json','utf8').trim());
const assert=(v,m)=>{if(!v)throw Error(m)},delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 const r={started_at:new Date().toISOString(),scope:'independent headless Chrome interaction/relative-mouse smoke; no native-window or long-performance acceptance',runner_sha256:crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex'),build:receipt(),packs:[],errors:[]};
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const context=await browser.newContext({viewport:{width:1366,height:768}}),page=await context.newPage(),cdp=await context.newCDPSession(page);
 page.on('pageerror',e=>r.errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')r.errors.push(m.text())});page.on('response',x=>{if(x.url().endsWith('.pck'))r.packs.push(x.url())});
 const read=async()=>JSON.parse((await cdp.send('Runtime.evaluate',{expression:'JSON.stringify({state:window.__playroom||null,dom:{locked:!!document.pointerLockElement,hidden:document.hidden,focused:document.hasFocus(),activation:navigator.userActivation.isActive},mouse_events:window.__owner_mouse_events||[],canvas:(()=>{const c=document.querySelector("canvas");if(!c)return null;const b=c.getBoundingClientRect();return {x:b.x,y:b.y,width:b.width,height:b.height,buffer:[c.width,c.height]}})()})',returnByValue:true,userGesture:false})).result.value);
 async function until(predicate,timeout=30000){const deadline=Date.now()+timeout;while(Date.now()<deadline){const s=await read();if(predicate(s))return s;await delay(100)}throw Error('State wait timed out')}
 async function clickStart(){const a=await read(),b=a.state.resume_button,v=a.state.viewport,c=a.canvas;const x=c.x+(b[0]+b[2]/2)*c.width/v[0],y=c.y+(b[1]+b[3]/2)*c.height/v[1];await page.mouse.move(x,y);await page.mouse.click(x,y);await until(s=>s.dom.locked&&s.state.navigation_active);return {x,y}}
 try{
  assert(r.build.pack==='scene-2a4b1894705b.pck','Unexpected candidate');
  await page.goto('http://127.0.0.1:8767/?test&owner-mouse-look=2a4b1894705b');
  r.initial=await until(s=>s.state?.frame_samples>=60,90000);await cdp.send('Runtime.evaluate',{expression:'window.__owner_mouse_events=[];document.addEventListener("mousemove",e=>window.__owner_mouse_events.push({type:"move",dx:e.movementX,dy:e.movementY,trusted:e.isTrusted}));document.querySelector("canvas").addEventListener("mouseenter",()=>window.__owner_mouse_events.push({type:"enter"}));',userGesture:false});assert(!r.initial.dom.locked&&!r.initial.state.navigation_active,'Initial input must be inactive');
  const point=await clickStart();r.entered=await read();assert(r.entered.state.target==='entry_stool','Spawn seat target changed');
  await page.keyboard.press('f');r.seated=await until(s=>s.state.mode==='SEATED');assert(!r.seated.dom.locked&&!r.seated.state.pointer_locked,'Seated cursor must be released');
  await page.screenshot({path:path.join(out,'seated.png')});await delay(6500);
  r.before_escape=await read();assert(!r.before_escape.dom.activation,'Transient activation still active');
  await page.keyboard.press('Escape');r.returned=await until(s=>s.state.mode==='EXPLORE'&&s.state.navigation_active&&!s.state.camera_blending&&s.dom.locked);await delay(200);
  const before=await read();await page.mouse.move(point.x+100,point.y);await delay(350);r.turned=await read();r.relative_angle=r.turned.state.camera_yaw-before.state.camera_yaw;
  assert(Math.abs(r.relative_angle+Math.PI/15)<.005,'100px did not produce rightward 12 degrees');
  await delay(500);r.stopped=await read();assert(Math.abs(r.stopped.state.camera_yaw-r.turned.state.camera_yaw)<.001,'Angular drift after stopping mouse');
  await page.mouse.move(point.x+100,point.y+80);await delay(250);r.vertical=await read();assert(Math.abs(r.vertical.state.camera_yaw-r.stopped.state.camera_yaw)<.001&&Math.abs(r.vertical.state.camera_pitch_degrees-40)<.05,'Vertical input changed orbit or pitch');
  await page.keyboard.press('Escape');r.paused=await until(s=>!s.dom.locked&&!s.state.navigation_active);const pos=r.paused.state;
  await page.keyboard.down('ArrowDown');await delay(250);await page.keyboard.up('ArrowDown');await delay(200);r.inactive=await read();assert(Math.hypot(r.inactive.state.x-pos.x,r.inactive.state.z-pos.z)<.001,'Paused movement leaked');
  await page.screenshot({path:path.join(out,'paused.png')});await clickStart();r.resumed=await read();assert(Math.abs(r.resumed.state.camera_yaw-r.paused.state.camera_yaw)<.001,'Resume changed camera angle');
  await page.screenshot({path:path.join(out,'tour.png')});await page.keyboard.press('Escape');
  assert(r.packs.some(x=>x.endsWith('/'+r.build.pack)),'Actual pack request missing');assert(r.errors.length===0,'Unexpected browser error');r.pass=true;
 }catch(e){r.pass=false;r.failure=String(e);r.failure_state=await read().catch(()=>null);await page.screenshot({path:path.join(out,'failure.png')}).catch(()=>{})}
 finally{r.ending_build=receipt();r.version_consistent=JSON.stringify(r.build)===JSON.stringify(r.ending_build);r.pass=r.pass&&r.version_consistent;r.finished_at=new Date().toISOString();await context.close();await browser.close();fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(r,null,2));console.log(JSON.stringify({pass:r.pass,failure:r.failure,relative_angle:r.relative_angle,errors:r.errors,version_consistent:r.version_consistent}));if(!r.pass)process.exitCode=1}
})();
