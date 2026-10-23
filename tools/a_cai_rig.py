"""Independent supporting-character rig and six reusable clips."""

def build(ns):
    globals().update(ns)
    arm_data=bpy.data.armatures.new('阿彩_骨架')
    armature=bpy.data.objects.new('ACai_Armature',arm_data)
    collection.objects.link(armature)
    bpy.ops.object.select_all(action='DESELECT');armature.select_set(True);bpy.context.view_layer.objects.active=armature
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,head,tail,parent=None):
        item=arm_data.edit_bones.new(name);item.head,item.tail=p(head),p(tail)
        if parent:item.parent=arm_data.edit_bones[parent]
    bone('root',(0,0,0),(0,.12,0))
    bone('hips',(0,.88,0),(0,1.02,0),'root')
    bone('spine',(0,1.02,0),(0,1.29,0),'hips')
    bone('neck',(0,1.29,0),(0,1.38,0),'spine')
    bone('head',(0,1.38,0),(0,1.72,0),'neck')
    bone('eyes',(0,1.528,.07),(0,1.56,.07),'head')
    for name,x,f in [('skirt.L',-.09,.06),('skirt.R',.09,.06),('skirt.back',0,-.07)]:bone(name,(x,.92,f),(x,.43,f),'hips')
    bone('carrier',(0,1.12,-.12),(0,1.32,-.16),'spine')
    bone('baby',(0,1.38,-.17),(0,1.48,-.17),'carrier')
    bone('basket',(.197,.96,.048),(.197,.81,.048),'hips')
    bone('sash',(-.02,.94,.11),(0,.56,.16),'hips')
    bone('hoe',(0,1.34,-.02),(0,1.44,-.02),'spine')
    for side,suffix in [(-1,'L'),(1,'R')]:
        bone('upper_arm.'+suffix,shoulders[suffix],elbows[suffix],'spine')
        bone('forearm.'+suffix,elbows[suffix],wrists[suffix],'upper_arm.'+suffix)
        bone('hand.'+suffix,wrists[suffix],hands[suffix],'forearm.'+suffix)
        bone('thigh.'+suffix,(side*.087,.88,0),(side*.087,.43,0),'hips')
        bone('shin.'+suffix,(side*.087,.43,0),(side*.087,.105,0),'thigh.'+suffix)
        bone('foot.'+suffix,(side*.087,.105,0),(side*.087,.04,.13),'shin.'+suffix)
    bpy.ops.object.mode_set(mode='OBJECT');arm_data.display_type='STICK'
    assert len(arm_data.bones)==26
    character.parent=armature;character.matrix_parent_inverse=Matrix.Identity(4)
    modifier=character.modifiers.new('骨骼蒙皮','ARMATURE');modifier.object=armature
    assert all(v.groups for v in character.data.vertices)
    assert all(g.name in arm_data.bones for g in character.vertex_groups)
    def rotate(name,axis,angle):
        pose=armature.pose.bones[name]
        local=pose.bone.matrix_local.to_3x3().inverted()@Vector(axis)
        pose.rotation_quaternion=Quaternion(local.normalized(),angle)
    armature.animation_data_create();bpy.context.scene.render.fps=30;actions={}
    for mode,frames in [('idle',141),('walk',30),('jump',24),('push',30),('carry',30),('inspect',90)]:
        action=bpy.data.actions.new(mode);action.use_fake_user=True;armature.animation_data.action=action
        for frame in range(frames+1):
            time,phase=frame/30,math.tau*frame/frames
            stride=math.sin(phase) if mode in {'walk','push','carry'} else 0
            for pose in armature.pose.bones:
                pose.rotation_mode='QUATERNION';pose.rotation_quaternion=Quaternion();pose.location=(0,0,0);pose.scale=(1,1,1)
            rotate('head',(0,1,0),math.sin(time*1.4)*.012)
            rotate('skirt.L',(1,0,0),stride*.025);rotate('skirt.R',(1,0,0),-stride*.025)
            rotate('skirt.back',(1,0,0),stride*.01)
            rotate('sash',(1,0,0),stride*.035);rotate('basket',(1,0,0),stride*.022)
            rotate('carrier',(1,0,0),math.sin(phase)*.003)
            rotate('baby',(0,1,0),math.sin(phase)*.004)
            for suffix,sign in [('L',1),('R',-1)]:
                rotate('thigh.'+suffix,(1,0,0),stride*.20*sign)
                rotate('shin.'+suffix,(1,0,0),max(0,-stride*sign)*.26)
                if mode=='walk' and suffix=='R':rotate('upper_arm.R',(1,0,0),stride*.12)
            if mode in {'push','carry'}:
                for suffix in ['L','R']:
                    rotate('upper_arm.'+suffix,(1,0,0),-.7 if mode=='push' else -.9)
                    rotate('forearm.'+suffix,(1,0,0),1.85 if suffix=='L' else -.3)
                armature.pose.bones['hoe'].scale=(.001,.001,.001)
            if mode=='jump':
                rotate('thigh.L',(1,0,0),-.2);rotate('thigh.R',(1,0,0),.2)
                rotate('shin.L',(1,0,0),.4);rotate('shin.R',(1,0,0),.4)
                rotate('forearm.L',(1,0,0),1.7);armature.pose.bones['hoe'].scale=(.001,.001,.001)
            if mode=='inspect':rotate('head',(1,0,0),.06)
            if mode=='idle' and frame in range(135,140):armature.pose.bones['eyes'].scale.y=.08
            for pose in armature.pose.bones:
                for prop in ['rotation_quaternion','location','scale']:pose.keyframe_insert(data_path=prop,frame=frame,group=pose.name)
        actions[mode]=action
    armature.animation_data.action=actions['idle']
    return armature,actions
