pico-8 cartridge // http://www.pico-8.com
version 42
__lua__


dt,lnames,hints=.01667,split"old city rooftops,construction site,factory,underground,downtown,neon district,cliff village,megastructure",split("⬆️ run   ⬅️➡️ steer   🅾️ jump|run into low obstacles: vault\nfaster run = smoother vault|❎ while running: slide|❎ just before landing: roll\nhigh drops without it hurt|jump at a ledge to grab it\n⬆️ climb  ⬅️➡️ shimmy  ❎ drop\n⬇️+🅾️ jump away|yellow = climbable\nhold ⬆️ to climb|hold 🅾️ into a wall: run up it\nhold 🅾️ along a wall: wallrun|on a wall press 🅾️: kick off\n(tic-tac / wall jump)|narrow beams: ⬅️➡️ keep balance|red awnings bounce you high|keep moving to build flow\nflow = higher top speed|three ways up: ladder,\nsteps, or run up the wall|wallrun, 🅾️ wall jump, wallrun\nor take the cable / skybridge|last climb: stairs, chimney\nor vault-jump-mantle|construction site: climb floor\nby floor to the crane|4m up: ladder, pallets, or\nhold 🅾️ and run up the formwork|❎ slide under the formwork bar\nor go round the lift core|hanging pallet: from still,\n⬆️🅾️ is a short precise hop|gap: hop the pallets, walk\nthe girder or wallrun the panel|safety nets bounce you\na floor up|climb the crane mast and walk\nthe jib to the cab|factory: long straights build\nflow - keep moving, keep speed|the catwalk is the sprint lane:\nladder or crate steps up|container tops: chain the jumps\nwithout stopping|hold 🅾️ along the tank: wallrun\nonto the pipe rack|❎ slide under the pipes,\nvault the valve|slag pit: plank, hook container\nor a full-flow long jump|underground: platform, train\nroof or the track bed|tunnel: wallrun, 🅾️ wall jump,\nwallrun - zig-zag the walls|❎ slide under pipes and cables|7m up: ladder, crate chain\nor run up from a crate|hop the narrow beams over\nthe shaft|downtown: up from the street\nto the rooftops|taxi, van, awning: bounce\nonto the balcony|roof garden: ❎ slide under\nthe pergola, vault the glass|cross on the cable or take\nthe skybridge|office roof: AC units,\npenthouse, tank - pick a line|garage: weave between the\ncars or hop the roofs|4m walls: ladder, gondola,\nAC units, or run up|neon district: speed - keep\nflow up and never stop|wallrun the billboard, hop the\nletters or balance the beam|bounce the bar awning onto\nthe high roof - then fly|the train: wallrun its side\nor run along the roof|leap from the train roof, run\nup the sign, or the ladders|cliff village: careful feet -\nlong falls, slow is fine|bridge, rope, or the roofs:\njump for the far house|up the cliff: ladders, the\nyellow rock, or the outcrops|the gorge: bridge, beams,\nor hop the rock pillars|terraces: ladders, crate and\ngrabs, or run up the walls|last wall: long ladder, or\nrun up the ledges|megastructure: climb it all,\nevery move counts|8m up: ladders, containers,\nor run up the machine twice|the gap: wallrun the panel,\nhop the plates or the pipe|wallrun the core, or the\nplates, or the pipe|bounce pad! then the core\nwallrun, plates or pipe|the crown: last climb, then\nsprint to the end","|")

function _init()
 cartdata"pk_parkour_2"
 menuitem(1,"restart level",restart)
 menuitem(2,"last checkpoint",respawn)
 menuitem(3,"level select",function() mode="title" end)

 menuitem(4,"perf overlay",function() dbg=not dbg end)
 music(0)
 mode="title"
 setlv(0)
end

function restart()
 cpi,tm,splits,score,cp,started=0,0,{},0,spawn
 respawn()
end

function respawn()
 px,py,pz,ang=unpack(cp)
 for k in all(split"vx,vy,vz,spd,flow,chain,idle,bal,balv,heavy,ngrab,jbuf,rbuf,coy,kicks,aph,shake,stun,popt,splt,shy,wrs,lc,lvy,oh") do _ENV[k]=0 end
 peak,pop,fade,bang,crouch,gb,wupd,lastwr=py,"",12,ang
 setst"ground"
 nearupd()
 camreset()
end

function inp()
 local o,x=jz,xx
 jz,xx,iu,id=btn(4),btn(5),btn(2),btn(3)
 jzp,xp,turn=jz and not o,xx and not x,(btn(0)and 1or 0)-(btn(1)and 1or 0)
end

function _update()
 inp()
 menu()
 step()
 jzp,xp=nil
 step()
end

function menu()
 if mode~="play" then
  if mode=="title" then
   ang+=.0016

   if btnp(0) then setlv(lv-1) end
   if btnp(1) and dget(lv*8)>0 then setlv(lv+1) end
  elseif jzp then
   setlv(lv+1)
  end
  if jzp or xp and mode=="done" then mode="play" restart() end
 end
end

function step()
 if mode=="play" then
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
    local o=dget(lv*8+cpi)
    sdel=o>0 and tm-o
    sfx(6)
   elseif b.m==12 then

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

function ft(f)
 local s=flr(f/60)
 return flr(s/60)..":"..sub("0"..s%60,-2).."."..sub("0"..flr(f%60*5/3),-2)
end

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

 pr(ft(tm),2,7,2)
 if dget(lv*8)>0 then pr(ft(dget(lv*8)),9,5,2) end

 if splt>0 then
  pr("checkpoint "..cpi..(sdel and "  "..(sdel<=0 and "-" or "+")..ft(abs(sdel)) or ""),20,sdel and sdel>0 and 8 or 11)
 end

 rectfill(2,121,2+hs()/9*40,124,flow>.6 and 10 or flow>.3 and 9 or 13)
 rect(1,120,43,125,5)

 if popt>0 then
  pr(pop..(chain>1 and " x"..chain or ""),108-popt*4,popt>.3 and 7 or 6)
 end
 if hint then
  rectfill(1,97,126,117,1)
  print(hints[hint],3,99,7)
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
 if dbg then print(stat(7).." "..stat(1).." "..#nb,1,9,7) end
end

mflag=split"1,1,1,1,1,3,1,5,1,1,8,8,8,1,1"

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
  local x,z,y,w,h,d,m=rd(2)/8,rd(2)/8,rd(2)/8,rd(1)/4,rd(1)/4,rd(1)/4,rd(1)
  local b={x,y,z,x+w,y+h,z+d,m=m%16,k=m\16,f=mflag[m%16]}
  if b.f&8>0 then
   add(trig,b)
   if b.m==11 and b.k==0 then spawn={x+w/2,y,z+d/2,sk[10]/256} end
  else
   add(boxes,b) add(dl,b)
  end
 end

 plb={}
 add(dl,plb)
 restart()
end

r=.3

function nearupd()
 nb={}
 for b in all(boxes) do
  if b[1]<px+8 and b[4]>px-8 and b[3]<pz+8 and b[6]>pz-8 and b[2]<py+8 and b[5]>py-8 then
   add(nb,b)
  end
 end
end

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

function stepup(b)
 if st~="air" and st~="wallrun" and b[5]-py<.55 and not phit(b[5]+.01) then
  py=b[5]+.01
  return true
 end
end

function pmove()
 wall,gnd=nil
 local ox,oz=px,pz
 px+=vx*dt
 local b=phit()
 if b and vx~=0 and not stepup(b) then
  wnx,wnz=ox<(b[1]+b[4])/2 and -1 or 1,0
  px,wall=wnx<0 and b[1]-r-.001 or b[4]+r+.001,b
 end
 pz+=vz*dt
 b=phit()
 if b and vz~=0 and not stepup(b) then
  wnx,wnz=0,oz<(b[3]+b[6])/2 and -1 or 1
  pz,wall=wnz<0 and b[3]-r-.001 or b[6]+r+.001,b
 end
 py+=vy*dt
 b=phit()
 if b and vy~=0 then
  if vy<0 then
   py,gnd=b[5],b

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

function narrow(b)
 return b and min(b[4]-b[1],b[6]-b[3])<.7
end

function canvault(b)
 local h,x,z=b[5]-py,px+cos(ang)*.5,pz+sin(ang)*.5
 return h>.5 and h<1.4 and b.f&2==0 and not hit(x-r,b[5]+.02,z-r,x+r,b[5]+1.6,z+r)
end

function findledge(lo,hi)
 local x,z=px+cos(ang)*.6,pz+sin(ang)*.6
 for b in all(nb) do
  local t=b[5]-py
  if t>lo and t<hi and x>b[1] and x<b[4] and z>b[3] and z<b[6] and not hit(x-.2,b[5]+.05,z-.2,x+.2,b[5]+1,z+.2) then
   return b
  end
 end
end

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

function trick(n,f,s)
 pop,popt,idle=n,1,0
 chain+=1
 score,flow=min(score+5*min(chain,20),32000),mid(0,flow+f,1)
 if s then sfx(s) end
end

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

  h=iu and 3.6 or 0
 else
  jv=6+spd*.2

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

 if vtop-py>1.15 then vt=min(vt,2) end
 vdur,vspd=({.38,.2,.12})[vt],({min(spd,2.2),spd*.92,spd*1.04})[vt]
 trick(({"climb over","vault","speed vault"})[vt],vt*.05-.05,7)
 setst"vault"
end

function airgrab()
 if ngrab>0 or xx then return end
 local b=findledge(.1,2.15)
 if b then
  if b[5]-py<1.3 then

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
 pa,pb,pdur={px,py,pz},{px+cos(ang)*.7,hb[5]+.01,pz+sin(ang)*.7},hcat and.3or.5
 setst"pull"
end

function wallkick(vp,out,n)
 vx,vy,vz,jbuf=-wnz*vp+wnx*out,max(vy,6.6-kicks*1.3),wnx*vp+wnz*out,0
 kicks+=1
 ang=atan2(vx,vz)
 toair()
 trick(n,.1,4)
end

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

g,s=20,{}

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

 if py<1 then
  sfx(11) respawn()
 end

 shy=-1
 for b in all(nb) do
  if px>b[1] and px<b[4] and pz>b[3] and pz<b[6] and b[5]<=py+.05 then shy=max(shy,b[5]) end
 end
 anim()
end

function gvel()
 vx,vy,vz=cos(ang)*spd,-3,sin(ang)*spd
 pmove()
end

s.ground=function()
 local nar,vmax=narrow(gb),6.2+flow*2.8
 if nar then
  vmax=4
  if balance() then return end
 else
  ang+=turn*(.6-min(spd,9)*.04)*dt
 end
 if heavy>0 then heavy-=dt vmax=2.5 end

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

   local tx,tz=-wnz,wnx
   if cos(ang)*tx+sin(ang)*tz<0 then tx,tz=-tx,-tz end
   ang=atan2(tx,tz)
   spd*=1-into*.5
  end
 end
end

function balance()
 ang+=angd((gb[4]-gb[1]>gb[6]-gb[3] and (cos(ang)>0 and 0 or .5) or (sin(ang)>0 and .75 or .25))-ang)*.15
 balv=balv*.97+((rnd(2)-1)*(1+spd*.8)+bal*2.5-turn*5)*dt
 bal+=balv*dt

 local lx,lz=-sin(ang)*bal,cos(ang)*bal
 px+=lx*.4*dt
 pz+=lz*.4*dt
 if abs(bal)>1 then
  vx,vy,vz,bal,balv=lx*2,1,lz*2,0,0
  brk("slipped",11)
  toair()
  return true
 end
end

s.air=function()
 coy-=dt
 if jbuf>0 and coy>0 then dojump() return end
 vy=max(vy-g*dt,-30)

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

 if not wall and jz and hs()>3.2 then

  for sd in all(split"0,.4,-.4,.8,-.8") do
   local b=solid(px-sin(ang)*sd,py+1,pz+cos(ang)*sd)
   if b and not wall and b~=lastwr and max(b[4]-b[1],b[6]-b[3])>2 then
    wall=b
    snapface(b,px>b[1] and px<b[4],1)
   end
  end
 end
 if not wall then return end
 local vin,vp=max(-vx*wnx-vz*wnz),vz*wnx-vx*wnz
 if wall.f&2>0 and iu and vin>.5 then

  startclimb()
 elseif jbuf>0 then

  wallkick(vp,max(3.2,vin*.5),"tic-tac")
 elseif jz and abs(vp)>3.2 and abs(vp)>vin*.7 and wall~=lastwr then

  wrs,lastwr=max(abs(vp),hs()*.85),wall
  wrt=.5+wrs*.12
  wrmax,vy,ang=wrt,mid(vy,1+wrs*.25,3.5),atan2(-wnz*vp,wnx*vp)
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

s.land,s.roll,s.slide,s.vault,s.wallrun=function()
 spd=max(spd-10*dt)
 gvel()
 ph=1.2
 if stt>stun then setst"ground" end
end,function()spd=max(spd-2*dt)ang+=turn*.25*dt gvel()ph=.9if not gnd then toair()return end if jbuf>0and stt>.2and not phit(py+.9)then dojump()return end if stt>.45then setst"ground"end end,function()spd=max(spd-1.6*dt)ang+=turn*.15*dt ph=.8gvel()if not gnd then toair()return end if jbuf>0and not phit(py+1)then dojump()return end if wall then spd*=.5end if not xx and stt>.35or spd<2.5then ph=1.8if phit()then ph,spd=.8,max(spd,2.5)else setst"ground"end end end,function()local k=min(stt/vdur,1)py,vx,vy,vz=vy0+(vtop+.05-vy0)*k,cos(ang)*vspd*.3,0,sin(ang)*vspd*.3pmove()if k>=1then spd=vspd vx,vy,vz=cos(ang)*spd,vt==3and 2.5or 1.5,sin(ang)*spd toair()end end,function()wrt-=dt vy-=g*(.05+(1-wrt/wrmax)*.55)*dt wrs=max(wrs-dt)vx,vz=cos(ang)*wrs-wnx,sin(ang)*wrs-wnz pmove()if gnd then land()return end if airgrab()then return end if jbuf>0then wallkick((vz*wnx-vx*wnz)*.9,4.8,"wall jump")elseif not wall or wrt<=0or xp then vx+=wnx vz+=wnz setst"air"end peak=py end

function wallup(vin)
 wupd=true
 snapface(wall)
 vy=max(vy,4+vin*.7)
 trick("wall climb",.05)
 setst"wallup"
end

s.wallup,s.hang,s.pull=function()
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
end,function()if stt<.12then return end if iu or jbuf>0and not id then startpull()elseif jbuf>0then jumpback()elseif xp then ngrab=.35toair()elseif turn~=0then local ox,oz,b=px,pz,hb px+=sin(ang)*turn*1.4*dt pz-=cos(ang)*turn*1.4*dt local x,z=px+cos(ang)*.6,pz+sin(ang)*.6if x<b[1]+.1or x>b[4]-.1or z<b[3]+.1or z>b[6]-.1or phit()then px,pz=ox,oz end aph+=dt*1.5end end,function()local k=min(stt/pdur,1)local a=lerp3(pa,pb,max(k*2-1))px,py,pz=a[1],lerp3(pa,pb,min(k*1.6,1))[2],a[3]if k>=1then spd,gb=hcat and iu and 4or 1setst"ground"end end

function startclimb()
 cb=wall
 local zf=cb[4]-cb[1]>cb[6]-cb[3]
 snapface(cb,zf)
 if zf then px=mid(cb[1],px,cb[4]) else pz=mid(cb[3],pz,cb[6]) end
 setst"climb"
 sfx(4)
end

s.climb,q=function()
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
end,split"0,0,.93,0,.07,0,.07,0,.1,0,.1,0,0,0"

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

function gait(t,h)
 local f=1.1+h*.13

 rt=.75
 aph+=f*dt
 local d=min(.6,.5*f/h)
 local s=h*d/f

 t[3]=sqrt(.757-s*s/4)+.07-(.5-d)*.06*cos(aph*2-d)
 for i=0,1 do
  local p,x,u=(aph+i/2)%1,0,.07
  if p<d then
   x=s/2-s*p/d
  else
   p=(p-d)/(1-d)

   x,u=sin(p)*.15-cos(p/2)*s/2,.07-sin(p/2)*(1.3-p)*(.08+h*.025)
  end

  local j=4+i*2
  t[j],t[j+1],t[j+4],t[j+5]=x,u,.03-x*.22,.14+h*.008
 end
 t[1]=.01+h*.004
end

function anim()
 rt=.3

 local h,n,tu=hs(),st=="air" and (vy>0 and (stt<.12 and "push" or "up") or py-shy<1.2 and "reach" or "fall") or st=="vault" and "v"..vt or st=="hang" and hcat and "cat" or st,angd(ang-bang)
 local t=split(poses[n] or "0,0,.93,.04,.07,-.04,.07,.03,.08,.03,.08,.03,0")
 add(t,0)

 bang+=tu*.25
 if st=="ground" then
  if h>.3 then
   gait(t,h)

   t[1]+=mid(-.04,(h-oh)*.25,.03)
  else

   t[3]+=sin(time()/4)*.004
  end
  if crouch then t[3]-=.3 t[1]+=.1 end

  if lvy<-4 then lc=(-lvy-4)*.03 end
  t[3]-=lc
  if narrow(gb) then

   t[8],t[10],t[12],tu=0,0,.25,bal*-.06
  end
 elseif st=="wallrun" then
  gait(t,wrs)

  local w=wnx*sin(bang)-wnz*cos(bang)
  t[2],t[12],t[13]=w*.04,.14,w*.2
 elseif st=="climb" then
  local w=sin(aph)*.12
  t[5]+=w t[7]-=w t[8]-=w/3 t[10]+=w/3
 elseif st=="pull" then

  local k=stt/pdur
  t[1],t[8],t[10]=k*.15,.46-k*.42,.46-k*.42
  if k>.35 then t[6],t[7]=.3,min(hb[5]-py,.5)+.07 end
 end
 lvy,oh,lc=st=="air" and vy or 0,h,lc*.85

 t[2]-=tu*(h+3)*.12
 if n=="roll" then t[14]=min(stt/.45,1) end
 for i=1,13 do q[i]+=(t[i]-q[i])*rt end
 q[14]=t[14]
end

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

function seg(o,a,l,sp,sd)
 return {o[1]-sin(a)*cos(sp)*l,o[2]-cos(a)*cos(sp)*l,o[3]-sin(sp)*sd*l}
end

function spn(t,f,s)
 return {sdf*t+lcf*f,q[3]+sdu*t+lsf*f,sds*t+s+sh}
end

function cap(a,b,r,c)
 if a and b then add(bp,{(a[3]+b[3])/2,a,b,r,c}) end
end

function drawplayer()
 local l,sl,hp=q[1],q[2],q[3]
 bfx,bfz,pcr,psr,bp,sdf,sdu,sds,lcf,lsf,sh=cos(bang),sin(bang),cos(q[14]),-sin(q[14]),{},-sin(l),cos(l)*cos(sl),-sin(sl),cos(l),sin(l),(q[5]-q[7])*.06

 if shy>0 then
  local sc={}
  for i=0,3 do
   add(sc,{tocam(px+cos(i/4)*.35,shy+.02,pz+sin(i/4)*.35)})
  end
  cpoly(sc,5)
 end
 local head=jp(spn(.76,0,0))
 if not head then return end

 local cs,lg=(cpos[1]-px)*-bfz+(cpos[3]-pz)*bfx>0 and 1 or -1,{}
 for sd=-1,1,2 do
  local i,nr,h,az=sd<0 and 4 or 6,sd==cs,(q[6]-q[4])*sd*.05,sd*.12+q[13]
  local f,u=q[i]-h,q[i+1]-hp
  local d=max(sqrt(f*f+u*u),.05)
  local x=(.0176+d*d)/2/d
  local y=sqrt(max(.2025-x*x))
  local k,an={h+(x*f-y*u)/d,hp+(x*u+y*f)/d,sd*.15+az/2+sh/2},{h+f,hp+u,az}

  add(lg,{jp{h,hp,sd*.17+sh},jp(k),jp(an),jp{an[1]-(an[2]-k[2])*.46,max(an[2]+(an[1]-k[1])*.46,.02),az},nr})

  local so=spn(.47,0,sd*.24)
  local el=seg(so,q[i+4],.28,q[12],sd)
  local je=jp(el)
  cap(jp(so),je,.065,nr and 8 or 2)
  cap(je,jp(seg(el,q[i+4]+q[i+5],.26,q[12],sd)),.055,15)
 end

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

 for p in all{split"0,.04,.15,1,0",split".18,.42,.19,8,0",split".22,.36,.12,5,-.12",split".5,.76,.05,15,0"} do
  cap(jp(spn(p[1],p[5],0)),jp(spn(p[2],p[5],0)),p[3],p[4])
 end

 cap(head,head,.15,15)
 local hb=jp(spn(.78,-.05,0))
 cap(hb,hb,.14,0)

 isort(bp,1)
 for p in all(bp) do
  local a,b,r,c=unpack(p,2)

  local ra,rb=r*fl/a[3],r*fl/b[3]
  for t=0,1,.2 do
   circfill(a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,ra+(rb-ra)*t,c)
  end
 end
end

function angd(a)
 return (a+.5)%1-.5
end

function camreset()
 cyaw,fl,cam,look=ang,70,{px-cos(ang)*4,py+3,pz-sin(ang)*4},{px,py+1,pz}
 camupd()
end

function camupd()
 local h=hs()
 cyaw+=angd(ang-cyaw)*(st=="hang" and .03 or .05+h*.005)
 local d,fx,fz=2.6+h*.13,cos(cyaw),sin(cyaw)

 local t,w,lk={px,py+1.4,pz},{px-fx*d,py+2.5+h*.04,pz-fz*d},{px+cos(ang)*(1+h*.3),py+.9,pz+sin(ang)*(1+h*.3)}
 if st=="wallrun" then w[1]+=wnx*.9 w[3]+=wnz*.9 end

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

function tocam(x,y,z)
 x-=cpos[1] y-=cpos[2] z-=cpos[3]
 local f=x*ccy+z*csy
 return z*ccy-x*csy,y*ccp-f*csp,f*ccp+y*csp
end

function proj(c)
 local z=c[3]
 c.s=c.s or {64+c[1]*fl/z,64-c[2]*fl/z}
 return c.s
end

near,fr=.2,0

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

function isort(t,k)
 for i=2,#t do
  local p,j=t[i],i-1
  while j>0 and t[j][k]<p[k] do t[j+1]=t[j] j-=1 end
  t[j+1]=p
 end
end

function lerp3(a,b,t)
 return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}
end

function fp(q,u,t)
 return lerp3(lerp3(q[1],q[4],u),lerp3(q[2],q[3],u),t)
end

function fq(q,u,t,v,w)
 return {fp(q,u,t),fp(q,u,w),fp(q,v,w),fp(q,v,t)}
end

faces,ci,cj,ck,fpat,dpat={split"1,3,7,5",split"1,2,6,5",split"1,3,4,2"},split"1,4,1,4,1,4,1,4",split"2,2,5,5,2,2,5,5",split"3,3,3,3,6,6,6,6",{0x3333,0x5555,0x7777,0x5a5a},split"0,0xf0f0,0,0x3333,0,0,0,0xa5a5"

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

 plb[1],plb[2],plb[3],plb[4],plb[5],plb[6]=px-r,py,pz-r,px+r,py+ph,pz+r

 local v={}
 for k=1,#dl do
  local b,d,e,f=dl[k],0,0,0
  for i=1,3 do
   local c,m=cpos[i],(b[i]+b[i+3])/2
   d+=abs(m-c)
   e+=max(max(b[i]-c,c-b[i+3]))
   f+=(m-c)*cfw[i]+abs((b[i+3]-b[i])*cfw[i])/2
  end
  b.d,b.e=d,e
  if e<sk[8]+24 and f>near then
   local x0,y0,x1,y1,cs=999,999,-999,-999,{}
   for i=1,8 do
    local c={tocam(b[ci[i]],b[cj[i]],b[ck[i]])}
    cs[i]=c
    if c[3]<near then

     x0,y0,x1,y1=-999,-999,999,999
    else
     local s=proj(c)
     x0,y0,x1,y1=min(x0,s[1]),min(y0,s[2]),max(x1,s[1]),max(y1,s[2])
    end
   end
   b.cs,b.bx=cs,{x0,y0,x1,y1}

   if x1>=0 and x0<128 and y1>=0 and y0<128 then
    if e<sk[8]+10 then
     add(v,b)
    elseif x0>-999 then
     rectfill(x0,y0,x1,y1,sk[7])
    end
   end
  end
 end

 isort(v,"d")
 fr+=1
 local function visit(b)
  if b.mk~=fr then
   b.mk=fr
   local x0,y0,x1,y1=unpack(b.bx)
   for i=1,#v do
    local a=v[i]
    local p=a.bx
    if a.mk~=fr and p[1]<x1 and p[3]>x0 and p[2]<y1 and p[4]>y0 and behind(a,b) then visit(a) end
   end
   if b==plb then drawplayer() else drawbox(b) end
  end
 end
 for b in all(v) do visit(b) end
 beacon()
 fxdraw()
end

function drawbox(b)
 local m,cs,fog=mats[b.m],b.cs,b.e>sk[8]
 for ax=1,3 do
  for sd=0,1 do
   if sd==0 and cpos[ax]<b[ax] or sd==1 and cpos[ax]>b[ax+3] then
    local q={}
    for k in all(faces[ax]) do add(q,cs[k+sd*(ax==3 and 4 or ax)]) end
    local c=ax==2 and sd==1 and m[1] or m[ax==1 and 2 or 3]
    if fog then fillp(0x5a5a) c+=sk[7]*16 end
    cpoly(q,c)
    fillp()

    if ax~=2 and not fog and stat(1)<.9 then deco(b,m[5],q,c) end
   end
  end
 end
end

function deco(b,dk,q,c)
 local h,t,k=b[5]-b[2],dk%16,dk\16
 if t==1 and h>3 then
  fillp(fpat[flr(b[1]+b[3])%3+1])
  for y=1.4,h-1.2,3 do
   cpoly(fq(q,.06,y/h,.94,(y+1.3)/h),c+k*16)
  end
 elseif t==3 and h>1.5 then
  fillp(fpat[b.k%4+1])
  cpoly(fq(q,.08,.15,.92,.85),({0xa9,0x7c,0xeb,0xb3})[b.k%4+1])
 elseif t==5 then
  fillp(0x0f0f)
  cpoly(fq(q,.2,.25,.8,.75),c+k*16)
 elseif t==7 then
  for i=1,2 do
   local a,e=q[i],q[i+2]
   if a[3]<near or e[3]<near then return end
   a,e=proj(a),proj(e)
   line(a[1],a[2],e[1],e[2],k)
  end
 elseif t>0 then
  fillp(dpat[t])
  cpoly(q,c+k*16)
 end
 fillp()
end

function sky()
 local hy=mid(-20,64+fl*csp/ccp,150)
 cls(sk[1])
 fillp(0x5a5a)
 rectfill(0,hy-34,127,hy-18,sk[1]+sk[2]*16)
 fillp()
 rectfill(0,hy-18,127,hy,sk[2])
 local yaw=atan2(ccy,csy)
 if sk[6]>0 then circfill(64-angd(.1-yaw)*fl*6,hy-30,7,sk[6]) end

 for i=0,47 do
  local x,hh=64-angd(i/48-yaw)*fl*6,(i*37%11+3)*fl*sk[11]/240
  rectfill(x-6,hy-hh,x+6,hy,i%3==0 and sk[3] or sk[4])
 end
 rectfill(0,hy,127,127,sk[5])
 rectfill(0,hy,127,hy+2,sk[7])
end

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

function fxdraw()
 local h=hs()
 for i=1,mode=="play" and (h-6.5)*2 or 0 do
  local a,d=rnd(),50+rnd(40)
  local c,s,e=cos(a),sin(a)*.8,d+h*1.5
  line(64+c*d,64+s*d,64+c*e,64+s*e,7)
 end
end
__gfx__
01001e5004a0d7d0a4219f61c7a1ffd1001020384850687080f878b8c8d8e8f0c090d04050a0d0a1000c8060402011d0e0401060d050555000000060d05000a0
90902050e020308020204740402000c0101000000000000000000000000000d050101a00402084c80000000000000005838810840080000700808080b0800040
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
100860aa0002b081c00c100b608a00108110504900cf00070040a040f041004e10060040a040f08f008d20870040a040f040200040090040a040f0ce10894088
0040a040f00fff0610c700011010504fff06106700503010712000061067005030107201200830ca0002101050412008306a0050301071242008306a00503010
7209ff00000000828587e00aff02100000828288200bff05200000828609100d0000000000838487200e000110000083020610000000300000060306200d0002
300000040686e005200320000004050ae0032009300000838386200c00064000008405871001200b400000830646e00c0008500000048606e001200a50000083
05871004100f600000068883200d0006600000830486100f00050009008101107300102030405060708090a0b0c0d0e0f0c060d060407060a1e00c6060d0d085
90404042c0c010419040400050005000a0909020a0a09040b030308340402000c010100000000000000000000000000050501000a0a0907076000fff0fff0000
8241823082000fff8200c0a08130800000008200c0c080b00fff0fff820082c002d00fff04006200031001900fffc500000010311040e400c500000010311040
0eff06004400062006100eff06004600062082100eff8c0046000620c01006000b0046000220c0100eff0a0048000620041006000f000000014501e00eff0600
0000302430100effa110000030243010a9000600000030243010a900a1100000302430100000e500820060011060420005008200805080908300e5008200c001
10200fff0400820003c0f0d10eff8600840006c080b10eff090084008230205086000a008400c04080300eff8c002500032020500eff8c00840010502050e300
8c008400105020500eff8a00840003c0e0d280000e0084006001106082004e008400a050809082000e002500a05060900eff0e00840001011020860007008600
804080308700e9008600600110600100480067008010809001002900870010c210500300e9008600c00110200eff0600860006c0e0d30eff8a00880006c080b2
ca000d006800a01080905b00ed00880010431050cc000d006800a01080905d00ed00880010431050ce000d006800a01080905f00ed00880010431050c0100d00
6800a01080905110ed00880010431050c2100d006800a01080905310ed008800104310500a004f006800051020400b00ec00c800c3e0107007008b00880081c0
43d404100600480004200610071006004a00042006100a1006004c00042006100d1006004e0074200610041006000000302430100410a110000030243010ab10
0600000030243010ab10a110000030243010ae100600000030253010ae10a110000030253010a1200600000030263010a120a110000030263010852006000000
302730108520a110000030273010041086008800c0c085b3e6100600880010010620c610070088001001606085100a008800b030018004100900880041c002d5
e91006008a0010010620c91000108a001001606008100a006b00801080907810ea008b0010821050c71086008a001150c090481086008a00d0a0c090ec100600
8c0010010620cc1007008c00100160608b100d008c00b03001800d1086008e00c0c085b4002009008e008050c03001200e008e00c040803006200b00000080a8
80f0e5204b008e00106140600a106b0001100620204007200b0080100180803003208c00af008010809073206d00cf0010a01050012009008e0072c003d60c10
ea008f0001c0a0300e100b00411001c080c006ff041000000303031006ff041006000320031006ff04100800032003100a000910000083c0823009ff00000000
818081900f000000000081a0c0308f0000004100c060c0400d2000000000800a80f00320600004100720204001ff03200000058705100e100910000005060510
00102038405068708098a0b8485890f0c090d0005000d0815100e060d05040303010819040205560505070d0505000a0909020a0a09040b030308340402000c0
c01040000000000000000000000000d000000080802042a4000bff0bff00000f8087e009100bff00000f800ae007300bff00000a800ae082500bff0000c8800a
e0cfff0bff0100208287100000c90001008c82201000000bff01008c82201000000bff06008c208710800081000100c0c001b000004bff010002c0e4d006004b
ff0100604065700b004bff8100402065500f00000001008050819003100fff010081c0823009004bff010001c065d402000800e2000b10a040e1004800010010
0160600700850001008050809007008600010080a0809001000600010081c0e1d108108bff0100c0c007b1861087000300c0c001b10a10080001000341a0f002
20080001000341a0a00a20080001000341a0f00c108500010002a0a0a003208500010002a0a0f009208500010002a0a0a00b10850001008050a0900f10810001
00c0508030852000000100804002900c200fffa1004020c25009100800830001c0a0d200308bff0100c0c0c9b20130490001007203022008308a000100028202
200e300cff0100028202200e200800830001c0a0d30530080043000b20a0500530860043000b202050053086000100402141400d308600010040214140044086
000100402141408a408600010040214140e43028000100104160600c30060004004020c1500140c70083006040a0300640060004004020c15008300600830081
c0c1d4094008008300c0c0a0b3094066008300c0c040b309408bff0100c0c045b30b4003008000c34020408c40c7004200a090c0a01d402900630010d110508e
40870063004710e0708e40c70001004031a0400650c70001004031a0408c50c70001004031a0400350670001006041106008400600830081c0c1d50e50060001
0002028220ed5007000100100260608b50c70083008050a0908e508600050081c002c00a0004100000c087c020032009100000c00ac010014086100000c0c8c0
200a5004100000c046c0100e1001ff0000c087c020064001ff0000c007c01000000f0000000a0405100d20041000008705051004600bff000005840a10001020
3848506870809078b81858e0f000000000000000e0b10c0060d0d085d03030159040205560505070d0505000a0909020b0b030300000000040402000a0a0a057
000000000000000000000000500000006090901a27008fff8fff000006808ae000000000010042500a1086000000010042500a108fff0000010040c10a200b00
0000010040c10a208fff8fff010006c140208fff8fff840006208a208fff0410010082c1402086000410010082c1402083000500a100407140e007000500a100
407140e083000a00a100407140e007000a00a100407140e083000f00a100407140e007000f00a100407140e001000600a1004040c03089000b00a1004040c030
a40002000100e0e084f0a400cb000100e0e023f08400821001000150c010840004100400014040208100e310030001601070020003006400401001a088000300
6400401001a0020009006400401001a0880009006400401001a002000f006400401001a088000f006400401001a001008000a10001c080b000000000a10042c0
81d004008410000081804ce004008410010040814c2086008410010040814c2004008410040081204c208400841001005090834084000d100100509003408400
8420010050904440c500081001005040403025000e108100b020205084000020a2005010205045000910e300401080a045000120e300401080a045000920e300
401080a084008410a10001c041d184000a10010001c0c1d284008410010001c040b10dff8c200000888007e08cff8c200100404307200e008c20010040430720
8cff8c200100c343402007008c200100c34340208cff0a3001000443402086000a3001000443402084000a30c600016040208cff8c208700092007200dff8730
4400882041100dff6730010088a1102000004730010060c1106084000d20010050908240840002300100a0e0a0908400c3300100a031a090840085300100a081
a090090000300100c0a0c0300b0003300100c05080300dff0230030010800170010000306700801001a0090000306700801001a00dff0d20010088c080b28400
0d20220050c080b20dff0430010088c0a1d30dff0830840088c001b384008a304400012043108400824044000120c11005000640440020200240c50006404400
2020024084000a4044000120841004008a30840040214c2086008a30840040214c2004008a30c60081204c2084000e30050001202050c40084408400c0404030
45008c30a600401080a045008340a600401080a045000c40a600401080a084000340840001c061d484008240840001c040b4000003504400852006108fff8250
840082c1402086008250840082c140208fff0350840040c106200b000350840040c106208fff0f50840006c140208fff82500800062086204000065084005040
6030a10006508400504060300300065084005040603064000650840050406030c50006508400504060302700065084005040603088000650840050406030e900
065084005040603004000a5084008120821004008a5084008140421004000b5084008160021004008b5084008180c11004000c50840081a0811004008c508400
81c0411004000d50840081e0011004008d5084008101c01004000e5084008121801004008e508400814140108400ee5087000140107084000350840001c080b5
04000d50070081c001c0001020b8405060708098a0b0c0d0c8f0c060d010507060c1020c6160d0d0115040201160d050555000000060505000a0909020507060
308080208730404000d0c0e01100000000000000000000000050500000e0e01050f60009ff0bff00008d800ee009ff071000008d808de009ff023000008d800a
e000000dff0100c0108c1086000dff0100c0108c100aff0bff01008a0301200aff0dff0100032106200aff090001000322862008000dff010083428c100b000d
ff850002c486a0030000000100c0c0c0b081000dff010082c0c2d0e60001002300901081400700e000210060111060e7000300430010216060c4000300010080
6001f0450085000100a090a13006008900620001100180c6008c00a300a0100240c60080106500a010814007006010c30060e01060c4000d000100c0e0c37103
0082000100c1c081d1810081000100806001f0000004002200a01001808dff02004300805060308bff85004300605080308eff08004300807080300cff0f0045
00806080308cff0210e500810110728cff02104500105010406fff02104500105010408800050085008030819009000a0085008050603008000c002600811020
5008000c00850010502050ea000c008500105020508b000d008500413081a00c00021085000150803008000000850081c002d209000610040001b041a0eeff06
102500101041500aff881065008a10c0100aff0410450003c001d30aff881085008ac0c0b18900e910850060c010608eff4910850080506030030029108500a0
3060900aff0a1001008a0306a001000e10070002e002200200ed10070060e0106005008e1007008050a03007008c100700813081a08bff0c100700803002900e
ff0d100700013060900b000c100700c05080308b0001200700108010108b006220070010801010ec000120070010801010ec0062200700108010106b00e02008
00e0a0e0108aff0320a700020110738aff03200700105010406eff03200700105010400fff012007008060013007000220a700811020500aff0a1007008ac001
d40cff06200100082209e00cff06204500082009100cff0820850010400850eb0008208500104008508dff09208500805001f081000a20850080500130860009
208500805001f08dff0d208500805001f081000e2085008050013086000d208500805001f08dff01308500805001f08100023085008050013086000130850080
5001f009000e20850081c08120e8008e20850010c0606004000c204600c010105084000b20850010011050840003308500100110500cff8620850008c0c0b20c
ff0820850008c081d50cff08300100084385a001000b308700040104a003000e308900020182a0e40081408b0020c120500cff0530850008c061b30cff053085
0008c061d60000e730850060011060040007308600c01080900400e730a600103310506500e730a600103310508100ea30870060011060840009308700a05080
3084000a308700a0a080308300ed308900600110604400cc308a00c010a0904400ed30aa0010311050a500ed30aa001031105003008e308b0002c002c0041000
000000030f03a00cef0e100000038c0310041003200000c34bc3a00fef07300000830a831000100c30000083cd83a00bff0b400000848f04a000102030405068
708088a0b8c0d0e0f00010201000701002720c21d010201ad020101e60d05055c010100060d0d000a0909020e0e0c030e0e0208740402000c010101c00000000
0000000000000000500000006010d05c15000fff0dff00000406891002008dff0c0001c0c0b00fff0dff0c0004c002d0010004000c00024060300fff0900ac00
04202050c4000c000c0010801090c4006d000c001080109026000c000c001080109026006d000c0010801090a400eb000d00e0a0e09007000300070030026071
aeff0a000600304260728fff00108a0080408172460001000c0040c140710fff03100000048508200fff03100b0004c0c0b1810006100b00813001a00fff0e10
ab0082b010730fff0e100b0010501040e3000e100b00105010400fff0f100b0004c002d10fff04100b00104103720600032089002081837006004620000020c4
40e042008420aa0080108071420086206a0080108072420088202a008010807300000320ea00201083400dff0a20000005058b100dff0a200a0005c0c0b20400
80300a008130c030040080306a008110c080040002300a0081c08720e60008308b0010c010500dff00300a00104103730eff0e200a00c0408030000004300a00
8050c0308dff09300a00804080308eff0c300a00108010908eff6d300a0010801090efff0c300a0010801090efff6d300a00108010906effeb300b00e0a0e090
800006300a00803001a00dff0b200a0005c081d20eff0240a9000110a0710eff04408900011060720dff8540000005c445200dff8540890005c0c0b303000a40
8900014060300dff0d402a00812020500dff0c40890005c002d346008640890040c1407200000050c70002200a1081000650000080e380e081000e50000080e3
80e0400002500800c0c008f082000850080080406030c1000d50a80021202050e3000d5008001050205000000050080002c0c0b40eff04600000048505a08100
8260080041c0c07382006260080060c010600200e360890060c0106000000f50080002c081d40fff84600b0003c002c00fff0dff0c0010108940e6000dff0c00
101089400fff03100b0010100870e60003100b00101008700dff0a200a0010108b40e6000a200a0010108b400dff8540890010104570e6008540890010104570
01ff0a000000030a03200d0009100000034b031002ff02300000030983a00e000c300000038c032004ff05500000038a03100c0002600000038903a000102038
485060708090a0b8c068e0f0c07060d0307060e1c20ca160d0508540706015404020004020200090404000a090902080c0a03080802087404020007060600000
000000000000000000000050000000b030300015000eff0cff00000481041080008cff0300c0c0c0b00eff0cff030004c081d003000eff030041c0032083000d
ff0300c050803040000400e200801081902000040063001010815041000400630010108150feff0400e200101081500eff0100030082c081d10eff0700000084
810510030007000300418081200eff0b00030041e04120010009000300604060300eff0700030082c0c0b10dff01100000058486108dff8f00e4004110c0900e
ff6f0003006001106000008f00e6004110c090efff00100500100160600100e010070060011060c200e01003006003106084008e00030001a0411044004f0044
0001a0e010c400ef00850001a0901084008010c60001a040100eff0d00030084c001d20dff0110090005c0c0b28dff0610090001c04120040007100900805080
3000000e10e8006010039000000520e80060100390efff0e10690010108650c0000e106900101086500000ea2009006080106003000e10e80020108240820003
200000a0a4a01003004420290020106140820007200000a0c4a010030048206900201061408500ee1000006094601085008020000060a4601085002220000060
b460108500c320000060c4601085006520000060d4601085000720000060e460108500a820000060f4601085004a200000600560100dff0b10090005c081d30d
ff0b200000050586f00dff0b200a0005c0c0b30dff8c200a0005c080d40eff0e200a0082c081200eff01300a00826181200eff04300a00820202208effed200a
0060c010608effe0308b0060a010608effe330cc0060a0106001000d200a0080308030030002306b006010c090040000300a0001a0013003008f20ec00021010
5003008230ec0002101050050004300a00018101100dff08300000050784100dff08300e0005c0c0b40dff01400000048805a00fffe0400e0060811060020000
400e0041c080100dff0c300e0005c081d500000640011001c001200eff0540011010011050040005400110100110502eff0540a210f21010710eff0240011003
c041c007ef04100000058c871009ef07100910038184a0011008200000858b871003100b200710838184a00cef0b400000060f87100a0000500000060a061000
102038405068708098a0b0c8d888f020905000008020a1230ce160500085d050201560d0505590404070d0505000a0909020a0a000408080208740402000c0c0
100000000000000000000000000050100081808020402500050000000000028a0ce00eff8bff0eff09018fa00000081001000702811000000cff050007020210
0000081009000702811000000cff0d000702021000000dffc0008120861000008b00c0008120461062000a00e0001010c05080000dff010001c0c0b000000dff
010081c081d08000030001000140603000000700810081202050810003100100c00182204200e2100100600110604200e710030060011060000004100100c0a0
a0f0000045100100c041a0f0000086100100c0e1c0f000000f00010081c081d100000810050082c081b10700091005006040c0300b000f00c400812084100b00
0000c400812005100b0004108500812020500e0009008500204183704c000d00e400601060904c000b00e400601060904b000a00e400101082500b0000100500
81c081d28b0006000500014060300d0000000500600210600b0002002600c01080900b0080006700c01080900b00e2004600106110500b006100870010c01050
6c00e2004600106110506c006100870010c0105000000cff090007c0c0b203000000c8000120031003000c00c80001200610430081000900c040603003000400
__map__
9800100202053c0074008e00060106093c0090008e00060106093c00ac008e0006010609320060008e0001013005300000009000100c083d4000200190000810300232007e0190000620010630004801a2000801080930006401b6000801080900008001d000700c183b9000f000cc001002480190000000cc00100248019800
4001d00008030c08ac009000ce00010130059c00a000ce00060106099c00bc00ce00060106099c00d800ce000601060994005000d0000c04060390004001d000100c184d90000000d00008102002a2000000d00006200106a0002000e40008010809a0000800f800080108098000c0ff1001300c0c4b7e00feff100106200106
6200c8ff10010c0a0a0f6200dcff10010c140a0f6200f0ff10010c1e080f5000d0ff1001081018020000c0ff1001700c0c5d500000005001200c0c5b580070005001180406035000d0005a012002020560002001500110050803500060015001200c100cc0feb0ff000030e0380e90015000000030c8380ee0fe9001000030a0
38016001e001000030f0300e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc50505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc50505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc50505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc50505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc777c777c777c7c7cc777777c777cccccccccccccccccccccccccccccccccccc50505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7c7c7c7c7c7c7c7c777777777c7ccccccccccccccccccccccccccccccccccc550505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc777c777c77cc77c77777777777cccccccccccccccccccccccccccbcccccccc550505000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
6c6c7c6c7c7c7c7c7c7777777777777c6c6c6c6c6c6c6c6c6c6c6c6cbbbc6c6c6c550505000c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
c6c676c6767676767677777777777776c6c6c6c6c6c6c6c6c6c666c6cbc6c6c6c65505050006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6
6c6c6c6c6c6c6c6c67777777777777776c6c6c6c6c6c6c6c6c66666c6c6c6c6c6c555505000c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
c6c6c6c6c6c6c6c6c777777777777777c6c6c6c6c6c6c6c6c6c666c6c6c6c6c6c65555050006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6
6c6caaac6c6cac6caaa7a7a7aaa7a7776aac6c6c6aacaaac6c66aaacac6c6aacaca55505000c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
c6c6a6a6c6c6a6c6a777a7a7a777a777a6c6c6c6a6a6a6c6c6c6a6c6a6c6a6a6a6a555050006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6
6c6caaac6c6cac6caa77a7a7aa77a777aaac6c6cacacaa6c6c66aa6cac6cacacaca55505000c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
c6c6a6a6c6c6a6c6a677aaa7a777a776c6a6c6c6a6a6a6c6c6c6a6c6a6c6a6a6aaa550050006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6
6c6caaac6c6caaacaaa77a77aaa7aaacaa6c6c6caa6cac6c6c66a66caaacaa6caaa55005000c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
c6c6c6c6c6c6c6c6c6c77777777777c6c6c6c6c6c6c6c6c6c6c666c6c6c6c6c6c655500500c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6
6c6c6c6c6c6c6c6c6c6c777777777c6c6c6c6c6c6c6c6c6c6c66666c6c6c6c6c6c555005006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
c6c6c6c6c6c6c6c6c6c6c6777776c6c6c6c6c6c6c6c6c6c6c6c666c6c6c6c6c6c655500500c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6
6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c66666c6c6c6c6c6c555005006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c
6666c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c666c6c6c6c6c6c655500500c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6666666666666
66666c6c6c6c6c6c6666666666666c6c6c6c6c6c6c6c6c6c6c66666c6c6c6c6c6c555005006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c666666666666
6666c6c6c6c6c6c666666666666666c6c6c6c6c6c6c6c6c6c6c666c6c6c6c6c6c655500500c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6666666666666
66666666666666666666666666666666666666666666666666666666666666666655500500666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666655500500666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666655505500666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666655505500666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666655505500666666666666666666666666666666666666666666666666666666
6666666666666666666666666666666666666666666666666660a906666666666655505500666666666666666666666666666666666666666666666666666666
6666666666666666666666666666666666666666666666666660a906666666666655505500666666666666666666666666666666666666666666666666666666
6666666666666666666666666666666666666666666666666660a9006666666666555055006666666666666dddddddd666666666666666666666666666666666
6666666666666666666666666666666666666666666666666660a9009666666666555055006666666666666dddddddd66666666666666666dddddddd66666666
6666666666666666666666666666666666666666666666666660a9009966666666555055006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666666666666666666666666660a9009966666666555050006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666666666666666666666666660a9009906666666555050006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666666666666666666666666660a9009900666666555050006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666666666666666666666666660aa009900666666555050006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666666666666666666666666660aa009900966666555050006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666666666666666666666666660aa009900966666555050006666666666666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666646464646464646464646460aa009900946464555050006464646464666dddddddd66666666666666666dddddddd66666666
666666666666ddddddddd6666666664646464646464646464640aa009900964646555050004646464646466dddddddd66666666666666666dddddddd66666666
6666666666666666666666666666646464646464646464646460aa00990094646455505004646464646466666666666666666666666666666666666666666666
6666666666666666666666666666664646464646464646464640aa00990096464655505006464646464646666666666666666666666666666666666666666666
6666666666666666666666666666666464646464646464646460aa00990094646455505004646464646466666666666666666666666666666666666666666666
4444444444444444444444444444444646464646464646464640aa00990096464655505006464646464644444444444444444444444444444444444444444444
4444444444444444444444444444446464646464646464646464aa00990094646455505004646464646464444444444444444444444444444444444444444444
4444444444444444444444444444444646464646464646464646aa00990096464655505006464646464644444444444444444444444444444444444444444444
4444444444444444444444444444446464646464646464636363aa00990094646455505004646464646444444444444444444444444444444444444444444444
4444444444444444444444444444444646464646464646463636aa00990096464655505006464646464644444444444444444444444444444444444444444444
4444444444444444444444444666666666666666666666666666aa00990096666655505006666666666666644444444444444444444444444444444444444444
444444444444444444444446d6d6d6d6d6d6d6d6d6d6d6d6d6d6aa0099009444445550500449d6d6d6d6d6d6d444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00990044444455505004449944466666666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00990044444445505004444994466666666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00990044444445505004444499466666666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00990444444444505004444444996666666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00990444444444505004444444499666666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00994444444444505004444444449996666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00994444444444505004444444444999666444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00944444400044445004444444464449996444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00944444000004445004444444466444999444444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00944444000004455004444444466644499944444444444444444444444444444444444444
4444444444444444444444466666666666444444444444444444aa00444444000004455004444444466664449999444444444444444444444444444444444444
44444444444444444444444666666666664444444444444444444444444444f000f4455004444444466666444499944444444444444444444444444444444444
444444444444444444444446666666666644444444444444444444444444444fff44455004444444466666664449999444444444444444444444444444444444
44444444444444444444444666666666664444444444444444444444444444488844455004444444466666666444999944444444444444444444444444444444
44444444444444444444444666666666664444444444444444444444444244888884844444444444466666666444499999444444444444444444444444444444
44444444444444444444444666666666664444444444444444444444442228855588884444444444466666666444444999944444444444444444444444444444
44444444444444444444444666666666664444444444444444444444442228555558884444444444466666666444444499994444444444444444444444444444
44444444444444444444444666666666664444444444444444444444442228555558884444444444466666666444444449999944444444444444444444444444
44444444444444444444444666666666664444444444444444444444442228555558888444444444466666666444444444999994444444444444444444444444
44444444444444444444444666666666664444444444444444444444442228555558484444444444466666666444444444449999944444444444444444444444
4444444444444444444444466666666666444444444444444444444444f248555558444444444444466666666444444444444999994444444444444444444444
44444444444444444444444666666666664444444444444444444444444448855588444444444444466666666444444444444499999944444444444444444444
44444444444444444444444666666666664444444444444444444444444440111111444444444444466666666444444444444449999994444444444444444444
44444444444444444444444666666666664444444444444444444444444400111111144444444444466666666444444444444444499999444444444444444444
66666666666666666666666666666666666666666666666666666666666000111111666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666000611111166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666606666611166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666000666611166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666000666661666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666600066611166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666660666611166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666600066661666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666600066611166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666660666611166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666555561666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666665555511166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666555555511166666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666665555555711556666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666655555111666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666665555516666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666555566666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
__meta:title__
parkour: rooftops
third-person 3d parkour
