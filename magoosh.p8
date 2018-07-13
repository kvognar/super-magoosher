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
cam={x=0, y=0, watermark=0, speed=2}
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
  game_states={title=title, game=game}

  state=game_states.game
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

title={name="super study", offset= 50}
function title:init()
  self.offset=50
end
function title:update()

end
function title:draw()
  print(self.name, 20, self.offset+sin(t/3000))
end

-- game logic
game={}
function game:init()
  self.test=tests.act
  self.scores={}
  self.boost_countdown=300
  foreach(self.test.subjects, function(subject)
    self.scores[subject]=self.test.scores.min
  end)
  self.player=player:new({x=60,y=128})
  player.dy=-4

  self.actors={self.player}
  self.boopers={}
  for i=0,5 do
    self:make_booper(false, true)
  end
end
function game:update()
  foreach(self.actors, function(actor)
    actor:update()
  end)
  self:boop_check()
  if (t > 60) self:booper_sweep()
  self:boost_check()
  self:update_camera()
  if(btnp(b.z)) self:boost()
end
function game:draw()
  local color = 6
  if (self.boosting) color = 12
  rectfill(0+cam.x,0+cam.y,255+cam.x,255+cam.y, color)
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
  print(self.boost_countdown, 50, 50+cam.y, 0)
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
function game:score_display()
  rectfill(0+cam.x, 0+cam.y, 255+cam.x, 12+cam.y,2)
  local offset=8
  for i=1,#self.test.subjects do
    local subject=self.test.subjects[i]

    print(subject,offset+cam.x,1+cam.y,7)
    print(self.scores[subject],offset+(4*#subject/2-1)+cam.x,7+cam.y)
    offset+=4*(#self.test.subjects[i]+1)
  end
  -- print(subject_scores.math[score], 1+cam.x,1+cam.y, 7)
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
  while moving_boopers<4 do
    self:make_booper(true, true)
    moving_boopers+=1
  end
  while #self.boopers < 8 do
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
end
function game:unboost()
  self.boosting=false
  self.player.min_dy=-4
  self.boost_countdown=600
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

booper=entity:new({
  w=8,
  h=8,
  spr_h=1,
  spr_w=1,
  booping=-4,
  subject=nil,
  frame_index=1,
  frames={
    math={5,21,37},
    reading={6},
    english={4},
    science={3}
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


__gfx__
00000000003333000000000000dddd0000dddd0000dddd0000dddd0000dddd000000000000000000000000000000000000333300000000000033330000cccc00
0000000003333330000000000d7117100d1761100d1111100d1111100d111110000000000000000000000000000000000333333000000000033333300c0000c0
007007003333333300000000d1711711d1711611d1711711d1111111d1111111000000000000000000000000000000000332f20000000000033fff00c000000c
000770003333337300000000d7111171d1666611d1117111d1111111d11111110000000000000000000000000000000033ffff000000000033f2f200cf00f23c
0007700037333733000000001788887d1161161d1117111d1111111d1111111d0000000000000000000000000000000033ffff000000000033ffff00c044ff3c
0070070033737333000000001788887d1161161d1171171d1111111d1111111d00000000000000000000000000000000334440000000000033444000cf44f23c
00000000033733300000000007777770011111d0011111d0011111d0011111d0000000000000000000000000000000000344400000000000034440000cf333c0
0000000000333300000000000011dd000011dd000011dd000011dd000011dd000000000000000000000000000000000000f0f0000000000000f0f00000cccc00
000000000000000000000000000000000000000000dddd0000000000000000000000000000000000000000000000000000cccc0000bbbb0000aaaa0000888800
00000000000000000000000000000000000000000d1111100000000000000000000000000000000000000000000000000c0000c00b0000b00a0000a008000080
0000000000000000000000000000000000000000d1117771000000000000000000000000000000000000000000000000c07e000cb033000ba099000a80220008
0000000000000000000000000000000000000000d1117111000000000000000000000000000000000000000000000000c0c0000cb030000ba090000a80200008
00000000000000000000000000000000000000001771711d000000000000000000000000000000000000000000000000c000000cb000000ba000000a80000008
00000000000000000000000000000000000000001117111d000000000000000000000000000000000000000000000000c000000cb000000ba000000a80000008
0000000000000000000000000000000000000000011111d00000000000000000000000000000000000000000000000000c0000c00b0000b00a0000a008000080
00000000000000000000000000000000000000000011dd0000000000000000000000000000000000000000000000000000cccc0000bbbb0000aaaa0000888800
000000000000000000000000000000000000000000dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000d77771000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000d111171100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000d111771100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001111171d00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001177771d00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000011111d000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000011dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
