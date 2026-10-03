-- procedural animation + 3d runner
-- pose q: 1 lean 2 side lean
-- 3 hip height 4/5 l thigh/knee
-- 6/7 r thigh/knee 8/9 l arm/elbow
-- 10/11 r arm/elbow 12 arm spread
-- 13 leg spread 14 body pitch
-- angles in turns, + = forward

q=split"0,0,.95,0,0,0,0,0,.1,0,.1,0,0,0"

-- key poses (q 1..13)
poses={
 up=".06,0,.95,.25,.4,-.04,.2,.3,.25,-.1,.2,.06,.03",
 push=".08,0,.98,-.06,.03,-.02,.04,.2,.1,-.15,.1,.04,.02",
 fall="-.02,0,.95,.1,.18,.04,.12,.34,.12,.36,.12,.14,.05",
 reach="0,0,.95,.08,.08,.02,.06,.15,.15,.12,.15,.18,.05",
 slide="-.12,0,.42,.25,0,.08,.42,-.06,.05,.2,.15,.12,.04",
 roll=".15,0,.5,.38,.45,.38,.45,.3,.3,.3,.3,0,0",
 land=".14,0,.55,.3,.5,.3,.5,.1,.1,.1,.1,.08,.06",
 v1=".15,0,1,.42,.5,.02,.12,.12,.04,.12,.04,0,.02",
 v2=".08,.12,1,.25,.25,.22,.2,.05,.02,.3,.1,.08,.1",
 v3="-.05,.15,1.05,.32,.05,.3,.08,.02,0,.35,.1,.1,.03",
 cat=".02,0,.95,.25,.12,.25,.12,.42,.15,.42,.15,0,.05",
 crouch=".15,0,.55,.18,.25,.18,.25,0,.1,0,.1,0,.04"
}

-- copy values into t from i
function ps(t,i,...)
 for k,a in ipairs{...} do t[i+k-1]=a end
end

-- run/walk/climb cycle: legs and
-- arms in antiphase
function cyc(t,amp,kn)
 local sl,cl=sin(aph)*amp,cos(aph)*amp
 ps(t,3,.95-abs(sl)*.25,sl,kn+max(cl)*1.8,-sl,kn+max(-cl)*1.8,-sl*.9,.15+amp*.7,sl*.9,.15+amp*.7)
end

function anim()
 local t,h,n=split"0,0,.95,0,.02,0,.02,0,.08,0,.08,.02,.03,0",hs(),st
 -- body turns smoothly and leans
 -- into the turn
 local tu=angd(ang-bang)
 bang+=tu*.25
 if st=="ground" then
  aph+=(h*.2+(h>.3 and .45 or 0))*dt
  n=crouch and "crouch"
  if h>.3 then
   local a=min(h/9,1)
   cyc(t,.08+a*.22,.06+a*.12)
   t[1]=.02+a*.07
  else
   t[1]=sin(time()/3)*.008
  end
  if narrow(gb) then
   -- balance: arms out
   ps(t,8,0,.08,0,.08,.23)
   tu=bal*-.06
  end
 elseif st=="air" then
  n=vy>0 and (stt<.12 and "push" or "up") or py-shy<1.5 and "reach" or "fall"
 elseif st=="vault" then
  n="v"..vt
 elseif st=="wallrun" or st=="wallup" then
  aph+=(wrs+3)*.25*dt
  cyc(t,.24,.18)
  -- lean towards the wall
  tu=(wnz*cos(ang)-wnx*sin(ang))*.15
  t[12]=.12
  if st=="wallup" then ps(t,1,-.04,0,.95,t[4]+.15,t[5],t[6]+.15,.1,.4,.1,.42) end
 elseif st=="hang" or st=="climb" then
  n=st=="hang" and hcat and "cat"
  local sw=sin(aph)*.06
  t=split"0,0,.95,0,.06,0,.06,.47,.03,.47,.03,0,.05,0"
  if st=="climb" then t=split"0,0,.95,.2,.3,.2,.3,.47,.03,.47,.03,0,.05,0" sw*=3 end
  t[4]+=sw t[6]-=sw t[8]-=sw t[10]+=sw
 elseif st=="pull" then
  local k=stt/pdur
  ps(t,1,.15*k,0,.95-k*.3,.35,.5,.1,.2,.45-k*.4,0,.45-k*.4)
 end
 if poses[n] then t=split(poses[n]) add(t,0) end
 t[2]-=tu*2
 if n=="roll" then t[14]=min(stt/.45,1) end
 for i=1,13 do q[i]+=(t[i]-q[i])*.3 end
 q[14]=t[14]
end

-- local (fwd,up,side) -> screen,
-- body pitch q[14] about the hip
function jp(p)
 local f,u,s=unpack(p)
 local ur=u-q[3]
 f,u=f*pcr+ur*psr,ur*pcr-f*psr+q[3]
 local c={tocam(px+bfx*f-bfz*s,py+u,pz+bfz*f+bfx*s)}
 if c[3]>near then
  local p=proj(c)
  p[3]=c[3]
  return p
 end
end

-- next joint: length l at swing a,
-- sideways spread sp on side sd
function seg(o,a,l,sp,sd)
 return {o[1]-sin(a)*cos(sp)*l,o[2]-cos(a)*cos(sp)*l,o[3]-sin(sp)*sd*l}
end

-- point along the spine at t
function spn(t,f,s)
 return {sdf*t+lcf*f,q[3]+sdu*t+lsf*f,sds*t+s}
end

-- queue a tapered limb segment
function cap(a,b,r,c)
 if a and b then add(bp,{(a[3]+b[3])/2,a,b,r,c}) end
end

-- queue the visible faces of a box
-- along the spine: heights u0..u1,
-- half width w, half depth d,
-- shifted forward by o
function tbox(u0,u1,w,d,o,cols)
 local cs,zc={},0
 for i=0,7 do
  local t,dp=i>3 and u1 or u0,(i%4>1 and d or -d)+o
  local c=jp(spn(t,dp,(i%2*2-1)*w))
  if not c then return end
  cs[i]=c
  zc+=c[3]/8
 end
 for k,f in pairs(bfaces) do
  local a,b,c,e=cs[f[1]],cs[f[2]],cs[f[3]],cs[f[4]]
  local z=(a[3]+b[3]+c[3]+e[3])/4
  -- faces nearer than the centre
  -- face the camera
  if z<zc then add(bp,{z,a,b,c,e,cols[k]}) end
 end
end

-- front back right left top bottom
bfaces={split"2,3,7,6",split"0,1,5,4",split"1,3,7,5",split"0,2,6,4",split"4,5,7,6",split"0,1,3,2"}

function drawplayer()
 local l,sl,hp=q[1],q[2],q[3]
 bfx,bfz,pcr,psr,bp=cos(bang),sin(bang),cos(q[14]),-sin(q[14]),{}
 -- spine direction + forward axis
 sdf,sdu,sds,lcf,lsf=-sin(l),cos(l)*cos(sl),-sin(sl),cos(l),sin(l)
 -- shadow blob
 if shy>0 then
  local sc={}
  for i=0,3 do
   add(sc,{tocam(px+cos(i/4)*.35,shy+.02,pz+sin(i/4)*.35)})
  end
  cpoly(sc,5)
 end
 local head=jp(spn(.76,0,0))
 if not head then return end
 -- which side faces the camera
 local cs=(cpos[1]-px)*-bfz+(cpos[3]-pz)*bfx>0 and 1 or -1
 local lg={}
 for sd=-1,1,2 do
  local i,nr=sd<0 and 4 or 6,sd==cs
  local th,kn,a,e,sp,lsp=q[i],q[i+1],q[i+4],q[i+5],q[12],q[13]
  -- leg: hip, knee, ankle, toe
  local h={0,hp,sd*.17}
  local k=seg(h,th,.45,lsp,sd)
  local an=seg(k,th-kn,.43,lsp,sd)
  add(lg,{jp(h),jp(k),jp(an),jp(seg(an,th-kn+.25,.2,0,sd)),nr})
  -- arm: shoulder, elbow, hand
  local sh=spn(.47,0,sd*.24)
  local el=seg(sh,a,.28,sp,sd)
  local je=jp(el)
  cap(jp(sh),je,.065,nr and 8 or 2)
  cap(je,jp(seg(el,a+e,.26,sp,sd)),.055,15)
 end
 -- two legs must always read as
-- two: every joint pair keeps a
-- leg width + 2px apart on screen
 local a,b=lg[1],lg[2]
 if a[1] and b[1] then
  local sg=sgn(b[1][1]-a[1][1])
  for i=1,4 do
   local p,o=a[i],b[i]
   if p and o then
    local m=max(.22*fl/p[3]+2-abs(o[1]-p[1]))/2*sg
    p[1]-=m
    o[1]+=m
   end
  end
 end
 for g in all(lg) do
  local c=g[5] and 1 or 0
  cap(g[1],g[2],.1,c)
  cap(g[2],g[3],.08,c)
  cap(g[3],g[4],.06,7)
 end
 -- pelvis, torso, backpack, neck
 tbox(-.1,.12,.16,.1,0,split"1,1,1,1,1,1")
 tbox(.1,.52,.2,.11,0,split"8,8,2,2,8,2")
 tbox(.16,.42,.13,.07,-.16,split"5,5,5,5,5,5")
 cap(jp(spn(.5,0,0)),head,.05,15)
 -- head: skin in front, hair behind
 cap(head,head,.15,15)
 local hb=jp(spn(.78,-.05,0))
 cap(hb,hb,.14,0)
 -- painter's order within the body
 for i=2,#bp do
  local p,j=bp[i],i-1
  while j>0 and bp[j][1]<p[1] do bp[j+1]=bp[j] j-=1 end
  bp[j+1]=p
 end
 for p in all(bp) do
  local a,b,r,c=unpack(p,2)
  if #p>5 then
   poly({a,b,r,c},p[6])
  else
   -- tapered capsule: a chain of
   -- discs, radius by depth
   local ra,rb=r*fl/a[3],r*fl/b[3]
   local n=ceil(sqrt((b[1]-a[1])^2+(b[2]-a[2])^2)/max(ra,1))+1
   for t=0,n do
    t/=n
    circfill(a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,ra+(rb-ra)*t,c)
   end
  end
 end
end
