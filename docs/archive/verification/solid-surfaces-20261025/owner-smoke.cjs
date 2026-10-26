const {chromium}=require('C:/Users/Xiao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const out=path.resolve('outputs/verification/solid-surfaces-20261025/owner-smoke');fs.mkdirSync(out,{recursive:true});
const receipt=()=>JSON.parse(fs.readFileSync('work/scene-v2-build-receipt.json','utf8').trim());
const assert=(value,message)=>{if(!value)throw Error(message)};
(async()=>{
 const result={started_at:new Date().toISOString(),scope:'independent headless browser movement and edge-stop smoke; no performance or full-house acceptance',runner_sha256:crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex'),build:receipt(),errors:[],packs:[]};
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const context=await browser.newContext({viewport:{width:1366,height:768}}),page=await context.newPage();
 page.on('pageerror',e=>result.errors.push(String(e)));page.on('response',r=>{if(r.url().endsWith('.pck'))result.packs.push(r.url())});
 const state=()=>page.evaluate(()=>window.__playroom);
 try{
  assert(result.build.pack==='scene-2072e5899240.pck','Unexpected candidate');
  await page.goto('http://127.0.0.1:8767/?test&owner-solid-surfaces=2072e5899240');
  await page.waitForFunction(()=>window.__playroom?.frame_samples>=60,null,{timeout:90000,polling:100});
  await page.mouse.click(683,384);await page.mouse.move(683,384);await page.waitForTimeout(250);
  result.before=await state();await page.keyboard.down('ArrowDown');await page.waitForTimeout(300);await page.keyboard.up('ArrowDown');await page.waitForTimeout(250);
  result.after_walk=await state();assert(result.after_walk.z>result.before.z+.2,'ArrowDown did not move player');
  const yaw=result.after_walk.camera_yaw;await page.mouse.move(1364,384);
  await page.waitForFunction(yaw=>Math.abs(window.__playroom.camera_yaw-yaw)>.12,yaw,{timeout:10000,polling:100});
  await page.mouse.move(683,384);await page.waitForTimeout(250);result.stop_start=await state();
  await page.waitForTimeout(500);result.stop_end=await state();
  assert(Math.abs(result.stop_end.camera_yaw-result.stop_start.camera_yaw)<.001,'Camera drifted after returning pointer to centre');
  assert(Math.abs(result.stop_end.edge_turn_rate)<.001,'Edge input did not stop');
  await page.screenshot({path:path.join(out,'current.png')});
  assert(result.packs.some(p=>p.endsWith('/'+result.build.pack)),'Candidate pack was not loaded');
  assert(result.errors.length===0,'Browser errors');result.pass=true;
 }catch(e){result.pass=false;result.failure=String(e)}
 finally{
  result.ending_build=receipt();result.version_consistent=JSON.stringify(result.build)===JSON.stringify(result.ending_build);if(!result.version_consistent)result.pass=false;
  result.finished_at=new Date().toISOString();await context.close();await browser.close();
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(result,null,2));console.log(JSON.stringify({pass:result.pass,version_consistent:result.version_consistent,errors:result.errors,failure:result.failure}));if(!result.pass)process.exitCode=1;
 }
})();
