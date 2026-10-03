-- particles + speed lines

parts={}

function puff(n)
 for i=1,n do
  add(parts,{px+rnd(.6)-.3,py+.1,pz+rnd(.6)-.3,rnd(2)-1,rnd(1.5),rnd(2)-1,.4+rnd(.3)})
 end
end

function fxupd()
 for e in all(parts) do
  for i=1,3 do e[i]+=e[i+3]*dt end
  e[7]-=dt
  if e[7]<0 then del(parts,e) end
 end
 -- dust while sliding/rolling
 if (st=="slide" or st=="roll") and rnd()<.4 then puff(1) end
end

function fxdraw()
 for e in all(parts) do
  local c={tocam(e[1],e[2],e[3])}
  if c[3]>near then
   local s=proj(c)
   circfill(s[1],s[2],e[7]*fl/c[3]*.5,e[7]>.3 and 7 or 6)
  end
 end
 -- speed lines at high speed
 local h=hs()
 if h>6.8 and mode=="play" then
  for i=1,(h-6.5)*2 do
   local a,d=rnd(),50+rnd(40)
   local e=d+h*1.5
   line(64+cos(a)*d,64+sin(a)*d*.8,64+cos(a)*e,64+sin(a)*e*.8,7)
  end
 end
end
