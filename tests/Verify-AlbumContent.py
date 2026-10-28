import json
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
ALBUM=ROOT/'godot/content/album/album.json'
data=json.loads(ALBUM.read_text(encoding='utf8'))
pages=data['pages']
assert len(pages)==13, f'expected 13 pages, got {len(pages)}'
assert len({page['id'] for page in pages})==13
assert all(len(page['spreads'])==2 for page in pages)
quarters=data['quarters']
assert len(quarters)==40, f'expected 40 quarter buckets, got {len(quarters)}'
assert sum(q['count'] for q in quarters)==778
assert sum(q['count']>0 for q in quarters)==39
assert next(q for q in quarters if q['year']==2022 and q['quarter']==4)['count']==0
assert [page['id'] for page in pages if page.get('draft')]==['africa','guzheng','snow']
texts='\n'.join(block.get('text','') for page in pages for spread in page['spreads'] for block in spread['blocks'])
for required in ('我脑子里想不到第二个人','让我们的求婚被记忆不断的加工美化','谢谢走出的第一步。','剩下的路，我都会勇敢向你奔赴。','明年之后的每个生日，','我都陪你一起过。','02.23 飞回宜昌 → 09.19 回国 → 10.03 这一夜 → 10.19 → …'):
 assert required in texts, f'missing approved phrase: {required}'
for producer_note in ('星群位置与疏密已根据真实朋友圈记录生成','原型将年份暂放','可以找到一张你的照片','素材来自她 2025-11 的回忆','正式页面仍需核对','待用真实的第一次线下相处照片替换','2048 已在客厅茶几上可玩','私人语言示例','照片待替换','原图待替换'):
 assert producer_note not in texts, f'creator note leaked into album: {producer_note}'
for key,path in data['assets'].items():
 if path.startswith('res://content/album/'):
  local=ROOT/'godot'/path.removeprefix('res://')
 else:
  local=ROOT/'godot'/path.removeprefix('res://')
 assert local.is_file(), f'missing asset {key}: {local}'
for page in pages:
 for spread in page['spreads']:
  for block in spread['blocks']:
   if block['type']=='photo':assert block['asset'] in data['assets'], f"unknown asset: {block['asset']}"
print(f'ALBUM_CONTENT_OK pages={len(pages)} spreads=26 quarters={len(quarters)} interactions=778 images={len(data["assets"])}')
prototype=(ROOT/'docs/design/prototypes/e03-time-album/v1.3.html').read_text(encoding='utf8')
script=prototype[prototype.index('<script>')+8:prototype.index('</script>')]
assert '.chat-star{fill:#e8b95d' in prototype and 'pointer-events:auto;cursor:help' in prototype
assert 'data-index="0"' not in script[script.index('function chatStarsSvg'):script.index('function footstepsSvg')]
assert 'data-track="fang"' in script and 'data-track="ying"' in script
assert "const side=p.side||'both'" in script and "t.classList.toggle('inactive',!active)" in script
assert "(p.side||'both')==='fang'?31:(p.side||'both')==='ying'?83:57" in script
assert '.life-track.inactive{opacity:.35;stroke-width:2}' in prototype and '.life-track.active{opacity:1;stroke-width:3.5}' in prototype
assert 'INTERACTIVE PROTOTYPE' not in prototype and '示意定位' not in prototype and '部分年份／配图待确认' not in prototype
print('ALBUM_PROTOTYPE_OK hover_stars=2 track_highlight=side producer_notes=clean')
