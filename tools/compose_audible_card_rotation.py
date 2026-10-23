from pathlib import Path
import json,hashlib,wave
import numpy as np

root=Path(__file__).resolve().parents[1]/'assets/audio/card_rotation_audit_20261020'
root.mkdir(parents=True,exist_ok=True)
sr=44100
rng=np.random.default_rng(20261020)
records=[]
for name,duration in [('rotation',1.0),('settle',.28)]:
    n=round(sr*duration);t=np.arange(n)/sr
    f=np.fft.rfftfreq(n,1/sr)
    noise=rng.normal(0,1,n)
    band=np.fft.irfft(np.fft.rfft(noise)*(f>650)*(f<4400),n)
    band=np.tanh(band*2.4)
    if name=='rotation':
        envelope=.65+.23*np.sin(2*np.pi*8*t)+.09*np.sin(2*np.pi*16*t)
        y=band*envelope
        for onset in np.arange(0,1,.125):
            dt=np.mod(t-onset,1)
            y+=.45*np.sin(2*np.pi*1850*dt)*np.exp(-dt*260)
        y=np.column_stack([y,np.roll(y,27)])
        # Circular crossfade; no click at the one-second loop boundary.
        k=300;fade=np.linspace(0,1,k)[:,None]
        seam=y[-k:]*(1-fade)+y[:k]*fade
        y[:k]=seam;y[-k:]=seam
        y*=.64/abs(y).max()
    else:
        y=(band*.50+.25*np.sin(2*np.pi*1650*t))*np.exp(-t*25)*np.minimum(1,t/.002)
        y=np.column_stack([y,y]);y*=.64/abs(y).max()
    path=root/(name+'.wav')
    with wave.open(str(path),'wb') as out:
        out.setparams((2,2,sr,0,'NONE','not compressed'));out.writeframes((y*32767).astype('<i2').tobytes())
    records.append(dict(file=path.name,seconds=duration,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),rms_dbfs=float(20*np.log10(np.sqrt(np.mean(y*y)))),peak_dbfs=float(20*np.log10(abs(y).max()))))
(root/'SOURCE.json').write_text(json.dumps(dict(origin='Original procedural paper air and wooden catches, no recorded samples; full PCM import and frame-accurate loop.',effects=records),indent=2),encoding='utf8')
print('AUDIBLE_ROTATION_CREATED',records)
