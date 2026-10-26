from pathlib import Path
import re,requests,hashlib,json
from fontTools.ttLib import TTFont
root=Path(__file__).resolve().parents[3]
old=TTFont(root/'work/mouse-look-20261025/baseline/outputs/godot/assets/NotoSansSC-Play.ttf')
chars=set(chr(code) for table in old['cmap'].tables for code in table.cmap)
chars.update(re.findall(r'[\u3400-\u9fff\u3000-\u303f\uff00-\uffef]',(root/'outputs/godot/playroom.gd').read_text()))
chars.update(chr(c) for c in range(32,127))
text=''.join(sorted(chars))
response=requests.get('https://fonts.googleapis.com/css2',params={'family':'Noto Sans SC:wght@400','text':text},headers={'User-Agent':'Mozilla/5.0'},timeout=40);response.raise_for_status()
url=re.search(r'url\(([^)]+)\)',response.text).group(1)
font=requests.get(url,timeout=40);font.raise_for_status()
p=root/'outputs/godot/assets/NotoSansSC-Play.ttf';p.write_bytes(font.content)
current=TTFont(p);present={c for table in current['cmap'].tables for c in table.cmap};missing=[c for c in text if ord(c)not in present];assert not missing,missing
(root/'outputs/verification/mouse-look-20261025/font-receipt.json').write_text(json.dumps({'source':url,'sha256':hashlib.sha256(font.content).hexdigest(),'characters':len(chars),'missing':missing},indent=2))
print('FONT_OK',len(font.content),len(chars))
