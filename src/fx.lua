-- speed lines at high speed

function fxdraw()
 local h=hs()
 for i=1,mode=="play" and (h-6.5)*2 or 0 do
  local a,d=rnd(),50+rnd(40)
  local c,s,e=cos(a),sin(a)*.8,d+h*1.5
  line(64+c*d,64+s*d,64+c*e,64+s*e,7)
 end
end
