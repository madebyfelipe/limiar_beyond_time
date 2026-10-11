"""Compare explicitly authored layouts; only camera poses are fitted.
Does not reconstruct meshes or modify files/resources.
"""
from env1_pose_diagnostic import *
layouts=[
    ('straight_90',.9,1.1,2.0,1.5,1.6),
    ('straight_70',.7,1.1,2.0,1.2,1.6),
    ('straight_75',.75,1.2,1.8,1.5,1.6),
]
for name,width,height,cx,cz,stepwidth in layouts:
    points=np.array([[0,height,0],[width,height,0],[width,height+2.1,0],[0,height+2.1,0],[cx-stepwidth/2,0,cz],[cx+stepwidth/2,0,cz]])
    print(name,'geometry',points.tolist())
    for i in range(2):
        start=initial[i] if i==0 else [-7,4.5,12,-12,-36,0,40]
        pose=diagnose(start,observations[i],points)
        print(i,'pose',pose.tolist(),'errors',np.linalg.norm(project(pose,points)-observations[i],axis=1)*1080/941)
