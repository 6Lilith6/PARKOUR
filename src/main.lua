-- parkour: rooftops
-- third-person 3d parkour
-- main loop, game flow,
-- checkpoints, timer, hud

dt=1/60
lnames=split"old city rooftops|construction site|factory|underground|downtown|neon district|cliff village|megastructure"
hints=split("⬆️ run   ⬅️➡️ steer   🅾️ jump|run into low obstacles: vault\nfaster run = smoother vault|❎ while running: slide|❎ just before landing: roll\nhigh drops without it hurt|jump at a ledge to grab it\n⬆️ climb  ⬅️➡️ shimmy  ❎ drop\n⬇️+🅾️ jump away|yellow = climbable\nhold ⬆️ to climb|hold 🅾️ into a wall: run up it\nhold 🅾️ along a wall: wallrun|on a wall press 🅾️: kick off\n(tic-tac / wall jump)|narrow beams: ⬅️➡️ keep balance|red awnings bounce you high|keep moving to build flow\nflow = higher top speed|three ways up: ladder,\nsteps, or run up the wall|wallrun, 🅾️ wall jump, wallrun\nor take the cable / skybridge|last climb: stairs, chimney\nor vault-jump-mantle|construction site: climb floor\nby floor to the crane|4m up: ladder, pallets, or\nhold 🅾️ and run up the formwork|❎ slide under the formwork bar\nor go round the lift core|hanging pallet: from still,\n⬆️🅾️ is a short precise hop|the gap: hop the pallets, balance\nthe girder or wallrun the panel|safety nets bounce you a floor up|climb the crane mast and walk\nthe jib to the cab|factory: long straights build\nflow - keep moving, keep speed|the catwalk is the sprint lane:\nladder or crate steps up|container tops: chain the jumps\nwithout stopping|hold 🅾️ along the tank: wallrun\nonto the pipe rack|❎ slide under the pipes,\nvault the valve|slag pit: plank, hook container\nor a full-flow long jump|underground: platform, train\nroof or the track bed|tunnel: wallrun, 🅾️ wall jump,\nwallrun - zig-zag the walls|❎ slide under pipes and cables|7m up: ladder, crate chain\nor run up from a crate|hop the narrow beams over\nthe shaft|downtown: up from the street\nto the rooftops|taxi, van, awning: bounce\nonto the balcony|roof garden: ❎ slide under\nthe pergola, vault the glass|cross on the cable or take\nthe skybridge|office roof: AC units,\npenthouse, tank - pick a line|garage: weave between the\ncars or hop the roofs|4m walls: ladder, gondola,\nAC units, or run up","|")

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
