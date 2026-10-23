"""Editable mesh recipes for the three supporting villagers (coordinates x,height,front)."""
import math
from mathutils import Vector


def initialize(ns):
    globals().update(ns)


def box(name,center,size,mat,joint='spine',bevel=.004):
    x,h,f=center;rx,rh,rf=[v/2 for v in size]
    pts=[(x+a*rx,h+b*rh,f+c*rf) for a,b,c in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    obj=mesh(name,pts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],mat,joint)
    if bevel:
        bpy.context.view_layer.objects.active=obj;obj.select_set(True)
        mod=obj.modifiers.new('RoundedEdges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def ellipse(name,cx,h,cf,rx,rf,radius,mat,joint='spine'):
    curve(name,[(cx+rx*math.cos(t),h,cf+rf*math.sin(t)) for t in [math.tau*j/64 for j in range(65)]],radius,mat,joint)


def disk_flower(name,x,h,f,size,mat,joint='spine'):
    for k in range(6):
        a=math.tau*k/6
        curve(name,[(x+size*(.36*math.cos(t)+.56*math.cos(a)),h+size*(.36*math.sin(t)+.56*math.sin(a)),f) for t in [math.tau*j/16 for j in range(17)]],.0012,mat,joint)


def hair_back():
    pts=[]
    for h,rx,rf in [(1.44,.055,.042),(1.51,.088,.078),(1.60,.101,.084),(1.67,.093,.077)]:
        for j in range(49):
            a=-math.pi/2+math.pi*j/48;pts.append((rx*math.sin(a),h,-.005-rf*math.cos(a)))
    obj=mesh('RearHairCap',pts,[(r*49+j,r*49+j+1,(r+1)*49+j+1,(r+1)*49+j) for r in range(3) for j in range(48)],mats['Hair'],'head')
    solidify(obj,.004)


def sash(red=True):
    mat=mats['Red'] if red else mats['Dark']
    loft('WaistWrap',[(.92,.145,.097,0,0),(.973,.14,.094,0,0)],mat,'hips',64,.01)
    for row in range(5):ellipse('WaistFold',0,.926+row*.009,0,.146,.099,.002,mats['RedLight'] if red else mats['Gold'],'hips')
    sphere('WaistKnot',(-.025,.947,.104),(.026,.023,.019),mat,'hips')
    for side in [-1,1]:
        ribbon('TiedWaistTail',[(-.025,.944,.119),(side*.04,.81,.123),(side*.055,.66,.13)],.044,mat,'sash')
        for j in range(7):curve('WaistFringe',[(side*.055+(j-3)*.005,.662,.131),(side*.055+(j-3)*.005,.642-rng.random()*.01,.132)],.0008,mat,'sash')


def arms(shoulders,elbows,wrists,hands,cuffs='Linen',sleeve=True,bracelet=False,grip='L'):
    for side,suffix in [(-1,'L'),(1,'R')]:
        shoulder,elbow,wrist,hand=[d[suffix] for d in [shoulders,elbows,wrists,hands]]
        if sleeve:
            sphere('RoundedShoulder.'+suffix,shoulder,(.063,.045,.060),mats['Robe'],'upper_arm.'+suffix,32,20)
            tube('UpperSleeve.'+suffix,shoulder,elbow,.062,.054,mats['Robe'],'upper_arm.'+suffix,40,.025)
            end=tuple(Vector(elbow).lerp(Vector(wrist),.18 if CFG['key']=='a_qiang' else .42))
            tube('TurnedCuff.'+suffix,elbow,end,.058,.053,mats[cuffs],'forearm.'+suffix,40,.015)
            if CFG['key']=='pu_mo':
                for t in [.25,.65]:
                    at=Vector(elbow).lerp(Vector(end),t)
                    # Narrow coloured bindings around the cuff's actual surface.
                    a,b=p(elbow),p(end);axis=(b-a).normalized();u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u)
                    radius=(.058*(1-t)+.053*t)*(1+.09*math.sin(t*math.pi))+.0014
                    curve('ThreeColourCuff',[(q.x,q.z,-q.y) for q in [p(tuple(at))+(u*math.cos(math.tau*j/64)+v*math.sin(math.tau*j/64))*radius for j in range(65)]],.0017,mats['Red'] if t<.5 else mats['Gold'],'forearm.'+suffix)
        else:end=elbow
        tube('Forearm.'+suffix,end,wrist,.032,.022,mats['Skin'],'forearm.'+suffix,32)
        tube('Wrist.'+suffix,wrist,hand,.022,.024,mats['Skin'],'hand.'+suffix,28)
        sphere('Palm.'+suffix,hand,(.027,.037,.022),mats['Skin'],'hand.'+suffix,28,18)
        x,h,f=hand
        for j in range(4):
            if suffix==grip:
                xx=x+(j-1.5)*.013
                if CFG['key']=='a_qiang':path=[(xx,h-.014,f+.017),(xx,h+.015,f+.025),(xx,h+.026,f+.005),(xx,h+.015,f-.016)]
                else:path=[(x-.019,h+.018-j*.012,f),(x-.012,h+.017-j*.012,f+.027),(x+.014,h+.014-j*.012,f+.018)]
            else:
                xx=x+(j-1.5)*.011;path=[(xx,h-.01,f+.01),(xx,h-.036,f+.017),(xx-.003,h-.043,f+.007)]
            curve('Fingers.'+suffix,path,.0058,mats['Skin'],'hand.'+suffix)
        curve('Thumb.'+suffix,[(x-side*.022,h+.018,f),(x-side*.029,h,f+.019),(x-side*.012,h-.011,f+.024)],.007,mats['Skin'],'hand.'+suffix)
        if bracelet:
            # Bracelet ring lies perpendicular to the actual forearm axis.
            center=p(wrist);direction=(p(wrist)-p(elbow)).normalized();u=direction.cross(Vector((0,1,0))).normalized();v=direction.cross(u)
            path=[]
            for j in range(65):
                q=center+(u*math.cos(math.tau*j/64)+v*math.sin(math.tau*j/64))*.026;path.append((q.x,q.z,-q.y))
            curve('SilverBracelet',path,.003,mats['Silver'],'forearm.'+suffix)


def sandals(short_pants=False):
    for side,suffix in [(-1,'L'),(1,'R')]:
        x=side*.087
        if short_pants:
            loft('LooseBreeches.'+suffix,[(.38,.053,.052,x,0),(.44,.073,.066,x,0),(.58,.090,.077,x,0),(.78,.087,.074,x,0),(.93,.068,.061,x,0)],mats['Dark'],'thigh.'+suffix,64,.04)
            for h in [.381,.396,.413]:loft('RolledTrouserCuff',[(h,.059,.056,x,0),(h+.012,.06,.057,x,0)],mats['Linen'],'thigh.'+suffix,48,.008)
        loft('Calf.'+suffix,[(.105,.025,.026,x,0),(.23,.035,.035,x,0),(.39,.043,.041,x,0)],mats['Skin'],'shin.'+suffix,40)
        sphere('BareFoot.'+suffix,(x,.063,.05),(.038,.034,.083),mats['Skin'],'foot.'+suffix,28,16)
        sphere('StrawSole.'+suffix,(x,.029,.042),(.047,.015,.104),mats['BambooDark'],'foot.'+suffix,32,16)
        for toe in range(5):sphere('Toe',(x+(toe-2)*.013,.055,.122-abs(toe-1)*.004),(.008,.012,.015),mats['Skin'],'foot.'+suffix,12,8)
        for row in range(19):
            f=-.044+row*.01;w=.043*math.sqrt(max(.01,1-((f-.042)/.106)**2))
            curve('WovenSandal',[(x-w,.041,f),(x,.044,f+.002),(x+w,.041,f)],.002,mats['BambooLight'],'foot.'+suffix)
        for sign in [-1,1]:
            curve('StrawCrossTie',[(x+sign*.04,.043,.085),(x-sign*.025,.088,.045),(x-sign*.037,.043,.005)],.004,mats['Rope'],'foot.'+suffix)
            curve('AnkleLacing',[(x+sign*.034,.05,-.02),(x+sign*.029,.115,0),(x-sign*.029,.124,.009)],.0027,mats['Rope'],'shin.'+suffix)
        ellipse('AnkleCord',x,.124,0,.029,.031,.0025,mats['Rope'],'shin.'+suffix)


def cloth_shoes(red=False):
    for side,suffix in [(-1,'L'),(1,'R')]:
        x=side*.084
        loft('Ankle',[(.065,.024,.025,x,0),(.27,.029,.028,x,0)],mats['Skin'],'shin.'+suffix,32)
        sphere('ClothShoe',(x,.069,.046),(.042,.041,.098),mats['Red'] if red else mats['Dark'],'foot.'+suffix,32,20)
        sphere('ShoeSole',(x,.028,.046),(.045,.012,.102),mats['BambooDark'],'foot.'+suffix,32,16)
        # Top opening around the ankle and a light seam along the sole.
        ellipse('ShoeOpening',x,.092,.006,.026,.035,.0023,mats['Silver'] if red else mats['Gold'],'foot.'+suffix)
        ellipse('ShoeSeam',x,.035,.046,.042,.096,.0013,mats['Linen'],'foot.'+suffix)
        if red:
            for k in range(6):
                a=math.tau*k/6
                sphere('ShoePetal',(x+.014*math.cos(a),.096,.105+.014*math.sin(a)),(.008,.002,.004),mats['Linen'],'foot.'+suffix,14,8)
            sphere('ShoeFlowerCenter',(x,.099,.105),(.005,.003,.005),mats['Gold'],'foot.'+suffix,14,8)
        else:
            for f in [.015,.045]:curve('ClothShoeLacing',[(x-.032,.085,f),(x,.11,f+.012),(x+.032,.085,f)],.002,mats['Rope'],'foot.'+suffix)


def skirt_weights(obj):
    for v in obj.data.vertices:
        x,h,f=v.co.x,v.co.z,-v.co.y
        hip=max(0,min(1,(h-.68)/.25));back=max(0,min(1,(-.005-f)/.08));right=max(0,min(1,.5+x/.14))
        for group in obj.vertex_groups:group.remove([v.index])
        for name,w in [('hips',hip),('skirt.back',(1-hip)*back),('skirt.L',(1-hip)*(1-back)*(1-right)),('skirt.R',(1-hip)*(1-back)*right)]:
            if w:(obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)).add([v.index],w,'REPLACE')


def build_a_qiang():
    hair_back()
    loft('TousledHairCap',[(1.61,.094,.079,0,0),(1.69,.104,.085,0,0),(1.73,.063,.056,0,0),(1.738,.01,.01,0,0)],mats['Hair'],'head',64,.025)
    for i in range(110):
        a=rng.random()*math.tau;rad=math.sqrt(rng.random());x=.099*rad*math.cos(a);f=.082*rad*math.sin(a);h=1.657+.073*math.sqrt(max(0,1-rad*rad))
        curve('TousledHairLock',[(x,h,f),(x+.018*math.cos(a+.4),h+.014,f+.017*math.sin(a+.4)),(x+.027*math.cos(a+.6),h+.008,f+.024*math.sin(a+.6))],.004,mats['HairLight'] if i%9==0 else mats['Hair'],'head',[.8,1,.02])
    for side in [-1,1]:
        for j in range(9):
            x=side*(.01+j*.01)
            curve('LooseForeheadHair',[(x,1.69,.052),(x+side*.008,1.66,.077),(x+side*.016,1.625+(j%3)*.006,.086)],.0035,mats['Hair'],'head',[1,.9,.02])
    loft('BlackForeheadTie',[(1.611,.100,.085,0,0),(1.643,.103,.086,0,0)],mats['Dark'],'head',80,.004)
    for h in [1.617,1.634]:ellipse('HeadTieFold',0,h,0,.102,.087,.002,mats['HairLight'],'head')
    sphere('BackTieKnot',(0,1.622,-.09),(.026,.02,.014),mats['Dark'],'head')
    for side in [-1,1]:ribbon('HeadTieTail',[(0,1.625,-.09),(side*.044,1.586,-.101),(side*.055,1.55,-.097)],.026,mats['Dark'],'headtie')
    # Bare chest with rounded torso; the indigo jacket is open down its front.
    loft('BareTorso',[(.94,.128,.077,0,0),(1.08,.139,.085,0,0),(1.22,.149,.09,0,0),(1.30,.139,.071,0,-.002),(1.34,.049,.039,0,0)],mats['Skin'],'spine',64,.002)
    pts=[];count=80
    for h,rx,rf in [(.79,.159,.101),(.94,.142,.093),(1.13,.151,.097),(1.28,.163,.085),(1.32,.085,.059)]:
        for j in range(count+1):
            a=math.pi/2+.31+(math.tau-.62)*j/count;pts.append((rx*math.cos(a),h,rf*math.sin(a)))
    jacket=mesh('OpenIndigoShortJacket',pts,[(r*(count+1)+j,r*(count+1)+j+1,(r+1)*(count+1)+j+1,(r+1)*(count+1)+j) for r in range(4) for j in range(count)],mats['Robe'],'spine',dust=True);solidify(jacket,.004)
    for side in [-1,1]:
        path=[(side*.052,1.317,.055),(side*.053,1.27,.081),(side*.047,1.13,.095),(side*.043,.95,.093),(side*.05,.80,.099)]
        curve('JacketFrontBinding',path,.003,mats['Edge'],'spine')
        for row in range(5):
            h=1.04+row*.045
            curve('ClothFrogButton',[(side*.055,h,.099),(side*.032,h,.102),(side*.03,h+.008,.103),(side*.05,h+.01,.10)],.0027,mats['Linen'],'spine')
            sphere('FrogKnot',(side*.03,h,.102),(.004,.005,.004),mats['Dark'],'spine',12,8)
    for side in [-1,1]:curve('ChestClavicle',[(0,1.27,.077),(side*.035,1.266,.087),(side*.072,1.282,.068)],.0012,mats['Crease'],'spine',[.1,.7,.05])
    shoulders={'L':(-.146,1.285,0),'R':(.146,1.285,0)}
    elbows={'L':(-.282,1.08,.016),'R':(.237,1.049,.014)}
    wrists={'L':(-.305,1.389,.017),'R':(.267,.865,.046)}
    hands={'L':(-.305,1.425,.01),'R':(.27,.824,.058)}
    arms(shoulders,elbows,wrists,hands,grip='L');sandals(True);sash()
    # Timber is a real bevelled beam. The end sockets are built from four rails,
    # leaving a visible mortise recess instead of drawing a black square on it.
    box('ShoulderFirBeam',(0,1.352,-.05),(.86,.125,.11),mats['Wood'],'beam',.008)
    for side in [-1,1]:
        cx=side*.443
        for h in [1.307,1.397]:box('MortiseTopBottom',(cx,h,-.05),(.048,.025,.115),mats['WoodLight'],'beam',.002)
        for f in [-.094,-.006]:box('MortiseSideRail',(cx,1.352,f),(.048,.067,.023),mats['Wood'],'beam',.002)
        box('MortiseRecess',(side*.448,1.352,-.05),(.004,.058,.06),mats['WoodDark'],'beam',0)
    for row in range(17):
        h=1.3+row*.006
        curve('FirWoodGrain',[(-.42,h,.007),(-.21,h+.002*math.sin(row),.008),(0,h+.003*math.cos(row),.008),(.42,h+.001,.007)],.0008,mats['WoodLight'] if row%4==0 else mats['WoodDark'],'beam')
    for i in range(20):
        x=rng.uniform(-.38,.37);h=rng.uniform(1.30,1.4)
        curve('TimberWear',[(x,h,.008),(x+.022,h+.002,.008)],.001,mats['WoodLight'],'beam')
    # The mountain knife remains inside its wooden sheath at the right hip.
    tube('WoodenKnifeSheath',(.162,.91,-.015),(.219,.59,.01),.034,.028,mats['WoodDark'],'sheath',32)
    tube('KnifeGrip',(.161,.91,-.015),(.148,1.025,-.021),.021,.018,mats['Wood'],'sheath',28)
    sphere('KnifePommel',(.148,1.025,-.021),(.025,.017,.019),mats['Wood'],'sheath',24,14)
    for i in range(7):ellipse('SheathHempBinding',.166+i*.001,.875+i*.005,-.012,.033,.033,.002,mats['Rope'],'sheath')
    curve('SheathSuspension',[(.13,.97,.006),(.185,.89,.021),(.207,.66,.031)],.004,mats['Rope'],'sheath')
    props=[('sash',(-.025,.95,.10),(0,.66,.13),'hips'),('beam',(0,1.35,-.05),(0,1.45,-.05),'spine'),('sheath',(.16,.94,0),(.22,.6,.01),'hips'),('headtie',(0,1.62,-.09),(0,1.55,-.1),'head')]
    return shoulders,elbows,wrists,hands,props


def build_yu_nan():
    hair_back()
    crown=loft('SweptHairCrown',[(1.60,.094,.08,0,0),(1.66,.100,.087,0,-.006),(1.706,.070,.064,0,-.009),(1.72,.012,.014,0,-.01)],mats['Hair'],'head',72,.01)
    for vertex in crown.data.vertices:
        x,h,f=vertex.co.x,vertex.co.z,-vertex.co.y
        if h<1.65 and f>0:
            vertex.co.z+=.035*max(0,min(1,f/.08))*(.5+.5*x/.1)
    for j in range(10):
        t=j/9
        curve('SideSweptFrontLock',[(-.028,1.704,.047),(-.045-.025*t,1.682,.070),(-.076-.014*t,1.63,.074),(-.086,1.58+.03*t,.057)],.004,mats['HairLight'] if j%4==0 else mats['Hair'],'head',[.3,1,.8,.01])
    for j in range(9):
        t=j/8
        curve('OppositeSweptFrontLock',[(-.025,1.707,.049),(.021,1.695,.073),(.07+.012*t,1.652,.078),(.087,1.60+.035*t,.06)],.004,mats['HairLight'] if j%4==0 else mats['Hair'],'head',[.3,1,.8,.01])
    sphere('LowChignon',(.023,1.49,-.105),(.071,.057,.052),mats['Hair'],'head',40,24)
    for i in range(30):
        t=i/29
        curve('SweptHairStrand',[(-.075+t*.15,1.62,.067),(-.08+t*.11,1.69,.015),(-.07+t*.12,1.64,-.072),(.023,1.51,-.147)],.0018,mats['HairLight'],'head',[.1,.75,.8,.08])
    for side in [-1,1]:curve('LooseFaceWisp',[(side*.07,1.646,.067),(side*.085,1.59,.07),(side*.078,1.546,.075)],.002,mats['Hair'],'head',[.6,1,.02])
    for k in range(9):
        angle=math.tau*k/9
        curve('ChignonTwist',[(.023+.062*math.cos(angle+t),1.49+.046*math.sin(angle+t),-.112-.039*math.sin(t)) for t in [j*math.pi/40 for j in range(41)]],.002,mats['HairLight'],'head')
    # Golden carved wooden comb at the back of the bun, with separate teeth.
    box('WoodCombCrest',(.049,1.55,-.147),(.082,.035,.008),mats['WoodLight'],'head',.008)
    for j in range(11):box('WoodCombTooth',(.014+j*.007,1.524,-.15),(.003,.031,.006),mats['Wood'],'head',.001)
    for j in range(5):curve('CombCarvedPetal',[(.022+j*.011,1.55,-.152),(.028+j*.011,1.561,-.154),(.033+j*.011,1.55,-.154)],.0009,mats['WoodDark'],'head')
    # Pink fitted wrap blouse, with a genuine V opening at the neck.
    rows=[(.82,.145,.092,0,0),(.92,.126,.084,0,0),(1.02,.114,.078,0,0),(1.16,.127,.088,0,0),(1.26,.137,.078,0,-.002),(1.32,.066,.045,0,0)]
    blouse=loft('PinkWrapBlouse',rows,mats['Robe'],'spine',72,.012)
    for v in blouse.data.vertices:
        if v.co.z>1.26:
            f=-v.co.y;v.co.z-=.08*max(0,min(1,f/.046))*max(0,min(1,(v.co.z-1.26)/.06))
    # The central neck remains skin coloured between the two wrapped collars.
    for side in [-1,1]:
        path=[(side*.044,1.326,.044),(side*.025,1.284,.066),(-side*.01,1.22,.084),(-side*.055,1.15,.087)]
        ribbon('PaleWrapCollar',path,.016,mats['Linen'],'spine')
        curve('CollarSilverStitch',[(x,h,f+.003) for x,h,f in path],.0011,mats['Silver'],'spine')
    # Slim black wrap skirt with fitted waist and embroidered hem.
    skirt=loft('BlackTubeSkirt',[(.19,.158,.108,0,0),(.23,.166,.112,0,0),(.48,.161,.112,0,0),(.73,.15,.104,0,0),(.93,.127,.084,0,0)],mats['Dark'],'hips',112,.006)
    skirt_weights(skirt)
    # Pattern is fitted to the cylinder, including the hidden side/back areas.
    def brocade_path(points,theta,offset=0):
        return [(.169*math.cos(theta+x/.169),h,.115*math.sin(theta+x/.169)) for x,h in points]
    for h in [.205,.216,.232,.405,.418,.429]:
        ellipse('SkirtRedGoldBorder',0,h,0,.169,.115,.0018,mats['Gold'] if int(h*1000)%2 else mats['Red'],'hips')
    for motif in range(16):
        a=math.tau*motif/16
        # Peacock body, raised curving neck and five eyed tail feathers.
        outline=[(-.014,.27),(-.024,.288),(-.014,.31),(.002,.325),(.013,.343),(.014,.365),(.005,.373),(-.005,.365),(.002,.356),(.012,.356)]
        curve('BrocadePeacockNeck',brocade_path(outline,a),.0017,mats['Gold'],'hips')
        body=[(-.017+.017*math.cos(t),.289+.023*math.sin(t)) for t in [math.tau*j/24 for j in range(25)]]
        curve('BrocadePeacockBody',brocade_path(body,a),.0017,mats['Gold'],'hips')
        for feather in range(5):
            x=-.024-feather*.005;h=.32+feather*.013
            curve('PeacockTailFeather',brocade_path([(-.029,.29),(x-.014,h),(x-.006,h+.018),(x+.002,h+.011)],a),.0014,mats['Blue'],'hips')
            eye=[(x-.005+.004*math.cos(t),h+.01+.006*math.sin(t)) for t in [math.tau*j/16 for j in range(17)]]
            curve('PeacockFeatherEye',brocade_path(eye,a),.001,mats['Gold'],'hips')
        curve('PeacockLegs',brocade_path([(-.023,.271),(-.023,.253),(-.014,.253)],a),.0012,mats['Gold'],'hips')
        for h in [.237,.395]:
            curve('BrocadeGeometricStitch',brocade_path([(-.03,h),(-.021,h+.007),(-.013,h),(-.005,h+.007),(.003,h)],a),.0012,mats['RedLight'],'hips')
    # Silver belt is braided wire with pendant chains on the right of the knot.
    for row in range(3):ellipse('SilverWaistBraid',0,.951+row*.005,0,.132,.09,.0017,mats['Silver'],'hips')
    sphere('SilverBeltKnot',(.075,.958,.076),(.018,.017,.01),mats['Silver'],'hips',24,14)
    for j in range(3):
        x=.071+j*.012
        curve('BeltPendantChain',[(x,.95,.095),(x+.004,.86-j*.02,.111),(x+.002,.79-j*.02,.12)],.0015,mats['Silver'],'belt')
        sphere('SilverBeltPendant',(x+.002,.78-j*.02,.121),(.006,.011,.003),mats['Silver'],'belt',18,10)
    shoulders={'L':(-.126,1.285,0),'R':(.126,1.285,0)}
    elbows={'L':(-.225,1.07,.078),'R':(.227,1.065,.01)}
    wrists={'L':(-.203,1.09,.147),'R':(.25,.893,.035)}
    hands={'L':(-.19,1.09,.164),'R':(.253,.855,.045)}
    arms(shoulders,elbows,wrists,hands,cuffs='Robe',bracelet=True,grip='L');cloth_shoes(True)
    # Folded indigo brocade sample over her left forearm, a separate cloth bone.
    ribbon('HeldBrocadeSample',[(-.18,1.12,.14),(-.18,1.1,.21),(-.18,.92,.22),(-.16,.75,.23)],.13,mats['Blue'],'brocade')
    for side in [-1,1]:curve('BrocadeSampleBorder',[(-.18+side*.055,1.1,.213),(-.18+side*.052,.93,.224),(-.16+side*.046,.75,.234)],.003,mats['Gold'],'brocade')
    for h in [.81,.88,.95,1.02]:disk_flower('BrocadeSampleFlowers',-.175,h,.227,.019,mats['RedLight'],'brocade')
    for j in range(15):curve('BrocadeSampleFringe',[(-.205+j*.006,.75,.234),(-.205+j*.006,.722-rng.random()*.01,.236)],.0012,mats['Red'],'brocade')
    curve('DonkeyLeadRope',[(.254,.861,.055),(.07,.74,.12),(-.25,.73,.17),(-.56,.87,.23),(-.64,.93,.27)],.0027,mats['Rope'],'spine')
    props=[('skirt.L',(-.09,.92,.05),(-.09,.23,.06),'hips'),('skirt.R',(.09,.92,.05),(.09,.23,.06),'hips'),('skirt.back',(0,.92,-.07),(0,.23,-.08),'hips'),('brocade',(-.20,1.1,.14),(-.17,.75,.23),'forearm.L'),('belt',(.07,.95,.09),(.09,.75,.12),'hips')]
    return shoulders,elbows,wrists,hands,props


def build_pu_mo():
    hair_back()
    sphere('GreyLowBun',(0,1.50,-.104),(.065,.043,.048),mats['HairGray'],'head',36,20)
    for j in range(22):
        a=math.tau*j/22
        curve('GreyBunLocks',[(.056*math.cos(a),1.5+.038*math.sin(a),-.12),(.045*math.cos(a+.3),1.5+.034*math.sin(a+.3),-.15),(0,1.5,-.154)],.0015,mats['HairLight'],'head')
    loft('BlackWrappedHeadcloth',[(1.59,.1,.085,0,-.01),(1.66,.123,.102,0,-.015),(1.73,.125,.106,0,-.02),(1.766,.071,.061,0,-.02),(1.775,.014,.015,0,-.02)],mats['Dark'],'head',80,.012)
    for row in range(6):
        curve('HeadclothSoftFold',[(.125*math.cos(t),1.63+row*.022+.017*math.sin(2*t+row*.5),-.02+.106*math.sin(t)) for t in [math.tau*j/96 for j in range(97)]],.006,mats['Hair'],'head')
    for side in [-1,1]:
        curve('GreyTempleWisp',[(side*.079,1.64,.064),(side*.088,1.59,.066),(side*.082,1.556,.065)],.0025,mats['HairGray'],'head',[.5,1,.03])
        for j in range(3):curve('GreyForeheadStrand',[(side*(.01+j*.014),1.645,.079),(side*(.023+j*.014),1.632,.083),(side*(.037+j*.014),1.61,.084)],.0009,mats['HairGray'],'head')
    tube('WoodHairpin',(-.16,1.58,-.083),(.115,1.585,-.084),.004,.005,mats['Wood'],'head',20)
    # Age lines follow the actual facial skin, avoiding floating wrinkle strips.
    for row in range(3):
        pts=[(x,1.609+row*.009+.001*math.sin(x*60)) for x in [-.055,-.035,-.015,.01,.032,.05]]
        curve('ForeheadAgeLine',[(x,h,skin_front(x,h)+.0005) for x,h in pts],.00045,mats['Crease'],'head',[.1,.6,.65,.65,.5,.05])
    for side in [-1,1]:
        for pts in [[(side*.018,1.51),(side*.033,1.50),(side*.053,1.507)],[(side*.025,1.482),(side*.036,1.462),(side*.04,1.447)],[(side*.05,1.444),(side*.05,1.425),(side*.043,1.415)]]:
            curve('FineAgeFold',[(x,h,skin_front(x,h)+.0005) for x,h in pts],.00055,mats['Crease'],'head',[.1,.65,.05])
        for j in range(3):
            pts=[(side*.07,1.53-j*.002),(side*.08,1.532-j*.006),(side*.087,1.53-j*.009)]
            curve('EyeCornerAgeLine',[(x,h,skin_front(x,h)+.0005) for x,h in pts],.00045,mats['Crease'],'head',[.1,.65,.05])
    robe=loft('LongIndigoRobe',[(.23,.182,.122,0,0),(.42,.19,.128,0,0),(.73,.17,.113,0,0),(.95,.138,.093,0,0),(1.2,.141,.088,0,-.002),(1.31,.11,.061,0,0)],mats['Robe'],'hips',88,.015,dust=True)
    skirt_weights(robe)
    # Upper robe must follow the spine independently from the leg panels.
    for v in robe.data.vertices:
        if v.co.z>1.02:
            for g in robe.vertex_groups:g.remove([v.index])
            (robe.vertex_groups.get('spine') or robe.vertex_groups.new(name='spine')).add([v.index],1,'REPLACE')
    for side in [-1,1]:
        path=[(side*.045,1.325,.045),(side*.033,1.29,.063),(-side*.01,1.2,.091),(-side*.08,1.1,.085)]
        ribbon('CrossedDarkCollar',path,.026,mats['Dark'],'spine')
        for row,key in enumerate(['Red','Gold','Green']):curve('ThreeColourCollar',[(x+(row-1)*.005,h,f+.003) for x,h,f in path],.0015,mats[key],'spine')
    # Black apron with coloured borders follows the front skirt panels.
    apron=mesh('BlackWaistApron',[(-.12,.94,.101),(.12,.94,.101),(.141,.32,.137),(-.141,.32,.137)],[(0,1,2,3)],mats['Dark'],'hips');solidify(apron,.003);skirt_weights(apron)
    for h in [.257,.27,.283]:ellipse('RobeHemColour',0,h,0,.187,.127,.0018,mats[['Red','Gold','Green'][int((h-.257)/.012)%3]],'hips')
    for key,offset in [('Red',0),('Gold',.005),('Green',.01)]:curve('ApronBorder',[(-.128,.92,.108),(-.143,.35+offset,.14),(.143,.35+offset,.14),(.128,.92,.108)],.0015,mats[key],'hips')
    sash(False)
    shoulders={'L':(-.135,1.28,0),'R':(.135,1.28,0)}
    elbows={'L':(-.235,1.069,.02),'R':(.245,1.045,.005)}
    wrists={'L':(-.231,1.026,.18),'R':(.275,.83,.056)}
    hands={'L':(-.229,1.014,.205),'R':(.28,.798,.067)}
    arms(shoulders,elbows,wrists,hands,cuffs='Robe',grip='L');cloth_shoes(False)
    for side,suffix in [(-1,'L'),(1,'R')]:
        loft('LooseUnderTrousers',[(.12,.035,.035,side*.084,0),(.25,.052,.049,side*.084,0),(.38,.058,.055,side*.084,0)],mats['Robe'],'shin.'+suffix,40,.015)
        for h in [.11,.13,.15]:ellipse('OldLegBindings',side*.084,h,0,.036,.036,.002,mats['Rope'],'shin.'+suffix)
    # A worn wool cloak, draped around the back and open between the hands.
    def felt(t,a,offset=0):
        h=.58+.765*t;rx=.221+.028*math.sin(t*math.pi);rf=.128+.023*math.sin(t*math.pi)
        if t>.86:
            q=(t-.86)/.14;rx=rx*(1-q)+.096*q;rf=rf*(1-q)+.065*q
        return ((rx+offset)*math.cos(a),h+(1-t)**7*.009*math.sin(a*15),-.015+(rf+offset)*math.sin(a))
    pts=[];cols=88;rows=30
    for row in range(rows+1):
        t=row/rows
        for col in range(cols+1):
            a=math.pi/2+.43+(math.tau-.86)*col/cols;pts.append(felt(t,a))
    cloak=mesh('OldWoolFeltCloak',pts,[(r*(cols+1)+j,r*(cols+1)+j+1,(r+1)*(cols+1)+j+1,(r+1)*(cols+1)+j) for r in range(rows) for j in range(cols)],mats['Felt'],'cloak.back');solidify(cloak,.006)
    for side,suffix in [(-1,'L'),(1,'R')]:
        sphere('FeltShoulderCap',(side*.13,1.289,-.005),(.082,.05,.08),mats['Felt'],'upper_arm.'+suffix,32,20)
    for v in cloak.data.vertices:
        x,h,f=v.co.x,v.co.z,-v.co.y;torso=max(0,min(1,(h-1.05)/.24));panel='cloak.L' if x<-.08 and f>-.04 else ('cloak.R' if x>.08 and f>-.04 else 'cloak.back')
        for g in cloak.vertex_groups:g.remove([v.index])
        for name,w in [('spine',torso),(panel,1-torso)]:
            if w:(cloak.vertex_groups.get(name) or cloak.vertex_groups.new(name=name)).add([v.index],w,'REPLACE')
    for row in range(17):
        for col in range(47):
            t=.015+row/17*.94+rng.uniform(-.008,.008);a=math.pi/2+.44+(math.tau-.88)*(col+rng.uniform(-.3,.3))/47
            x,h,f=felt(t,a,.002);joint='spine' if h>1.22 else ('cloak.L' if x<-.08 and f>-.04 else ('cloak.R' if x>.08 and f>-.04 else 'cloak.back'))
            curve('ShortWoolFibres',[(x,h,f),(x+.003*math.cos(a),h-.015,f+.003*math.sin(a)),(x+.001,h-.026-rng.random()*.013,f)],.0024,mats['FeltLight'] if (row+col)%13==0 else mats['Felt'],'spine' if h>1.22 else joint,[.1,1,.02])
    for side in [-1,1]:
        for row in range(17):
            t=row/17;a=math.pi/2+(.43 if side<0 else math.tau-.43)
            x,h,f=felt(t,a,.005)
            curve('CloakEdgeStitch',[(x-.003,h+.003,f+.002),(x+.004,h-.007,f+.003)],.0012,mats['Linen'],'spine' if h>1.2 else 'cloak.L' if side<0 else 'cloak.R')
    # Soft belt pouch, black clay tea jar, and a separate three-legged coal pan.
    sphere('HerbAndFlintPouch',(.115,.79,.141),(.055,.082,.03),mats['Bag'],'pouch',32,20)
    for j in range(4):sphere('PouchFlint',(.085+j*.019,.858,.148),(.009,.014,.009),mats['WoodLight'],'pouch',14,8)
    disk_flower('PouchStitchedFlower',.115,.80,.173,.016,mats['Gold'],'pouch')
    curve('PouchDrawstring',[(.06,.85,.15),(.115,.87,.17),(.169,.85,.15)],.0025,mats['Rope'],'pouch')
    loft('BlackClayTeaJar',[(.97,.05,.05,-.225,.146),(.99,.069,.066,-.225,.146),(1.075,.071,.068,-.225,.146),(1.11,.045,.044,-.225,.146),(1.14,.036,.035,-.225,.146)],mats['Pot'],'teapot',56,.002)
    ellipse('JarLip',-.225,1.143,.146,.038,.037,.004,mats['PotEdge'],'teapot')
    sphere('DarkTeaSurface',(-.225,1.138,.146),(.031,.001,.03),mats['WoodDark'],'teapot',24,12)
    for i in range(15):
        a=rng.random()*math.tau;h=rng.uniform(.996,1.1)
        curve('ClayJarWear',[(-.225+.071*math.cos(a),h,.146+.069*math.sin(a)),(-.225+.071*math.cos(a+.1),h+.003,.146+.069*math.sin(a+.1))],.0008,mats['PotEdge'],'teapot')
    cx,ch,cf=.28,.626,.074
    loft('CopperCoalPan',[(ch-.05,.082,.082,cx,cf),(ch,.119,.119,cx,cf),(ch+.045,.131,.131,cx,cf)],mats['Bronze'],'firepan',56)
    ellipse('CoalPanRim',cx,ch+.047,cf,.133,.133,.004,mats['Gold'],'firepan')
    for j in range(3):
        a=math.tau*j/3
        tube('BrazierFoot',(cx+.075*math.cos(a),ch-.04,cf+.075*math.sin(a)),(cx+.082*math.cos(a),ch-.135,cf+.082*math.sin(a)),.012,.009,mats['Bronze'],'firepan',20)
    for i in range(17):
        a=i*2.399963;r=.104*math.sqrt((i+.5)/17)
        sphere('GlowingCoals',(cx+r*math.cos(a),ch+.044+rng.uniform(0,.012),cf+r*math.sin(a)),(.023,.014,.021),mats['Ember'] if i%3 else mats['Coal'],'firepan',16,10)
    curve('CopperPanHandle',[(cx-.128, ch+.035,cf),(cx-.11,ch+.11,cf),(cx-.05,ch+.17,cf),(cx+.05,ch+.17,cf),(cx+.11,ch+.11,cf),(cx+.128,ch+.035,cf)],.006,mats['Bronze'],'firepan')
    props=[('skirt.L',(-.09,.93,.05),(-.09,.24,.06),'hips'),('skirt.R',(.09,.93,.05),(.09,.24,.06),'hips'),('skirt.back',(0,.93,-.07),(0,.24,-.08),'hips'),('cloak.L',(-.12,1.29,.05),(-.2,.58,.07),'spine'),('cloak.R',(.12,1.29,.05),(.2,.58,.07),'spine'),('cloak.back',(0,1.29,-.08),(0,.58,-.14),'spine'),('pouch',(.11,.88,.14),(.11,.71,.14),'hips'),('teapot',hands['L'],(-.225,1.12,.146),'hand.L'),('firepan',hands['R'],(.28,.63,.074),'hand.R'),('sash',(0,.95,.1),(0,.66,.13),'hips')]
    return shoulders,elbows,wrists,hands,props


def build(ns):
    initialize(ns)
    return {'a_qiang':build_a_qiang,'yu_nan':build_yu_nan,'pu_mo':build_pu_mo}[CFG['key']]()
