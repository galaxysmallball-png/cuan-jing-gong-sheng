"""Independent pack animal rig: four legs, ears, head, tail and two panniers."""


def build(ns):
    globals().update(ns)
    data=bpy.data.armatures.new('驮布毛驴_骨架');rig=bpy.data.objects.new('PackDonkey_Armature',data);collection.objects.link(rig)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,start,end,parent=None):
        item=data.edit_bones.new(name);item.head,item.tail=p(start),p(end)
        if parent:item.parent=data.edit_bones[parent]
    bone('root',(0,0,0),(0,.15,0));bone('spine',(0,.75,-.25),(0,.87,.25),'root')
    bone('neck',(0,.87,.25),(0,1.19,.40),'spine');bone('head',(0,1.19,.40),(0,1.13,.67),'neck')
    bone('eyes',(0,1.25,.52),(0,1.29,.52),'head');bone('tail',(0,.94,-.39),(0,.43,-.49),'spine')
    for side,suffix in [(-1,'L'),(1,'R')]:
        bone('ear.'+suffix,(side*.071,1.33,.446),(side*.111,1.71,.43),'head')
        bone('cargo.'+suffix,(side*.17,1.02,-.07),(side*.225,.65,-.07),'spine')
        for front,kind in [(.225,'front'),(-.275,'hind')]:
            upper=f'{kind}_upper.{suffix}';lower=f'{kind}_lower.{suffix}';hoof=f'{kind}_hoof.{suffix}';x=side*.109
            bone(upper,(x,.78,front),(x,.386,front+.015),'spine')
            bone(lower,(x,.386,front+.015),(x,.115,front+.028),upper)
            bone(hoof,(x,.115,front+.028),(x,.045,front+.07),lower)
    bpy.ops.object.mode_set(mode='OBJECT');data.display_type='STICK'
    character.parent=rig;character.matrix_parent_inverse=Matrix.Identity(4)
    mod=character.modifiers.new('骨骼蒙皮','ARMATURE');mod.object=rig
    assert len(data.bones)==22 and all(v.groups for v in character.data.vertices)
    assert all(g.name in data.bones for g in character.vertex_groups)
    def rotate(name,axis,angle):
        pose=rig.pose.bones[name];local=pose.bone.matrix_local.to_3x3().inverted()@Vector(axis)
        pose.rotation_quaternion=Quaternion(local.normalized(),angle)
    rig.animation_data_create();actions={};bpy.context.scene.render.fps=30
    for mode,frames in [('idle',141),('walk',36),('jump',24),('push',36),('carry',36),('inspect',90)]:
        action=bpy.data.actions.new(mode);action.use_fake_user=True;rig.animation_data.action=action
        for frame in range(frames+1):
            phase=math.tau*frame/frames
            for pose in rig.pose.bones:
                pose.rotation_mode='QUATERNION';pose.rotation_quaternion=Quaternion();pose.location=(0,0,0);pose.scale=(1,1,1)
            moving=mode in ['walk','push','carry'];stride=math.sin(phase) if moving else 0
            rotate('head',(1,0,0),math.sin(phase)*.015+(.09 if mode=='inspect' else 0))
            rotate('ear.L',(0,1,0),math.sin(phase)*.045);rotate('ear.R',(0,1,0),-math.sin(phase+.3)*.035)
            rotate('tail',(0,0,1),math.sin(phase)*.07)
            for side,suffix in [(-1,'L'),(1,'R')]:
                rotate('cargo.'+suffix,(1,0,0),stride*.009*side)
                for front,kind in [(.225,'front'),(-.275,'hind')]:
                    sign=side*(1 if kind=='front' else -1)
                    rotate(f'{kind}_upper.{suffix}',(1,0,0),stride*.18*sign)
                    rotate(f'{kind}_lower.{suffix}',(1,0,0),max(0,-stride*sign)*.24)
                    rotate(f'{kind}_hoof.{suffix}',(1,0,0),stride*.025*sign)
            if mode=='idle' and frame in range(135,140):rig.pose.bones['eyes'].scale.y=.08
            for pose in rig.pose.bones:
                for prop in ['rotation_quaternion','location','scale']:pose.keyframe_insert(data_path=prop,frame=frame,group=pose.name)
        actions[mode]=action
    rig.animation_data.action=actions['idle']
    return rig,actions
