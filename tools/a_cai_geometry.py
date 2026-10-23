"""Geometry recipe for A Cai, called inside build_a_cai_blender.py."""

def build(ns):
    globals().update(ns)
    # Hair covers the rear scalp below the wrapped cap; the face stays open.
    hair_rows=[(1.43,.050,.038),(1.49,.086,.070),(1.57,.098,.079),(1.65,.096,.075),(1.69,.080,.063)]
    points=[]
    for h,rx,rf in hair_rows:
        for j in range(49):
            t=-math.pi/2+math.pi*j/48
            points.append((rx*math.sin(t),h,-rf*math.cos(t)-.006))
    hair=mesh('CoveredRearScalp',points,[(r*49+j,r*49+j+1,(r+1)*49+j+1,(r+1)*49+j) for r in range(4) for j in range(48)],mats['Hair'],'head')
    solidify(hair,.004)
    # Rounded cloth cap and several broad overlapping wraps rather than a sphere.
    loft('TurbanCrown', [(1.61,.097,.085,0,-.008),(1.66,.123,.100,0,-.012),(1.73,.139,.112,0,-.018),(1.77,.112,.093,0,-.023),(1.79,.018,.020,0,-.023)], mats['Veil'], 'head', 80, .006)
    for band in range(6):
        h=1.66+band*.019
        curve('WrappedBlackCloth', [((.126+.008*math.sin(band*.6))*math.cos(t),h+.017*math.sin(t*2+band*.65),-.018+.106*math.sin(t)) for t in [math.tau*j/96 for j in range(97)]], .007, mats['VeilEdge'], 'head')
    # Flower band follows the whole head, visible from front, side and back.
    loft('IndigoFlowerHeadband',[(1.648,.131,.110,0,-.018),(1.697,.133,.112,0,-.018)],mats['UnderCap'],'head',96)
    for row in range(2):
        curve('RedBandBorder', [(.130*math.cos(t),1.653+row*.039+.012*math.cos(t),-.018+.109*math.sin(t)) for t in [math.tau*j/120 for j in range(121)]], .003, mats['Sash'], 'head')
    for flower in range(24):
        a=math.tau*flower/24
        for petal in range(5):
            phi=math.tau*petal/5
            path=[]
            for j in range(17):
                t=math.tau*j/16
                u=.005*math.cos(t)+.007*math.cos(phi)
                v=.004*math.sin(t)+.007*math.sin(phi)
                path.append((.135*math.cos(a+u/.13),1.674+v,-.018+.114*math.sin(a+u/.13)))
            curve('RedBlueHeadbandFlower',path,.0012,mats['Sash'] if flower%2 else mats['BlueThread'],'head')
    for side in [-1,1]:
        ribbon('HeadbandTail',[(side*.12,1.67,-.04),(side*.134,1.57,-.075),(side*.123,1.51,-.08)],.024,mats['UnderCap'],'head')
        for j in range(4):
            curve('HeadbandTassel',[(side*.123+(j-1.5)*.005,1.52,-.08),(side*.125+(j-1.5)*.005,1.485,-.075)],.0015,mats['Sash'],'head')
        # Wisps curl across the forehead and around the ears.
        curve('LooseTempleHair',[(side*.076,1.647,.062),(side*.088,1.606,.072),(side*.079,1.58,.079),(side*.088,1.56,.071)],.003,mats['Hair'],'head')
        curve('ForeheadWisp',[(side*.035,1.66,.08),(side*.045,1.633,.087),(side*.033,1.615,.091)],.002,mats['Hair'],'head')
        curve('SmallSilverEarring',[(side*.087+.007*math.cos(t),1.474+.012*math.sin(t),.004) for t in [math.tau*j/32 for j in range(33)]],.0018,mats['Silver'],'head')
    # Shirt, open dark vest, and visible crossed batik collar.
    loft('IndigoBlouse',[(.84,.137,.087,0,0),(.98,.116,.079,0,0),(1.18,.135,.087,0,0),(1.29,.128,.077,0,-.005),(1.33,.060,.044,0,-.004)],mats['Robe'],'spine',64,.002)
    for side in [-1,1]:
        points=[(side*.04,1.319,.044),(side*.115,1.27,.067),(side*.119,1.12,.069),(side*.13,.94,.075),(side*.156,.84,.071)]
        ribbon('BlackSleevelessVest',points,.078,mats['Vest'],'spine')
        curve('VestFrontSeam',[(x-side*.039,h,f+.003) for x,h,f in points],.002,mats['VestEdge'],'spine')
    collar=[(-.048,1.324,.046),(-.025,1.279,.077),(.007,1.22,.089),(.054,1.15,.088)]
    ribbon('CrossCollarLeft',collar,.034,mats['UnderCap'],'spine')
    other=[(.048,1.324,.046),(.024,1.279,.078),(-.004,1.225,.091),(-.049,1.16,.087)]
    ribbon('CrossCollarRight',other,.034,mats['UnderCap'],'spine')

    def flower(name,cx,ch,cf,size,joint='spine',back=False):
        for petal in range(6):
            a=math.tau*petal/6
            path=[]
            for j in range(17):
                t=math.tau*j/16
                u=size*(.32*math.cos(t)+.58*math.cos(a))
                v=size*(.32*math.sin(t)+.58*math.sin(a))
                path.append((cx+u,ch+v,cf))
            curve(name,path,.00115,mats['Linen'],joint)
        curve(name+'Center',[(cx+size*.12*math.cos(t),ch+size*.12*math.sin(t),cf) for t in [math.tau*j/16 for j in range(17)]],.001,mats['Linen'],joint)
    for line in [collar,other]:
        for a,b in zip(line,line[1:]):
            for t in [.15,.65]:
                x,h,f=[a[k]*(1-t)+b[k]*t for k in range(3)]
                flower('CollarWaxFlower',x,h,f+.003,.010)
    shoulders={'L':(-.126,1.272,0),'R':(.126,1.272,0)}
    elbows={'L':(-.271,1.08,.027),'R':(.231,1.034,.012)}
    wrists={'L':(-.311,1.302,.012),'R':(.259,.873,.052)}
    hands={'L':(-.311,1.349,-.009),'R':(.260,.813,.066)}
    for side,suffix in [(-1,'L'),(1,'R')]:
        shoulder,elbow,wrist,hand=[d[suffix] for d in [shoulders,elbows,wrists,hands]]
        tube('BlouseUpperSleeve',shoulder,elbow,.064,.052,mats['Robe'],'upper_arm.'+suffix,40,.004)
        cuff_end=tuple(elbow[i]*.37+wrist[i]*.63 for i in range(3))
        tube('RolledIndigoSleeve',elbow,cuff_end,.054,.045,mats['Robe'],'forearm.'+suffix,40,.004)
        cuff_start=tuple(elbow[i]*.73+wrist[i]*.27 for i in range(3))
        tube('BatikCuff',cuff_start,cuff_end,.055,.05,mats['UnderCap'],'forearm.'+suffix,40)
        # Cuff flowers run around the arm, not on a flat floating panel.
        a,b=p(cuff_start),p(cuff_end); axis=(b-a).normalized(); u=axis.cross(Vector((0,1,0))).normalized(); v=axis.cross(u)
        for j in range(9):
            theta=math.tau*j/9
            for k in range(5):
                phi=math.tau*k/5; path=[]
                for q in range(13):
                    t=math.tau*q/12
                    frac=.5+(.004*math.sin(t)+.006*math.sin(phi))/(b-a).length
                    angle=theta+(.004*math.cos(t)+.006*math.cos(phi))/.057
                    radius=(.055*(1-frac)+.05*frac)*(1+.09*math.sin(frac*math.pi))+.0014
                    pos=a.lerp(b,frac)+(u*math.cos(angle)+v*math.sin(angle))*radius
                    path.append((pos.x,pos.z,-pos.y))
                curve('CuffWaxFlower',path,.001,mats['Linen'],'forearm.'+suffix)
        for frac in [.08,.92]:
            radius=(.055*(1-frac)+.05*frac)*(1+.09*math.sin(frac*math.pi))+.0013
            path=[]
            for j in range(65):
                theta=math.tau*j/64; pos=a.lerp(b,frac)+(u*math.cos(theta)+v*math.sin(theta))*radius
                path.append((pos.x,pos.z,-pos.y))
            curve('CuffWaxDyeBorder',path,.0012,mats['Linen'],'forearm.'+suffix)
        tube('BareForearm',cuff_end,wrist,.034,.023,mats['Skin'],'forearm.'+suffix,32)
        tube('WristToPalm',wrist,hand,.023,.025,mats['Skin'],'hand.'+suffix,28)
        sphere('Palm',hand,(.030,.045,.023),mats['Skin'],'hand.'+suffix,28,18)
        if suffix=='L':
            for finger in range(4):
                x=-.335+finger*.014
                curve('GrippingHoeFinger',[(x,1.326,.025),(x,1.349,.023),(x,1.361,.005),(x,1.35,-.012)],.0063,mats['Skin'],'hand.L')
            curve('GrippingThumb',[(-.284,1.32,.026),(-.28,1.34,.025),(-.294,1.348,.014)],.009,mats['Skin'],'hand.L')
        else:
            for finger in range(4):
                x=.241+finger*.012
                curve('RestingFinger',[(x,.804,.071),(x,.779-finger*.002,.076),(x-.004,.77-finger*.002,.064)],.0052,mats['Skin'],'hand.R')
            curve('RestingThumb',[(.235,.832,.07),(.222,.81,.078),(.224,.798,.074)],.007,mats['Skin'],'hand.R')
    # True pleated cross section: a pair of sharp valleys between each broad fold.
    rows=[(.415,.222,.157),(.44,.22,.156),(.62,.193,.139),(.81,.166,.115),(.91,.135,.090)]
    count=192; pts=[]
    for h,rx,rf in rows:
        for j in range(count):
            a=math.tau*j/count
            inset=[.0,.0,-.012,-.010][j%4]
            pts.append(((rx+inset)*math.cos(a),h,(rf+inset)*math.sin(a)))
    faces=[(r*count+j,r*count+(j+1)%count,(r+1)*count+(j+1)%count,(r+1)*count+j) for r in range(len(rows)-1) for j in range(count)]
    skirt=mesh('IndigoPleatedSkirt',pts,faces,mats['Robe'],'hips')
    for poly in skirt.data.polygons: poly.use_smooth=False
    for vertex in skirt.data.vertices:
        x,h,f=vertex.co.x,vertex.co.z,-vertex.co.y
        # Blend the panel boundaries and pin the waistband to the hips. Hard
        # left/right assignments twist the narrow pleat valleys during a step.
        hip=max(0,min(1,(h-.68)/.23))
        back=max(0,min(1,(-.005-f)/.08))
        right=max(0,min(1,.5+x/.14))
        skirt.vertex_groups['hips'].remove([vertex.index])
        for joint,weight in [('hips',hip),('skirt.back',(1-hip)*back),('skirt.L',(1-hip)*(1-back)*(1-right)),('skirt.R',(1-hip)*(1-back)*right)]:
            if weight>0:
                group=skirt.vertex_groups.get(joint) or skirt.vertex_groups.new(name=joint)
                group.add([vertex.index],weight,'REPLACE')
    solidify(skirt,.003)
    loft('UnderSkirt',[(.425,.208,.144,0,0),(.89,.13,.087,0,0)],mats['Robe'],'hips',64)
    loft('RedWaistSash',[(.914,.138,.094,0,0),(.956,.132,.091,0,0),(.976,.133,.09,0,0)],mats['Sash'],'hips',64,.002)
    for h in [.924,.939,.955,.97]:
        curve('WaistSashFold',[(.139*math.cos(t),h+.003*math.sin(t*3),.096*math.sin(t)) for t in [math.tau*j/80 for j in range(81)]],.002,mats['RedLight'],'hips')
    sphere('SashKnot',(-.02,.938,.106),(.032,.025,.022),mats['Sash'],'hips')
    for side in [-1,1]:
        path=[(-.02,.932,.118),(side*.035,.82,.12),(side*.046,.67,.147),(side*.06,.565,.156)]
        ribbon('LongRedSashTail',path,.047,mats['Sash'],'sash')
        for row in range(5):
            h=.593+row*.012
            curve('SashTailBatikBorder',[(side*.06-.022,h,.16),(side*.06+.022,h+.002,.16)],.0011,mats['RedLight'],'sash')
        for j in range(7):
            curve('SashTailFringe',[(side*.06+(j-3)*.006,.568,.159),(side*.06+(j-3)*.006,.55,.16)],.0009,mats['Sash'],'sash')
    # Bare calves and woven sandals, including visible toes and ankle lashings.
    for side,suffix in [(-1,'L'),(1,'R')]:
        x=side*.087
        tube('UpperLeg',(x,.87,0),(x,.43,0),.058,.043,mats['Skin'],'thigh.'+suffix,32)
        loft('BareCalf',[(.105,.025,.027,x,0),(.20,.032,.034,x,0),(.33,.044,.042,x,0),(.44,.042,.040,x,0)],mats['Skin'],'shin.'+suffix,40)
        sphere('BareFoot',(x,.063,.048),(.038,.034,.085),mats['Skin'],'foot.'+suffix,28,16)
        sphere('HempSandalSole',(x,.029,.044),(.046,.016,.102),mats['BambooDark'],'foot.'+suffix,32,16)
        for toe in range(5):
            sphere('Toe',(x+(toe-2)*.013,.056,.122-abs(toe-1)*.004),(.008,.012,.016),mats['Skin'],'foot.'+suffix,14,8)
        for row in range(19):
            f=-.044+row*.01; w=.041*math.sqrt(max(.01,1-((f-.044)/.105)**2))
            curve('SandalWovenSole',[(x-w,.04,f),(x,.043,f+.002),(x+w,.04,f)],.002,mats['BambooLight'],'foot.'+suffix)
        for side2 in [-1,1]:
            curve('SandalCrossStrap',[(x+side2*.039,.041,.080),(x-side2*.025,.086,.043),(x-side2*.032,.043,.005)],.005,mats['Rope'],'foot.'+suffix)
            curve('AnkleLacing',[(x+side2*.032,.047,-.02),(x+side2*.029,.112,-.005),(x-side2*.029,.125,.005),(x-side2*.03,.095,.025)],.003,mats['Rope'],'shin.'+suffix)
        for row in range(2):
            curve('AnkleTie',[(x+.028*math.cos(t),.125+row*.006,.03*math.sin(t)) for t in [math.tau*j/40 for j in range(41)]],.002,mats['Rope'],'shin.'+suffix)
    # Fabric back carrier with square batik panel and supporting shoulder straps.
    for side in [-1,1]:
        ribbon('CarrierShoulderStrap',[(side*.08,1.035,.09),(side*.103,1.27,.075),(side*.1,1.315,-.025),(side*.10,1.23,-.19)],.026,mats['Bag'],'carrier')
        ribbon('CarrierWaistTie',[(side*.11,1.04,-.16),(side*.15,.96,-.07),(side*.1,.946,.10)],.022,mats['Bag'],'carrier')
    loft('WrappedBabyBody',[(1.05,.085,.048,0,-.16),(1.13,.1,.059,0,-.16),(1.32,.085,.057,0,-.16),(1.38,.05,.036,0,-.16)],mats['UnderCap'],'carrier',48)
    # Main panel is curved slightly around the body, with a visibly bound top edge.
    panel=[]
    for h in [1.045,1.08,1.18,1.29,1.36]:
        for j in range(17):
            x=-.111+j*.222/16; panel.append((x,h,-.225+.024*(x/.111)**2))
    panel_faces=[(r*17+j,r*17+j+1,(r+1)*17+j+1,(r+1)*17+j) for r in range(4) for j in range(16)]
    carrier=mesh('SquareBatikBabyCarrier',panel,panel_faces,mats['UnderCap'],'carrier');solidify(carrier,.005)
    for side in [-1,1]:
        side_panel=mesh('CarrierSideWrap',[(side*.111,1.045,-.201),(side*.111,1.36,-.201),(side*.089,1.37,-.113),(side*.086,1.07,-.113)],[(0,1,2,3)],mats['UnderCap'],'carrier')
        solidify(side_panel,.004)
        curve('BoundCarrierSide',[(side*.11,1.045,-.202),(side*.114,1.36,-.204),(side*.089,1.37,-.112)],.0025,mats['Linen'],'carrier')
    for h in [1.055,1.07,1.333,1.35]:
        curve('CarrierBatikHorizontalBorder',[(x,h,-.23+.024*(x/.111)**2) for x in [-.108+j*.216/40 for j in range(41)]],.0016,mats['Linen'],'carrier')
    for side in [-1,1]:
        for x in [side*.096,side*.105]:curve('CarrierBatikVerticalBorder',[(x,1.07,-.23+.024*(x/.111)**2),(x,1.335,-.23+.024*(x/.111)**2)],.0015,mats['Linen'],'carrier')
    for x in [-.061,0,.061]:
        for h in [1.12,1.2,1.28]:flower('CarrierWaxFlower',x,h,-.231+.024*(x/.111)**2,.023,'carrier',True)
    # Baby faces away from the mother. The sleeping expression is modelled too.
    sphere('SleepingBabyHead',(0,1.421,-.175),(.056,.066,.054),mats['Skin'],'baby',40,24)
    loft('BabyHairCap',[(1.437,.052,.05,0,-.174),(1.47,.044,.041,0,-.174),(1.485,.014,.016,0,-.174)],mats['Hair'],'baby',48)
    curve('BabyBatikHeadband',[(.055*math.cos(t),1.452+.005*math.cos(t),-.174+.051*math.sin(t)) for t in [math.tau*j/64 for j in range(65)]],.005,mats['Linen'],'baby')
    for side in [-1,1]:
        curve('SleepingBabyClosedEye',[(side*.009,1.43,-.226),(side*.02,1.426,-.228),(side*.031,1.431,-.22)],.0015,mats['Hair'],'baby')
        sphere('BabyEar',(side*.054,1.425,-.173),(.01,.016,.01),mats['Skin'],'baby',18,10)
    sphere('BabyNose',(0,1.414,-.228),(.009,.011,.009),mats['Skin'],'baby',20,12)
    curve('SleepingBabyMouth',[(-.01,1.395,-.224),(0,1.393,-.228),(.01,1.395,-.224)],.0013,mats['Lip'],'baby')
    # Woven hip basket, independently suspended so its movement remains slight.
    cx,ch,cf=.197,.877,.048
    loft('HipBasketBody',[(ch-.064,.043,.038,cx,cf),(ch+.045,.057,.049,cx,cf)],mats['BambooDark'],'basket',48)
    for row in range(20):
        h=ch-.06+row*.0055; radius=.044+(h-ch+.06)*.12
        curve('HipBasketHorizontalWeave',[(cx+(radius+.001*math.sin(t*28+row*math.pi))*math.cos(t),h,cf+radius*.86*math.sin(t)) for t in [math.tau*j/72 for j in range(73)]],.0017,mats['Bamboo'],'basket')
    for rib in range(32):
        a=math.tau*rib/32
        curve('HipBasketVerticalWeave',[(cx+(.044+.013*t)*math.cos(a),ch-.06+.108*t,cf+(.038+.011*t)*math.sin(a)) for t in [j/12 for j in range(13)]],.0015,mats['BambooLight'],'basket')
    curve('BasketBoundRim',[(cx+.059*math.cos(t),ch+.05,cf+.051*math.sin(t)) for t in [math.tau*j/64 for j in range(65)]],.004,mats['BambooLight'],'basket')
    for side in [-1,1]:curve('HipBasketSuspension',[(cx+side*.04,ch+.05,cf),(.151+side*.02,.97,.05)],.003,mats['Rope'],'basket')
    # Small hoe across the shoulder; all its geometry is bound to one stow bone.
    tube('HoeWoodShaft',(-.42,1.336,-.01),(.37,1.363,-.045),.013,.016,mats['Wood'],'hoe',32)
    for j in range(4):curve('HoeWoodGrain',[(-.4,1.34+j*.002,-.001),(-.1,1.35+j*.002,-.008),(.34,1.37+j*.002,-.035)],.0008,mats['Grain'],'hoe')
    tube('HoeSocket',(.35,1.36,-.045),(.397,1.36,-.045),.024,.023,mats['Iron'],'hoe',32)
    blade=mesh('ForgedHoeBlade',[(.365,1.35,-.06),(.407,1.35,-.06),(.441,1.15,-.04),(.355,1.15,-.04)],[(0,1,2,3)],mats['Iron'],'hoe');solidify(blade,.006)
    curve('HoeWornCuttingEdge',[(.355,1.15,-.041),(.441,1.15,-.041)],.002,mats['Silver'],'hoe')
    return shoulders,elbows,wrists,hands
