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
