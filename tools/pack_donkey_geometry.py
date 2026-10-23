"""Grey pack donkey, saddle, woven panniers and embroidered cloth rolls."""


def build(ns):
    globals().update(ns)
    from village_geometry import initialize,box,ellipse
    initialize(ns)
    sphere('DonkeyBarrel',(0,.81,-.04),(.155,.235,.395),mats['Fur'],'spine',48,32)
    sphere('DonkeyChest',(0,.86,.23),(.137,.19,.17),mats['Fur'],'spine',40,24)
    sphere('DonkeyRump',(0,.82,-.30),(.14,.21,.16),mats['Fur'],'spine',40,24)
    loft('SlopingDonkeyNeck',[(.82,.105,.11,0,.24),(1.01,.102,.11,0,.32),(1.17,.086,.09,0,.38),(1.24,.076,.075,0,.41)],mats['Fur'],'neck',48)
    sphere('LongDonkeyHead',(0,1.22,.472),(.105,.15,.17),mats['Fur'],'head',48,32)
    sphere('PaleMuzzle',(0,1.127,.615),(.104,.094,.13),mats['Muzzle'],'head',40,24)
    curve('DonkeyMouth',[(-.065,1.08,.703),(0,1.073,.738),(.065,1.08,.703)],.0024,mats['Dark'],'head')
    for side in [-1,1]:
        sphere('DarkNostril',(side*.065,1.14,.715),(.015,.013,.005),mats['Dark'],'head',24,14)
        sphere('EyeSocket',(side*.089,1.256,.516),(.024,.028,.018),mats['Dark'],'head',28,18)
        sphere('DonkeyEye',(side*.095,1.258,.526),(.015,.019,.014),mats['Eye'],'eyes',28,18)
        sphere('EyeGlint',(side*.1,1.266,.538),(.004,.004,.002),mats['Linen'],'eyes',16,10)
        joint='ear.L' if side<0 else 'ear.R'
        # Tapered leaf-shaped ears with a separate inner surface.
        ear=loft('LongDonkeyEar',[(1.33,.028,.022,side*.071,.446),(1.48,.041,.026,side*.092,.442),(1.63,.027,.02,side*.108,.435),(1.715,.002,.002,side*.111,.43)],mats['Fur'],joint,40)
        mesh('InnerEar',[(side*.07-.018,1.37,.469),(side*.07+.018,1.37,.469),(side*.108+.02,1.58,.459),(side*.111,1.684,.447),(side*.108-.02,1.58,.459)],[(0,1,2,3,4)],mats['Ear'],joint)
    for i in range(47):
        t=i/46;h=.98+t*.29;f=.195+t*.125
        curve('UprightMane',[(-.007,h,f),(rng.uniform(-.012,.012),h+.013,f-.008),(rng.uniform(-.008,.008),h+.02,f-.012)],.0026,mats['Dark'],'neck',[.8,1,.02])
    for side,suffix in [(-1,'L'),(1,'R')]:
        for front,kind in [(.225,'front'),(-.275,'hind')]:
            upper=f'{kind}_upper.{suffix}';lower=f'{kind}_lower.{suffix}';hoof=f'{kind}_hoof.{suffix}'
            x=side*.109;knee=(x,.386,front+.015);ankle=(x,.115,front+.028)
            tube('UpperLeg',(x,.78,front),knee,.043,.03,mats['Fur'],upper,32)
            sphere('Knee',knee,(.035,.044,.031),mats['Fur'],lower,24,16)
            tube('LowerLeg',knee,ankle,.026,.022,mats['Fur'],lower,28)
            sphere('Fetlock',ankle,(.025,.031,.027),mats['Fur'],lower,24,16)
            loft('DarkHoof',[(.005,.033,.041,x,front+.043),(.028,.036,.044,x,front+.043),(.078,.029,.036,x,front+.037),(.092,.024,.029,x,front+.03)],mats['Hoof'],hoof,32)
            curve('HoofRim',[(x-.027,.061,front+.073),(x,.066,front+.087),(x+.027,.061,front+.073)],.0015,mats['Muzzle'],hoof)
    curve('DonkeyTail',[(0,.95,-.398),(.015,.76,-.455),(.035,.50,-.49)],.015,mats['Fur'],'tail',[1,.65,.4])
    for j in range(24):
        a=math.tau*j/24
        curve('TailHair',[(.035+.014*math.cos(a),.53,-.49+.012*math.sin(a)),(.03+.02*math.cos(a),.43,-.50+.015*math.sin(a)),(.02+.015*math.cos(a),.375-rng.random()*.018,-.50)],.0019,mats['Dark'],'tail',[.4,1,.02])
    # Leather saddle over a folded blue blanket.
    loft('BlueSaddleBlanket',[(.83,.185,.32,0,-.04),(.95,.145,.31,0,-.04),(1.025,.08,.22,0,-.04)],mats['Blue'],'spine',64)
    box('LeatherPackSaddle',(0,1.012,-.06),(.20,.05,.40),mats['Leather'],'spine',.02)
    for side in [-1,1]:
        joint='cargo.L' if side<0 else 'cargo.R';cx=side*.225;cf=-.07
        loft('WovenPannier',[(.62,.073,.16,cx,cf),(.87,.094,.184,cx,cf)],mats['BambooDark'],joint,64)
        for row in range(28):
            t=row/27
            path=[]
            for j in range(97):
                a=math.tau*j/96;wave=.0015*math.sin(a*36+row*math.pi)
                path.append((cx+(.074+.020*t+wave)*math.cos(a),.625+.24*t,cf+(.161+.023*t+wave)*math.sin(a)))
            curve('PannierHorizontalWeave',path,.002,mats['Bamboo'] if row%3 else mats['BambooLight'],joint)
        for rib in range(48):
            a=math.tau*rib/48
            curve('PannierVerticalWeave',[(cx+(.075+.019*t)*math.cos(a),.626+.241*t,cf+(.161+.023*t)*math.sin(a)) for t in [j/16 for j in range(17)]],.0016,mats['BambooLight'],joint)
        ellipse('PannierBoundRim',cx,.876,cf,.097,.187,.005,mats['BambooLight'],joint)
        for f in [-.22,.10]:curve('SaddlePannierRope',[(0,1.05,f),(side*.17,1.00,f),(cx,.88,f)],.004,mats['Rope'],joint)
        # Cloth rolls are modelled, with concentric cloth ends and tie cords.
        for i in range(4):
            h=.952+(i//2)*.065;f=-.18+(i%2)*.18
            x1=side*.08;x2=side*.30
            tube('BrocadeClothRoll',(x1,h,f),(x2,h,f),.039,.039,mats['Red'] if i%2 else mats['Blue'],joint,40)
            for r in [.008,.018,.028,.036]:
                curve('ClothRollSpiral',[(x2+side*.001,h+r*math.cos(a),f+r*math.sin(a)) for a in [math.tau*j/40 for j in range(41)]],.0012,mats['Gold'],joint)
            for offset in [-.018,.018]:
                x=side*.19+offset
                curve('ClothRollTie',[(x,h+.043*math.cos(a),f+.043*math.sin(a)) for a in [math.tau*j/40 for j in range(41)]],.002,mats['Rope'],joint)
        # A patterned brocade cloth hangs outside each pannier.
        points=[(cx+side*.102,.97,-.13),(cx+side*.112,.86,-.13),(cx+side*.117,.63,-.13)]
        obj=mesh('DrapedBrocade',[(x,h,f+offset) for x,h,f in points for offset in [-.095,.095]],[(0,1,3,2),(2,3,5,4)],mats['Blue'],joint);solidify(obj,.003)
        for h in [.67,.69,.87,.89]:
            curve('PannierBrocadeBorder',[(cx+side*.119,h,-.22),(cx+side*.119,h,-.04)],.002,mats['Gold'],joint)
        for j in range(4):
            f=-.202+j*.05
            curve('BrocadeDiamond',[(cx+side*.12,.73,f),(cx+side*.12,.78,f+.02),(cx+side*.12,.83,f),(cx+side*.12,.78,f-.02),(cx+side*.12,.73,f)],.0015,mats['RedLight'],joint)
        for j in range(17):curve('PannierFringe',[(cx+side*.119,.635,-.22+j*.011),(cx+side*.118,.61-rng.random()*.014,-.22+j*.011)],.0012,mats['Gold'],joint)
    # Bridle encircles the muzzle and passes behind the long ears.
    curve('MuzzleBridle',[(.10*math.cos(a),1.13+.062*math.sin(a),.674) for a in [math.tau*j/64 for j in range(65)]],.004,mats['Leather'],'head')
    for side in [-1,1]:
        curve('HeadBridle',[(side*.097,1.13,.67),(side*.109,1.26,.50),(side*.08,1.36,.40),(0,1.375,.37)],.004,mats['Leather'],'head')
        curve('BrassBridleRing',[(side*.111,1.18+.014*math.cos(a),.586+.014*math.sin(a)) for a in [math.tau*j/32 for j in range(33)]],.002,mats['Gold'],'head')
