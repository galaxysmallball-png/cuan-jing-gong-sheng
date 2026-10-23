from pathlib import Path
import hashlib,json,shutil,zipfile

root=Path(__file__).resolve().parents[1]
base=root/'builds/scroll-guidance-correction-2026-10-22'
target=root/'previews/scroll-guidance-android-assets-20261022'
target.mkdir(parents=True,exist_ok=True)
(target/'.gdignore').touch()
with zipfile.ZipFile(base/'Android/CuanJingGongSheng.apk') as archive:
    assert archive.testzip() is None,'APK CRC error'
    for entry in archive.infolist():
        if not entry.filename.startswith('assets/') or entry.is_dir():continue
        relative=Path(entry.filename[len('assets/'):])
        assert not relative.is_absolute() and '..' not in relative.parts
        output=target/relative
        assert output.resolve().is_relative_to(target.resolve())
        output.parent.mkdir(parents=True,exist_ok=True)
        with archive.open(entry) as src,output.open('wb') as dest:shutil.copyfileobj(src,dest,1024*1024)
    records=[]
    for name in ['icon','icon_foreground','icon_background','icon_monochrome']:
        data=archive.read('res/mipmap-xxxhdpi-v4/'+name+'.webp')
        extension='.png' if data.startswith(b'\x89PNG') else '.webp'
        file='launcher-'+name+extension
        (base/'Android'/file).write_bytes(data)
        records.append(dict(name=name,file=file,bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
(base/'Android/launcher-assets.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('APK_RUNTIME_ASSETS_AND_FOUR_LAUNCHER_VARIANTS_EXTRACTED')
