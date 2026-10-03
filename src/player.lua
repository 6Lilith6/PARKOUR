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
