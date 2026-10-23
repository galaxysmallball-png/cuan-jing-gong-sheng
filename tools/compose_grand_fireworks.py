"""Original procedural firework foley; no recorded or third-party samples."""
from pathlib import Path
import hashlib,json,wave
import numpy as np

out=Path(__file__).resolve().parents[1]/'assets/audio/grand_fireworks_20261021'
out.mkdir(parents=True,exist_ok=True)
sr=44100
rng=np.random.default_rng(2026102119)

def noise(n,lo,hi):
    f=np.fft.rfftfreq(n,1/sr)
    shape=(1-np.exp(-(f/max(lo,1))**4))*np.exp(-(f/hi)**4)
    y=np.fft.irfft(np.fft.rfft(rng.normal(size=n))*shape,n)
    return y/max(float(np.std(y)),1e-6)

def save(name,y):
    # Short soft saturation leaves room for overlapping shells in the game.
    y=np.tanh(y*1.05)
    y*=.70/max(float(np.max(np.abs(y))),1e-6)
    y[-900:]*=np.linspace(1,0,900)[:,None]
    path=out/(name+'.wav')
    with wave.open(str(path),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(sr)
        w.writeframes((y*32767).astype('<i2').tobytes())
    return dict(file=path.name,seconds=len(y)/sr,peak=float(np.max(np.abs(y))),rms=float(np.sqrt(np.mean(y*y))),sha256=hashlib.sha256(path.read_bytes()).hexdigest())

t=np.arange(int(.78*sr))/sr
n=len(t)
envelope=np.sin(np.clip(t/.73,0,1)*np.pi)**.8
hiss=noise(n,600,6700)*envelope*.30
jet=noise(n,130,1300)*envelope*.16
whistle=np.sin(2*np.pi*(1150*t+520*t*t))*envelope*.018
launch=hiss+jet+whistle
launch[:1400]+=noise(1400,90,3200)*np.exp(-np.arange(1400)/360)*.45
stereo=np.column_stack([launch,np.roll(launch,37)*.94+noise(n,1100,7000)*envelope*.025])
records=[save('firework_launch',stereo)]

t=np.arange(int(2.85*sr))/sr
n=len(t)
snap=noise(n,400,12500)*np.exp(-t/ .012)*1.15
thump=noise(n,24,230)*np.exp(-t/.19)*.49
pressure=(np.sin(2*np.pi*(57*t-7*t*t))*.28+np.sin(2*np.pi*103*t)*.13)*np.exp(-t/.16)
roar=noise(n,120,5200)*np.exp(-t/.36)*.18
mono=(snap+thump+pressure+roar)*np.minimum(1,t/.0005)
stereo=np.column_stack([mono,np.roll(mono,19)*.96])
for i in range(64):
    when=float(rng.uniform(.10,2.5));duration=float(rng.uniform(.009,.050))
    k=int(when*sr);count=min(int(duration*sr),n-k)
    tt=np.arange(count)/sr
    crack=noise(count,500,10500)*np.exp(-tt/(duration*.16))
    crack*=float(rng.uniform(.025,.14))*np.exp(-when/.95)
    pan=float(rng.uniform(.12,.88))
    stereo[k:k+count,0]+=crack*np.sqrt(1-pan)
    stereo[k:k+count,1]+=crack*np.sqrt(pan)
dry=stereo.copy()
for delay,gain in [(.093,.13),(.171,.105),(.287,.080),(.449,.050),(.673,.026)]:
    offset=int(delay*sr)
    stereo[offset:]+=dry[:-offset,::-1]*gain
records.append(save('firework_burst',stereo))
(out/'SOURCE.txt').write_text('原创程序合成烟花拟音，未使用外部录音或采样。升空：喷气、火药嘶鸣；绽放：瞬态炸响、低频冲击、空间回声和分散噼啪尾音。游戏烟花专用音量提高5 dB，仍服从玩家音量与静音设置。非实地录音。\n',encoding='utf-8')
(out/'SOURCE.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(records,ensure_ascii=False))
