"""Download selected, attributed real-object photographs for the in-game reference tab."""
from pathlib import Path
import urllib.request, urllib.parse, json, re, hashlib, time, concurrent.futures

root=Path(__file__).resolve().parents[1]
out=root/'assets/references/folk'
out.mkdir(parents=True,exist_ok=True)
spec={
 'bai':('Bai fabric, tie-dyed - Yunnan Provincial Museum - DSC02211.JPG','白族扎染布 · 云南省博物馆'),
 'batik':('Miao batik 苗族蜡染, Guizhou, 2016 (52410712522).jpg','贵州苗族蜡染实物'),
 'brocade':('Dai brocade - Yunnan Provincial Museum - DSC02009.JPG','傣锦 · 云南省博物馆'),
 'basket':('Shengzhou Bamboo Weaving Basket in Zhejiang Provincial Museum 2014-04.JPG','嵊州竹编提篮 · 浙江省博物馆'),
 'carrier':('Batik baby carrier, Hmong - Vietnam Museum of Ethnology - Hanoi, Vietnam - DSC03042.JPG','赫蒙族蜡染背婴布 · 越南民族学博物馆'),
 'pack':('PackSaddleUSA.jpg','木质驮鞍 · 美国器型对照'),
 'hoe':('Hoes, Warring States period, Jingzhou Museum1.jpg','战国铁锄与铁插 · 荆州博物馆（农具对照）'),
 'joinery':('Examples of Wood Joints.jpg','木作榫接实物 · 连接方式对照'),
 'knife':('Billhooks - দা - DSC00576.jpg','孟加拉国钩形柴刀 · 器型对照'),
 'tea':('Longshan Culture Black Pottery (10126003864).jpg','龙山文化黑陶器 · 山东博物馆（陶色与器型对照）'),
 'brazier':('Brazier, China, Qing dynasty, 1880-199 AD, metal - Spurlock Museum, UIUC - DSC06063.jpg','清代金属火盆 · 斯珀洛克博物馆'),
 'pouch':('Object from Tibet 3.jpg','藏地火镰袋 · 取火器对照'),
 'chisel':('Stonemason reaching for tools.jpg','石匠錾凿作业实拍 · 工具使用对照'),
 'bell':('Liao Bronze Horse Bell (9834270546).jpg','辽代铜马铃 · 中国国家博物馆'),
 'cord':('Chinese knot.JPG','红绳中国结 · 编结实物对照'),
 'donkey':('Donkey Kart Turpan, China - panoramio.jpg','吐鲁番驴车 · 畜力运输对照'),
 'loom':('Loom - Yunnan Nationalities Museum - DSC04094.JPG','纳西族织机 · 云南民族博物馆'),
}
headers={'User-Agent':'CuanGameArtResearch/1.0 (local educational game)'}
def get(url):
    for attempt in range(5):
        try: return urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=40).read()
        except Exception:
            if attempt==4: raise
            time.sleep(3*(attempt+1))
cache=root/'references/folk-photos-2026-10-18/selected-metadata.json'
if cache.exists(): metadata=json.loads(cache.read_text(encoding='utf-8'))
else:
    params=dict(action='query',format='json',titles='|'.join('File:'+v[0] for v in spec.values()),prop='imageinfo',iiprop='url|extmetadata',iiurlwidth=1280)
    metadata=json.loads(get('https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(params)))
    cache.write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
pages={page['title']:page for page in metadata['query']['pages'].values()}
records={}
def download(item):
    key,(filename,caption)=item
    page=pages['File:'+filename]
    info=page['imageinfo'][0]; meta=info['extmetadata']
    clean=lambda field: re.sub('<[^>]+>','',str(meta.get(field,{}).get('value',''))).strip()
    license=clean('LicenseShortName')
    assert license in ['CC0','Public domain','CC BY-SA 2.0','CC BY-SA 3.0','CC BY-SA 4.0','CC BY 4.0'],(key,license)
    url=info.get('thumburl',info['url']).split('?')[0]
    target=out/(key+'.jpg')
    if not target.exists(): target.write_bytes(get(url))
    payload=target.read_bytes()
    assert payload[:2]==b'\xff\xd8' or payload[:8]==b'\x89PNG\r\n\x1a\n',(key,'not a photo file')
    record=dict(file='res://assets/references/folk/'+target.name,title=caption,
        source=info['descriptionurl'],download=url,author=clean('Artist'),license=license,
        license_url=clean('LicenseUrl'),description=clean('ImageDescription'),sha256=hashlib.sha256(payload).hexdigest(),
        use='实物照片作工艺/器型对照；不称剧中角色原物，不据照片推断未标明民族。')
    return key,record
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    for future in concurrent.futures.as_completed([pool.submit(download,item) for item in spec.items()]):
        key,record=future.result(); records[key]=record
        print(key,record['license'],flush=True)
records['brush']=dict(file='res://assets/references/bamboo_brush_holder_met.jpg',title='张希黄竹刻笔筒 · 大都会艺术博物馆',source='https://www.metmuseum.org/art/collection/search/39625',author='The Metropolitan Museum of Art',license='Public Domain',license_url='https://www.metmuseum.org/policies/image-resources',region=[720,850,1560,2260])
items={
 'bai_tiedye':['bai'], 'yang_trade_goods':['basket'], 'scholar_tools':['brush'],
 'caravan_pack':['pack','bell'], 'miao_batik':['batik','carrier'], 'dai_brocade':['brocade'],
 'shared_tea':['tea','brazier'], 'cloth_loom':['loom'], 'a_cai_hoe':['hoe'],
 'a_cai_basket':['basket'], 'baby_carrier':['carrier'], 'a_qiang_beam':['joinery'],
 'a_qiang_knife':['knife'], 'tea_jar':['tea'], 'fire_basin':['brazier'], 'flint_pouch':['pouch'],
 'yu_nan_brocade':['brocade'], 'donkey':['donkey'], 'garden_item_1':['chisel'],
 'garden_item_2':['bell'], 'garden_item_3':['cord'],
}
(out/'catalog.json').write_text(json.dumps(dict(photos=records,items=items),ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 游戏实物照片来源与署名','照片仅作对应工艺或器型参照；实际物品的地区、馆藏和作者见下列条目。外国器型不会标为剧中民族原物。','']
for key,r in records.items():
    lines += [f"- {r['title']} — {r['author']} — {r['license']}",f"  来源：{r['source']}",f"  授权：{r.get('license_url','')}，本地文件：{r['file']}", '']
(out/'CREDITS.md').write_text('\n'.join(lines),encoding='utf-8')
print('FOLK_PHOTOS_READY',len(records),'photos',len(items),'objects')
