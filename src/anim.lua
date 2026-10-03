-- procedural animation
-- pose q: 1 lean 2 side lean
-- 3 hip height 4/5 l thigh/knee
-- 6/7 r thigh/knee 8/9 l arm/elbow
-- 10/11 r arm/elbow 12 arm spread
-- 13 body pitch (rolls)
-- angles in turns, + = forward

q=split"0,0,.95,0,0,0,0,0,.1,0,.1,0,0"

-- key poses (from index 1)
poses={
 up=".04,0,.95,.22,.35,-.05,.15,.3,.2,-.08,.2,.05",
 fall="-.02,0,.95,.12,.12,0,.08,.32,.1,.36,.1,.12",
 slide="-.1,0,.42,.24,.02,.06,.35,-.1,.05,.22,.1,.05",
 roll=".1,0,.5,.38,.45,.38,.45,.3,.3,.3,.3,0",
 land=".13,0,.55,.3,.5,.3,.5,.1,.1,.1,.1,.08",
 v1=".12,0,1,.35,.45,0,.1,.15,.05,.15,.05,0",
 v2=".06,.1,1,.25,.2,.22,.15,.08,.02,.3,.1,.08",
 v3="-.06,.14,1.05,.3,.05,.28,.08,.02,0,.35,.1,.1",
 cat=".02,0,.95,.25,.12,.25,.12,.42,.15,.42,.15,0",
 crouch=".14,0,.55,.18,.25,.18,.25,0,.1,0,.1,0"
}

-- copy pose values into t at i
function ps(t,i,...)
 for k,a in ipairs{...} do t[i+k-1]=a end
end

-- run/walk/climb cycle
function cyc(t,amp,kn)
 local sl,cl=sin(aph)*amp,cos(aph)*amp
 ps(t,3,.95-abs(sl)*.25,sl,kn+max(cl)*1.6,-sl,kn+max(-cl)*1.6,-sl*.9,.12+amp*.6,sl*.9,.12+amp*.6)
end

function anim()
 local t,h,n=split"0,0,.95,0,.02,0,.02,0,.08,0,.08,.02,0",hs(),st
 if st=="ground" then
  aph+=(h*.2+(h>.3 and .45 or 0))*dt
  n=crouch and "crouch"
  if h>.3 then
   local a=min(h/9,1)
   cyc(t,.06+a*.2,.05+a*.1)
   t[1]=.01+a*.06
  else
   -- idle: breathing
   t[1]=sin(time()/3)*.008
  end
  t[2]=turn*h*.006
  if narrow(gb) then
   -- balance: arms out
   ps(t,8,0,.08,0,.08,.22)
   t[2]=bal*.08
  end
 elseif st=="air" then
  n=vy>0 and "up" or "fall"
 elseif st=="vault" then
  n="v"..vt
 elseif st=="wallrun" or st=="wallup" then
  aph+=(wrs+3)*.25*dt
  cyc(t,.2,.15)
  t[2]=(wnz*cos(ang)-wnx*sin(ang))*.07
  if st=="wallup" then ps(t,1,-.04,0,.95,t[4]+.15,t[5],t[6]+.15,.1,.4,.1,.42) end
 elseif st=="hang" or st=="climb" then
  n=st=="hang" and hcat and "cat"
  local sw=sin(aph)*.05
  ps(t,1,.02,0,.95,sw,.04,-sw,.04,.47-sw,.03,.47+sw,.03)
  if st=="climb" then ps(t,4,.2+sw*3,.3,.2-sw*3,.3) end
 elseif st=="pull" then
  local k=stt/pdur
  ps(t,1,.15*k,0,.95-k*.3,.35,.5,.1,.2,.45-k*.4,0,.45-k*.4,0)
 end
 if poses[n] then t=split(poses[n]) add(t,0) end
 if n=="roll" then t[13]=min(stt/.45,1) end
 for i=1,12 do q[i]+=(t[i]-q[i])*.3 end
 q[13]=t[13]
end

-- skeleton -> screen, draw limbs
function drawplayer()
 local fx,fz,hip,cr,sr=cos(ang),sin(ang),q[3],cos(q[13]),-sin(q[13])
 -- shadow blob
 if shy>0 then
  local sc={}
  for i=0,3 do
   add(sc,{tocam(px+cos(i/4)*.35,shy+.02,pz+sin(i/4)*.35)})
  end
  cpoly(sc,5)
 end
 -- local (fwd,up,side) -> screen
 local function j(f,u,sd)
  local ur=u-hip
  f,u=f*cr+ur*sr,ur*cr-f*sr+hip
  local c={tocam(px+fx*f-fz*sd,py+u,pz+fz*f+fx*sd)}
  if c[3]>near then
   local s=proj(c)
   s[3]=c[3]
   return s
  end
 end
 local l,sl=q[1],q[2]
 local nf,nu,ns=-sin(l)*.55,hip+cos(l)*cos(sl)*.55,-sin(sl)*.55
 local neck,head=j(nf,nu,ns),j(nf*1.45,hip+(nu-hip)*1.45,ns*1.45)
 if not head then return end
 local w,parts=mid(1,flr(fl/head[3]/9),3),{}
 for sd=-1,1,2 do
  local i=sd<0 and 4 or 6
  local th,kn,a,e,sp=q[i],q[i+1],q[i+4],q[i+5],q[12]
  local kf,ku=-sin(th)*.45,hip-cos(th)*.45
  add(parts,{sd,j(0,hip,sd*.12),j(kf,ku,sd*.12),j(kf-sin(th-kn)*.45,ku-cos(th-kn)*.45,sd*.13),1,1})
  -- arm: swing a, spread sp
  local ef,eu,es=-sin(a)*cos(sp)*.3,-cos(a)*cos(sp)*.3,-sin(sp)*sd*.3
  local sf,su,ss=nf,nu-.06,ns+sd*.2
  add(parts,{sd,j(sf,su,ss),j(sf+ef,su+eu,ss+es),j(sf+ef-sin(a+e)*cos(sp)*.28,su+eu-cos(a+e)*cos(sp)*.28,ss+es*1.9),8,15})
 end
 -- far side limbs first
 local cs=(cpos[1]-px)*-fz+(cpos[3]-pz)*fx>0 and -1 or 1
 for pass=1,3 do
  if pass==2 then
   -- torso + head
   local a,b,c,d=parts[1][2],parts[3][2],parts[4][2],parts[2][2]
   if a and b and c and d then poly({a,b,c,d},8) end
   limb(neck,head,15,w)
   circfill(head[1],head[2],w*1.3,15)
   circfill(head[1],head[2]-w*.5,w,4)
  else
   for pt in all(parts) do
    if pt[1]==cs*(3-pass*2) then
     limb(pt[2],pt[3],pt[5],w)
     limb(pt[3],pt[4],pt[6],w)
    end
   end
  end
 end
end

function limb(a,b,c,w)
 if a and b then
  for o=0,w-1 do line(a[1]+o,a[2],b[1]+o,b[2],c) end
 end
end
