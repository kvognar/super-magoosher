pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
t=0
b={
  left=0,
  right=1,
  up=2,
  down=3,
  z=4,
  x=5
}
score=1
tests={
  act={
    scores={
      min=1,
      max=36,
      scale=1
    },
    subjects={"math","reading","english","science"}
  }
}


function _init()
  game_states={title=title, game=game, results=results}

  state=game_states.title
  state:init()
end

function _update60()
  t+=1
  state:update()
end

function _draw()
  cls()
  state:draw()
end
function transition_to(new_state)
  state=new_state
  t=0
  camera()
  state:init()
end

title={}
function title:init()
  self.name="super magoosher"
  self.msg={
    "collect study bubbles to",
    "improve your test scores",
    "press ❎ to start"
  }


end
function title:update()
  if (btnp(b.x)) transition_to(game_states.game)
end
function title:draw()
  rectfill(0,0,128,128,13)
  color(7)
  print(self.name, hcenter(self.name), 40)
  for i=1,#self.msg do
    print(self.msg[i],hcenter(self.msg[i]),50+6*i)
  end
end

-- game logic
game={}
function game:init()
  cam={x=0, y=0, watermark=0, speed=2}
  self.test=tests.act
  self.scores={}
  self.game_over=false
  self.boost_countdown=300
  foreach(self.test.subjects, function(subject)
    self.scores[subject]=self.test.scores.min
  end)
  self.clouds={}
  for i=0,3 do
    self:make_clouds()
  end

  self.player=player:new({x=60,y=128})
  self.player.dy=-4

  self.actors={self.player}
  self.boopers={}
  for i=0,2 do
    self:make_booper(false, true)
  end
  self.booster=nil
end
function game:make_clouds()
  add(self.clouds, cloud:new({x=rnd(128), y=cam.y+rnd(128)-128}))
end

function game:update()
  foreach(self.actors, function(actor)
    actor:update()
  end)
  foreach(self.clouds, function(cloud)
    cloud:update()
  end)

  self:boop_check()
  if (t > 60) self:booper_sweep()
  self:boost_check()
  self:update_camera()
  if(btnp(b.z)) self:boost()
  self:end_check()
end
function game:draw()
  local color = 12
  if (self.boosting) color = 3
  rectfill(0+cam.x,0+cam.y,255+cam.x,255+cam.y, color)
  foreach(self.clouds, function(cloud)
    cloud:draw()
  end)
  -- print(#self.boopers, 0+cam.x, 0+cam.y, 0)
  -- print(self.player.dy, 0+cam.x, 8+cam.y, 0)
  foreach(self.actors,function(actor)
    actor:draw()
  end)
  foreach(self.boopers, function(booper)
    booper:draw()
  end)
  if(self.booster) self.booster:draw()
  camera(0, cam.y)
  self:score_display()
end
function game:update_camera()
  if self.boosting then
    cam.watermark=self.player.y-100
    cam.speed=abs(self.player.y)*2
  else
    cam.speed=2
  end
  if cam.y > cam.watermark then
    cam.y -= cam.speed
  elseif cam.y < cam.watermark then
    cam.y += cam.speed
  end
  if abs(cam.y-cam.watermark) < cam.speed then
    cam.y=cam.watermark
  end
end
function game:end_check()
  if (not self.game_over) and self.player.y > cam.y+150 then
    self.game_over=true
    self.game_over_timer=150
  elseif self.game_over and self.game_over_timer > 0 then
    self.game_over_timer-=1
  elseif self.game_over and self.game_over_timer<=0 then
    transition_to(game_states.results)
  end
end

function game:score_display()
  rectfill(0+cam.x, 0+cam.y, 255+cam.x, 12+cam.y,2)
  local offset=8
  for i=1,#self.test.subjects do
    local subject=self.test.subjects[i]

    print(subject,offset+cam.x,1+cam.y,7)
    print(self.scores[subject],offset+(4*#subject/2-1)+cam.x,7+cam.y)
    offset+=4*(#self.test.subjects[i]+1)
  end
  if self.game_over then
    print("game over", hcenter("game over"),40+cam.y,7)
  end

  local msg = "magoosh boost!"
  if self.boosting then
    local color = t%15
    print(msg,hcenter(msg), 70+cam.y,color)
  end
end

function game:make_booper(moving, onscreen)
  local x
  local y
  local dx
  if onscreen then
    y = cam.y+rnd(128)
  else
    y=cam.y-rnd(128)-10
  end
  if moving then
    if rnd(2) > 1 then
      x=130
      dx=-1
    else
      x=-10
      dx=1
    end
  else
    x=rnd(118)
    dx=0
  end
  local booper = booper:new({x=x, y=y, dx=dx})
  local subject=self.test.subjects[flr(rnd(#self.test.subjects)+1)]
  booper:init(subject)
  add(self.boopers, booper)
end
function game:booper_sweep()
  foreach(self.boopers, function(booper)
    if booper.y > cam.y+128 or
    booper.x > 140 or booper.x < -10
     then
      del(self.boopers, booper)
    end
  end)
  local moving_boopers=0
  foreach(self.boopers, function(booper)
    if (booper.dx !=0) moving_boopers+=1
  end)
  while moving_boopers<2 do
    self:make_booper(true, true)
    moving_boopers+=1
  end
  while #self.boopers < 4 do
    self:make_booper(false, false)
  end
end
function game:boop_check()
  foreach(self.boopers, function(booper)
    booper:update()
  end)
  foreach(self.boopers, function(booper)
    if (self.player.dy > 0 or self.boosting) and self.player:collide(booper) then
      self:boop(booper)
    end
  end)
end
function game:boop(booper)
  self.player.dy = booper.booping--mid(booper.booping,self.player.dy+booper.booping, self.player.min_dy)
  cam.watermark=booper.y-120
  sfx(0)

  del(self.boopers, booper)
  if self.scores[booper.subject] < self.test.scores.max then
    self.scores[booper.subject]+=self.test.scores.scale
  end
end
function game:boost_check()
  if self.booster and self.player:collide(self.booster) then
    self:boost()
  elseif self.booster==nil and self.boost_countdown < 0 then
    self.booster=booster:new({x=rnd(116)+2,y=cam.y-64})
  elseif self.boosting and self.boost_countdown < 1 then
      self:unboost()
  elseif self.booster and self.booster.y > cam.y+150 then
    self.booster=nil
    self.boost_countdown=600
  else
    self.boost_countdown-=1
  end
end
function game:boost()
  self.boosting=true
  self.player.min_dy=-8
  self.player.dy=-8
  cam.watermark=self.player.y -100
  self.booster=nil
  self.boost_countdown=150
  sfx(1)
end
function game:unboost()
  self.boosting=false
  self.player.min_dy=-4
  self.boost_countdown=600
  foreach(self.boopers,function(booper)
    booper.dx=0
    booper.dy=0
  end)
end


-- entities
entity = {x=0,y=0,dx=0,dy=0,damping=1,w=5,h=8,spr_w=1,spr_h=1,frames={},frame_index=1,frametime=1,facing_left=false}
function entity:new(attrs)
  attrs = attrs or {}
  return setmetatable(attrs,{__index=self})
end
function entity:draw()
  if self.current_frames and #self.current_frames>0 then
    spr(self.current_frames[self.frame_index],self.x,self.y,self.spr_w,self.spr_h,self.facing_left)
  else
    rectfill(self.x,self.y,self.x+self.spr_w,self.y+self.spr_h,8)
  end
end
function entity:update()
  self.x+=self.dx
  self.y+=self.dy
  self.dx*=self.damping
  self.dy*=self.damping
end

function entity:collide(other)
  return self.x+self.w > other.x and
    other.x+other.w > self.x and
    self.y+self.h > other.y and
    other.y+other.h > self.y
end

player=entity:new({
  w=8, h=8,
  frames={
    rising=12,
    falling=14,
  },
  min_dy=-4,
  current_frames={12},
  gravity=.1,
})

function player:update()
  self:process_buttons()
  self:move()
  if self.dy > 0 then
    self.current_frames={self.frames.falling}
  else
    self.current_frames={self.frames.rising}
  end
end

function player:move()
  self.dy+=self.gravity
  self.dy=mid(-6, self.dy, 6)
  self.x+=self.dx
  self.y+=self.dy
  self.dx*=self.damping
  self.dy*=self.damping
  if state.boosting then
    self.dy=self.min_dy
  end
  self.y=max(self.y,cam.y+12)
end

function player:process_buttons()
  if btn(b.left) then
    self.dx-=0.5
    self.facing_left=true
  elseif btn(b.right) then
    self.dx+=0.5
    self.facing_left=false
  end
  self.dx*=.8
  self.dx=mid(self.dx, -2, 2)
end

function player:boop(velocity)
  self.dy = max(self.dy+velocity, self.min_dy)
end
function player:draw()
  if state.boosting then
    pal(3,14)
    entity.draw(self)
    pal()
  else
    entity.draw(self)
  end
end

booper=entity:new({
  w=16,
  h=16,
  spr_h=2,
  spr_w=2,
  booping=-4,
  subject=nil,
  frame_index=1,
  frames={
    math={24},
    reading={19},
    english={22},
    science={17}
  }
})
function booper:init(subject)
  self.current_frames=self.frames[subject]
  self.subject=subject
end
function booper:update()
  if state.boosting then
    if self.x > state.player.x then
      self.dx = -1
    else
      self.dx = 1
    end
    if self.y > state.player.y then
      self.dy = -1
    else
      self.dy = 1
    end
  end
  entity.update(self)
end

booster=entity:new({
  w=8,
  h=8,
  spr_h=1,
  spr_w=1,
  current_frames={1}
})

cloud=entity:new({

})
function cloud:draw()
  circfill(self.x-5,self.y,4,6)
  circfill(self.x-5-1,self.y-1,4,7)
  circfill(self.x+5,self.y,4,6)
  circfill(self.x+5-1,self.y-1,4,7)
  circfill(self.x,self.y+3,4,6)
  circfill(self.x-1,self.y+-1,4,7)
  circfill(self.x,self.y-3,4,6)
  circfill(self.x-1,self.y-3-1,4,7)
end
function cloud:update()
  if cam.y > cam.watermark then
    self.y-=(cam.speed/2)
  end
  if self.y > cam.y + 140 then
    self.y = cam.watermark - rnd(128) - 20
    self.x = rnd(128)
  end
end

--results!
results={}
colleges={}
colleges[15]="rust college"
colleges[16]="clark atlanta university"
colleges[17]="alabama state university"
colleges[20]="university of texas el paso"
colleges[24]="michigan state university"
colleges[26]="miami university"
colleges[34]="uc berkeley"
colleges[35]="dartmouth"
colleges[36]="harvard"
function results:init()
  self.acceptances={}
  self.total_score=0
  for test,score in pairs(game.scores) do
    self.total_score+=score
  end
  self.total_score=self.total_score/#game.test.subjects
  -- self.total_score=36
  for i=0,flr(self.total_score) do
    if (colleges[i]) add(self.acceptances, colleges[i])
  end

  self.message={"your act score: " .. self.total_score}
  if #self.acceptances > 0 then
    add(self.message, "you got into:")
    add(self.message, "")
    foreach(self.acceptances, function(college)
      add(self.message, college)
    end)
    add(self.message,"")
    add(self.message,"")
    add(self.message,"nice work!")
    add(self.message,"press x to continue")
  else
    add(self.message, "")
    add(self.message, "it's okay--")
    add(self.message, "lots of schools don't")
    add(self.message, "require test results anymore!")
    add(self.message,"")
    add(self.message,"")
    add(self.message,"try again?")
    add(self.message,"press x to continue")
  end

  self.ticker=60
  self.message_index=0
end

function results:draw()
  cls()
  rectfill(0,0,128,128,3)
  color(7)
  for i=1,self.message_index do
    print(self.message[i], hcenter(self.message[i]), 1+6*i)
  end
end

function results:update()
  self.ticker -=1
  if self.ticker < 1 and self.message_index < #self.message then
    self.message_index +=1
    self.ticker = 40
  end
  if self.message_index == #self.message and btnp(b.x) then
    transition_to(game_states.title)
  end
end

function hcenter(s)
  -- screen center minus the
  -- string length times the
  -- pixels in a char's width,
  -- cut in half
  return 64-#s*2
end

__gfx__
00000000003333000000000000dddd0000dddd0000dddd0000dddd0000dddd000000000000000000000000000000000000333300000000000033330000cccc00
0000000003333330000000000d7117100d1761100d1111100d1111100d111110000000000000000000000000000000000333333000000000033333300c0000c0
007007003333333300000000d1711711d1711611d1711711d1111111d1111111000000000000000000000000000000000332f20000000000033fff00c000000c
000770003333337300000000d7111171d1666611d1117111d1111111d11111110000000000000000000000000000000033ffff000000000033f2f200cf00f23c
0007700037333733000000001788887d1161161d1117111d1111111d1111111d0000000000000000000000000000000033ffff000000000033ffff00c044ff3c
0070070033737333000000001788887d1161161d1171171d1111111d1111111d00000000000000000000000000000000334440000000000033444000cf44f23c
00000000033733300000000007777770011111d0011111d0011111d0011111d0000000000000000000000000000000000344400000000000034440000cf333c0
0000000000333300000000000011dd000011dd000011dd000011dd000011dd000000000000000000000000000000000000f0f0000000000000f0f00000cccc00
0000000000000aaaaaa0000000000dddddd0000000dddd0000000ffffff0000000000eeeeee0000000000dddddd0000000cccc0000bbbb0000aaaa0000888800
00000000000aa99999999000000dd111111110000d111110000ff44444444000000ee22222222000000dd111111110000c0000c00b0000b00a0000a008000080
0000000000a999444499990000d1111111111100d111777100f444444444440000e222222222220000d1111111111100c07e000cb033000ba099000a80220008
000000000a999774477999900d11111111111110d11171110f444444444e44400e222222222222200d11111111111110c0c0000cb030000ba090000a80200008
000000000a999974479999900d477774477774101771711d0f444444446ee4400e227777777762200d11111111111110c000000cb000000ba000000a80000008
00000000a999997dd7999999d1477777777774111117111df44444444aa6ee44e227777777762222d111111111111111c000000cb000000ba000000a80000008
00000000a99997dddd799999d147555775557411011111d0f4444444aaaa6444e227277227722222d1111111111111110c0000c00b0000b00a0000a008000080
00000000999997dddd79999911477777777774110011dd004444444aaaaa44442222277227722222111111111111111100cccc0000bbbb0000aaaa0000888800
000000009999788888879999114755577555741100dddd00444444aaaaa444442222277227722222111111111111111100000000000000000000000000000000
000000009999788e8887999911477777777774110d77771044444aaaaa4444442222277227722222111111111111111100000000000000000000000000000000
00000000999788888e8879991147555775557411d11117114444ffaaa44444442222277227727222111111111111111100000000000000000000000000000000
0000000009978e88888879900147777777777410d11177110444fffa444444400222776227776220011111111111111000000000000000000000000000000000
00000000099977777777999001111444444111101111171d04445ff4444444400222762227662220011111111111111000000000000000000000000000000000
00000000009999999999990000111111111111001177771d00444444444444000022222222222200001111111111110000000000000000000000000000000000
0000000000099999999990000001111111111000011111d000044444444440000002222222222000000111111111100000000000000000000000000000000000
00000000000009999990000000000111111000000011dd0000000444444000000000022222200000000001111110000000000000000000000000000000000000
__sfx__
0001000018050190501c0501d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00000000010050150501a05020050250501e0501f0502205026050290502d0502f0502405026050270502a0502c0502f05033050370502c0502e05030050320503405036050380503a0503a0500000000000
