const {chromium}=require('C:/Users/Xiao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
const width=Number(process.argv[2]||1920),height=Number(process.argv[3]||1080);
const video=process.argv.includes('video');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const page=await browser.newPage({viewport:{width,height},...(video?{recordVideo:{dir:'work/scene-v2-video',size:{width:1280,height:720}}}:{})}),errors=[],record={started_at:new Date().toISOString(),video_capture:video,build:JSON.parse(fs.readFileSync('work/scene-v2-build-receipt.json','utf8').replace(/^\uFEFF/,'')),viewport:{width,height},seats:[],rooms:[],frames:[]};
 const packs=[];page.on('response',r=>{if(r.url().endsWith('.pck'))packs.push(r.url().split('/').pop())});
 page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 const state=()=>page.evaluate(()=>window.__playroom),assert=(v,m)=>{if(!v)throw Error(m)};
 const settle=async()=>page.waitForTimeout(350);
 async function axis(axis,target){for(let i=0;i<35;i++){let s=await state(),d=target-s[axis];if(Math.abs(d)<.07)return;
   const sign=Math.sign(d),c=Math.cos(s.camera_yaw),n=Math.sin(s.camera_yaw),v={ArrowUp:[-n,-c],ArrowDown:[n,c],ArrowRight:[c,-n],ArrowLeft:[-c,n]};
   const key=Object.keys(v).find(k=>v[k][axis==='x'?0:1]*sign>.9);assert(key,'Camera must settle on cardinal angle');
   await page.keyboard.down(key);await page.waitForTimeout(Math.max(45,Math.min(1800,(Math.abs(d)-.025)/1.65*1000)));await page.keyboard.up(key);await settle();
 }throw Error(`Blocked ${axis}=${target} at ${JSON.stringify(await state())}`)}
 async function walk(x,z){await axis('x',x);await axis('z',z)}
 async function shot(name){await page.screenshot({path:`work/v2-chrome-${width}-${name}.png`})}
 async function cycle(id){const info=(await state()).seats.find(s=>s.id===id);await walk(info.approach[0],info.approach[2]);
   for(let i=0;i<3;i++){
    if(i>0){let dx=0,dz=0;if(i===1)dz=id==='window_seat'?.25:-.25;else{dx=['dining_chair','study_chair'].includes(id)?-.3:.3;if(id==='sofa_middle')dz=-.25}await axis('z',info.approach[2]+dz);await axis('x',info.approach[0]+dx)}
    await settle();const approachFrom=await state();assert(approachFrom.target===id,`Wrong target for ${id}`);await page.keyboard.press('f');
    await page.waitForFunction(()=>window.__playroom.mode==='SEATED',null,{timeout:30000});await page.waitForTimeout(650);const seated=await state();assert(seated.seat_id===id&&seated.animation==='SitIdle',`Wrong pose ${id}`);
    if(i===0)await shot(id);await page.keyboard.down('w');await page.keyboard.press('q');await page.keyboard.press('f');await page.mouse.wheel(0,200);await settle();
    const locked=await state();assert(Math.hypot(locked.x-seated.x,locked.z-seated.z)<.01,'Seated movement leaked');assert(locked.target_camera_yaw===seated.target_camera_yaw,'Seated camera input leaked');
    await page.keyboard.press('Escape');await page.waitForFunction(()=>window.__playroom.mode==='EXPLORE',null,{timeout:30000});
    const exited=await state();assert(exited.transition_collisions.length===0,`Transition collision ${id}: ${JSON.stringify(exited.transition_collisions)}`);assert(Math.hypot(exited.x-info.exit[0],exited.z-info.exit[2])<.1,'Exit point mismatch');assert(exited.input_locked,'Held movement not locked on exit');await page.keyboard.up('w');await settle();record.seats.push({id,iteration:i+1,approach_from:approachFrom,seated,exited});console.log("SEAT_OK",id,i+1);
   }}
 try{await page.goto('http://127.0.0.1:8767/?test&v=scene-v2-validation');await page.waitForFunction(()=>window.__playroom,null,{timeout:90000});await page.locator('canvas').click({position:{x:30,y:250}});await page.waitForTimeout(1200);
   record.gpu=await page.evaluate(()=>{let gl=document.querySelector('canvas').getContext('webgl2'),e=gl.getExtension('WEBGL_debug_renderer_info');return e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):'unknown'});record.cold_start=await state();await page.waitForTimeout(30000);await page.waitForFunction(()=>window.__playroom.frame_samples>=600,null,{timeout:120000});record.warm_start=await state();console.log('WARM_READY',width,record.warm_start.frame_mean_ms);record.rooms.push(await state());await shot('entry');assert((await state()).lightmap.probe_points>0,'Missing runtime light probes');const wasdStart=await state();await page.keyboard.down('a');await page.waitForTimeout(300);await page.keyboard.up('a');await settle();assert((await state()).x<wasdStart.x-.15,'WASD movement failed');await axis('x',wasdStart.x);
   await cycle('entry_stool');await walk(0,-3.6);await cycle('sofa_middle');await cycle('window_seat');await walk(0,-6.8);record.rooms.push(await state());await shot('balcony');await page.keyboard.down('ArrowUp');await page.waitForTimeout(1800);await page.keyboard.up('ArrowUp');await settle();assert((await state()).z>-8,'Escaped balcony');
   await walk(0,1);record.rooms.push(await state());await walk(-.7,3.1);await cycle('dining_chair');await axis('z',3.05);await walk(.6,5.7);record.rooms.push(await state());await shot('dining');
   await page.keyboard.down('ArrowDown');await page.waitForTimeout(1400);await page.keyboard.up('ArrowDown');await settle();assert((await state()).z<6.6,'Entered kitchen');await shot('kitchen');
   await walk(.6,1);await walk(3.25,2.9);record.rooms.push(await state());await shot('wash');await page.keyboard.down('ArrowDown');await page.waitForTimeout(1500);await page.keyboard.up('ArrowDown');await settle();assert((await state()).z<4.4,'Entered closed bathroom');await walk(3.25,1);await walk(6.85,1);await shot('hallway');await page.keyboard.down('ArrowRight');await page.waitForTimeout(3600);await page.keyboard.up('ArrowRight');await settle();assert((await state()).x<11.9,'Escaped closed hallway');await walk(6.85,3.7);await cycle('study_chair');record.rooms.push(await state());await shot('study');
   const beforeRotation=(await state()).target_camera_yaw;
   for(let i=0;i<4;i++){await page.keyboard.press('q');await page.waitForTimeout(1200);assert(Math.abs((await state()).target_camera_yaw-beforeRotation-(i+1)*Math.PI/2)<.01,'Q rotation');await shot(`study-angle-${i}`)}
   await page.keyboard.down('e');await page.waitForTimeout(1200);await page.keyboard.up('e');assert(Math.abs((await state()).target_camera_yaw-beforeRotation-3*Math.PI/2)<.01,'E hold must rotate once');await page.keyboard.press('q');await page.waitForTimeout(1200);
   record.rapid_camera=[];for(let repeat=0;repeat<3;repeat++){for(const key of ['q','e']){await page.keyboard.press(key);await page.keyboard.press(key);await page.waitForTimeout(3000);const s=await state();record.rapid_camera.push(s);assert(s.camera_facing_dot>.999,'Rapid camera lost focus');assert(s.player_screen[0]>0&&s.player_screen[0]<s.viewport[0]&&s.player_screen[1]>0&&s.player_screen[1]<s.viewport[1],'Rapid camera moved character offscreen')}}
   for(let j=0;j<6;j++){await page.mouse.wheel(0,200);await page.waitForTimeout(80)}await page.waitForTimeout(900);assert((await state()).target_zoom===1.15,'Zoom maximum');for(let j=0;j<12;j++){await page.mouse.wheel(0,-200);await page.waitForTimeout(80)}await page.waitForTimeout(900);assert((await state()).target_zoom===.85,'Zoom minimum');
   for(let i=0;i<30;i++){await page.waitForTimeout(1000);record.frames.push(await state())}
   if(process.argv[4]==='soak'){const start=Date.now();let loops=0;while(Date.now()-start<600000){
    await axis('x',6.85);await axis('z',1);await walk(3.25,2.9);record.frames.push(await state());await axis('z',1);await walk(0,-6.8);record.frames.push(await state());await walk(0,1);await walk(.6,5.7);record.frames.push(await state());await axis('z',1);await walk(6.85,3.7);await walk(8.16,4);record.frames.push(await state());loops++;console.log("SOAK_LOOP",loops,Date.now()-start);
   }record.soak={elapsed_ms:Date.now()-start,loops};await shot('soak-finish')}
   assert(new Set(record.rooms.map(s=>s.active_room)).size===6,'Six accessible rooms not recorded');record.checks={seat_cycles:record.seats.length,accessible_rooms:[...new Set(record.rooms.map(s=>s.active_room))],boundaries:['balcony','kitchen','bathroom','hallway'],camera_q_four_directions:true,camera_e_hold_once:true,zoom_limits:[.85,1.15],wasd:true,arrow_movement:true,seated_input_isolation:true,transition_collisions_clear:true};
   record.performance_target_met=record.frames.length>0&&record.frames.every(s=>s.frame_mean_ms<=1000/60);record.performance_criterion='Every post-route/soak sampled 600-frame rolling mean <= 16.667 ms; functional pass is separate';
   record.loaded_packs=packs;assert(packs.includes(record.build.pack),'Loaded pack differs from receipt');record.ending_build=JSON.parse(fs.readFileSync('work/scene-v2-build-receipt.json','utf8').replace(/^\uFEFF/,''));assert(record.ending_build.pack===record.build.pack,'Build changed during campaign');record.pass=errors.length===0;
 }catch(e){record.pass=false;record.failure=String(e);await shot('failure').catch(()=>{});record.state=await state().catch(()=>null)}
 finally{record.finished_at=new Date().toISOString();record.errors=errors;await page.context().close();if(video)record.video=await page.video().path();fs.writeFileSync(`work/v2-chrome-${width}-verification.json`,JSON.stringify(record,null,2));console.log(JSON.stringify({pass:record.pass,failure:record.failure,errors,seats:record.seats.length}));await browser.close()}
})();










