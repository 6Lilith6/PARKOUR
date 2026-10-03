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
-- sets wall/gnd/roof contacts
function pmove()
 wall,gnd,roof=nil
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
   py,roof=b[2]-ph,b
  end
  vy=0
 end
end

function hs()
 return sqrt(vx*vx+vz*vz)
end
