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
  pr("⬅️➡️ steer  ⬆️ run  ⬇️ brake",96,6)
  pr("🅾️ jump/wall  ❎ slide/roll/drop",104,6)
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
  local s,w=hints[hint],0
  for l in all(split(s,"\n")) do w=max(w,#l) end
  rectfill(62-w*2,97,66+w*2,117,1)
  print(s,64-w*2,99,7)
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
