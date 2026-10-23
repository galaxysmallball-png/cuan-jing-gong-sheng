"""Original airy card-ring rotation: no recorded samples or pitched music notes."""
import hashlib,json,wave
from pathlib import Path
import numpy as np
root=Path(__file__).resolve().parents[1]/'assets/audio/card_rotation_20261020'
root.mkdir(parents=True,exist_ok=True)
sr=44100
rng=np.random.default_rng(20261020)
records=[]
for name,duration in [('rotation',1.0),('settle',.28)]:
    n=int(sr*duration); t=np.arange(n)/sr
    noise=rng.normal(0,1,n)
    # Remove bass; a paper-like band between 900 Hz and 6 kHz avoids a buzzy hum.
    f=np.fft.rfftfreq(n,1/sr)
    band=np.fft.irfft(np.fft.rfft(noise)*(f>900)*(f<6000),n)
    if name=='rotation':
        envelope=.65+.22*np.sin(2*np.pi*8*t)+.12*np.sin(2*np.pi*16*t)
        sound=band*envelope
        # Short wooden catches accompany passage, without melodic bleeps.
        for onset in np.arange(0,1,.125):
            dt=np.mod(t-onset,1)
            sound+=.18*np.sin(2*np.pi*2100*dt)*np.exp(-dt*700)
        sound=np.column_stack([sound*(.82+.18*np.sin(2*np.pi*t)),np.roll(sound,31)*(.82-.18*np.sin(2*np.pi*t))])
        # The loop is periodic; close its seam with a short circular crossfade.
        k=256; fade=np.linspace(0,1,k)[:,None]
        seam=sound[-k:]*(1-fade)+sound[:k]*fade
        sound[:k]=seam; sound[-k:]=seam
    else:
        sound=(band*.28+np.sin(2*np.pi*1750*t)*.12)*np.exp(-t*39)
        sound*=np.minimum(1,t/.002)
        sound=np.column_stack([sound,sound])
    sound*=.48/max(abs(sound).max(),1e-8)
    pcm=(sound*32767).astype('<i2')
    path=root/(name+'.wav')
    with wave.open(str(path),'wb') as out:
        out.setparams((2,2,sr,0,'NONE','not compressed'));out.writeframes(pcm.tobytes())
    records.append(dict(file=path.name,seconds=duration,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),peak_dbfs=float(20*np.log10(abs(sound).max())),rms_dbfs=float(20*np.log10(np.sqrt(np.mean(sound**2))))))
(root/'SOURCE.json').write_text(json.dumps(dict(origin='Original procedural paper air and wood catches; no external recordings.',rate=sr,effects=records),indent=2),encoding='utf8')
print('CARD_ROTATION_AUDIO_CREATED',len(records))
