from pathlib import Path
from PIL import Image,ImageStat
import json
out=Path('outputs/verification/fixed-scene-transition-20261025');metrics=[];captures=[]
for directory in ['smoke-1366','campaign-1366-prefix','study-completion-1366','campaign-1920']:
 run=out/directory
 report=json.loads((run/'report.json').read_text()) if (run/'report.json').exists() else {}
 accepted={str(c['id'])+'-'+str(c['yaw'])+'-'+str(c['amount']) for c in report.get('cycles',[])}
 for p in run.glob('*-trace.json'):
  frames=json.loads(p.read_text());fade=[(i,f) for i,f in enumerate(frames) if f.get('transition_phase')=='fade_out'];black=[(i,f) for i,f in enumerate(frames) if f.get('transition_phase')=='black' and f.get('fade_alpha')==1];sit=[(i,f) for i,f in enumerate(frames) if f.get('animation')=='SitDown']
  if not (fade and black and sit):continue
  start=fade[0][0];end=sit[0][0];window=frames[start:end+1];metrics.append({'run':directory,'trace':p.name,'accepted_complete_case':p.name.removesuffix('-trace.json') in accepted,'fade_out_first_to_black_ms':black[0][1]['t']-fade[0][1]['t'],'black_to_revealed_sit_ms':sit[0][1]['t']-black[0][1]['t'],'transition_first_submitted_to_sit_ms':sit[0][1]['t']-fade[0][1]['t'],'transition_render_frame_peak_ms':max(window[i]['t']-window[i-1]['t'] for i in range(1,len(window))),'black_submitted_frames':len(black),'all_sit_revealed':all(f['fade_alpha']==0 for _,f in sit)})
 for frames_dir in run.glob('*-frames'):
  black_images=[];count=0
  for p in frames_dir.glob('*.jpg'):
   count+=1;im=Image.open(p).convert('RGB');st=ImageStat.Stat(im)
   if max(st.mean)<1 and max(x[1] for x in st.extrema)<4:black_images.append(p.as_posix())
  captures.append({'directory':frames_dir.as_posix(),'frame_count':count,'black_images':black_images})
result={'timing_scope':'Actual frame_pre_draw submission timestamps: first fade_out sample through first revealed SitDown; excludes later seated PNG screenshot costs. Nominal Tween durations remain 150ms/200ms. Capture JPEG timestamps are retained separately, not assumed to share engine clock.','metrics':metrics,'continuous_screencasts':captures}
(out/'transition-metrics.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps({'trace_count':len(metrics),'capture_sets':len(captures),'all_captures_have_black':all(x['black_images'] for x in captures),'duration_range_ms':[min(x['transition_first_submitted_to_sit_ms'] for x in metrics),max(x['transition_first_submitted_to_sit_ms'] for x in metrics)],'peak_ms':max(x['transition_render_frame_peak_ms'] for x in metrics)}))
