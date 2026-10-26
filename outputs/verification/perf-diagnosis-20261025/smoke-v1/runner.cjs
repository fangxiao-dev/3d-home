const {chromium}=require('C:/Users/Xiao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve('outputs/verification/perf-diagnosis-20261025'),work=path.resolve('work/perf-diagnosis-20261025');
const planPath=process.argv[2],plan=JSON.parse(fs.readFileSync(planPath,'utf8')),out=path.join(root,plan.name);fs.mkdirSync(out,{recursive:true});
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex'),read=p=>JSON.parse(fs.readFileSync(p,'utf8').trim()),assert=(v,m)=>{if(!v)throw Error(m)};
(async()=>{const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:!plan.headful});const context=await browser.newContext({viewport:{width:1920,height:1080},deviceScaleFactor:1}),page=await context.newPage();
 const report={started_at:new Date().toISOString(),runner_sha256:sha(__filename),plan_sha256:sha(planPath),probe_sha256:sha(path.join(root,'gpu-probe.js')),receipt:read(path.join(work,'diag-receipt.json')),headful:!!plan.headful,errors:[],loaded_packs:[],blocks:[]};
 page.on('pageerror',e=>report.errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')report.errors.push(m.text())});page.on('response',r=>{if(r.url().endsWith('.pck'))report.loaded_packs.push(r.url())});
 await page.addInitScript({path:path.join(root,'gpu-probe.js')});
 await page.addInitScript(()=>{window.__diagRaf=[];window.__diagCaptureRaf=false;function raf(t){if(window.__diagCaptureRaf)window.__diagRaf.push([t,performance.now()]);requestAnimationFrame(raf)}requestAnimationFrame(raf)});
 let serial=0;
 async function measure(frames,probe){const id=++serial;await page.evaluate(({id,frames,probe})=>{window.__diagRaf=[];window.__diagCaptureRaf=true;if(probe)window.gpuProbe.start();else window.gpuProbe.stop();window.perfMeasureStartAt=performance.now();window.perfCommand({action:'measure',id,frames})},{id,frames,probe});await page.waitForFunction(id=>window.perfResult?.id===id,id,{timeout:120000,polling:100});await page.evaluate(()=>{window.__diagCaptureRaf=false;window.gpuProbe.stop()});await page.waitForFunction(()=>{window.gpuProbe.poll();return window.gpuProbe.read().pending===0},null,{timeout:15000,polling:100});return page.evaluate(()=>({game:window.perfResult,gpu:window.gpuProbe.read(),raf:window.__diagRaf,start:window.perfMeasureStartAt,end:window.perfResultReceivedAt}))}
 try{
  await page.goto('http://127.0.0.1:8772/');await page.waitForFunction(()=>window.perfReady,null,{timeout:180000,polling:100});await page.mouse.click(960,540);await page.mouse.move(960,540);
  report.environment=await page.evaluate(()=>{const c=document.querySelector('canvas'),gl=c.getContext('webgl2'),e=gl.getExtension('WEBGL_debug_renderer_info'),b=c.getBoundingClientRect();return {renderer:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):null,canvas:[c.width,c.height],drawingBuffer:[gl.drawingBufferWidth,gl.drawingBufferHeight],css:[b.width,b.height],inner:[innerWidth,innerHeight],dpr:devicePixelRatio,visible:document.visibilityState,focus:document.hasFocus()}});
  assert(report.environment.renderer.includes('Intel'),'Unexpected GPU');assert(report.environment.visible==='visible','Not visible');
  await page.evaluate(()=>window.perfCommand({action:'configure',id:'startup',pose:'study'}));await measure(600,false);
  for(let i=0;i<plan.blocks.length;i++){
   const block=plan.blocks[i],config={action:'configure',id:'config-'+i,pose:'study',...block.config};await page.evaluate(c=>window.perfCommand(c),config);await page.waitForFunction(id=>window.perfAck===id,config.id,{polling:50});
   await measure(plan.warmup_frames||120,false);const result=await measure(plan.measure_frames||300,block.probe!==false);
   const walls=result.game.rows.map(r=>r[0]),sorted=[...walls].sort((a,b)=>a-b);const mean=walls.reduce((a,b)=>a+b,0)/walls.length;
   report.blocks.push({label:block.label,config,started_after_warmup_frames:plan.warmup_frames||120,...result,mean_ms:mean,p50_ms:sorted[Math.floor(sorted.length*.5)],p95_ms:sorted[Math.floor(sorted.length*.95)]});
   fs.writeFileSync(path.join(out,'progress.json'),JSON.stringify({completed:i+1,total:plan.blocks.length,label:block.label,mean_ms:mean,time:new Date().toISOString()}));console.log('BLOCK',i,block.label,mean,result.gpu.gpu_timer_available);
   if(block.screenshot)await page.screenshot({path:path.join(out,String(i)+'-'+block.label+'.png')});
  }
  report.pass=report.errors.length===0;
 }catch(e){report.pass=false;report.failure=String(e);report.stack=e.stack;await page.screenshot({path:path.join(out,'failure.png'),timeout:10000}).catch(()=>{})}
 finally{report.ending_receipt=read(path.join(work,'diag-receipt.json'));report.pack_sha256_end=sha(path.join(work,'diag-web/index.pck'));report.version_consistent=report.receipt.pack_sha256===report.pack_sha256_end&&JSON.stringify(report.receipt)===JSON.stringify(report.ending_receipt)&&report.loaded_packs.some(p=>p.endsWith('/index.pck'));if(!report.version_consistent)report.pass=false;report.finished_at=new Date().toISOString();fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));await context.close();await browser.close();if(!report.pass)process.exitCode=1;console.log(JSON.stringify({pass:report.pass,blocks:report.blocks.length,errors:report.errors,failure:report.failure}))}
})();
