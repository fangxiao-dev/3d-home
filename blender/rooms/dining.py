"""Finished dining furniture; dimensions follow scene-v2-spec.json."""
import bpy


def build(api):
    api.shell({'west': (), 'east': (), 'south': ((-1.7,.9),)})
    api.furniture_id='dining_table'
    x,y=-1.05,-4.18
    # Thin rounded oval top with a lower reveal, turned pedestal and splayed feet.
    api.cylinder('table top',(x,y,.72),.69,.06,'tablewood',solid=True).scale.y=.79
    api.cylinder('table edge reveal',(x,y,.677),.65,.025,'wood').scale.y=.79
    api.cylinder('pedestal foot',(x,y,.085),.27,.09,'wood',r2=.19,solid=True)
    api.cylinder('pedestal column',(x,y,.36),.115,.49,'tablewood',r2=.085,solid=True)
    api.cylinder('pedestal collar',(x,y,.60),.16,.09,'wood',r2=.12)
    for dx,dy in ((.4,0),(-.4,0),(0,.34),(0,-.34)):
        api.rod('table curved foot',(x,y,.16),(x+dx,y+dy,.055),.055,'wood')
    api.furniture_id='dining_chair'
    chair(api,-2.45,y)
    api.furniture_id='dining_sideboard'
    # Real open niche: separate lower cabinets, counter and shallow upper cupboard.
    cx,cy=1.69,-3.68
    api.box('sideboard plinth',(cx,cy,.08),(.49,2.18,.16),'wood',.018,True,'east')
    api.box('sideboard lower carcass',(cx,cy,.48),(.53,2.18,.72),'cream',.02,True,'east')
    api.box('sideboard stone counter',(cx-.03,cy,.88),(.63,2.26,.07),'trim',.018,True,'east')
    api.box('sideboard niche back',(1.94,cy,1.20),(.04,2.18,.60),'wall',.005,False,'east')
    for yy in (-4.40,-3.68,-2.96):
        api.box('sideboard inset door',(1.412,yy,.49),(.045,.68,.65),'trim',.012,False,'east')
        api.box('sideboard raised field',(1.382,yy,.49),(.018,.54,.49),'cream',.008,False,'east')
        api.rod('sideboard brass pull',(1.35,yy-.09,.70),(1.35,yy+.09,.70),.012,'brass',False,'east')
    api.box('sideboard upper back',(1.94,cy,1.94),(.05,2.18,.90),'cream',.01,False,'east')
    for z in (1.48,1.92,2.40):
        api.box('sideboard upper shelf',(1.73,cy,z),(.47,2.24,.045),'trim',.012,False,'east')
    for yy in (-4.78,-4.06,-3.32,-2.58):
        api.box('sideboard upper stile',(1.73,yy,1.94),(.47,.045,.92),'trim',.006,False,'east')
    # Dish stacks and closed storage keep useful empty display bays.
    for yy in (-4.4,-3.68):
        for i in range(4):
            api.cylinder('ceramic plates',(1.70,yy,1.52+i*.018),.13,.012,'throw',side='east')
    api.furniture_id='refrigerator'
    fx,fy=1.59,-5.50
    # Openable doors reveal a real cavity rather than a solid black block.
    api.box('refrigerator back',(fx+.35,fy,.95),(.06,1.25,1.90),'black',.025,True)
    for yy in (fy-.60,fy+.60):
        api.box('refrigerator side',(fx,yy,.95),(.76,.05,1.90),'black',.018,True)
    for zz in (.04,1.86):
        api.box('refrigerator cap',(fx,fy,zz),(.76,1.25,.08),'black',.018,True)
    for zz in (.68,1.22):
        api.box('refrigerator shelf',(fx,fy,zz),(.66,1.13,.035),'trim',.008,False)
    api.box('refrigerator toe grille',(1.195,fy,.08),(.025,1.13,.10),'frame',.008,False)
    for i,yy in enumerate((fy-.313,fy+.313)):
        hinge=bpy.data.objects.new('refrigerator hinge '+str(i),None)
        bpy.context.collection.objects.link(hinge)
        hinge.location=(1.19,fy+(-.62 if i==0 else .62),.95)
        hinge['room_id']='dining'; hinge['furniture_id']='refrigerator'; hinge['hinge_axis']='Y'; hinge['movable']=True
        door=api.box('refrigerator door '+str(i),(1.178,yy,.98),(.055,.605,1.80),'screen',.025,False)
        handle=api.rod('refrigerator handle '+str(i),(1.105,fy+(-.07 if i==0 else .07),.68),(1.105,fy+(-.07 if i==0 else .07),1.35),.018,'frame')
        for obj in (door,handle):
            world=obj.matrix_world.copy(); obj.parent=hinge; obj.matrix_world=world; obj['movable']=True
    api.furniture_id='dining_pendant'
    api.cylinder('pendant rose',(x,y,2.72),.09,.04,'brass',side='top')
    api.rod('pendant cord',(x,y,2.70),(x,y,2.20),.008,'wood',side='top')
    api.cylinder('pleated pendant',(x,y,2.14),.25,.24,'trim',r2=.14,side='top')
    api.cylinder('pendant diffuser',(x,y,2.02),.22,.012,'bulb',side='top')


def chair(api,x,y):
    api.box('chair timber seat',(x,y,.393),(.49,.49,.065),'wood',.065,True)
    api.box('chair upholstered pad',(x+.015,y,.438),(.43,.43,.024),'cushion',.045,False)
    for dx in (-.18,.18):
        for dy in (-.19,.19):
            api.rod('chair tapered leg',(x+dx*1.14,y+dy*1.13,.025),(x+dx,y+dy,.38),.025,'wood')
    for dy in (-.215,.215):
        api.rod('chair back post',(x-.20,y+dy,.35),(x-.245,y+dy,.88),.025,'wood')
    api.box('chair curved crest',(x-.23,y,.855),(.065,.49,.09),'wood',.04,True)
    for dy in (-.12,0,.12):
        api.rod('chair back spindle',(x-.205,y+dy,.45),(x-.235,y+dy,.82),.013,'wood')

