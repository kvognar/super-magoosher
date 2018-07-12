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
cam={x=0, y=0, watermark=128}
score=0

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
  self.player=player:new({x=50,y=128})
  player.dy=-6
  self.actors={self.player}
  self.boopers={}
  for i=0,8 do
    local x = rnd(100)+10
    local y = rnd(64)
    self:make_booper(x, y)
  end
end
function game:update()
  foreach(self.actors, function(actor)
    actor:update()
  end)
  foreach(self.boopers, function(booper)
    if self.player:collide(booper) then
      self.player:boop(booper.booping)
      del(self.boopers, booper)
      score+=1
    end
  end)
  self:booper_sweep()
end
function game:draw()
  rectfill(0+cam.x,0+cam.y,255+cam.x,255+cam.y,6)
  print(#self.boopers, 0+cam.x, 0+cam.y, 0)
  print(self.player.dy, 0+cam.x, 8+cam.y, 0)
  print(score, 0+cam.x, 16+cam.y, 3)
  foreach(self.actors,function(actor)
    actor:draw()
  end)
  foreach(self.boopers, function(booper)
    booper:draw()
  end)
  if self.player.y - cam.watermark < 80 then
    cam.y=self.player.y-80
    cam.watermark=cam.y
    camera(0, cam.y)
  end
end
function game:make_booper(x, y)
  local booper = booper:new({
    x=x,
    y=y
  })
  add(self.boopers, booper)
end
function game:booper_sweep()
  foreach(self.boopers, function(booper)
    if booper.y > self.player.y+128 then
      del(self.boopers, booper)
    end
  end)
  while #self.boopers < 10 do
    self:make_booper(rnd(110)+10, cam.y-60)
  end
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
  w=8, h=8, spr_w=8, spr_h=8,
  gravity=.1,
})

function player:update()
  self:process_buttons()
  self:move()
end

function player:move()
  self.dy+=self.gravity
  self.dy=mid(-6, self.dy, 6)
  self.x+=self.dx
  self.y+=self.dy
  self.dx*=self.damping
  self.dy*=self.damping
end

function player:process_buttons()
  if btn(b.left) then
    self.dx-=1
  elseif btn(b.right) then
    self.dx+=1
  end
  self.dx*=.8
  self.dx=mid(self.dx, -2, 2)
end

function player:boop(velocity)
  self.dy += velocity
end

booper=entity:new({
  w=8,
  h=8,
  spr_h=1,
  spr_w=1,
  booping=-10,
  current_frames={1},
  frame_index=1,
  frames={1}
})


__gfx__
00000000003333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000333333730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000373337330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700337373330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033733300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
