from pathlib import Path
import urllib.request,urllib.parse,json,re,hashlib,shutil
root=Path(__file__).resolve().parents[1]
out=root/'assets/references/folk'
query=dict(action='query',format='json',titles='File:Donkey 06.jpg',prop='imageinfo',iiprop='url|extmetadata',iiurlwidth=1280)
def get(url): return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'CuanGameArtResearch/1.0'}),timeout=35).read()
raw=json.loads(get('https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(query)))
info=next(iter(raw['query']['pages'].values()))['imageinfo'][0]
meta=info['extmetadata']
clean=lambda name: re.sub('<[^>]+>','',meta.get(name,{}).get('value','')).strip()
assert clean('LicenseShortName')=='CC0'
url=info['thumburl'].split('?')[0]
payload=get(url)
assert payload[:2]==b'\xff\xd8'
shutil.copy2(out/'donkey.jpg',root/'references/folk-photos-2026-10-18/donkey-road-original.jpg')
(out/'donkey.jpg').write_bytes(payload)
catalog=json.loads((out/'catalog.json').read_text(encoding='utf-8'))
catalog['photos']['donkey']=dict(file='res://assets/references/folk/donkey.jpg',title='负载毛驴实拍 · 驮具与布囊对照',source=info['descriptionurl'],download=url,author=clean('Artist'),license='CC0',license_url=clean('LicenseUrl'),description=clean('ImageDescription'),sha256=hashlib.sha256(payload).hexdigest(),use='驮运动物与驮具对照，不称剧中毛驴原物。')
(out/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 游戏实物照片来源与署名','照片仅作对应工艺或器型参照；地区、馆藏和作者见各条目。外国器型不标为剧中民族原物。','']
for r in catalog['photos'].values(): lines += [f"- {r['title']} — {r['author']} — {r['license']}",f"  来源：{r['source']}",f"  授权：{r.get('license_url','')}，本地文件：{r['file']}",'']
(out/'CREDITS.md').write_text('\n'.join(lines),encoding='utf-8')
print('DONKEY_CLOSE_PHOTO_READY')
