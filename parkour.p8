pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- parkour: rooftops
-- third-person 3d parkour
-- main loop, game flow,
-- checkpoints, timer, hud

dt=1/60
hints=split("⬆️ run   ⬅️➡️ steer   🅾️ jump|run into low obstacles: vault\nfaster run = smoother vault|❎ while running: slide|❎ just before landing: roll\nhigh drops without it hurt|jump at a ledge to grab it\n⬆️ climb  ⬅️➡️ shimmy  ❎ drop\n⬇️+🅾️ jump away|yellow = climbable\nhold ⬆️ to climb|hold 🅾️ into a wall: run up it\nhold 🅾️ along a wall: wallrun|on a wall press 🅾️: kick off\n(tic-tac / wall jump)|narrow beams: ⬅️➡️ keep balance|red awnings bounce you high|keep moving to build flow\nflow = higher top speed|three ways up: ladder,\nsteps, or run up the wall|wallrun, 🅾️ wall jump, wallrun\nor take the cable / skybridge|last climb: stairs, chimney\nor vault-jump-mantle","|")

function _init()
 cartdata"pk_rooftops_1"
 loadlvl()
 menuitem(1,"restart level",restart)
 menuitem(2,"last checkpoint",respawn)
 music(0,2000)
 mode="title"
 restart()
end

function restart()
 cpi,tm,splits,score,cp,started,run=0,0,{},0,spawn,false,{}
 respawn()
end

-- reset player at checkpoint
function respawn()
 px,py,pz,ang=unpack(cp)
 vx,vy,vz,spd,flow,chain,idle,bal,balv,heavy,ngrab,jbuf,rbuf,coy,kicks,aph,shake,stun,popt,splt,shy,wrs=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 peak,pop,fade,crouch,gb,wupd,lastwr=py,"",12
 setst"ground"
 nearupd()
 camreset()
end

function inp()
 local o,x=jz,xx
 jz,xx,iu,id=btn(4),btn(5),btn(2),btn(3)
 jzp,xp=jz and not o,xx and not x
 turn=(btn(0) and 1 or 0)-(btn(1) and 1 or 0)
end

function _update60()
 inp()
 if mode~="play" then
  if mode=="title" then ang+=.0008 end
  if jzp then mode="play" restart() end
 else
  if btn()>0 then started=true end
  if started then
   tm=min(tm+1,32000)
   -- record for the ghost
   if tm%4==0 then add(run,px) add(run,py) add(run,pz) end
  end
  fade,splt,popt=max(fade-1),max(splt-dt),max(popt-dt)
  pupd()
  trigupd()
 end
 camupd()
 fxupd()
end

function trigupd()
 hint=nil
 for b in all(trig) do
  if px>b[1] and px<b[4] and pz>b[3] and pz<b[6] and py>b[2]-1 and py<b[5] then
   if b.m==11 and b.k>cpi then
    cpi,cp,splt=b.k,{(b[1]+b[4])/2,b[2],(b[3]+b[6])/2,ang},2.5
    splits[cpi]=tm
    sdel=dget(cpi)>0 and tm-dget(cpi)
    sfx(6)
   elseif b.m==12 then
    -- finish line
    mode,best="done",dget(0)
    newbest=best==0 or tm<best
    if newbest then
     ghost=run
     dset(0,tm)
     for i,s in pairs(splits) do dset(i,s) end
    end
    dset(20,1)
    sfx(9)
   elseif b.m==13 then
    hint=b.k+1
   end
  end
 end
end

-- m:ss.cc from frames
function ft(f)
 local s=flr(f/60)
 return flr(s/60)..":"..sub("0"..s%60,-2).."."..sub("0"..flr(f%60*5/3),-2)
end

-- outlined text (centered if no x)
function pr(s,y,c,x)
 x=x or 64-#s*2
 for d=-1,1,2 do print(s,x+d,y,0) print(s,x,y+d,0) end
 print(s,x,y,c)
end

function _draw()
 render()
 if mode=="title" then
  rectfill(0,30,127,74,0)
  pr("\^w\^tparkour",36,7,36)
  pr("rooftops",50,9)
  pr("press 🅾️ to start",64,7)
  pr("⬅️➡️ steer  ⬆️ run  ⬇️ brake",92,6,6)
  pr("🅾️ jump, hold on walls",100,6,6)
  pr("❎ slide / roll / drop",108,6,6)
  if dget(20)>0 then pr("best "..ft(dget(0)),116,10) end
  return
 end
 -- timer, best time
 pr(ft(tm),2,7,2)
 if dget(20)>0 then pr(ft(dget(0)),9,5,2) end
 -- checkpoint split vs best
 if splt>0 then
  pr("checkpoint "..cpi..(sdel and "  "..(sdel<=0 and "-" or "+")..ft(abs(sdel)) or ""),20,sdel and sdel>0 and 8 or 11)
 end
 -- speed + flow meter
 rectfill(2,121,2+hs()/9*40,124,flow>.6 and 10 or flow>.3 and 9 or 13)
 rect(1,120,43,125,5)
 -- move popup + chain
 if popt>0 then
  pr(pop..(chain>1 and " x"..chain or ""),108-popt*4,popt>.3 and 7 or 6)
 end
 if hint then
  rectfill(2,97,125,117,1)
  print(hints[hint],4,99,7)
 end
 if fade>0 then
  fillp(fade>6 and 0 or 0x5a5a)
  rectfill(0,0,127,127,0)
  fillp()
 end
 if mode=="done" then
  rectfill(16,34,111,96,0)
  rect(16,34,111,96,7)
  pr("rooftops cleared",40,10)
  pr("time  "..ft(tm),52,7)
  pr(newbest and "new best!" or "best  "..ft(best),60,newbest and 11 or 6)
  pr("flow score "..score,72,12)
  pr("🅾️ time trial again",86,7)
 end
end
-->8
-- level geometry
-- boxes are stored in map memory
-- (0x2000) by tools/build.py:
-- x,z:2 bytes (/8) y,w,h,d:1 byte
-- (/4) mat:1 byte (lo=mat hi=arg)

-- materials:
-- top,side x,side z,flags,deco
-- flags 1 solid 2 climb 4 bouncy
-- 8 trigger
-- deco 1 windows 2 rungs 3 ad
-- 4 stripes 5 vents
mats={}
for m in all(split("6,13,5,1,1|15,4,2,1,1|7,6,13,1,5|9,4,4,1|6,13,5,1|10,9,9,3,2|5,14,2,1,3|8,2,2,5,4|4,4,2,1|12,1,1,1|0,0,0,8|0,0,0,8|0,0,0,8|13,5,1,1,1","|")) do
 add(mats,split(m))
end

function loadlvl()
 boxes,trig,dl={},{},{}
 for a=0x2002,0x2001+peek2(0x2000)*9,9 do
  local x,z,y,m=peek2(a)/8,peek2(a+2)/8,peek(a+4)/4,peek(a+8)
  local b={x,y,z,x+peek(a+5)/4,y+peek(a+6)/4,z+peek(a+7)/4,m=m%16,k=m\16}
  b.f,b.rad=mats[b.m][4],(b[4]-x+b[5]-y+b[6]-z)/2
  if b.f&8>0 then
   add(trig,b)
   if b.m==11 and b.k==0 then spawn={x+1,y,z+1,.75} end
  else
   add(boxes,b) add(dl,b)
  end
 end
 -- player pseudo-box, sorted
 -- with the world for drawing
 plb={rad=1}
 add(dl,plb)
end
-->8
-- collision system
-- player = aabb at feet px,py,pz
-- radius r, height ph

r=.3

-- gather boxes near the player
function nearupd()
 nb={}
 for b in all(boxes) do
  if b[1]<px+8 and b[4]>px-8 and b[3]<pz+8 and b[6]>pz-8 and b[2]<py+8 and b[5]>py-8 then
   add(nb,b)
  end
 end
end

-- first near solid overlapping
-- the given region
function hit(x0,y0,z0,x1,y1,z1)
 for b in all(nb) do
  if x0<b[4] and x1>b[1] and y0<b[5] and y1>b[2] and z0<b[6] and z1>b[3] then
   return b
  end
 end
end

function phit(y)
 y=y or py
 return hit(px-r,y,pz-r,px+r,y+ph,pz+r)
end

function solid(x,y,z)
 return hit(x-.05,y-.05,z-.05,x+.05,y+.05,z+.05)
end

-- step onto low curbs/stairs
function stepup(b)
 if st~="air" and st~="wallrun" and b[5]-py<.55 and not phit(b[5]+.01) then
  py=b[5]+.01
  return true
 end
end

-- move by velocity, axis by axis.
-- sets wall/gnd contacts
function pmove()
 wall,gnd=nil
 px+=vx*dt
 local b=phit()
 if b and vx~=0 and not stepup(b) then
  px=vx>0 and b[1]-r-.001 or b[4]+r+.001
  wall,wnx,wnz=b,-sgn(vx),0
 end
 pz+=vz*dt
 b=phit()
 if b and vz~=0 and not stepup(b) then
  pz=vz>0 and b[3]-r-.001 or b[6]+r+.001
  wall,wnx,wnz=b,0,-sgn(vz)
 end
 py+=vy*dt
 b=phit()
 if b and vy~=0 then
  if vy<0 then
   py,gnd=b[5],b
   -- prefer wide footing over
   -- beams/ladder tops
   for o in all(nb) do
    if px-r<o[4] and px+r>o[1] and pz-r<o[6] and pz+r>o[3] and o[5]==py and not narrow(o) then gnd=o end
   end
  else
   py=b[2]-ph
  end
  vy=0
 end
end

function hs()
 return sqrt(vx*vx+vz*vz)
end
-->8
-- parkour detection + move
-- starters used by the states

function narrow(b)
 return b and min(b[4]-b[1],b[6]-b[3])<.7
end

-- low obstacle with free space
-- on top in front of us?
function canvault(b)
 local h,x,z=b[5]-py,px+cos(ang)*.5,pz+sin(ang)*.5
 return h>.5 and h<1.4 and b.f&2==0 and not hit(x-r,b[5]+.02,z-r,x+r,b[5]+1.6,z+r)
end

-- ledge in front of the hands,
-- top lo..hi above the feet,
-- with room to climb onto it
function findledge(lo,hi)
 local x,z=px+cos(ang)*.6,pz+sin(ang)*.6
 for b in all(nb) do
  local t=b[5]-py
  if t>lo and t<hi and x>b[1] and x<b[4] and z>b[3] and z<b[6] and not hit(x-.2,b[5]+.05,z-.2,x+.2,b[5]+1,z+.2) then
   return b
  end
 end
end

-- face box b from the side the
-- player is outside of
function snapface(b,zf)
 if zf==nil then zf=max(b[1]-px,px-b[4])<=max(b[3]-pz,pz-b[6]) end
 if not zf then
  wnx,wnz=px<b[1] and -1 or 1,0
  px=wnx<0 and b[1]-r or b[4]+r
 else
  wnx,wnz=0,pz<b[3] and -1 or 1
  pz=wnz<0 and b[3]-r or b[6]+r
 end
 ang,vx,vy,vz=atan2(-wnx,-wnz),0,0,0
end

-- move feedback: name, flow, sfx
function trick(n,f,s)
 pop,popt,idle=n,1,0
 chain+=1
 score=min(score+5*min(chain,20),32000)
 flow=mid(0,flow+f,1)
 if s then sfx(s) end
end

-- a mistake: breaks the chain
function brk(n,s)
 pop,popt,chain,idle=n,1,0,0
 flow*=.4
 if s then sfx(s) end
end

function toair()
 peak=py
 setst"air"
end

function dojump()
 local h,jv=spd,6.2
 if spd<2.5 then
  -- standing: precise hop
  h=iu and 3.6 or 0
 else
  jv=6+spd*.2
  -- takeoff right at an edge
  if not solid(px+cos(ang)*.8,py-.3,pz+sin(ang)*.8) then
   h*=1.08 trick("edge jump",.06)
  end
 end
 if narrow(gb) then jv-=.6 end
 if st=="slide" or st=="roll" then jv-=.5 trick(st.." jump",.05) end
 vx,vy,vz,jbuf=cos(ang)*h,jv,sin(ang)*h,0
 toair()
 sfx(1)
end

function startvault(b)
 vtop,vy0,vt=b[5],py,spd<3.6 and 1 or spd<6.3 and 2 or 3
 -- tall obstacles can't be
 -- speed vaulted cleanly
 if vtop-py>1.15 then vt=min(vt,2) end
 vdur,vspd=({.38,.2,.12})[vt],({min(spd,2.2),spd*.92,spd*1.04})[vt]
 trick(({"climb over","vault","speed vault"})[vt],vt*.05-.05,7)
 setst"vault"
end

-- in-air ledge test: mantle low
-- ledges, hang from high ones
function airgrab()
 if ngrab>0 or xx then return end
 local b=findledge(.1,2.15)
 if b then
  if b[5]-py<1.3 then
   -- wall climbs flow into a vault
   spd=max(hs(),st=="wallup" and 4.5 or 0)
   startvault(b)
   return true
  end
  if vy<2.5 then
   hb,hcat=b,hs()>3
   snapface(b)
   py=b[5]-(hcat and 1.5 or 2.05)
   setst"hang"
   trick(hcat and "cat leap" or "ledge grab",hcat and .1 or 0,4)
   return true
  end
 end
end

function startpull()
 pa,pb={px,py,pz},{px+cos(ang)*.7,hb[5]+.01,pz+sin(ang)*.7}
 pdur=hcat and .3 or .5
 setst"pull"
end

-- kick off a wall (tic-tac / wall
-- jump): keep along-wall speed vp
function wallkick(vp,out,n)
 vx,vy,vz,jbuf=-wnz*vp+wnx*out,max(vy,6.6-kicks*1.3),wnx*vp+wnz*out,0
 kicks+=1
 ang=atan2(vx,vz)
 toair()
 trick(n,.1,4)
end

-- jump away from a ledge/ladder
function jumpback()
 ang+=.5
 vx,vy,vz,ngrab=cos(ang)*4.5,6.5,sin(ang)*4.5,.25
 toair()
 trick("wall jump",.05,4)
end

function bonk()
 vx,vz,spd,shake=0,0,0,.15
 brk("ouch",11)
end
-->8
-- player physics + state machine
-- one update function per state

g=20
s={}

function setst(n)
 st,stt,ph=n,0,1.8
end

function pupd()
 nearupd()
 stt+=dt
 jbuf,rbuf,ngrab=max(jbuf-dt),max(rbuf-dt),max(ngrab-dt)
 if jzp then jbuf=.12 end
 if xp then rbuf=.3 end
 s[st]()
 -- fell into the street
 if py<1 then
  sfx(11) respawn()
 end
 -- shadow height
 shy=-1
 for b in all(nb) do
  if px>b[1] and px<b[4] and pz>b[3] and pz<b[6] and b[5]<=py+.05 then shy=max(shy,b[5]) end
 end
 anim()
end

-- ground velocity from heading
function gvel()
 vx,vy,vz=cos(ang)*spd,-3,sin(ang)*spd
 pmove()
end

-- idle/walk/run/sprint/crouch
-- and balancing on beams
s.ground=function()
 local nar,vmax=narrow(gb),6.2+flow*2.8
 if nar then
  vmax=4
  if balance() then return end
 else
  ang+=turn*(.6-min(spd,9)*.04)*dt
 end
 if heavy>0 then heavy-=dt vmax=2.5 end
 -- crouch: x held slow, or
 -- no headroom
 ph=1.8
 crouch=xx and spd<3.5 or phit()
 if crouch then ph,vmax=1,1.6 end
 if iu then
  spd+=(spd<5 and 9 or 2.2)*dt
 else
  spd-=(id and 16 or spd>3 and 4 or 9)*dt
 end
 if spd>vmax then spd=max(vmax,spd-6*dt) end
 spd=max(spd)
 -- momentum: flow builds while
 -- fast, drains when slow
 if spd>5.8 then flow=min(flow+.04*dt,1) end
 if spd<3 then flow=max(flow-.5*dt) end
 if spd<1.5 then
  idle+=dt
  if idle>1.2 then chain=0 end
 end
 if jbuf>0 and not crouch then dojump() return end
 if xp and spd>=3.5 and not nar then
  spd*=1.05
  trick("slide",0,3)
  setst"slide"
  return
 end
 gvel()
 if not gnd then
  coy,vy=.1,0
  toair()
  return
 end
 gb=gnd
 local f=flr(aph*2)
 if f~=lstep and spd>.5 then sfx(0) end
 lstep=f
 if wall then
  local into=-cos(ang)*wnx-sin(ang)*wnz
  if wall.f&2>0 and iu and into>.5 then
   startclimb()
  elseif into>.5 and spd>1 and canvault(wall) then
   startvault(wall)
  elseif into>.6 and jz and spd>3 then
   wallup(spd*into)
  elseif into>.7 then
   if spd>5.5 then
    bonk()
    stun=.3
    setst"land"
   end
   spd=0
  elseif into>0 then
   -- glancing: slide along it
   local tx,tz=-wnz,wnx
   if cos(ang)*tx+sin(ang)*tz<0 then tx,tz=-tx,-tz end
   ang=atan2(tx,tz)
   spd*=1-into*.5
  end
 end
end

-- beam wobble grows with speed,
-- ⬅️➡️ counters it
function balance()
 ang+=angd((gb[4]-gb[1]>gb[6]-gb[3] and (cos(ang)>0 and 0 or .5) or (sin(ang)>0 and .75 or .25))-ang)*.15
 balv=balv*.97+((rnd(2)-1)*(1+spd*.8)+bal*2.5-turn*5)*dt
 bal+=balv*dt
 -- drift sideways with the lean
 px-=sin(ang)*bal*.4*dt
 pz+=cos(ang)*bal*.4*dt
 if abs(bal)>1 then
  vx,vy,vz=-sin(ang)*bal*2,1,cos(ang)*bal*2
  bal,balv=0,0
  brk("slipped",11)
  toair()
  return true
 end
end

s.air=function()
 coy-=dt
 if jbuf>0 and coy>0 then dojump() return end
 vy=max(vy-g*dt,-30)
 -- limited air steering
 local da=turn*.2*dt
 local c,sn=cos(da),sin(da)
 ang+=da
 vx,vz=vx*c-vz*sn,vx*sn+vz*c
 if iu and hs()<3.6 then
  vx+=cos(ang)*5*dt vz+=sin(ang)*5*dt
 end
 if id then vx*=.97 vz*=.97 end
 pmove()
 peak=max(peak,py)
 if gnd then land() return end
 if airgrab() then return end
 -- holding z near a wall pulls
 -- you onto it (wallrun magnet)
 if not wall and jz and hs()>3.2 then
  for sd=-1,1,2 do
   local b=solid(px-sin(ang)*sd*.8,py+1,pz+cos(ang)*sd*.8)
   if b and b~=lastwr and max(b[4]-b[1],b[6]-b[3])>2 then
    wall=b
    if px>b[1] and px<b[4] then
     wnx,wnz=0,pz<b[3] and -1 or 1
     pz=wnz<0 and b[3]-r or b[6]+r
    else
     wnx,wnz=px<b[1] and -1 or 1,0
     px=wnx<0 and b[1]-r or b[4]+r
    end
   end
  end
 end
 if not wall then return end
 local vin,vp=max(-vx*wnx-vz*wnz),vz*wnx-vx*wnz
 if wall.f&2>0 and iu and vin>.5 then
  -- catch a ladder/pipe mid-air
  startclimb()
 elseif jbuf>0 then
  -- tic-tac: kick off, keep
  -- the along-wall speed
  wallkick(vp,max(3.2,vin*.5),"tic-tac")
 elseif jz and abs(vp)>3.2 and abs(vp)>vin*.7 and wall~=lastwr then
  -- wallrun
  wrs,lastwr=max(abs(vp),hs()*.85),wall
  wrt=.5+wrs*.12
  wrmax=wrt
  vy=mid(vy,1+wrs*.25,3.5)
  ang=atan2(-wnz*vp,wnx*vp)
  trick("wallrun",.1,5)
  setst"wallrun"
 elseif jz and vin>2 and not wupd then
  wallup(vin)
 else
  if vin>6.5 then bonk() end
  vx+=wnx*vin vz+=wnz*vin
 end
end

function land()
 local h,hv=peak-py,hs()
 if hv>.5 then ang=atan2(vx,vz) end
 spd,gb,coy,wupd,kicks,lastwr=hv,gnd,0,false,0
 puff(4)
 -- awning: bounce up
 if gb.f&4>0 then
  toair()
  vy=jz and 12.5 or 11
  trick("bounce",.1,10)
  return
 end
 sfx(2)
 if narrow(gb) then
  spd,bal,balv=min(spd,2.5),0,0
  if h>.6 then trick("precision",.08) end
  setst"ground"
  return
 end
 if h>1.6 and rbuf>0 then
  if h<11 then
   spd=max(spd*.95,4)
   trick("roll",.12,3)
   setst"roll"
   return
  end
  -- too high even for a roll
  h-=4
 end
 if h>4.6 then
  spd*=.15
  stun,shake,heavy,flow=.6,.3,.6,0
  brk("hard landing",8)
  setst"land"
 elseif h>2.6 then
  spd*=.6
  stun,flow=.15,max(flow-.25)
  setst"land"
 else
  spd*=.97
  setst"ground"
 end
end

-- stunned after a bad landing
s.land=function()
 spd=max(spd-10*dt)
 gvel()
 ph=1.2
 if stt>stun then setst"ground" end
end

s.roll=function()
 spd=max(spd-2*dt)
 ang+=turn*.25*dt
 gvel()
 ph=.9
 if not gnd then toair() return end
 if jbuf>0 and stt>.2 then dojump() return end
 if stt>.45 then setst"ground" end
end

s.slide=function()
 spd=max(spd-1.6*dt)
 ang+=turn*.15*dt
 ph=.8
 gvel()
 if not gnd then toair() return end
 if jbuf>0 then dojump() return end
 if wall then spd*=.5 end
 if not xx and stt>.35 or spd<2.5 then
  ph=1.8
  if phit() then
   -- still under something
   ph,spd=.8,max(spd,2.5)
  else
   setst"ground"
  end
 end
end

s.vault=function()
 local k=min(stt/vdur,1)
 py=vy0+(vtop+.05-vy0)*k
 vx,vy,vz=cos(ang)*vspd*.3,0,sin(ang)*vspd*.3
 pmove()
 if k>=1 then
  spd=vspd
  vx,vy,vz=cos(ang)*spd,vt==3 and 2.5 or 1.5,sin(ang)*spd
  toair()
 end
end

s.wallrun=function()
 wrt-=dt
 vy-=g*(.05+(1-wrt/wrmax)*.55)*dt
 wrs=max(wrs-dt)
 vx,vz=cos(ang)*wrs-wnx,sin(ang)*wrs-wnz
 pmove()
 if gnd then land() return end
 if airgrab() then return end
 if jbuf>0 then
  wallkick((vz*wnx-vx*wnz)*.9,4.8,"wall jump")
 elseif not wall or wrt<=0 or xp then
  vx+=wnx vz+=wnz
  setst"air"
 end
 peak=py
end

-- run up a wall head-on
function wallup(vin)
 wupd=true
 snapface(wall)
 vy=max(vy,4+vin*.7)
 trick("wall climb",.05)
 setst"wallup"
end

s.wallup=function()
 vx,vy,vz=-wnx*.5,vy-g*dt,-wnz*.5
 pmove()
 peak=max(peak,py)
 if gnd then land() return end
 if airgrab() then return end
 if jbuf>0 then
  wallkick(0,4.5,"wall jump")
 elseif vy<-1.5 or not wall then
  setst"air"
 end
end

-- hanging / cat leap on a ledge
s.hang=function()
 if stt<.12 then return end
 if iu or jbuf>0 and not id then
  startpull()
 elseif jbuf>0 then
  jumpback()
 elseif xp then
  ngrab=.35
  toair()
 elseif turn~=0 then
  -- shimmy along the edge
  local ox,oz,b=px,pz,hb
  px+=sin(ang)*turn*1.4*dt
  pz-=cos(ang)*turn*1.4*dt
  local x,z=px+cos(ang)*.6,pz+sin(ang)*.6
  if x<b[1]+.1 or x>b[4]-.1 or z<b[3]+.1 or z>b[6]-.1 or phit() then px,pz=ox,oz end
  aph+=dt*1.5
 end
end

s.pull=function()
 local k=min(stt/pdur,1)
 local ky,kf=min(k*1.6,1),max(k*2-1)
 px,py,pz=pa[1]+(pb[1]-pa[1])*kf,pa[2]+(pb[2]-pa[2])*ky,pa[3]+(pb[3]-pa[3])*kf
 if k>=1 then
  spd,gb=hcat and iu and 4 or 1
  setst"ground"
 end
end

-- ladders + drainpipes (yellow):
-- always face their broad side
function startclimb()
 cb=wall
 local zf=cb[4]-cb[1]>cb[6]-cb[3]
 snapface(cb,zf)
 if zf then px=mid(cb[1],px,cb[4]) else pz=mid(cb[3],pz,cb[6]) end
 setst"climb"
 sfx(4)
end

s.climb=function()
 local d=(iu and 1 or 0)-(id and 1 or 0)
 py+=d*2.6*dt
 aph+=d*dt*1.2
 if py+1.9>cb[5] then
  py=cb[5]-1.9
  if d>0 then hb,hcat=cb startpull() return end
 end
 if d<0 and solid(px,py-.05,pz) then setst"ground" spd=0 return end
 if jbuf>0 then
  jumpback()
 elseif xp or py<cb[2]-1.5 then
  ngrab=.35
  toair()
 end
end
-->8
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
-->8
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
   -- too close: lift over the head
   if k<.4 then dx,dy,dz=tx-fx*.3,ty+1.6,tz-fz*.3 end
   break
  end
 end
 local ey=dy-cam[2]
 cam[1]+=(dx-cam[1])*.2
 cam[3]+=(dz-cam[3])*.2
 cam[2]+=ey*min(.3,.07+abs(ey)*.04)
 -- look ahead along the run
 look[1]+=(tx+cos(ang)*(1+h*.3)-look[1])*.2
 look[2]+=(ty-.2-look[2])*.15
 look[3]+=(tz+sin(ang)*(1+h*.3)-look[3])*.2
 fl+=(72-h*1.7-fl)*.1
 shake=max(shake-dt)
 local sx,sy,sz=cam[1]+rnd(shake)-shake/2,cam[2]+rnd(shake),cam[3]
 cpos={sx,sy,sz}
 local lx,ly,lz=look[1]-sx,look[2]-sy,look[3]-sz
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

-- camera space -> screen
function proj(c)
 local z=c[3]
 return {64+c[1]*fl/z,64-c[2]*fl/z}
end
-->8
-- 3d rendering: painter's sort
-- of boxes, near-plane clipping,
-- scanline polygons, fog, sky

near=.2

-- convex polygon fill: downward
-- edges fill one side, upward
-- edges the other
function poly(v,c)
 local l,rr,y0,y1={},{},999,-1
 for i=1,#v do
  local a,b,t=v[i],v[i%#v+1],l
  local ax,ay,bx,by=a[1],a[2],b[1],b[2]
  if ay>by then ax,ay,bx,by,t=bx,by,ax,ay,rr end
  local sl,ya,yb=(bx-ax)/(by-ay),max(ceil(ay)),min(ceil(by)-1,127)
  local x=ax+(ya-ay)*sl
  for y=ya,yb do
   t[y]=x
   x+=sl
  end
  if ya<y0 then y0=ya end
  if yb>y1 then y1=yb end
 end
 for y=y0,y1 do rectfill(l[y] or 0,y,rr[y] or 0,y,c) end
end

-- clip camera-space polygon
-- against the near plane
function cpoly(vs,c)
 local o,n={},#vs
 for i=1,n do
  local a,b=vs[i],vs[i%n+1]
  if a[3]>=near then add(o,proj(a)) end
  if (a[3]<near)~=(b[3]<near) then
   local t=(near-a[3])/(b[3]-a[3])
   add(o,proj{a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,near})
  end
 end
 if #o>2 then poly(o,c) end
end

function lerp3(a,b,t)
 return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}
end

-- point on face quad (u across,
-- t up) for decorations
function fp(q,u,t)
 return lerp3(lerp3(q[1],q[4],u),lerp3(q[2],q[3],u),t)
end

-- corner order per axis so that
-- 1-2 and 4-3 are vertical edges
faces={split"0,2,6,4",split"0,1,5,4",split"0,2,3,1"}
ubx=split"-999,-999,999,999"
fpat={0x3333,0x5555,0x7777,0x5a5a}

-- must a be drawn before b?
-- every separating plane must have
-- the camera on the same side (if
-- not, or the camera is between
-- them, they can't overlap: no
-- constraint). intersecting boxes
-- fall back to distance
function behind(a,b)
 local r
 for i=1,3 do
  local c,s=cpos[i]
  if a[i+3]<=b[i] then
   s=c>=b[i] and 1 or c<=a[i+3] and 0 or 2
  elseif b[i+3]<=a[i] then
   s=c<=b[i+3] and 1 or c>=a[i] and 0 or 2
  end
  if s then
   if s==2 or r and r~=s then r=2 break end
   r=s
  end
 end
 return r==1 or not r and a.d>b.d
end

function render()
 sky()
 -- player pseudo-box joins sort
 plb[1],plb[2],plb[3],plb[4],plb[5],plb[6]=px-r,py,pz-r,px+r,py+ph,pz+r
 -- d: centre distance (tie
 -- break), e: gap distance (fog).
 -- boxes in range and in front
 -- get camera-space corners and
 -- screen bounds
 local v,o,out={},{},{}
 for b in all(dl) do
  local d,e,f,bx=0,0,0
  for i=1,3 do
   local c,m=cpos[i],(b[i]+b[i+3])/2
   d+=abs(m-c)
   e+=max(max(b[i]-c,c-b[i+3]))
   f+=(m-c)*cfw[i]
  end
  b.d,b.e=d,e
  if e<50 and f>-b.rad then
   bx,b.cs=split"999,999,-999,-999",{}
   b.bx=bx
   for i=0,7 do
    local c={tocam(b[1+i%2*3],b[2+flr(i/2)%2*3],b[3+flr(i/4)*3])}
    b.cs[i]=c
    -- corner behind us: unbounded
    local s=c[3]>near and proj(c) or ubx
    bx[1],bx[2],bx[3],bx[4]=min(bx[1],s[1]),min(bx[2],s[2]),max(bx[3],s[3] or s[1]),max(bx[4],s[4] or s[2])
   end
  end
  -- on screen?
  add(e<50 and f>-b.rad and bx[3]>=0 and bx[1]<128 and bx[4]>=0 and bx[2]<128 and v or o,b)
 end
 -- painter's order: topological
 -- sort over screen-overlapping
 -- pairs (dfs, back to front)
 fr=(fr or 0)+1
 local function visit(b)
  if b.mk~=fr then
   b.mk=fr
   local x0,y0,x1,y1=unpack(b.bx)
   for i=1,#v do
    local a=v[i]
    local p=a.bx
    if p[1]<x1 and p[3]>x0 and p[2]<y1 and p[4]>y0 and behind(a,b) then visit(a) end
   end
   add(out,b)
   if b==plb then drawplayer() else drawbox(b) end
  end
 end
 for b in all(v) do visit(b) end
 for b in all(o) do add(out,b) end
 dl=out
 beacon()
 -- ghost of the best run
 local i=flr(tm/4)*3
 if ghost and ghost[i+3] and mode=="play" then
  local a,c={tocam(ghost[i+1],ghost[i+2],ghost[i+3])},{tocam(ghost[i+1],ghost[i+2]+1.7,ghost[i+3])}
  if a[3]>near and c[3]>near then
   a,c=proj(a),proj(c)
   fillp(0x5a5a)
   rectfill(a[1]-1,c[2],a[1]+1,a[2],12)
   circfill(c[1],c[2],2,12)
   fillp()
  end
 end
 fxdraw()
end

function drawbox(b)
 local m,cs=mats[b.m],b.cs
 local fog=b.e>40 and 2 or b.e>26 and 1 or 0
 for ax=1,3 do
  for sd=0,1 do
   if sd==0 and cpos[ax]<b[ax] or sd==1 and cpos[ax]>b[ax+3] then
    local q={}
    for k in all(faces[ax]) do add(q,cs[k+sd*(ax==3 and 4 or ax)]) end
    local c=ax==2 and sd==1 and m[1] or m[ax==1 and 2 or 3]
    if fog==2 then c=13 elseif fog==1 then fillp(0x5a5a) c+=208 end
    cpoly(q,c)
    fillp()
    if ax~=2 and fog==0 then deco(b,m[5],q,c,ax) end
   end
  end
 end
end

-- surface details on vertical faces
function deco(b,dk,q,c,ax)
 local h=b[5]-b[2]
 if dk==1 and h>3 then
  -- window bands
  fillp(fpat[flr(b[1]+b[3])%3+1])
  for y=1.4,h-1.2,3 do
   cpoly({fp(q,.06,y/h),fp(q,.06,(y+1.3)/h),fp(q,.94,(y+1.3)/h),fp(q,.94,y/h)},c+(c==1 and 192 or 16))
  end
 elseif dk==2 then
  -- ladder rungs
  fillp(0xf0f0)
  cpoly(q,10)
 elseif dk==3 and h>1.5 then
  -- billboard poster
  fillp(fpat[b.k%4+1])
  cpoly({fp(q,.08,.15),fp(q,.08,.85),fp(q,.92,.85),fp(q,.92,.15)},({0xa9,0x7c,0xeb,0xb3})[b.k%4+1])
 elseif dk==4 then
  fillp(0x3333)
  cpoly(q,0x78)
 elseif dk==5 then
  fillp(0x0f0f)
  cpoly({fp(q,.2,.25),fp(q,.2,.75),fp(q,.8,.75),fp(q,.8,.25)},0x5d)
 end
 fillp()
end

-- sky gradient, sun, skyline
function sky()
 local hy=mid(-20,64+fl*csp/ccp,150)
 cls(12)
 fillp(0x5a5a)
 rectfill(0,hy-34,127,hy-18,0xc6)
 fillp()
 rectfill(0,hy-18,127,hy,6)
 local yaw=atan2(ccy,csy)
 local sx=64-angd(.1-yaw)*fl*6
 circfill(sx,hy-30,7,7)
 -- distant city silhouettes
 for i=0,47 do
  local x=64-angd(i/48-yaw)*fl*6
  local hh=(i*37%11+3)*fl/30
  rectfill(x-6,hy-hh,x+6,hy,i%3==0 and 13 or 5+(i%2)*8)
 end
 rectfill(0,hy,127,127,5)
 rectfill(0,hy,127,hy+2,13)
end

-- next checkpoint marker (seen
-- through walls as a guide)
function beacon()
 for b in all(trig) do
  if b.m==12 or b.m==11 and b.k==cpi+1 then
   local x,z=(b[1]+b[4])/2,(b[3]+b[6])/2
   local a,c={tocam(x,b[2],z)},{tocam(x,b[2]+5,z)}
   if a[3]>near and c[3]>near then
    a,c=proj(a),proj(c)
    local col=b.m==12 and 10 or 11
    line(a[1],a[2],c[1],c[2],col)
    circfill(c[1],c[2],1+t()*4%2,col)
   end
  end
 end
end
-->8
-- particles + speed lines

parts={}

function puff(n)
 for i=1,n do
  add(parts,{px+rnd(.6)-.3,py+.1,pz+rnd(.6)-.3,rnd(2)-1,rnd(1.5),rnd(2)-1,.4+rnd(.3)})
 end
end

function fxupd()
 for e in all(parts) do
  for i=1,3 do e[i]+=e[i+3]*dt end
  e[7]-=dt
  if e[7]<0 then del(parts,e) end
 end
 -- dust while sliding/rolling
 if (st=="slide" or st=="roll") and rnd()<.4 then puff(1) end
end

function fxdraw()
 for e in all(parts) do
  local c={tocam(e[1],e[2],e[3])}
  if c[3]>near then
   local s=proj(c)
   circfill(s[1],s[2],e[7]*fl/c[3]*.5,e[7]>.3 and 7 or 6)
  end
 end
 -- speed lines at high speed
 local h=hs()
 if h>6.8 and mode=="play" then
  for i=1,(h-6.5)*2 do
   local a,d=rnd(),50+rnd(40)
   local e=d+h*1.5
   line(64+cos(a)*d,64+sin(a)*d*.8,64+cos(a)*e,64+sin(a)*e*.8,7)
  end
 end
end
__map__
810000000000005038880148000800380808080b0800040038480c160d0800300038480c181d1800480038060404034400480038060404037000480038060404030000800038500302050800900038480c102d0000b4003c500101052000b40038010401057e00b40038010401057800d00038010801097800e6003801080109
8e00d00038010801098e00e60038010801097600ce00400e0a0e091000d00038040204030800e00038300c183d1000280100503068021000380130500c081b1000500130500c28ad28006801301002100a70006801301002100a1000a00130500c0cbd3200f60130061001062000b80130160c1f5d7800b80130080406037000
d80130100a10016c00a001301a0c1c4d7000d8013a100c107d4c00b80130100c1f6d2000f801005040740e2000000240500c082b4000300240060404036000500240080504033000700240100c1801900040024001180105c80020020010343002c000a0023f180101059800900240140c148db000ce0242280e0107d000d002
2001220105e800d00220012201058000b80240180c146df000000200483c7801f40000023c0a0c783b280130023c1002180a300190023c06040403500190023c06040403580110023c100c100e2001140248180c0117600140023c100c383d8001c002320a010c04800198022a0a010c04a00140020048247002e00180022408
0406030002b0022406040403a4011e032402240106a001f802240a0c135dc00110032810010808e40114033b10010604b401e002241e0c189d7001200300504878017001280348500c084b800160034806040403a00160034806040403c00160034806040403e00160034806040403700190034c500101059001900348010401
05ee01900348010401059001b803481002100ad001b803481002100a7801e00348010801097801f60348010801098e01e00348010801098e01f60348010801097601de03500e0a0e09d001f0034820140127800128040040444402980150044408050803d00168044406040403a001b00443010110046001d00400403c480160
01e0043c400c085b700110053c06040403b00118053c0802100a600130053c200c18cdd0016005340c083401d00160053c01063405e60160053c01063405d80190053c06030403900160053b010134057e0158053e01101c177e01780520011e01059e01880540011024279e01a80520012001055001c8050050404c025001e0
0540500c086b6801080640060404035001000640500c1cdd60016006004054300e800148064004060c01880148064004040c01900148064004020c01600148064010080c016a015e0648060c0106b801400640080c0a01b801200640080506038001800654200118058001800655200b180cc001b006540118010590ff000000
2858780ea0ff20010028288802b0ff50020028689001d00000000038487802e00010010038206001000000030060306002d0002003004060680e50023002004050a00e300290030038386802c000600400485078011002b004003860640ec0008005004068600e1002a00500385078014001f0060060883802d0006006003840
6801f00050004818100137000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001e62500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000164311d430224250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000e64508625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002062424630216250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000282352d225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001a6251c6151a6251c61500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000024040280402b0403004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001c63522625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000a665066550c0530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007000024540285402b540305502b530305550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000014041200412c0350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000123530c345000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e000015130001000010015130001000010015130001001813000100001001813000100001001c1300010011130001000010011130001000010011130001001313000100001001313000100001001713000100
000e00001804300000346150000034615000003461500000180430000034615000003461500000346150000018043000003461500000346150000034615000001804300000346150000034615000003461500000
000e00001113000100001001113000100001001113000100131300010000100131300010000100131300010015130001000010015130001000010018130001001713000100001001713000100001001c13000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 10114040
02 12114040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc777c777c777c7c7cc77c7c7c777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7c7c7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc777c777c77cc77cc7c7c7c7c77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7ccc7c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7ccc7c7c7c7c7c7c77ccc77c7c7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc222222222222222222222222222222222222222222222222222222222222222222222222cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc222222222222222222222222222222222222222222222222222222222222222222222222cccccccccccccccc
cccc999cc99cc99c999c999cc99c999cc99ccccc222222222222222222222222222222222222222222222222222222222222222222222222cccccccccccccccc
cccc9c9c9c9c9c9c9cccc9cc9c9c9c9c9ccccccc222222222222222222222222222222222222222222222222222222222222222222222222cccccccccccccccc
cccc99cc9c9c9c9c99ccc9cc9c9c999c999ccccc222221212121212121212121212121212121212121212121212121212121212121212222cccccccccccccccc
6c6c9c9c9c9c9c9c9c6c696c9c9c9c6c6c9c6c6c2222212121212121212121212121212121212121212121212121212121212121212222226c6c6c6c6c6c6c6c
c6c6969699c699c696c6c9c699c696c699c6c6c6222221212121212121212121212121212121212121212121212121212121212121222222c6c6c6c6c6c6c6c6
6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c22222121212121212121212121212121212121212121212121212121212121212122222c6c6c6c6c6c6c6c6c
c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c62222222222222222222222222222222222222222222aaa22222222222222222222222226c6c6c6c6c6c6c6c6
6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c222222222222222222222222222222222222222222aaaaa222222222222222222222222c6c6c6c6c6c6c6c6c
c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6222222222222222222222222222222222222222222aaaaa2222222222222222222222226c6c6c6c6c6c6c6c6
6c6c6c6c6c6c6c6cdddddddddddddc6c6c6c6c6c222222222222222222222222222222222222222222aaaaa222222222222222222222222ddddddddd6c6c6c6c
c6c6c6c6c6c6c6c6ddddddddddddd6c6c6c6c6c62222222222222222222222222222222222222222222aaa2222222222222222222222222dddddddddc6c6c6c6
6c6c6c6c6c6c6c6cdddddddddddddc6c6c6c6c6c22222222222222222222225522222222222222222222a22222222222222222222222222ddddddddd6c6c6c6c
c6c6c6c6c6c6c6c6ddddddddddddd6c6c6c6c6c6c2222121212121212121215521212121212121212121a1212121212121212121212222ddddddddddc6c6c6c6
6c6c6c6c6c6c6c6cdddddddddddddc6c6c6c6c6c62222121212121212121215521212121212121212121a1212121212121212121212222dddddddddd6c6c6c6c
c6c6c6c6c6c6c6c6ddddddddddddd6c6c6c6c6c6c2222121212121212121215521212121212121212121a1212121212121212121212222ddddddddddc6c6c6c6
6c6c6c6c6c6c6c6cdddddddddddddc6c6c6c6c6c6222212121212121212121552121212121212121212a21212121212121212121212222dddddddddd6c6c6c6c
ddddddddddddd6c6ddddddddddddd6c6c6c6c6c6c222222222222222222222552222222222222222222a22222222222222222222222222ddddddddddc6c6c6c6
dddddddddddddc6cdddddddddddddc6c6c6c6c6c6222222222222222222222552222222222222222222a22222222222222222222222222dddddddddd6c6c6c6c
ddddddddddddd6c6ddddddddddddd555555555c6c222222222222222222222552222222222222222222a22222222222222222222222222dddddddddddddddddd
ddddddddddddd666ddddddddddddd555555555666222222222222222222222552222222222222222222a2222222222222222222222222ddddddddddddddddddd
ddddddddddddd666ddddddddddddd555555555666222222222222222222222552222222222222222222a2222222222222222222222222ddddddddddddddddddd
ddddddddddddd666ddddddddddddd555555555666222212121212121212121552121212121212121212a2121212121212121212122222ddddddddddddddddddd
ddddddddddddd666ddddddddddddd555555555666222212121212121212121552121212121212121212a2121212121212121212122222ddddddddddddddddddd
ddddddddddddd666ddddddddddddd555555555666222212121212121212121552121212121212121212a2121212121212121212122222ddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555666222212121212121212121552121212121212121212a2121212121212121212122222ddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555666222222222222222222222552222222222222222222a2222222222222222222222222ddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555666522222222222222222222252222222222222222222a222222222222222222222222dddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555dddd22222222222222222222252222222222222222222a222222222222222222222222dddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555dddd22222222222222222222252222222222222222222a222222222222222222222222dddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555dddd2222222222222222222225222222222222222222a2222222222222222222222222dddddddddddddddddddd
ddddddddddddddddddddddddddddd555555555dddd2222212121212121212125212121212121212121a1212121212121212121212222dddddddddddddddddddd
55555dddddddddddddddddddddddd555555555dddd2222212121212121212125212121212121212121a1212121212121212121212222dddddddddddddddddddd
55555dddddddddddddddddddddddd555555555dddd2222212121212121212125212121212121212121a1212121212121212121212222dddddddddddddddddddd
55555dddddddddddddddddddddddd555555555dddd2222212121212121212125212121212121212121a121212121212121212121222ddddddddddddddddddddd
55555dddddddddddddddddddddddd555555555dddd2222222222222222222225222222222222222222a222222222222222222222222ddddddddddddddddddddd
55555dddddddddddddddddddddddd555555555dddd2222222222222222222225555555555555555555a55555555555555555555555555555dddddddddddddddd
55555ddddddddddddddddddddddd1111111111111111111111111111111111155555555555555555555555555555555555555555555555551111111111111111
dddddddddddddddddddddddddddd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
dddddddddddddddddddddddddddd111111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddddddddddddddd111111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cc444cc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
5555555555555555555555555555111111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1c44444c1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
5555555555555555555555555555111111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1c44444c1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
6666666dddddddd5555555555555111111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1c44444c1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddd555555555555111111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cf444fc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddd555555555555511111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccfffcc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddd555555555555511111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cff1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddd555555555555511111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddd555555555555511111111ccc1ccc1ccc1ccc1ccc1ccc1ccc1c881ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dddddddddddddddd555555555555511111111ccc1ccc1ccc1ccc1ccc1ccc1ccc188888888ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
ddddddddddddddddd55555555555511111111ccc1ccc1ccc1ccc1ccc1ccc1ccc888888888ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
ddddddddddddddddd5555555555551111111111111111111111111111111111f8888888811111111111111111111111111111111111111111111111111111111
ddddddddddddddddd555555555555111111111111111111111111111111111f88888888111111111111111111111111111111111111111111111111111111111
ddddddddddddddddd555555555555111111111111111111111111111111111f88888881111111111111111111111111111111111111111111111111111111111
ddddddddddddddddd55555555555551111111111111111111111111111111f888888811111111111111111111111111111111111111111111111111111111111
ddddddddddddddddd555555555555511111111111111111111111111111111888888111111111111111111111111111111111111111111111111111111111111
ddddddddddddddddd555555555555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
dddddd11dddddddddd55555555555511111111111111111111111666666661166666666666611111111111111111111111111111111111111111111111111111
dd11dd11dd1ddddddd55555555555511111111111111111111116666666661166666666666661111111111111111111111111111111111111111111111111111
dd11dd11dd1ddddddd55555555555511111111111111111111116666666661166666666666661111111111111111111111111111111111111111111111111111
dd11dd11dd1ddddddd55555555555511111111111111111111166666666661166666666666666111111111111111111111111111111111111111111111111111
dd11dd11dd1ddddddd55555555555511111111111111111111166666666666666666666666666111111111111111111111111111111111111111111111111111
dd11dd11dd1ddddddd55555555555551111111111111111111666666666666666666666666666611111111111111111111111111111111111111111111111111
dd11dd11ddddddddddd5555555555551111111111111111111666666666666666666666666666611111111111111111111111111111111111111111111111111
dd11dd1dddddddddddd55555555555511111111c1ccc1ccc1666666666666666666666666666666c1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dd11ddddddddddddddd55555555555511111111c1ccc1ccc666666666666666666666666666666661ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc
dd1dddddddddddddddd55555555555511111111c1ccc1ccc666666666666666666666666666666661ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cccdd666666
ddddddddddddddddddd55555555555511111111c1ccc1cc6666666666666666666666666666666666ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cccdddd6666
ddddddddddddddddddd55555555555511111111c1ccc1cc6666666666666666666666666666666666ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cccdddddd66
dddddddddddddddddddd5555555555511111111c1ccc1c555555555555555555555555555555555555cc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccc1cccdddddddd
dddddddddddddddddddd5555555555511111111c1ccc1cc5555555555555555555555555555555555ccc1ccc1ccc1ccc1ccc1ccc1ccc1cccd666666666dddddd
ddddddddddd1dddddddd5555555555551111111c1ccc1cc5555555555555555555555555555555555ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccddd6666666666dddd
dddddddddd11dddddddd5555555555551111111c1ccc1cc5555555555555555555555555555555555ccc1ccc1ccc1ccc1ccc1ccc1ccc1ccddddd6666666666dd
dddddddddd11dddddddd5555555555551111111c1ccc1cc5555555555555555555555555555555555ccc1ccc1ccc1ccc1ccc1cc666666666dddddd6666666666
dddddd11dd11dddddddd55555555555511111111111111155555555555555555555555555555555551111111111111111111111d6666666666ddddd666666666
dddddd11dd11ddddddddd5555555555511111111111111155555555555555555555555555555555551111111111111111111111ddd666666666dddddd6666666
ddd1dd11dd11ddddddddd5555555555511111111111111155555555555555555555555555555555551111111111111111111111dddd666666666dddddd666666
dd11dd11dd11ddddfffffffffffffffffffffffffffffff5555555555555555555555555555555555ffffffffffffffffffffffddddd6666666666dddddd6666
dd11dd11dd11dddffffffffffffffffffffffffffffffff5555555555555555555555555555555555fffffffffffffffffffffffddddd6666666666ddddddd66
dd11dd11dd1ddffffffffffffffffffffffffffffffffff5555555555555555555555555555555555ffffffffffffffffffffffffddddd66666666666dddddd6
dd11dd11ddddfffffffffffffffffffffffffffffffffff5555555555555555555555555555555555fffffffffffffffffffffffffddddd66666666666dddddd
dd11dd11dddffffffffffffffffffffffffffffffffffff5555555555555555555555555555555555ffffffffffffffffffffffffffdddddd6666666666ddddd
dd11dd1dddfffffffffffffffffffffffffffffffffffff5555555555555555555555555555555555fffffffffffffffffffffffffffdddddd66666666666ddd
dd11ddddfffffffffffffffffffffffffffffffffffffff5555555555555555555555555555555555ffffffffffffffffffffffffffffdddddd66666666666dd
dd11dddffffffffffffffffffffffffffffffffffffffff5555555555555555555555555555555555fffffffffffffffffffffffffffffdddddd666666666666
dd1dddfffffffffffffffffffffffffffffffffffffffff5555555555555555555555555555555555ffffffffffffffffffffffffffffffdddddd66666666666
dddddfffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555fffffffffffffffffffffffffffffffffddddd6666666666
dddfffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffdddddd66666666
ddffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555fffffffffffffffffffffffffffffffffffdddddd6666666
dfffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffdddddd666666
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555fffffffffffffffffffffffffffffffffffffdddddd66666
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffdddddd6666
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffddddd5555
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffdddd5555
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffddd5555
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffdd5555
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffd5555
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff55555555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5555555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5555555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
