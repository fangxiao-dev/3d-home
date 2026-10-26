"""Retain the bounded A-B-A experiment without changing accepted raw reports."""
from pathlib import Path
import json,hashlib,re
root=Path.cwd();evidence=root/'outputs/verification/navigation-v2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
phases=[];bodies=[]
for name,relative in [('A_original','performance-comparison-study'),('B_cache','perf-trial/performance-comparison-study'),('A_restored','perf-trial/baseline-repeat-study')]:
    folder=evidence/relative;report=read(folder/'report.json');runner=folder/'runner.cjs'
    assert report['pass'] and report['runner_sha256']==sha(runner)
    assert report['ending_build']['pack']==report['build']['pack']
    assert all(report['build']['pack'] in case['loaded_packs'] and not case['errors'] for case in report['cases'])
    text=runner.read_text();body=text[text.index('(async()=>'):];bodies.append(hashlib.sha256(body.encode()).hexdigest())
    cases=[]
    for case in report['cases']:
        state=case['engine_state']
        cases.append({'mode':case['mode'],'raf_mean_ms':case['mean_ms'],'raf_p95_ms':case['p95_ms'],'game_mean_ms_at_end':case['game_mean_ms_at_end'],'game_frames_per_raf':case['game_frames_per_raf_frame'],'route':case['route'],'actual_test_pose':{k:state[k] for k in ['x','z','camera_yaw','zoom']} if state else None})
    phases.append({'name':name,'report':relative+'/report.json','report_sha256':sha(folder/'report.json'),'runner_sha256':sha(runner),'pack':report['build']['pack'],'runtime':report['build']['runtime'],'started_at':report['started_at'],'finished_at':report['finished_at'],'cases':cases})
assert len(set(bodies))==1,'Measurement semantics changed beyond output directory'
baseline=root/'work/navigation-v2/perf-trial/baseline'
core=[row for row in read(baseline/'manifest.json') if not row['path'].startswith('outputs/verification/')]
assert all(sha(root/row['path'])==row['sha256'] for row in core)
receipt=read(root/'work/scene-v2-build-receipt.json');assert receipt['pack']=='scene-1a42f717cba2.pck'
config=json.loads(re.search(r'const GODOT_CONFIG = (\{.*?\});',(root/'outputs/web/index.html').read_text(),re.S).group(1))
assert config['mainPack']==receipt['pack'] and sha(root/'outputs/web'/receipt['pack'])==receipt['sha256']
assert sha(root/'outputs/godot/playroom.gd')==receipt['runtime']
equivalence=read(root/'work/navigation-v2/perf-trial/visibility-equivalence.json')
visual=read(evidence/'perf-trial/fixed-1366-occlusion/report.json');assert visual['pass'] and len(visual['occlusion_cases'])==20
controls=read(root/'work/navigation-v2/perf-trial/control-reuse.json');accepted_controls=read(evidence/'r3-control-reuse.json')
assert controls['unchanged_functions']==accepted_controls['unchanged_functions'] and not controls['changed_functions']
decision={'decision':'ROLLED_BACK','retained_pack':receipt['pack'],'retained_runtime':receipt['runtime'],'trial_pack':'scene-e33ba67657c7.pck','reason':'A-B-A does not establish a consistent whole-frame benefit. Restored baseline normal 28.142 ms is faster than trial 32.065 ms, while test results also vary by phase. Keep the previously validated implementation.','phases':phases,'measurement_body_sha256':bodies[0],'measurement_semantics_equal':True,'microbenchmark_and_equivalence':equivalence,'equivalence_limit':'336 Explore poses only; source invokes bone rays in both paths, but those calls were not separately instrumented. No new browser seat-cycle claim is made for the rejected trial.','trial_visual_cases':20,'control_functions_unchanged':19,'restored_product_files':core,'restored_product_hashes_match':True,'performance_acceptance_unchanged':'Original retained-package 1920 soak still has 19 of 52 means above 40 ms. Short windows do not replace it.','owner_UI_check':'EVIDENCE_GAP'}
(evidence/'perf-trial/decision.json').write_text(json.dumps(decision,indent=2));print(json.dumps({'decision':decision['decision'],'retained_pack':receipt['pack'],'product_files_verified':len(core),'measurement_semantics_equal':True}))
