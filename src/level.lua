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
