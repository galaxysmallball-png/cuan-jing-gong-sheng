"""Read-only Commons search and image rights metadata; cache for art selection."""
from pathlib import Path
import json, urllib.request, urllib.parse, concurrent.futures, re, time

root = Path(__file__).resolve().parents[1]
cache = root/'references/folk-photos-2026-10-18'
cache.mkdir(parents=True,exist_ok=True)
(cache/'.gdignore').touch()
queries = {
    'pack3':'incategory:"Pack saddles" filetype:bitmap',
    'hoe3':'incategory:"Hoes" filetype:bitmap',
    'knife3':'incategory:"Billhooks" filetype:bitmap',
    'chisel3':'intitle:"Stonemason" intitle:"tools" filetype:bitmap',
    'donkey3':'incategory:"Pack donkeys" filetype:bitmap',
}
def run(item):
    key,query = item
    path = cache/(key+'.json')
    if path.exists(): data=json.loads(path.read_text(encoding='utf-8'))
    else:
        args=dict(action='query',format='json',generator='search',gsrsearch=query,gsrnamespace=6,gsrlimit=5,prop='imageinfo',iiprop='url|extmetadata',iiurlwidth=1200)
        request=urllib.request.Request('https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(args),headers={'User-Agent':'CuanGameArtResearch/1.0 (educational local game)'})
        for attempt in range(5):
            try:
                data=json.load(urllib.request.urlopen(request,timeout=35)); break
            except Exception:
                if attempt==4: raise
                time.sleep(3*(attempt+1))
        path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    rows=[]
    for page in data.get('query',{}).get('pages',{}).values():
        info=page.get('imageinfo',[{}])[0]; meta=info.get('extmetadata',{})
        clean=lambda name: re.sub('<[^>]+>','',meta.get(name,{}).get('value',''))
        rows.append(dict(title=page['title'],description=clean('ImageDescription')[:155],license=clean('LicenseShortName'),author=clean('Artist')[:80]))
    return key,rows
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    for future in concurrent.futures.as_completed([pool.submit(run,item) for item in queries.items()]):
        try: print(json.dumps(future.result(),ensure_ascii=True),flush=True)
        except Exception as error: print(type(error).__name__,str(error),flush=True)
