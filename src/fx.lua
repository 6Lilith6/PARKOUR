-- speed lines at high speed

function fxdraw()
 local h=hs()
 for i=1,mode=="play" and (h-6.5)*2 or 0 do
  local a,d=rnd(),50+rnd(40)
  local e=d+h*1.5
  line(64+cos(a)*d,64+sin(a)*d*.8,64+cos(a)*e,64+sin(a)*e*.8,7)
 end
end
