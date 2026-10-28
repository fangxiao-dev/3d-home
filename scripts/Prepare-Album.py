from html.parser import HTMLParser
from pathlib import Path
import base64, json, re, subprocess, tempfile
ROOT=Path(__file__).resolve().parent.parent
PROTO=ROOT/'docs/design/prototypes/e03-time-album'
SOURCE=PROTO/'v1.2.html'
AGGREGATE=PROTO/'E03-点赞互动-时间聚合.json'
CONTENT=ROOT/'godot/content/album'
IMAGES=CONTENT/'images'
EXTRACTOR=r"""
const fs=require('fs');const html=fs.readFileSync(process.argv[2],'utf8');const start=html.indexOf('const ASSETS=');const end=html.indexOf('function yearX');if(start<0||end<0)throw Error('v1.2 data section missing');global.document={querySelector(){return null}};const result=new Function(html.slice(start,end)+`\nreturn {assets:ASSETS,pages,spreads:pages.map(p=>content(p)),pastStarClusters};`)();fs.writeFileSync(process.argv[3],JSON.stringify(result),'utf8');
"""
class Node:
 def __init__(self,tag,attrs): self.tag=tag;self.attrs=dict(attrs);self.children=[]
class TreeParser(HTMLParser):
 def __init__(self): super().__init__(convert_charrefs=True);self.root=Node('root',[]);self.stack=[self.root]
 def handle_starttag(self,tag,attrs):
  if tag=='br':self.stack[-1].children.append('\n');return
  n=Node(tag,attrs);self.stack[-1].children.append(n)
  if tag not in {'img','br','hr','meta','link','input','source','wbr'}:self.stack.append(n)
 def handle_endtag(self,tag):
  for i in range(len(self.stack)-1,0,-1):
   if self.stack[i].tag==tag:self.stack=self.stack[:i];return
 def handle_data(self,data):
  if data.strip():self.stack[-1].children.append(data.strip())
def text_of(node):
 if isinstance(node,str):return node
 return ' '.join(filter(None,(text_of(x) for x in node.children)))
def find(node,cond):
 if not isinstance(node,str) and cond(node):return node
 if not isinstance(node,str):
  for c in node.children:
   r=find(c,cond)
   if r:return r
 return None
def classes(n):return set(n.attrs.get('class','').split())
def main_blocks(markup, assets, page_id, spread_index):
 parser=TreeParser();parser.feed(markup)
 header=find(parser.root,lambda n:n.tag=='div' and 'page-top' in classes(n))
 eyebrow=text_of(find(header,lambda n:n.tag=='span' and 'eyebrow' in classes(n))) if header else ''
 body=find(parser.root,lambda n:n.tag=='div' and 'page-content' in classes(n)) or parser.root
 out=[];reverse={v:k for k,v in assets.items()}
 def walk(n):
  if isinstance(n,str):
   return
  cls=classes(n)
  if n.tag in {'h1','h2','h3'} or 'hero-year' in cls:
   out.append({'type':'heading','text':text_of(n),'level':3 if n.tag=='h3' else 2});return
  if 'frame-empty' in cls:
   sub=n.children[-1] if n.children else ''
   out.append({'type':'blank','text':text_of(n),'variant':{'dayone':'phone','proposal':'polaroid','future':'film'}.get(page_id,'frame')});return
  if 'photo-card' in cls:
   img=find(n,lambda x:x.tag=='img');src=img.attrs.get('src','') if img else ''
   key=reverse.get(src)
   if key:
    cap=find(n,lambda x:'photo-caption' in classes(x))
    out.append({'type':'photo','asset':key,'caption':text_of(cap) if cap else '', 'class_name':' '.join(n.attrs.get('class','').split()),'style':n.attrs.get('style','')})
   return
  if n.tag=='p':
   typ='note' if cls & {'tiny-script','footnote'} else 'text'
   if text_of(n):out.append({'type':typ,'text':text_of(n),'class_name':' '.join(cls),'style':n.attrs.get('style','')})
   return
  if 'quote' in cls:
   out.append({'type':'quote','text':text_of(n),'class_name':'quote','style':n.attrs.get('style','')});return
  if cls & {'hand-note','private-note','memo','chat','footnote','date-tag','hero-year','wedding-banner','chip','tile','small-cap'}:
   typ='quote' if 'private-note' in cls else 'note'
   if text_of(n):out.append({'type':typ,'text':text_of(n),'class_name':' '.join(cls),'style':n.attrs.get('style','')})
   return
  if n.tag in {'img','svg','path','circle','ellipse'}:return
  for c in n.children:walk(c)
 for child in body.children:walk(child)
 layout='collage' if page_id in {'firstmeet','travel'} else 'red' if page_id=='marriage' else 'standard'
 return {'eyebrow':eyebrow,'layout':layout,'spread_index':spread_index,'blocks':out}
def main():
 CONTENT.mkdir(parents=True,exist_ok=True);IMAGES.mkdir(parents=True,exist_ok=True)
 with tempfile.TemporaryDirectory(prefix='e03-album-') as td:
  extracted=Path(td)/'extract.json'
  extractor=Path(td)/'extract.cjs';extractor.write_text(EXTRACTOR,encoding='utf8')
  subprocess.run(['node',str(extractor),str(SOURCE),str(extracted)],check=True,capture_output=True,text=True)
  source=json.loads(extracted.read_text(encoding='utf8'))
 assets={}
 for key,data in source['assets'].items():
  if not data.startswith('data:') or key in {'tree2017','tree2024'}:continue
  head,payload=data.split(',',1);mime=head[5:].split(';',1)[0]
  ext={'image/webp':'webp','image/svg+xml':'svg','image/png':'png','image/jpeg':'jpg'}.get(mime)
  if not ext:continue
  name=f'{key}.{ext}';(IMAGES/name).write_bytes(base64.b64decode(payload))
  assets[key]=f'res://content/album/images/{name}'
 # Existing real archive photographs are local project assets already owned by E04.
 for key,name in [('tree2017','W5k9bcxbcoJpvyx7nP3cJAQOnLc.jpg'),('tree2024','AveNbQC5CobBevxA2imcvws5nnb.jpg'),('treeSnow','XlNBb1iD4oMSbBxnLSKciABmndf.jpg')]:
  assets[key]=f'res://content/letters/images/{name}'
 pages=[]
 for i,p in enumerate(source['pages']):
  q=dict(p);q['spreads']=[main_blocks(m,source['assets'],p['id'],j) for j,m in enumerate(source['spreads'][i])]
  if p['id']=='tree':q['spreads'][0]['blocks'][0]['asset']='tree2017';q['spreads'][1]['blocks'][0]['asset']='tree2024'
  if p['id']=='reconnect':
   q['title']='重新连接';q['spreads'][0]['blocks']=[{'type':'heading','text':'那些疏密不同的星群，','level':2},{'type':'text','text':'那些年，朋友圈里留下的点赞比想象中还多。却直到后来，我们才真正聊起彼此的生活。'},{'type':'note','text':'直到有一天，一个小小的回应，接上了一段真正的对话。'}]
  pages.append(q)
 snow={'id':'snow','time':2023.6,'date':'某年 · 待核实','short':'雪山与湖水','title':'她自己珍惜的那一天','tag':'认识之前，她也有一段会记一辈子的生活','kind':'snow','side':'ying','draft':True,'spreads':[
  {'eyebrow':'YING · A QUIET MEMORY','layout':'standard','spread_index':0,'blocks':[{'type':'note','text':'某年 · 新疆 · 年份待核实','class_name':'date-tag'},{'type':'photo','asset':'skyBlue','caption':'莹仔 · 雪山与湖水 / 示意插画','style':'--rot:-3deg;--imgH:210px'},{'type':'note','text':'只听湖水。','class_name':'hand-note'}]},
  {'eyebrow':'SOMETHING SHE KEEPS','layout':'standard','spread_index':1,'blocks':[{'type':'heading','text':'不忙着出片，只是站在那里。','level':2},{'type':'text','text':'站在雪山脚下听湖水，舒服得觉得这一生都会记得。'},{'type':'note','text':'和那棵圣诞树一样，这是她在认识彼此之前，就很珍贵的一天。'},{'type':'note','text':'素材来自她 2025-11 的回忆；具体年份与照片待她那边提供。','class_name':'footnote'}]}
 ]}
 # Restore this unit from v1.1's approved design; v1.2 prototype accidentally omitted it.
 pages.insert(4,snow)
 # Remove creator instructions that the prototype source mistakenly exposed as album copy.
 cleanup={
  'start':{'星群位置与疏密已根据真实朋友圈记录生成'},
  'africa':{'原型将年份暂放在 2020 附近，正式时间及两人照片都待确认。'},
  'guzheng':{'可以找到一张你的照片。两张照片不必相似，真实的不同就很好。','此单元在时间轴上的位置仅是演示，不代表已核实的年份。'},
  'snow':{'素材来自她 2025-11 的回忆；具体年份与照片待她那边提供。'},
  'reconnect':{'这里的对白仅选用已有记录中的短句；正式页面仍需核对。'},
  'firstmeet':{'待用真实的第一次线下相处照片替换。'},
  'travel':{'2048 已在客厅茶几上可玩，这里只留一小条回忆。'},
 }
 for page in pages:
  for spread in page['spreads']:
   spread['blocks']=[b for b in spread['blocks'] if b.get('text','') not in cleanup.get(page['id'],set())]
  for spread in page['spreads']:
   for block in spread['blocks']:
    block['caption']=block.get('caption','').replace('戒指照片待替换','戒指照片').replace('领证原图待替换','领证照片')
 # Restore three text details that the v1.2 HTML source omitted from the approved v1.1 pages.
 skies=next(p for p in pages if p['id']=='skies')
 skies['spreads'][1]['blocks'].append({'type':'note','text':'「我脑子里想不到第二个人」 · 2026.07.29 · 莹仔','class_name':'private-note'})
 proposal=next(p for p in pages if p['id']=='proposal')
 proposal['spreads'][0]['blocks'].append({'type':'note','text':'“让我们的求婚被记忆不断的加工美化。”','class_name':'hand-note'})
 proposal['spreads'][1]['blocks']=[b for b in proposal['spreads'][1]['blocks'] if not (b['type']=='quote' and '记忆不断地加工美化' in b.get('text','')) and not (b['type']=='note' and '正式文字待确认' in b.get('text',''))]
 proposal['spreads'][1]['blocks'].append({'type':'quote','text':'“谢谢走出的第一步。\n剩下的路，我都会勇敢向你奔赴。”','class_name':'quote'})
 proposal['spreads'][1]['blocks'].append({'type':'note','text':'❜❜ 他奔赴的路：02.23 飞回宜昌 → 09.19 回国 → 10.03 这一夜 → 10.19 → …','class_name':'steps-memo'})
 future=next(p for p in pages if p['id']=='future')
 future['spreads'][1]['blocks'].append({'type':'quote','text':'“明年之后的每个生日，\n我都陪你一起过。”\n—— 莹仔 · 2026.10.16','class_name':'quote'})
 # Asset paths in HTML prototype point to the shared local Godot content folder.
 aggregate=json.loads(AGGREGATE.read_text(encoding='utf8'))
 quarters=[]
 for q in aggregate['quarters']:
  year,quarter,count=q['year'],q['quarter'],q['count']
  quarters.append({'year':year,'quarter':quarter,'count':count,'time':year+(quarter-.5)/4})
 album={'version':1,'pages':pages,'assets':assets,'quarters':quarters,
  'real_stars':[{'t':2017+207/365,'label':'2017.07.27 · 她发来「在不」','shape':'spark'},{'t':2019+12/365,'label':'2019.01.13 · 她回「谢谢大兄弟」','shape':'star'}],
  'call_hours':{'1':99.8,'2':62.9,'3':64.1,'4':91.3,'5':83.1,'6':84.7,'7':87.7,'8':70.9,'9':25.3,'10':0.2},
  'tracks':{'top':[[1,43],[2.65,43],[2.8,62],[3.25,62],[3.45,43],[7,43],[9.45,43],[9.62,62],[10.75,62],[11,46],[12,45],[13,43]],'bottom':[[1,82],[2.65,84],[2.8,62],[3.25,62],[3.45,88],[7,88],[9.45,86],[9.62,62],[10.75,62],[11,78],[12,84],[13,86]]},
  'footsteps':[{'time':2017+207/365,'who':'ying','label':'2017 · 她先开口：「在不」'},{'time':2025+316/365,'who':'ying','label':'2025.11.13 · 她先开口'},{'time':2026.0,'month':1.0,'who':'ying','label':'2026.01.01 · 她先开口：「是的吧？」'},{'time':2026.15,'month':2+(23-1)/28,'who':'fang','label':'02.23 飞回宜昌'},{'time':2026.72,'month':9+(19-1)/30,'who':'fang','label':'09.19 回国'},{'time':2026.755,'month':10+(3-1)/31,'who':'fang','label':'10.03 求婚'},{'time':2026.8,'month':10+(19-1)/31,'who':'fang','label':'10.19 领证'},{'time':2027.2,'month':12.9,'who':'fang','label':'向未来继续奔赴'}]}
 target=CONTENT/'album.json';target.write_text(json.dumps(album,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 print(f'album.json: {len(pages)} pages, {len(quarters)} quarter buckets, {sum(q["count"] for q in quarters)} interactions, {len(assets)} shared image assets')
def build_prototype():
 html=SOURCE.read_text(encoding='utf8')
 # Replace every in-page content literal with a renderer over album.json blocks.
 html=re.sub(r'<title>[^<]*</title>', '<title>我们的时间 · E03 真实星群交互原型 v1.3</title>', html, count=1)
 html=html.replace('.page p{font-size:13px;', '.page p{font-size:16px;').replace('.page p{font-size:11px;line-height:1.7}', '.page p{font-size:15px;line-height:1.65}')
 s=html.index('<script>')+len('<script>');e=html.index('</script>',s);js=html[s:e]
 # Remove old embedded data literals; all page and star data now comes from the shared JSON.
 js=re.sub(r'const ASSETS=.*?;\s*const pages=\[.*?\n\];\s*const pastStarClusters=.*?;\s*', '', js, count=1, flags=re.S)
 # Replace the hand-authored HTML content switch with the shared semantic blocks.
 a=js.index('function content(p){');b=js.index('function yearX(',a)
 renderer=r'''function esc(value){return String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function assetUrl(key){const path=album.assets[key]||'';return path.startsWith('res://')?'../../../../godot/'+path.slice(6):''}
function renderBlock(block,page,spread){
 const text=esc(block.text||'').replace(/\n/g,'<br>'),cls=esc(block.class_name||''),style=block.style?` style="${esc(block.style)}"`:'';
 switch(block.type){
  case 'heading':return `<h${block.level===3?3:2}${style}>${text}</h${block.level===3?3:2}>`;
  case 'text':return `<p class="${cls}"${style}>${text}</p>`;
  case 'note':
   if(cls.includes('wedding-banner')){const bits=(block.text||'').split(/\s+/);return `<div class="wedding-banner"><div class="xi">${esc(bits.shift()||'囍')}</div><small>${esc(bits.join(' '))}</small></div>`}
   return `<div class="${cls||'hand-note'}"${style}>${text}</div>`;
  case 'quote':return `<div class="quote"${style}>${text}</div>`;
  case 'blank':return `<div class="frame-empty ${esc(block.variant||'')}"${style}><div class="inside"><span>✳</span><strong>这一刻没有照片</strong><div>${text}</div></div></div>`;
  case 'photo':return `<div class="photo-card"${style}><div class="image-box"><img src="${esc(assetUrl(block.asset))}" alt="${esc(block.caption||'示意素材')}"></div><div class="photo-caption">${esc(block.caption||'')}</div></div>`;
  default:return '';
 }
}
function content(p){return p.spreads.map((spread,index)=>{
 const photos=spread.blocks.filter(b=>b.type==='photo');let body=spread.blocks.map(b=>renderBlock(b,p,spread)).join('');
 if(spread.layout==='collage'&&photos.length>1){let inserted=false;body=spread.blocks.map(b=>{if(b.type!=='photo')return renderBlock(b,p,spread);if(inserted)return '';inserted=true;return `<div class="photo-overlap">${photos.map(photo=>renderBlock(photo,p,spread)).join('')}</div>`}).join('')}
 return `${headerLine(spread.eyebrow,String(index+pageNumber(p)).padStart(2,'0'))}<div class="page-content">${body}</div>`;
 })}
function pageNumber(p){return pages.indexOf(p)*2+1}
'''
 js=js[:a]+renderer+js[b:]
 # Wrap startup so drawing waits for the single content file.
 js=js.replace("'use strict';", "'use strict';\n(async function bootAlbum(){\n const response=await fetch('../../../../godot/content/album/album.json');if(!response.ok)throw new Error('album.json failed to load');const album=await response.json();\n const ASSETS=Object.fromEntries(Object.keys(album.assets).map(key=>[key,assetUrl(key)]));\n const pages=album.pages;const pastStarClusters=album.quarters.filter(q=>q.count>0).map(q=>({time:q.time,count:q.count,label:`${q.year} 年第 ${q.quarter} 季度`}));\n const realStars=album.real_stars;const callHours=album.call_hours;")
 # ASSETS must be resolved after assetUrl function is declared; use a small resolver before page code.
 js=js.replace(" const ASSETS=Object.fromEntries(Object.keys(album.assets).map(key=>[key,assetUrl(key)]));", " const ASSETS=album.assets;")
 # Add chat stars and subtle paired footprints to the overview timeline.
 marker='function overviewSvg(){'
 extras=r'''function chatStarsSvg(){return realStars.map((star,i)=>{const x=yearX(star.t),shape=i===0?`<path d="M${x} 45l3 8 8 3-8 3-3 8-3-8-8-3 8-3z"/>`:`<path d="M${x} 45l2.3 7.7 7.7 2.3-7.7 2.3L${x} 65l-2.3-7.7L${x-8} 55l7.7-2.3z"/>`;return `<g class="chat-star" tabindex="0" role="img" aria-label="${esc(star.label)}"><title>${esc(star.label)}</title>${shape}</g>`}).join('')}
function footstepsSvg(detail=false){return album.footsteps.filter(f=>detail?f.month!=null:f.time<2026).map(f=>{const x=detail?monthX(f.month):yearX(f.time),y=f.who==='ying'?88:detail?35:92;return `<g class="footstep" aria-hidden="true"><title>${esc(f.label)}</title><ellipse cx="${x-2.2}" cy="${y}" rx="1.3" ry="2.1"/><ellipse cx="${x+2.2}" cy="${y-2.7}" rx="1.3" ry="2.1"/></g>`}).join('')}
'''
 js=js.replace(marker,extras+marker)
 js=js.replace('const stars=pastStarClusters.map((c,i)=>starClusterSvg(c,i)).join(\'\');', "const stars=pastStarClusters.map((c,i)=>starClusterSvg(c,i)).join('')+chatStarsSvg()+footstepsSvg();")
 js=js.replace("${stars}${nodes}${nodeSvg(pages[5],5,yearX(2026.05),58,'zoom-node')}", "${stars}${nodes}${nodeSvg(pages.find(p=>p.kind==='dayone'),pages.findIndex(p=>p.kind==='dayone'),yearX(2026.05),58,'zoom-node')}")
 js=js.replace("p.side==='fang'?31:p.kind==='guzheng'?79:55", "(p.side||'both')==='fang'?31:(p.side||'both')==='ying'?83:57")
 js=js.replace('<path d="M48 58 C87 58 92 31', '<path class="life-track" data-track="fang" d="M48 58 C87 58 92 31')
 js=js.replace('<path d="M48 58 C87 58 92 83', '<path class="life-track" data-track="ying" d="M48 58 C87 58 92 83')
 # Source the month rails and call-hour stitches from the shared data.
 js=js.replace('const trackTop=[[1,43],[2,64],[3,43],[7,43],[9,62],[10,62],[11,48],[12,45],[13,43]];', 'const trackTop=album.tracks.top;')
 js=js.replace('const bottom=[[1,82],[2,64],[3,88],[7,88],[9,62],[10,62],[11,78],[12,84],[13,86]];', 'const bottom=album.tracks.bottom;')
 js=js.replace('<polyline points="${points(trackTop)}"', '<polyline class="life-track" data-track="fang" points="${points(trackTop)}"')
 js=js.replace('<polyline points="${points(bottom)}"', '<polyline class="life-track" data-track="ying" points="${points(bottom)}"')
 js=js.replace("const nodes=pages.map((p,i)=>p.month?nodeSvg(p,i,monthX(p.month),p.kind==='firstmeet'||p.kind==='travel'||p.kind==='proposal'||p.kind==='marriage'?62:66):'').join('');", "const nodes=pages.map((p,i)=>p.month?nodeSvg(p,i,monthX(p.month),p.kind==='firstmeet'||p.kind==='travel'||p.kind==='proposal'||p.kind==='marriage'?62:66):'').join('');const stitches=stitchesSvg(trackTop,bottom);")
 js=js.replace('${nodes}<g class="time-pointer" id="detailCursor">','${stitches}${nodes}${footstepsSvg(true)}<g class="time-pointer" id="detailCursor">')
 js=js.replace("document.querySelectorAll('.timeline-node').forEach(n=>n.classList.toggle('active',Number(n.dataset.index)===pageIndex));", "document.querySelectorAll('.timeline-node').forEach(n=>n.classList.toggle('active',Number(n.dataset.index)===pageIndex));const side=p.side||'both';document.querySelectorAll('.life-track').forEach(t=>{const active=side==='both'||t.dataset.track===side;t.classList.toggle('active',active);t.classList.toggle('inactive',!active)});")
 # Detail star overlay generation.
 js=js.replace('function detailSvg(){', "function stitchesSvg(top,bottom){const yAt=(points,m)=>{for(let i=1;i<points.length;i++){if(m<=points[i][0]){const a=points[i-1],b=points[i],t=(m-a[0])/(b[0]-a[0]);return a[1]+(b[1]-a[1])*t}}return points.at(-1)[1]};return Object.entries(callHours).filter(([m,h])=>Number(m)<9&&Number(h)>0).map(([month,h])=>{const x=monthX(Number(month)),a=yAt(top,Number(month)),b=yAt(bottom,Number(month)),n=Math.min(5,Math.max(1,Math.round(Math.sqrt(Number(h))/3)));return Array.from({length:n},(_,i)=>{const y=a+(b-a)*(i+1)/(n+1);return `<path class=\"stitch\" d=\"M${x-1.7} ${y-1.5}l3.4 3\"/>`}).join('')}).join('')}\nfunction detailSvg(){")
 # Skip empty quarter buckets and leave chat stars non-interactive.
 js=js.replace("function starClusterSvg(c,i){", "function starClusterSvg(c,i){")
 # Build shared data URL paths from the prototype directory.
 js=js.replace("const response=await fetch('../../../../godot/content/album/album.json');", "const response=await fetch('../../../../godot/content/album/album.json');")
 html=html[:s]+js+"\n})();\n"+html[e:]
 # Fix page renderer asset resolver to map res:// references into the workspace path.
 html=html.replace(".timeline-ticks{font-size:11px;", ".chat-star{fill:#e8b95d;stroke:#fff0c8;stroke-width:1.5;filter:drop-shadow(0 0 4px #f6cf79);pointer-events:auto;cursor:help}.footstep{fill:#bd9873;opacity:.32;pointer-events:none}.stitch{stroke:#d7b58e;stroke-width:1.4;opacity:.75}.life-track{transition:stroke-width .25s ease,opacity .25s ease}.life-track.inactive{opacity:.35;stroke-width:2}.life-track.active{opacity:1;stroke-width:3.5}.timeline-ticks{font-size:11px;")
 html=html.replace('<span class="prototype-flag">INTERACTIVE PROTOTYPE · 素材未定稿</span>', '')
 html=html.replace('　·　部分年份／配图待确认', '')
 html=html.replace("${p.draft?' · 示意定位':''}", "${p.draft?' · 日期待核实':''}")
 (PROTO/'v1.3.html').write_text(html,encoding='utf8')

if __name__=='__main__':
 main()
 build_prototype()
