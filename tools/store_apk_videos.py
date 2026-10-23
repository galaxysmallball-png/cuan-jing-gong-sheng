from pathlib import Path
import copy,shutil,sys,zipfile

# Android can stream Theora directly from an uncompressed APK asset. Preserve
# every entry's bytes, while removing the old signature before zipalign/signing.
source=Path(sys.argv[1])
target=Path(sys.argv[2])
stored=[]
with zipfile.ZipFile(source) as incoming,zipfile.ZipFile(target,'w',allowZip64=False) as outgoing:
    for item in incoming.infolist():
        upper=item.filename.upper()
        if upper.startswith('META-INF/') and (upper.endswith(('.SF','.RSA','.DSA','.EC')) or upper=='META-INF/MANIFEST.MF'):continue
        out_item=copy.copy(item)
        if item.filename.lower().endswith('.ogv'):
            out_item.compress_type=zipfile.ZIP_STORED
            stored.append(item.filename)
        with incoming.open(item) as read,outgoing.open(out_item,'w') as write:
            shutil.copyfileobj(read,write,1024*1024)
assert len(stored)==5,'Expected all five supplied films'
print('APK_VIDEO_STORAGE_OK: five byte-preserved, directly streamable video assets')
