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
function _init()
  game_states={title=title, game=game}

  state=game_states.game
  state:init()
end

function _update()
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

game={}
function game:init()
  self.player=player:new({x=50,y=50})
  self.actors={self.player, box}
end
function game:update()
  foreach(self.actors, function(actor)
    actor:update()
  end)
end
function game:draw()
  foreach(self.actors,function(actor)
    actor:draw()
  end)
  print(self.player:collide(box))
end

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
  gravity=.2,
})
box=entity:new({
  x=60, y=40, w=20, h=20, spr_h=20, spr_w=20
})

function player:update()
  self:process_buttons()
  self:move()
end

function player:move()
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

booper=entity:new({

})

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033333700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033337300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000037373300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700003733000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
