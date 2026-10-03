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
 -- break), e: gap distance (fog),
 -- f: depth of the nearest
 -- corner (all behind: culled).
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
   f+=(m-c)*cfw[i]+abs((b[i+3]-b[i])*cfw[i])/2
  end
  b.d,b.e=d,e
  if e<sk[8]+24 and f>near then
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
  if e<sk[8]+24 and f>near and bx[3]>=0 and bx[1]<128 and bx[4]>=0 and bx[2]<128 then add(v,b) end
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
