"""Offline camera-only diagnostic. Does not write any project resources/images.
The six shared world points and measured pixels remain fixed.
"""
import json
import numpy as np

world = np.array([[0,1.1,0],[.9,1.1,0],[.9,3.2,0],[0,3.2,0],[1.469,0,.673],[3.031,0,.327]])
observations = [np.array([[723,493],[748,493],[749,363],[724,364],[803,558],[840,548]]),np.array([[746,514],[812,515],[813,328],[745,321],[839,663],[975,652]])]
initial = [[-12.70145,2.31744,9.786856,-3,-59,0,50],[9.0313,4.5131,10.7497,-12,36,0,40]]

def project(p,points):
    # Godot YXZ rotation order: global Y, local X, local Z.
    x,y,z=np.deg2rad(p[3:6]); cx,sx=np.cos(x),np.sin(x); cy,sy=np.cos(y),np.sin(y); cz,sz=np.cos(z),np.sin(z)
    rot=np.array([[cy,0,sy],[0,1,0],[-sy,0,cy]]) @ np.array([[1,0,0],[0,cx,-sx],[0,sx,cx]]) @ np.array([[cz,-sz,0],[sz,cz,0],[0,0,1]])
    q=(points-np.array(p[:3])) @ rot
    f=470.5/np.tan(np.deg2rad(p[6]/2))
    return np.column_stack((836-f*q[:,0]/q[:,2],470.5+f*q[:,1]/q[:,2]))

def diagnose(start, obs, points=world):
    scale=np.array([10,10,10,30,30,10,30.])
    low=np.array([-150,.2,.1,-80,-85,-10,10])/scale
    high=np.array([150,100,200,5,85,10,90])/scale
    x=np.array(start)/scale; damping=.01
    def residual(v): return (project(v*scale,points)-obs).ravel()
    for iteration in range(2000):
        r=residual(x)
        jac=np.column_stack([(residual(x+np.eye(len(x))[i]*1e-5)-r)/1e-5 for i in range(len(x))])
        h=jac.T@jac; g=jac.T@r
        delta=np.linalg.solve(h+damping*np.diag(np.maximum(np.diag(h),1)), -g)
        trial=np.clip(x+delta,low,high)
        if np.dot(residual(trial),residual(trial)) < r@r:
            x=trial; damping=max(damping/3,1e-9)
            if np.linalg.norm(delta)<1e-9: break
        else: damping=min(damping*5,1e12)
        if damping>=1e12: break
    return x*scale

if __name__=='__main__':
    reports=[]
    for name,obs,start in zip(['01','03'],observations,initial):
        print(name,'baseline',np.linalg.norm(project(start,world)-obs,axis=1)*1080/941)
        pose=diagnose(start,obs)
        errors=np.linalg.norm(project(pose,world)-obs,axis=1)*1080/941
        item=dict(shot=name,pose=pose.tolist(),errors=errors.tolist(),max=float(errors.max()))
        reports.append(item)
        print(json.dumps(item))
    print('Resources untouched; diagnostic only.')
