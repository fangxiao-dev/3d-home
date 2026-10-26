from pathlib import Path
import re
import requests
root = Path(__file__).resolve().parents[3]
text = '暂时走不过去请换个位置再试出口受阻方向键入口软墩长沙发窗边坐位餐椅书房椅起身我们的家·客厅↑↓←→移动Q/E旋转滚轮缩放软墩沙发中部窗边坐垫查看坐下沿标记寻找两个和Esc返回：/·。ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789<>，鼠标靠近左右边缘转向'
css = requests.get('https://fonts.googleapis.com/css2', params={'family':'Noto Sans SC:wght@400','text':text}, timeout=40, headers={'User-Agent':'Mozilla/5.0'})
css.raise_for_status()
url = re.search(r'url\(([^)]+)\)', css.text).group(1)
font = requests.get(url, timeout=40)
font.raise_for_status()
(root / 'outputs/godot/assets/NotoSansSC-Play.ttf').write_bytes(font.content)
print('Navigation UI font bytes:', len(font.content))
