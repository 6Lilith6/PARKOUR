-- procedural animation + 3d runner
-- pose q: 1 lean 2 side lean
-- 3 hip height 4/5 l ankle fwd/up
-- 6/7 r ankle fwd/up (ankle
-- targets: knees follow by ik)
-- 8/9 l arm/elbow 10/11 r arm/
-- elbow 12 arm spread 13 feet
-- side shift 14 body pitch
-- angles in turns, + = forward

q=split"0,0,.93,0,.07,0,.07,0,.1,0,.1,0,0,0"

-- key poses (q 1..13)
poses={
 push=".06,0,.95,-.3,.12,.2,.4,.15,.15,-.1,.15,.04,0",
 up=".04,0,.95,-.1,.3,.15,.35,.12,.2,.05,.2,.08,0",
 fall=".02,0,.95,0,.18,.1,.12,.15,.15,.12,.15,.15,0",
 reach=".04,0,.93,.14,.08,.02,.12,.12,.12,.08,.12,.12,0",
 slide="-.1,.03,.45,.75,.07,-.05,.07,-.12,.05,.15,.2,.1,0",
 roll=".15,0,.6,.15,.4,.1,.35,.3,.3,.3,.3,0,0",
 land=".14,0,.56,.18,.07,-.12,.07,.12,.15,.08,.15,.06,0",
 v1=".15,0,1,.15,.45,.05,.5,.1,.08,.12,.08,0,0",
 v2=".1,.08,1,.25,.4,.15,.45,.06,.04,.08,.04,.08,.12",
 v3=".08,.12,1,.3,.45,.2,.5,.06,.02,.15,.12,.12,.2",
 cat="0,0,.95,.25,.45,.25,.4,.46,.03,.46,.03,0,0",
 hang="0,0,.95,.04,.1,-.03,.12,.46,.03,.46,.03,0,0",
 wallup=".02,0,.95,.3,.4,.24,.15,.38,.12,.42,.12,.05,0",
 climb="0,0,.95,.2,.3,.2,.3,.42,.1,.42,.1,0,0",
 pull="0,0,.95,.04,.1,0,.12,.46,.2,.46,.2,0,0"
}

-- run cycle at speed h: cadence
-- and stride from speed, the
-- stance foot moves back at
-- exactly h (planted), swing
-- foot lifts and swings forward
function gait(t,h)
 local f=1.1+h*.13
 -- legs follow the cycle closely
 rt=.75
 aph+=f*dt
 local d=min(.6,.5*f/h)
 local s=h*d/f
 -- pelvis: lowest mid-stance
 -- (runs), ballistic in flight
 t[3]=sqrt(.757-s*s/4)+.07-(.5-d)*.06*cos(aph*2-d)
 for i=0,1 do
  local p,x,u=(aph+i/2)%1,0,.07
  if p<d then
   x=s/2-s*p/d
  else
   p=(p-d)/(1-d)
   -- heel kicks up behind, then
   -- the leg reaches forward low
   -- and pulls back into contact
   x,u=sin(p)*.15-cos(p/2)*s/2,.07-sin(p/2)*(1.3-p)*(.08+h*.025)
  end
  -- arms swing against the leg
  local j=4+i*2
  t[j],t[j+1],t[j+4],t[j+5]=x,u,.03-x*.22,.14+h*.008
 end
 t[1]=.01+h*.004
end

function anim()
 rt=.3
 -- pose for this state (ground and
 -- wallrun start from standing)
 local h,n,tu=hs(),st=="air" and (vy>0 and (stt<.12 and "push" or "up") or py-shy<1.2 and "reach" or "fall") or st=="vault" and "v"..vt or st=="hang" and hcat and "cat" or st,angd(ang-bang)
 local t=split(poses[n] or "0,0,.93,.04,.07,-.04,.07,.03,.08,.03,.08,.03,0")
 add(t,0)
 -- body follows the heading with
 -- a short lag
 bang+=tu*.25
 if st=="ground" then
  if h>.3 then
   gait(t,h)
   -- lean with acceleration
   t[1]+=mid(-.04,(h-oh)*.25,.03)
  else
   -- idle: slow breathing only
   t[3]+=sin(time()/4)*.004
  end
  if crouch then t[3]-=.3 t[1]+=.1 end
  -- landing: knees take the
  -- impact, more for harder ones
  if lvy<-4 then lc=(-lvy-4)*.03 end
  t[3]-=lc
  if narrow(gb) then
   -- balance: arms out
   t[8],t[10],t[12],tu=0,0,.25,bal*-.06
  end
 elseif st=="wallrun" then
  gait(t,wrs)
  -- lean into the wall, feet on it
  local w=wnx*sin(bang)-wnz*cos(bang)
  t[2],t[12],t[13]=w*.04,.14,w*.2
 elseif st=="climb" then
  local w=sin(aph)*.12
  t[5]+=w t[7]-=w t[8]-=w/3 t[10]+=w/3
 elseif st=="pull" then
  -- arms press down as the body
  -- rises, a knee comes up to
  -- the ledge
  local k=stt/pdur
  t[1],t[8],t[10]=k*.15,.46-k*.42,.46-k*.42
  if k>.35 then t[6],t[7]=.3,min(hb[5]-py,.5)+.07 end
 end
 lvy,oh,lc=st=="air" and vy or 0,h,lc*.85
 -- lean into turns, more when fast
 t[2]-=tu*(h+3)*.12
 if n=="roll" then t[14]=min(stt/.45,1) end
 for i=1,13 do q[i]+=(t[i]-q[i])*rt end
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
-- (shifted over the stance leg)
function spn(t,f,s)
 return {sdf*t+lcf*f,q[3]+sdu*t+lsf*f,sds*t+s+sh}
end

-- queue a tapered limb segment
function cap(a,b,r,c)
 if a and b then add(bp,{(a[3]+b[3])/2,a,b,r,c}) end
end

function drawplayer()
 local l,sl,hp=q[1],q[2],q[3]
 bfx,bfz,pcr,psr,bp=cos(bang),sin(bang),cos(q[14]),-sin(q[14]),{}
 -- spine direction + forward axis
 sdf,sdu,sds,lcf,lsf=-sin(l),cos(l)*cos(sl),-sin(sl),cos(l),sin(l)
 -- pelvis drifts over the foot
 -- that carries the weight
 sh=(q[5]-q[7])*.06
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
  -- leg: two-bone ik from the hip
  -- (pelvis turns with the
  -- stride) to the ankle target,
  -- knee bends forward
  local h,az=(q[6]-q[4])*sd*.05,sd*.12+q[13]
  local f,u=q[i]-h,q[i+1]-hp
  local d=max(sqrt(f*f+u*u),.05)
  local x=(.0176+d*d)/2/d
  local y=sqrt(max(.2025-x*x))
  local k,an={h+(x*f-y*u)/d,hp+(x*u+y*f)/d,sd*.15+az/2+sh/2},{h+f,hp+u,az}
  -- foot square to the shin,
  -- flat on the ground
  add(lg,{jp{h,hp,sd*.17+sh},jp(k),jp(an),jp{an[1]-(an[2]-k[2])*.46,max(an[2]+(an[1]-k[1])*.46,.02),az},nr})
  -- arm: shoulder, elbow, hand
  local so=spn(.47,0,sd*.24)
  local el=seg(so,q[i+4],.28,q[12],sd)
  local je=jp(el)
  cap(jp(so),je,.065,nr and 8 or 2)
  cap(je,jp(seg(el,q[i+4]+q[i+5],.26,q[12],sd)),.055,15)
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
 for p in all{split"0,.04,.15,1,0",split".18,.42,.19,8,0",split".22,.36,.12,5,-.12",split".5,.76,.05,15,0"} do
  cap(jp(spn(p[1],p[5],0)),jp(spn(p[2],p[5],0)),p[3],p[4])
 end
 -- head: skin in front, hair behind
 cap(head,head,.15,15)
 local hb=jp(spn(.78,-.05,0))
 cap(hb,hb,.14,0)
 -- painter's order within the body
 isort(bp,1)
 for p in all(bp) do
  local a,b,r,c=unpack(p,2)
  -- tapered capsule: a chain of
  -- discs, radius by depth (limbs
  -- are short enough for 6)
  local ra,rb=r*fl/a[3],r*fl/b[3]
  for t=0,1,.2 do
   circfill(a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,ra+(rb-ra)*t,c)
  end
 end
end
