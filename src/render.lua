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
fpat={0x3333,0x5555,0x7777,0x5a5a}

-- a should be drawn before b?
function behind(a,b)
 for i=1,3 do
  local c=cpos[i]
  if a[i+3]<=b[i] then
   if c>=b[i] then return true end
   if c<=a[i+3] then return false end
  elseif b[i+3]<=a[i] then
   if c<=b[i+3] then return true end
   if c>=a[i] then return false end
  end
 end
 return a.d>b.d
end

function render()
 sky()
 -- player pseudo-box joins sort
 plb[1],plb[2],plb[3],plb[4],plb[5],plb[6]=px-r,py,pz-r,px+r,py+ph,pz+r
 -- d: centre distance (sort tie
 -- break), e: gap distance (fog).
 -- only boxes in range and not
 -- behind the camera get sorted
 local v,o={},{}
 for b in all(dl) do
  local d,e,f=0,0,0
  for i=1,3 do
   local c,m=cpos[i],(b[i]+b[i+3])/2
   d+=abs(m-c)
   e+=max(max(b[i]-c,c-b[i+3]))
   f+=(m-c)*cfw[i]
  end
  b.d,b.e=d,e
  add(e<50 and f>-b.rad and v or o,b)
 end
 -- insertion sort: list stays
 -- nearly sorted frame to frame
 for i=2,#v do
  local b,j=v[i],i-1
  while j>0 and behind(b,v[j]) do
   v[j+1]=v[j]
   j-=1
  end
  v[j+1]=b
 end
 for b in all(v) do
  if b==plb then drawplayer() else drawbox(b) end
 end
 for b in all(o) do add(v,b) end
 dl=v
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
 local m,cs,vis=mats[b.m],{},0
 for i=0,7 do
  local c={tocam(b[1+i%2*3],b[2+flr(i/2)%2*3],b[3+flr(i/4)*3])}
  if c[3]>near then vis+=1 end
  cs[i]=c
 end
 if vis==0 then return end
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
