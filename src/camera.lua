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
 cyaw+=angd(ang-cyaw)*(st=="hang" and .03 or .05+h*.005)
 local d,fx,fz=2.6+h*.13,cos(cyaw),sin(cyaw)
 -- above + behind, looking down
 -- at the runner and ahead
 local t,w,lk={px,py+1.4,pz},{px-fx*d,py+2.5+h*.04,pz-fz*d},{px+cos(ang)*(1+h*.3),py+.9,pz+sin(ang)*(1+h*.3)}
 if st=="wallrun" then w[1]+=wnx*.9 w[3]+=wnz*.9 end
 -- boom collision: stop before a
 -- solid; too close -> lift up
 for k=.15,1,.15 do
  if solid(unpack(lerp3(t,w,k))) then
   w=k<.55 and {px-fx*.3,py+3,pz-fz*.3} or lerp3(t,w,k-.15)
   break
  end
 end
 for i=1,3 do
  cam[i]+=(w[i]-cam[i])*(i==2 and min(.3,.07+abs(w[2]-cam[2])*.04) or .2)
  look[i]+=(lk[i]-look[i])*.2
 end
 fl+=(72-h*1.7-fl)*.1
 shake=max(shake-dt)
 cpos={cam[1]+rnd(shake)-shake/2,cam[2]+rnd(shake),cam[3]}
 local lx,ly,lz=look[1]-cpos[1],look[2]-cpos[2],look[3]-cpos[3]
 local yaw,pit=atan2(lx,lz),atan2(sqrt(lx*lx+lz*lz),ly)
 ccy,csy,ccp,csp=cos(yaw),sin(yaw),cos(pit),sin(pit)
 cfw={ccy*ccp,csp,csy*ccp}
end

-- world -> camera space
function tocam(x,y,z)
 x-=cpos[1] y-=cpos[2] z-=cpos[3]
 local f=x*ccy+z*csy
 return z*ccy-x*csy,y*ccp-f*csp,f*ccp+y*csp
end

-- camera space -> screen, cached
-- on the point (shared corners
-- project once per frame)
function proj(c)
 local z=c[3]
 c.s=c.s or {64+c[1]*fl/z,64-c[2]*fl/z}
 return c.s
end
