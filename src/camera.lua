-- third-person camera
-- lags behind the heading, pulls
-- back + widens fov with speed,
-- never clips into walls

-- shortest signed angle diff
function angd(a)
 return (a+.5)%1-.5
end

function camreset()
 cyaw,fl=ang,70
 cam,look={px-cos(ang)*4,py+3,pz-sin(ang)*4},{px,py+1,pz}
 camupd()
end

function camupd()
 local h=hs()
 local fs=st=="hang" or st=="climb" or st=="wallup"
 cyaw+=angd(ang-cyaw)*(fs and .03 or .05+h*.005)
 local d,fx,fz=2.7+h*.14,cos(cyaw),sin(cyaw)
 local tx,ty,tz=px,py+1.4,pz
 local dx,dy,dz=tx-fx*d,ty+.7+h*.04,tz-fz*d
 if st=="wallrun" then dx+=wnx*.9 dz+=wnz*.9 end
 -- boom collision: stop before
 -- the first solid sample
 for k=.15,1,.15 do
  if solid(tx+(dx-tx)*k,ty+(dy-ty)*k,tz+(dz-tz)*k) then
   k-=.15
   dx,dy,dz=tx+(dx-tx)*k,ty+(dy-ty)*k,tz+(dz-tz)*k
   break
  end
 end
 local ey=dy-cam[2]
 cam[1]+=(dx-cam[1])*.2
 cam[3]+=(dz-cam[3])*.2
 cam[2]+=ey*min(.3,.07+abs(ey)*.04)
 -- look ahead along the run
 look[1]+=(tx+cos(ang)*h*.3-look[1])*.2
 look[2]+=(ty-.2-look[2])*.15
 look[3]+=(tz+sin(ang)*h*.3-look[3])*.2
 fl+=(72-h*1.7-fl)*.1
 shake=max(shake-dt)
 local sx,sy,sz=cam[1]+rnd(shake)-shake/2,cam[2]+rnd(shake),cam[3]
 cpos={sx,sy,sz}
 local lx,ly,lz=look[1]-sx,look[2]-sy,look[3]-sz
 local yaw,pit=atan2(lx,lz),atan2(sqrt(lx*lx+lz*lz),ly)
 ccy,csy,ccp,csp=cos(yaw),sin(yaw),cos(pit),sin(pit)
end

-- world -> camera space
function tocam(x,y,z)
 x-=cpos[1] y-=cpos[2] z-=cpos[3]
 local f=x*ccy+z*csy
 return z*ccy-x*csy,y*ccp-f*csp,f*ccp+y*csp
end

-- camera space -> screen
function proj(c)
 local z=c[3]
 return {64+c[1]*fl/z,64-c[2]*fl/z}
end
