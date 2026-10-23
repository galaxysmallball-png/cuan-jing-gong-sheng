from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib, io, json, urllib.request, zipfile, http.client
from concurrent.futures import as_completed

workspace=Path(__file__).resolve().parents[3]
tools=workspace/'数媒/.tools'
cache=tools/'android/downloads'
cache.mkdir(parents=True,exist_ok=True)

def read_range(url,start,end):
    parts=[]
    cursor=start
    attempts=0
    while cursor<=end:
        limit=min(cursor+1024*1024-1,end)
        request=urllib.request.Request(url,headers={'User-Agent':'CuanGameBuild/1.0','Range':f'bytes={cursor}-{limit}'})
        try:
            with urllib.request.urlopen(request,timeout=45) as response:
                assert response.status==206 and response.headers['Content-Range'].startswith(f'bytes {cursor}-')
                try:data=response.read()
                except http.client.IncompleteRead as error:data=error.partial
                if not data:raise RuntimeError('Empty range')
                parts.append(data)
                cursor+=len(data)
        except Exception:
            attempts+=1
            if attempts>15:raise
    return b''.join(parts)

class RemoteZip(io.RawIOBase):
    def __init__(self,url):
        self.url=url
        request=urllib.request.Request(url,headers={'Range':'bytes=0-0','User-Agent':'CuanGameBuild/1.0'})
        with urllib.request.urlopen(request,timeout=45) as response:
            self.size=int(response.headers['Content-Range'].split('/')[-1])
        self.position=0
    def seekable(self):return True
    def tell(self):return self.position
    def seek(self,offset,whence=0):
        self.position=offset if whence==0 else self.position+offset if whence==1 else self.size+offset
        return self.position
    def read(self,n=-1):
        if n<0:n=self.size-self.position
        end=min(self.size,self.position+n)
        jobs=[(start,min(start+4*1024*1024,end)-1) for start in range(self.position,end,4*1024*1024)]
        with ThreadPoolExecutor(max_workers=4) as pool:
            chunks=list(pool.map(lambda pair:read_range(self.url,*pair),jobs))
        self.position=end
        return b''.join(chunks)

def fetch(name,url,sha):
    path=cache/name
    remote=RemoteZip(url)
    print(f'{name}: {remote.size//1024//1024} MiB total',flush=True)
    with path.open('wb') as out:
        for start in range(0,remote.size,4*1024*1024):
            out.write(read_range(url,start,min(start+4*1024*1024,remote.size)-1))
    assert hashlib.sha256(path.read_bytes()).hexdigest()==sha,name+' checksum mismatch'
    return path

jobs=[('commandlinetools.zip','https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip','90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'),
      ('godot-4.7.2-templates.tpz','https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz','f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011')]
paths=[fetch(*jobs[0])]
sdk=tools/'android/sdk'
with zipfile.ZipFile(paths[0]) as archive:
    for entry in archive.infolist():
        if entry.filename.endswith('/'):continue
        relative=Path(entry.filename).relative_to('cmdline-tools')
        dest=sdk/'cmdline-tools/latest'/relative
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(archive.read(entry))
templates=tools/'godot/4.7.2/editor_data/export_templates/4.7.2.stable'
with zipfile.ZipFile(RemoteZip(jobs[1][1])) as archive:
    for name in ['android_debug.apk','android_release.apk']:
        entry=next(item for item in archive.namelist() if item.endswith('/'+name))
        payload=archive.read(entry)
        (templates/name).write_bytes(payload)
        print(name+': ZIP CRC checked, '+str(len(payload))+' bytes',flush=True)
(tools/'android/download-sources.json').write_text(json.dumps(jobs,indent=2),encoding='utf-8')
print('ANDROID_SDK_HASH_AND_TEMPLATE_ZIP_CRC_VERIFIED',flush=True)
