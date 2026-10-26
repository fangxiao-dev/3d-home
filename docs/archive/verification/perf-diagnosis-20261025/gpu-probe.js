// Installed before the isolated engine. No gl.finish or synchronous query readback.
(() => {
 let gl,ext,active=null,collect=false,generation=0,frames=[],pending=[],allocations=[],disjoint=0;
 let viewport=[0,0],drawFB=null,boundRB=null,unit=0;
 const textures=new WeakMap(),renderbuffers=new WeakMap(),attachments=new WeakMap(),boundTextures=new Map();
 const getContext=HTMLCanvasElement.prototype.getContext;
 HTMLCanvasElement.prototype.getContext=function(...args){const result=getContext.apply(this,args);if(result&&args[0]==='webgl2'&&this.id==='canvas'&&!gl){gl=result;install();}return result};
 function install(){
  ext=gl.getExtension('EXT_disjoint_timer_query_webgl2');
  const wrap=(name,fn)=>{const original=gl[name].bind(gl);gl[name]=(...args)=>{fn(...args);return original(...args)}};
  wrap('viewport',(x,y,w,h)=>viewport=[w,h]);
  wrap('bindFramebuffer',(target,fb)=>{if(target===gl.FRAMEBUFFER||target===gl.DRAW_FRAMEBUFFER)drawFB=fb});
  wrap('activeTexture',value=>unit=value);
  wrap('bindTexture',(target,texture)=>boundTextures.set(target+':'+unit,texture));
  function textureSize(target,w,h){const t=boundTextures.get(target+':'+unit);if(t&&Number.isFinite(w)&&Number.isFinite(h)){const size={width:w,height:h,samples:0};textures.set(t,size);allocations.push({kind:'texture',...size,t:performance.now()})}}
  wrap('texImage2D',(target,level,format,w,h)=>textureSize(target,w,h));
  wrap('texStorage2D',(target,levels,format,w,h)=>textureSize(target,w,h));
  wrap('bindRenderbuffer',(target,rb)=>boundRB=rb);
  function rbSize(samples,w,h){if(boundRB){const size={width:w,height:h,samples};renderbuffers.set(boundRB,size);allocations.push({kind:'renderbuffer',...size,t:performance.now()})}}
  wrap('renderbufferStorage',(target,format,w,h)=>rbSize(0,w,h));
  wrap('renderbufferStorageMultisample',(target,samples,format,w,h)=>rbSize(samples,w,h));
  function attach(attachment,obj,kind){if(drawFB){let map=attachments.get(drawFB);if(!map){map=new Map();attachments.set(drawFB,map)}map.set(attachment,{obj,kind})}}
  wrap('framebufferTexture2D',(target,attachment,textarget,texture)=>attach(attachment,texture,'texture'));
  wrap('framebufferRenderbuffer',(target,attachment,rbtarget,rb)=>attach(attachment,rb,'renderbuffer'));
  function draw(){if(!active)return;active.draws++;let size={width:gl.drawingBufferWidth,height:gl.drawingBufferHeight,samples:0};if(drawFB){const map=attachments.get(drawFB),attachment=map?.get(gl.COLOR_ATTACHMENT0)||map?.get(gl.DEPTH_ATTACHMENT);size=attachment?(attachment.kind==='texture'?textures:renderbuffers).get(attachment.obj)||{}:{}}const key=viewport.join('x')+'@'+(size.width??'?')+'x'+(size.height??'?')+'s'+(size.samples??'?');active.passes[key]=(active.passes[key]||0)+1}
  for(const name of ['drawElements','drawArrays','drawElementsInstanced','drawArraysInstanced','drawRangeElements'])if(gl[name])wrap(name,draw);
 }
 function poll(){if(!gl||!ext)return;const bad=gl.getParameter(ext.GPU_DISJOINT_EXT);if(bad){disjoint++;for(const p of pending)p.invalid=true}const rest=[];for(const p of pending){if(gl.getQueryParameter(p.query,gl.QUERY_RESULT_AVAILABLE)){const query=p.query;if(!bad&&!p.invalid&&p.generation===generation&&p.draws>0){p.gpu_ms=gl.getQueryParameter(query,gl.QUERY_RESULT)/1e6;delete p.query;frames.push(p)}gl.deleteQuery(query)}else rest.push(p)}pending=rest;}
 const nativeRAF=window.requestAnimationFrame.bind(window);
 window.requestAnimationFrame=cb=>nativeRAF(ts=>{
  poll();if(!gl||!collect||active){cb(ts);return}
  const row={generation,raf_t:ts,start:performance.now(),draws:0,passes:{}};
  if(ext){row.query=gl.createQuery();gl.beginQuery(ext.TIME_ELAPSED_EXT,row.query)}
  active=row;try{cb(ts)}finally{active=null;row.callback_wall_ms=performance.now()-row.start;if(ext){gl.endQuery(ext.TIME_ELAPSED_EXT);pending.push(row)}else if(row.draws>0&&row.generation===generation)frames.push(row)}
 });
 window.gpuProbe={
  start(){generation++;frames=[];disjoint=0;collect=true;return generation},
  stop(){collect=false;poll()},
  poll,
  read(){poll();return {gpu_timer_available:!!ext,gpu_disjoint_observations:disjoint,pending:pending.filter(p=>p.generation===generation).length,frames,allocations:allocations.slice(-200),drawing_buffer:gl?[gl.drawingBufferWidth,gl.drawingBufferHeight]:null,canvas_id:gl?.canvas.id}},
 };
})();
