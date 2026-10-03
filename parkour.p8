pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- parkour: rooftops
-- third-person 3d parkour
-- main loop, game flow,
-- checkpoints, timer, hud

dt=1/60
lnames=split"old city rooftops|construction site|factory|underground|downtown|neon district|cliff village|megastructure"
hints=split("⬆️ run   ⬅️➡️ steer   🅾️ jump|run into low obstacles: vault\nfaster run = smoother vault|❎ while running: slide|❎ just before landing: roll\nhigh drops without it hurt|jump at a ledge to grab it\n⬆️ climb  ⬅️➡️ shimmy  ❎ drop\n⬇️+🅾️ jump away|yellow = climbable\nhold ⬆️ to climb|hold 🅾️ into a wall: run up it\nhold 🅾️ along a wall: wallrun|on a wall press 🅾️: kick off\n(tic-tac / wall jump)|narrow beams: ⬅️➡️ keep balance|red awnings bounce you high|keep moving to build flow\nflow = higher top speed|three ways up: ladder,\nsteps, or run up the wall|wallrun, 🅾️ wall jump, wallrun\nor take the cable / skybridge|last climb: stairs, chimney\nor vault-jump-mantle|construction site: climb floor\nby floor to the crane|4m up: ladder, pallets, or\nhold 🅾️ and run up the formwork|❎ slide under the formwork bar\nor go round the lift core|hanging pallet: from still,\n⬆️🅾️ is a short precise hop|the gap: hop the pallets, balance\nthe girder or wallrun the panel|safety nets bounce you a floor up|climb the crane mast and walk\nthe jib to the cab|factory: long straights build\nflow - keep moving, keep speed|the catwalk is the sprint lane:\nladder or crate steps up|container tops: chain the jumps\nwithout stopping|hold 🅾️ along the tank: wallrun\nonto the pipe rack|❎ slide under the pipes,\nvault the valve|slag pit: plank, hook container\nor a full-flow long jump|underground: platform, train\nroof or the track bed|tunnel: wallrun, 🅾️ wall jump,\nwallrun - zig-zag the walls|❎ slide under pipes and cables|7m up: ladder, crate chain\nor run up from a crate|hop the narrow beams over\nthe shaft|downtown: up from the street\nto the rooftops|taxi, van, awning: bounce\nonto the balcony|roof garden: ❎ slide under\nthe pergola, vault the glass|cross on the cable or take\nthe skybridge|office roof: AC units,\npenthouse, tank - pick a line|garage: weave between the\ncars or hop the roofs|4m walls: ladder, gondola,\nAC units, or run up|neon district: speed - keep\nflow up and never stop|wallrun the billboard, hop the\nletters or balance the beam|bounce the bar awning onto\nthe high roof - then fly|the train: wallrun its side\nor run along the roof|leap from the train roof, run\nup the sign, or the ladders|cliff village: careful feet -\nlong falls, slow is fine|bridge, rope, or the roofs:\njump for the far house|up the cliff: ladders, the\nyellow rock, or the outcrops|the gorge: bridge, beams,\nor hop the rock pillars|terraces: ladders, crate and\ngrabs, or run up the walls|last wall: long ladder, or\nrun up the ledges","|")

function _init()
 cartdata"pk_parkour_2"
 menuitem(1,"restart level",restart)
 menuitem(2,"last checkpoint",respawn)
 menuitem(3,"level select",function() mode="title" end)
 music(0,2000)
 mode="title"
 setlv(0)
end

function restart()
 cpi,tm,splits,score,cp,started=0,0,{},0,spawn
 respawn()
end

-- reset player at checkpoint
function respawn()
 px,py,pz,ang=unpack(cp)
 for k in all(split"vx,vy,vz,spd,flow,chain,idle,bal,balv,heavy,ngrab,jbuf,rbuf,coy,kicks,aph,shake,stun,popt,splt,shy,wrs") do _ENV[k]=0 end
 peak,pop,fade,bang,crouch,gb,wupd,lastwr=py,"",12,ang
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
  if mode=="title" then
   ang+=.0008
   -- level select: next level
   -- unlocks once this one's done
   if btnp(0) then setlv(lv-1) end
   if btnp(1) and dget(lv*8)>0 then setlv(lv+1) end
  elseif jzp then
   setlv(lv+1)
  end
  if jzp or xp and mode=="done" then mode="play" restart() end
 else
  if btn()>0 then started=true end
  if started then tm=min(tm+1,32000) end
  fade,splt,popt=max(fade-1),max(splt-dt),max(popt-dt)
  pupd()
  trigupd()
 end
 camupd()
end

function trigupd()
 hint=nil
 for b in all(trig) do
  if px>b[1] and px<b[4] and pz>b[3] and pz<b[6] and py>b[2]-1 and py<b[5] then
   if b.m==11 and b.k>cpi then
    cpi,cp,splt=b.k,{(b[1]+b[4])/2,b[2],(b[3]+b[6])/2,ang},2.5
    splits[cpi]=tm
    sdel=dget(lv*8+cpi)>0 and tm-dget(lv*8+cpi)
    sfx(6)
   elseif b.m==12 then
    -- finish line
    mode,best="done",dget(lv*8)
    newbest=best==0 or tm<best
    if newbest then
     dset(lv*8,tm)
     for i,s in pairs(splits) do dset(lv*8+i,s) end
    end
    sfx(9)
   elseif b.m==13 then
    hint=b.k+1+sk[9]
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
  pr("⬅️ "..lv+1 ..". "..lnames[lv+1].." ➡️",50,9)
  pr("press 🅾️ to start",64,7)
  rectfill(0,90,127,112,0)
  print("⬅️➡️ steer  ⬆️ run  ⬇️ brake\n🅾️ jump, hold on walls\n❎ slide / roll / drop",6,92,6)
  if dget(lv*8)>0 then pr("best "..ft(dget(lv*8)),116,10) end
  return
 end
 -- timer, best time
 pr(ft(tm),2,7,2)
 if dget(lv*8)>0 then pr(ft(dget(lv*8)),9,5,2) end
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
  pr(lnames[lv+1],40,10)
  pr("time  "..ft(tm),52,7)
  pr(newbest and "new best!" or "best  "..ft(best),60,newbest and 11 or 6)
  pr("flow score "..score,72,12)
  pr("🅾️ next level  ❎ retry",86,7)
 end
end
-->8
-- level data, written into cart
-- memory by tools/build.py.
-- 0x0000: 8 x 2-byte level address
-- level block:
--  16 display palette
--  11 sky: top,haze,sil a,sil b,
--     ground,sun,fog col,fog dist,
--     hint base,spawn heading,
--     silhouette height
--  15 materials x 4: top,side x,
--     side z,deco (lo=type hi=col)
--  2 box count, boxes x 10 bytes:
--  x,z,y:2 (/8) w,h,d:1 (/4)
--  mat:1 (lo=material hi=arg)
-- material flags (fixed per id):
-- 1 solid 2 climb 4 bouncy 8 trigger
mflag=split"1,1,1,1,1,3,1,5,1,1,8,8,8,1,1"

-- read an n-byte value
function rd(n)
 ra+=n
 return n>1 and peek2(ra-2) or peek(ra-1)
end

function setlv(l)
 lv=mid(0,l,7)
 ra=peek2(lv*2)
 for i=0,15 do pal(i,rd(1),1) end
 sk,mats,boxes,trig,dl={},{},{},{},{}
 for i=1,11 do sk[i]=rd(1) end
 for i=1,15 do mats[i]={rd(1),rd(1),rd(1),mflag[i],rd(1)} end
 for i=1,rd(2) do
  local x,z,y=rd(2)/8,rd(2)/8,rd(2)/8
  local w,h,d,m=rd(1)/4,rd(1)/4,rd(1)/4,rd(1)
  local b={x,y,z,x+w,y+h,z+d,m=m%16,k=m\16,f=mflag[m%16],rad=(w+h+d)/2}
  if b.f&8>0 then
   add(trig,b)
   if b.m==11 and b.k==0 then spawn={x+w/2,y,z+d/2,sk[10]/256} end
  else
   add(boxes,b) add(dl,b)
  end
 end
 -- player pseudo-box, sorted
 -- with the world for drawing
 plb={rad=1}
 add(dl,plb)
 restart()
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
function snapface(b,zf,keep)
 if zf==nil then zf=max(b[1]-px,px-b[4])<=max(b[3]-pz,pz-b[6]) end
 if not zf then
  wnx,wnz=px<b[1] and -1 or 1,0
  px=wnx<0 and b[1]-r or b[4]+r
 else
  wnx,wnz=0,pz<b[3] and -1 or 1
  pz=wnz<0 and b[3]-r or b[6]+r
 end
 if not keep then ang,vx,vy,vz=atan2(-wnx,-wnz),0,0,0 end
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
 local lx,lz=-sin(ang)*bal,cos(ang)*bal
 px+=lx*.4*dt
 pz+=lz*.4*dt
 if abs(bal)>1 then
  vx,vy,vz=lx*2,1,lz*2
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
  for sd=-.8,.8,.4 do
   local b=solid(px-sin(ang)*sd,py+1,pz+cos(ang)*sd)
   if b and b~=lastwr and max(b[4]-b[1],b[6]-b[3])>2 then
    wall=b
    snapface(b,px>b[1] and px<b[4],1)
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
 local a=lerp3(pa,pb,max(k*2-1))
 px,py,pz=a[1],lerp3(pa,pb,min(k*1.6,1))[2],a[3]
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
 cyaw+=angd(ang-cyaw)*((st=="hang" or st=="climb" or st=="wallup") and .03 or .05+h*.005)
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
dpat=split"0,0xf0f0,0,0x3333,0,0,0,0xa5a5"

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
 local v={}
 for b in all(dl) do
  local d,e,f,bx=0,0,0
  for i=1,3 do
   local c,m=cpos[i],(b[i]+b[i+3])/2
   d+=abs(m-c)
   e+=max(max(b[i]-c,c-b[i+3]))
   f+=(m-c)*cfw[i]
  end
  b.d,b.e=d,e
  if e<sk[8]+24 and f>-b.rad then
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
  if e<sk[8]+24 and f>-b.rad and bx[3]>=0 and bx[1]<128 and bx[4]>=0 and bx[2]<128 then add(v,b) end
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
   if b==plb then drawplayer() else drawbox(b) end
  end
 end
 for b in all(v) do visit(b) end
 beacon()
 fxdraw()
end

function drawbox(b)
 local m,cs=mats[b.m],b.cs
 local fog=b.e>sk[8]+14 and 2 or b.e>sk[8] and 1 or 0
 for ax=1,3 do
  for sd=0,1 do
   if sd==0 and cpos[ax]<b[ax] or sd==1 and cpos[ax]>b[ax+3] then
    local q={}
    for k in all(faces[ax]) do add(q,cs[k+sd*(ax==3 and 4 or ax)]) end
    local c=ax==2 and sd==1 and m[1] or m[ax==1 and 2 or 3]
    if fog==2 then c=sk[7] elseif fog==1 then fillp(0x5a5a) c+=sk[7]*16 end
    cpoly(q,c)
    fillp()
    -- details only with cpu to spare
    if ax~=2 and fog==0 and stat(1)<.9 then deco(b,m[5],q,c) end
   end
  end
 end
end

-- surface details on vertical
-- faces. deco: lo=type hi=colour
-- 1 window bands 3 poster 5 vent
-- 6 neon outline 7 cross brace
-- 2/4/8 full pattern (rungs,
-- stripes, rough stone/grime)
function deco(b,dk,q,c)
 local h,t,k=b[5]-b[2],dk%16,dk\16
 if t==1 and h>3 then
  fillp(fpat[flr(b[1]+b[3])%3+1])
  for y=1.4,h-1.2,3 do
   cpoly({fp(q,.06,y/h),fp(q,.06,(y+1.3)/h),fp(q,.94,(y+1.3)/h),fp(q,.94,y/h)},c+k*16)
  end
 elseif t==3 and h>1.5 then
  fillp(fpat[b.k%4+1])
  cpoly({fp(q,.08,.15),fp(q,.08,.85),fp(q,.92,.85),fp(q,.92,.15)},({0xa9,0x7c,0xeb,0xb3})[b.k%4+1])
 elseif t==5 then
  fillp(0x0f0f)
  cpoly({fp(q,.2,.25),fp(q,.2,.75),fp(q,.8,.75),fp(q,.8,.25)},c+k*16)
 elseif t==6 or t==7 then
  local s={}
  for v in all(q) do
   if v[3]<near then return end
   add(s,proj(v))
  end
  for i=1,t==6 and 4 or 2 do
   local a,e=s[i],s[t==6 and i%4+1 or i+2]
   line(a[1],a[2],e[1],e[2],k)
  end
 elseif t>0 then
  fillp(dpat[t])
  cpoly(q,c+k*16)
 end
 fillp()
end

-- sky gradient, sun, skyline
function sky()
 local hy=mid(-20,64+fl*csp/ccp,150)
 cls(sk[1])
 fillp(0x5a5a)
 rectfill(0,hy-34,127,hy-18,sk[1]+sk[2]*16)
 fillp()
 rectfill(0,hy-18,127,hy,sk[2])
 local yaw=atan2(ccy,csy)
 if sk[6]>0 then circfill(64-angd(.1-yaw)*fl*6,hy-30,7,sk[6]) end
 -- distant silhouettes
 for i=0,47 do
  local x,hh=64-angd(i/48-yaw)*fl*6,(i*37%11+3)*fl*sk[11]/240
  rectfill(x-6,hy-hh,x+6,hy,i%3==0 and sk[3] or sk[4])
 end
 rectfill(0,hy,127,127,sk[5])
 rectfill(0,hy,127,hy+2,sk[7])
end

-- next checkpoint marker (seen
-- through walls as a guide)
function beacon()
 for b in all(trig) do
  if b.m==12 or b.m==11 and b.k==cpi+1 then
   local c={tocam((b[1]+b[4])/2,b[2]+4,(b[3]+b[6])/2)}
   if c[3]>near then
    c=proj(c)
    circfill(c[1],c[2],1+t()*4%2,b.m-1)
   end
  end
 end
end
-->8
-- speed lines at high speed

function fxdraw()
 local h=hs()
 if h>6.8 and mode=="play" then
  for i=1,(h-6.5)*2 do
   local a,d=rnd(),50+rnd(40)
   local e=d+h*1.5
   line(64+cos(a)*d,64+sin(a)*d*.8,64+cos(a)*e,64+sin(a)*e*.8,7)
  end
 end
end
__gfx__
01003750cd90f0d0cd11b861e0a119d1001020384850687080f878b8c8d8e8f0c090d04050a0d0a1000c8060402011d0e0401060d050555000000060d05000a0
90902050e020308020204740402000c0101000000000000000000000000000d050101a00402084180000000000000005838810840080000700808080b0800040
00070084c061d080000300070084c081d18100840007006040403044008400070060404030070084000700604040300000080007000530205080000900070084
c001d200004b0087000510105002004b00070010401050e7004b0007001040105087000d0007001080109087006e00070010801090e8000d00070010801090e8
006e000700108010906700ec000800e0a0e09001000d0007004020403080000e00070003c081d30100821000000503862001008310060005c080b10100051006
0005c082da820086100600012001a0070086100600012001a001000a10060005c0c0db23006f1006006001106002008b10060061c0f1d587008b100600804060
3007008d10060001a00110c6000a100600a1c0c1d407008d10470001c001d7c4008b10060001c0f1d602008f100000050447e002000020080005c080b2040003
200800604040300600052008008050403003000720080001c08110090004200800108110508c0002200000014303200c000a20e7008110105089000920080041
c041d80b00ec20480082e010700d000d200400102210508e000d2004001022105008008b20080081c041d60f000020000084c387104f0000208700a0c087b382
1003208700012081a0031009208700604040300510092087006040403085100120870001c001e002104120090081c0107106100420870001c083d308100c2046
00a010c040081089204500a010c0400a1004200000844207200e10082084008040603000200b208400604040304a10e1308400204210600a108f208400a0c031
d50c1001300500011080804e1041306700011060404b100e208400e1c081d90710023000000584871007108230090005c080b4081006300900604040300a1006
300900604040300c1006300900604040300e1006300900604040300710093089000510105009100930090010401050ee10093009001040105009108b30090001
2001a00d108b300900012001a087100e3009001080109087106f30090010801090e8100e30090010801090e8106f300900108010906710ed300a00e0a0e0900d
100f3009000241107208108240000004444420891005408800805080300d1086408800604040300a100b4068001010014006100d40000004c3841006100e4087
0004c080b5071001508700604040300b1081508700802001a006100350870002c081dc0d1006508600c08043100d1006508700106043506e1006508700106043
508d10095087006030403009100650670010104350e7108550c7001001c171e7108750040010e11050e9108850080010014272e9108a5004001002105005108c
5000000504c42005100e50080005c080b68610806008006040403005100060080005c0c1dd061006600000044503e00810846008004060c01088108460080040
40c0100910846008004020c0100610846008000180c010a610e560090060c010608b100460080080c0a0108b100260080080506030081008608a000210815008
100860aa0002b081c00c100b608a001081105009ff00000000828587e00aff02100000828288200bff05200000828609100d0000000000838487200e00011000
0083020610000000300000060306200d0002300000040686e005200320000004050ae0032009300000838386200c00064000008405871001200b400000830646
e00c0008500000048606e001200a5000008305871004100f600000068883200d0006600000830486100f00050009008101107300102030405060708090a0b0c0
d0e0f0c060d060407060e1e00c6060d0d08590404042c0c010419040400050005000a0909020a0a09040b030308340402000c010100000000000000000000000
000050501000a0a0907086000fff0fff00008241823082000fff8200c0a08130800000008200c0c080b00fff0fff820082c002d00fff04006200031001900fff
c500000010311040e400c5000000103110400eff06004400062006100eff06004600062082100eff8c0046000620c01006000b0046000220c0100eff0a004800
0620041006000f000000014501e00eff06000000302430100effa110000030243010a9000600000030243010a900a1100000302430100000e500820060011060
420005008200805080908300e5008200c00110200fff0400820003c0f0d10eff8600840006c080b10eff090084008230205086000a008400c04080300eff8c00
2500032020500eff8c00840010502050e3008c008400105020500eff8a00840003c0e0d280000e0084006001106082004e008400a050809082000e002500a050
60900eff0e00840001011020860007008600804080308700e9008600600110600100480067008010809001002900870010c210500300e9008600c00110200eff
0600860006c0e0d30eff8a00880006c080b209006d000d0006202040ca000d006800a01080905b00ed00880010421050cc000d006800a01080905d00ed008800
10421050ce000d006800a01080905f00ed00880010421050c0100d006800a01080905110ed00880010421050c2100d006800a01080905310ed00880010421050
0a004f006800051020400b00ec00c800c3e0107007008b00880081c043d404100600480004200610071006004a00042006100a1006004c00042006100d100600
4e0074200610041006000000302430100410a110000030243010ab100600000030243010ab10a110000030243010ae100600000030253010ae10a11000003025
3010a1200600000030263010a120a110000030263010852006000000302730108520a110000030273010041086008800c0c085b3e6100600880010010620c610
070088001001606085100a008800b030018004100900880041c002d5e91006008a0010010620c91000108a001001606008100a006b00801080907810ea008b00
10821050c71086008a001150c090481086008a00d0a0c090ec1006008c0010010620cc1007008c00100160608b100d008c00b03001800d1086008e00c0c085b4
002009008e008050c03001200e008e00c040803006200b00000080a880f0e5204b008e00106140600a106b0001100620204007200b0080100180803003208c00
af008010809073206d00cf0010a01050012009008e0072c003d60c10ea004f0001e0a0300e100b00411001c080c006ff041000000303031006ff041006000320
031006ff04100800032003100a000910000083c0823009ff00000000818081900f000000000081a0c0308f0000004100c060c0400d2000000000800a80f00320
600004100720204001ff03200000058705100e10091000000506051000102038405068708098a0b8485890f0c090d0005000d0815100e060d050403030108190
40205560505070d0505000a0909020a0a09040b030308340402000c0c01040000000000000000000000000d00000008080204294000bff0bff00000f8087e009
100bff00000f800ae007300bff00000a800ae082500bff0000c8800ae0cfff0bff0100208287100000c90001008c82201000000bff01008c82201000000bff06
008c208710800081000100c0c001b000004bff010002c0e4d006004bff0100604065700b004bff8100402065500f00000001008050819003100fff010081c082
3009004bff010001c065d402000800e2000b10a040e10048000100100160600700850001008050809007008600010080a0809001000600010081c0e1d108108b
ff0100c0c007b1081087000300c0c001b10a10080001000341a0f00220080001000341a0a00a20080001000341a0f00c108500010002a0a0a003208500010002
a0a0f009208500010002a0a0a00b10850001008050a0900f1081000100c0508030852000000100804002900c200fffa1004020c25009100800830001c0a0d200
308bff0100c0c0c9b20130490001007203022008308a000100028202200e300cff0100028202200e200800830001c0a0d30530080043000b20a0500530860043
000b202050053086000100402141400d308600010040214140044086000100402141408a408600010040214140e43028000100104160600c30060004004020c1
500140c70083006040a0300640060004004020c15008300600830081c0c1d4094006008300c0c0c1b309408bff0100c0c045b30b4003008000c34020408c40c7
004200a090c0a01d402900630010d110508e40870063004710e0708e40c70001004031a0400650c70001004031a0408c50c70001004031a04003506700010060
41106008400600830081c0c1d50e500600010002028220ed5007000100100260608b50c70083008050a0908e508600050081c002c00a0004100000c087c02003
2009100000c00ac010014086100000c0c8c0200a5004100000c046c0100e1001ff0000c087c020064001ff0000c007c01000000f0000000a0405100d20041000
008705051004600bff000005840a100010203848506870809078b81858e0f000000000000000e0b10c0060d0d085d03030159040205560505070d0505000a090
9020b0b030300000000040402000a0a0a067000000000000000000000000500000006090901a27008fff8fff000006808ae000000000010042500a1086000000
010042500a108fff0000010040c10a200b000000010040c10a208fff8fff010006c140208fff8fff840006208a208fff0410010082c1402086000410010082c1
402083000500a100407140e007000500a100407140e083000a00a100407140e007000a00a100407140e083000f00a100407140e007000f00a100407140e00100
0600a1004040c03089000b00a1004040c030a40002000100e0e084f0a400cb000100e0e023f08400821001000150c010840004100400014040208100e3100300
01601070020003006400401001a0880003006400401001a0020009006400401001a0880009006400401001a002000f006400401001a088000f006400401001a0
01008000a10001c080b000000000a10042c081d004008410000081804ce004008410010040814c2086008410010040814c2004008410040081204c2084008410
a1005040834084000d10a1005040034084008420a10050404440c500081001005040403025000e108100b020205084000020a2005010205045000910e3004010
80a045000120e300401080a045000920e300401080a084008410a10001c041d184000a10010001c0c1d284008410010001c040b10dff8c200000888007e08cff
8c200100404307200e008c200100404307208cff8c200100c343402007008c200100c34340208cff0a3001000443402086000a3001000443402084000a30c600
016040208cff8c208700092007200dff87304400882041100dff6730010088a1102000004730010060c1106084000d20a10050408240840002300100a0e0a090
8400c3300100a031a090840085300100a081a090090000300100c0a0c0300b0003300100c05080300dff0230030010800170010000306700801001a009000030
6700801001a00dff0d20010088c080b284000d20220050c080b20dff0430010088c0a1d30dff0830840088c001b384008a304400012043108400824044000120
c110c40006404400202002400600064044002020024084000a4044000120841004008a30840040214c2086008a30840040214c2004008a30c60081204c208400
0e30050001202050c40084408400c040403045008c30a600401080a045008340a600401080a045000c40a600401080a084000340840001c061d4840082408400
01c040b4000003504400852006108fff8250840082c1402086008250840082c140208fff0350840040c106200b000350840040c106208fff0f50840006c14020
8fff825008000620862040000650840050406030a10006508400504060300300065084005040603064000650840050406030c500065084005040603027000650
84005040603088000650840050406030e900065084005040603004000a5084008120821004008a5084008140421004000b5084008160021004008b5084008180
c11004000c50840081a0811004008c50840081c0411004000d50840081e0011004008d5084008101c01004000e5084008121801004008e508400814140108400
ee5087000140107084000350840001c080b504000d50070081c001c0001020b8405060708098a0b0c0d0c8f0c060d010507060c1020c6160d0d0115040201160
d050555000000060505000a0909020507060308080208730404000d0c0e01100000000000000000000000050500000e0e01050f60009ff0bff00008d800ee009
ff071000008d808de009ff023000008d800ae000000dff0100c0108c1086000dff0100c0108c100aff0bff01008a0301200aff0dff0100032106200aff090001
000322862008000dff010083428c100b000dff850002c486a0030000000100c0c0c0b081000dff010082c0c2d0e60001002300901081400700e0002100601110
60e7000300430010216060c40003000100806001f0450085000100a090a13006008900620001100180c6008c00a300a0100240c60080106500a0108140070060
10c30060e01060c4000d000100c0e0c371030082000100c1c081d1810081000100806001f0000004000200a01001808dff02004300805060308bff8500430060
5080308eff08004300807080300cff0f004500806080308cff0210e500810110728cff02104500105010406fff02104500105010408800050085008030819009
000a0085008050603008000c0026008110205008000c00850010502050ea000c008500105020508b000d008500413081a00c0002108500015080300800000085
0081c002d209000610040001b041a0eeff06102500101041500aff881065008a10c0100aff0410450003c001d30aff881085008ac0c0b18900e910850060c010
608eff4910850080506030030029108500a03060900aff0a1001008a0306a001000e10070002e002200200ed10070060e0106005008e1007008050a03007008c
100700813081a08bff0c100700803002900eff0d100700013060900b000c100700c05080308b0001200700108010108b006220070010801010ec000120070010
801010ec0062200700108010106b00e0200800e0a0e0108aff0320a700020110738aff03200700105010406eff03200700105010400fff012007008060013007
000220a700811020500aff0a1007008ac001d40cff06200100082209e00cff06204500082009100cff0820850010400850eb0008208500104008508dff092085
00805001f081000a20850080500130860009208500805001f08dff0d208500805001f081000e2085008050013086000d208500805001f08dff01308500805001
f081000230850080500130860001308500805001f009000e20850081c08120e8008e20850010c0606004000c204600c010105084000b20850010011050840003
308500100110500cff8620850008c0c0b20cff0820850008c081d50cff08300100084385a001000b308700040104a003000e308900020182a0e40081408b0020
c120500cff0530850008c061b30cff0530850008c061d60000e730850060011060040007306600c01080900400e7308600104310506500e73086001043105081
00ea30870060011060840009308700a050803084000a308700a0a080308300ed308900600110604400cc306a00c010a0904400ed308a0010411050a500ed308a
001041105003008e308b0002c002c0041000000000030f03a00cef0e100000038c0310041003200000c34bc3a00fef07300000830a831000100c30000083cd83
a00bff0b400000848f04a000102030405068708088a0b8c0d0e0f00010201000701002720c21d010201ad020101e60d05055c010100060d0d000a0909020e0e0
c030e0e0208740402000c010101c000000000000000000000000500000006010d05c15000fff0dff00000406891002008dff0c0001c0c0b00fff0dff0c0004c0
02d0010004000c00024060300fff0900ac0004202050c4000c000c0010801090c4006d000c001080109026000c000c001080109026006d000c0010801090a400
eb000d00e0a0e09007000300070030026071aeff0a000600304260728fff00108a0080408172460001000c0040c140710fff03100000048508200fff03100b00
04c0c0b1810006100b00813001a00fff0e10ab0082b010730fff0e100b0010501040e3000e100b00105010400fff0f100b0004c002d10fff04100b0010410372
0600032089002081837006004620000020c440e042008420aa0080108071420086206a0080108072420088202a008010807300000320ea00201083400dff0a20
000005058b100dff0a200a0005c0c0b2040080300a008130c030040080306a008110c080040002300a0081c08720e60008308b0010c010500dff00300a001041
03730eff0e200a00c0408030000004300a008050c0308dff09300a00804080308eff0c300a00108010908eff6d300a0010801090efff0c300a0010801090efff
6d300a00108010906effeb300b00e0a0e090800006300a00803001a00dff0b200a0005c081d20eff0240a9000110a0710eff04408900011060720dff85400000
05c445200dff8540890005c0c0b303000a408900014060300dff0d402a00812020500dff0c40890005c002d346008640890040c1407200000050c70002200a10
81000650000080e380e081000e50000080e380e0400002500800c0c008f082000850080080406030c1000d50a80021202050e3000d5008001050205000000050
080002c0c0b40eff04600000048505a081008260080041c0c07382006260080060c010600200e360890060c0106000000f50080002c081d40fff84600b0003c0
02c00fff0dff0c0010108940e6000dff0c00101089400fff03100b0010100870e60003100b00101008700dff0a200a0010108b40e6000a200a0010108b400dff
8540890010104570e600854089001010457001ff0a000000030a03200d0009100000034b031002ff02300000030983a00e000c300000038c032004ff05500000
038a03100c0002600000038903a000102038485060708090a0b8c068e0f0c07060d0307060e1c20ca160d0508540706015404020004020200090404000a09090
2080c0a03080802087404020007060600000000000000000000000000050000000b030300015000eff0cff00000481041080008cff0300c0c0c0b00eff0cff03
0004c081d003000eff030041c0032083000dff0300c050803040000400e200801081902000040063001010815041000400630010108150feff0400e200101081
500eff0100030082c081d10eff0700000084810510030007000300418081200eff0b00030041e04120010009000300604060300eff0700030082c0c0b10dff01
100000058486108dff8f00e4004110c0900eff6f0003006001106000008f00e6004110c090efff00100500100160600100e010070060011060c200e010030060
03106084008e00030001a0411044004f00440001a0e010c400ef00850001a0901084008010c60001a040100eff0d00030084c001d20dff0110090005c0c0b28d
ff0610090001c041200400071009008050803000000e10e8006010039000000520e80060100390efff0e10690010108650c0000e106900101086500000ea2009
006080106003000e10e80020108240820003200000a0a4a01003004420290020106140820007200000a0c4a010030048206900201061408500ee100000609460
1085008020000060a4601085002220000060b460108500c320000060c4601085006520000060d4601085000720000060e460108500a820000060f4601085004a
200000600560100dff0b10090005c081d30dff0b200000050586f00dff0b200a0005c0c0b30dff8c200a0005c080d40eff0e200a0082c081200eff01300a0082
6181200eff04300a00820202208effed200a0060c010608effe0308b0060a010608effe330cc0060a0106001000d200a0080508030030002306b006010c09004
0000300a0001a0013003008f20ec000210105003008230ec0002101050050004300a00018101100dff08300000050784100dff08300e0005c0c0b40dff014000
00048805a00fffe0400e0060811060020000400e0041c080100dff0c300e0005c081d500000640011001c001200eff0540011010011050040005400110100110
502eff0540a210f21010710eff0240011003c041c007ef04100000058c871009ef07100910038184a0011008200000858b871003100b200710838184a00cef0b
400000060f87100a0000500000060a0610001020384850687080f878b8c8d8e8f0c090d04050a0d0a1000c8060402011d0e0401060d050555000000060d05000
a090902050e020308020204740402000c0101000000000000000000000000000d050101a00402084180000000000000005838810840080000700808080b08000
4000070084c061d080000300070084c081d181008400070060404030440084000700604040300700840007006040403000000800070005302050800009000700
84c001d200004b0087000510105002004b00070010401050e7004b0007001040105087000d0007001080109087006e00070010801090e8000d00070010801090
e8006e000700108010906700ec000800e0a0e09001000d0007004020403080000e00070003c081d30100821000000503862001008310060005c080b101000510
060005c082da820086100600012001a0070086100600012001a001000a10060005c0c0db23006f1006006001106002008b10060061c0f1d587008b1006008040
603007008d10060001a00110c6000a100600a1c0c1d407008d10470001c001d7c4008b10060001c0f1d602008f100000050447e002000020080005c080b20400
03200800604040300600052008008050403003000720080001c08110090004200800108110508c0002200000014303200c000a20e70081101050890009200800
41c041d80b00ec20480082e010700d000d200400102210508e000d2004001022105008008b20080081c041d60f000020000084c387104f0000208700a0c087b3
821003208700012081a0031009208700604040300510092087006040403085100120870001c001e002104120090081c0107106100420870001c083d308100c20
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
64000a010c048001980254000a010c04a0014002000048247002e00180024800080406030002b002480006040403a4011e03480002240106a001f80248000a0c135dc0011003500010010808e4011403760010010604b401e00248001e0c189d70012003000050487801700128039000500c084b80016003900006040403a001
6003900006040403c0016003900006040403e00160039000060404037001900398005001010590019003900001040105ee0190039000010401059001b80390001002100ad001b80390001002100a7801e0039000010801097801f6039000010801098e01e0039000010801098e01f6039000010801097601de03a0000e0a0e09
d001f0039000201401278001280400004044440298015004880008050803d0016804880006040403a001b0048600010110046001d0040000403c48016001e0047800400c085b70011005780006040403b001180578000802100a600130057800200c18cdd001600568000c083401d0016005780001063405e601600578000106
3405d8019005780006030403900160057600010134057e0158057c0001101c177e0178054000011e01059e0188058000011024279e01a8054000012001055001c805000050404c025001e0058000500c086b68010806800006040403500100068000500c1cdd6001600600004054300e80014806800004060c01880148068000
04040c0190014806800004020c0160014806800010080c016a015e069000060c0106b80140068000080c0a01b801200680000805060380018006a8002001180580018006aa00200b180cc001b006a8000118010590ff000000002858780ea0ff2001000028288802b0ff5002000028689001d0000000000038487802e0001001
00003820600100000003000060306002d000200300004060680e5002300200004050a00e30029003000038386802c00060040000485078011002b00400003860640ec000800500004068600e1002a0050000385078014001f006000060883802d0006006000038406801f0005000900018100137000000000000000000000000
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
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
