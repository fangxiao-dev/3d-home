"""Subset bundled OFL Noto fonts to actual local letters and UI characters."""
import json, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'work/python-deps'))
from fontTools import subset
from fontTools.ttLib import TTFont

info=json.loads((ROOT/'work/blender-setup.json').read_text(encoding='utf-8-sig'))
fonts=Path(info['executable']).parent/'4.5/datafiles/fonts'
text=(ROOT/'godot/content/letters/catalog.json').read_text(encoding='utf-8')
for path in (ROOT/'godot').glob('*.gd'):text+=path.read_text(encoding='utf-8')
for path in (ROOT/'godot/content/album').glob('*.json'):text+=path.read_text(encoding='utf-8')
chars=set(map(ord,text))|set(range(32,127))
for source,target in [('Noto Sans CJK Regular.woff2','NotoSansSC-Reading.ttf'),('NotoEmoji-VariableFont_wght.woff2','NotoEmoji-Reading.ttf')]:
    font=TTFont(fonts/source);font.flavor=None
    options=subset.Options();options.layout_features=['*'];options.name_IDs=['*'];options.notdef_outline=True
    sub=subset.Subsetter(options=options);sub.populate(unicodes=chars);sub.subset(font)
    font.save(ROOT/'godot/assets'/target)
print('READING_FONTS_OK')
