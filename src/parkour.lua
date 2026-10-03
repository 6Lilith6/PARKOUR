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
