pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

objects = {}
clouds = {}
cannon_r = 0
cannon_x = 64
enemy_count=1

points={}
prevpoints={}
decel=1.125
damp=0.125
dampm=-0.095
gravity=-.975
waterlvl=16

for i=0,12 do 
    add(clouds,{x=rnd(132),y=rnd(100),s=16+rnd(32)})
end

for i=-15,143,1 do
    add(points,waterlvl)
    add(prevpoints,waterlvl)
end

function _init()
    --ammo=10
    frames=0
	seconds=0
	minutes=0
    seconds_left=60
    minutes_left=0
	music_timer=3200
    difficulty=1
    init_object(cannon,0,0)
    init_object(base_enemy,0,0)
    loop=true
    music(1)
end

cannon =
{
    init=function(this)
        this.spr=1
        this.x=56
        this.y=104
        this.r=0 -- rotation
        -- momentum
        this.mx=0
        this.rx=0
    end,
    update=function(this)
        local x_input = btn(1) and .5 or (btn(0) and -.5 or 0)
        -- movement
        this.mx=mid(-3,this.mx+x_input/2,3)
        this.x=mid(0,this.x+this.mx,114)
        this.mx=appr(this.mx,0,.04)

        -- rotation
        this.rx=mid(-0.03,this.rx+(x_input*.005),0.03)
        this.r+=this.rx
        this.rx=appr(this.rx,0,.001)

        this.r=mid(-.25,this.r,.25)
        if (abs(this.r)==.25) this.rx=0

        if btnp(4) and seconds_left >= 1 then
            sfx(7)
            init_object(cannonball,this.x + 4, 108)
            seconds_left-=1
        end

        if (this.collide(base_enemy,0,0)~=nil or this.collide(king_enemy,0,0)~=nil or this.collide(ninja_enemy,0,0)~=nil) end_game()
        
        cannon_r=this.r-0.25
        
        -- wavy stuff
        points[flr(this.x + (btn(0) and 15 or btn(1) and 2 or 8))]-=.5
        local h=pt(flr(this.x+4))+pt(flr(this.x+8))+pt(flr(this.x+12))
        this.y = 102+h/4

    end,
    draw=function(this)
        rspr(8,16,88,8,this.r,2)
        sspr(88,8,16,16,this.x-1,this.y,16,16)
    end
}

base_enemy =
{
    init=function(this)
        this.health=3
        this.x=flr(rnd(120))
        this.y=8
        this.spr=3
        this.active=true
        this.dmg_frames=0
    end,
    update=function(this)
        this.y+=0.75
        if (this.y>112 and this.active) this.active = false seconds_left -= 10 enemy_count-=1 spawn_enemy() for i=flr(this.x+1),flr(this.x+6) do points[i]-=3 end
        if (this.y>128) destroy_object(this)
    end,
    draw=function(this)
        palt(15,true)
        palt(0,false)
        if this.dmg_frames > 0 then
            this.dmg_frames-=1
            for c=1,16 do
                pal(c,8)
            end
        end
        spr(this.spr,this.x,this.y)
        pal()
        palt(15,false)
        palt(0,true)
    end
}
add(types,base_enemy)

king_enemy =
{
    init=function(this)
        this.health=5
        this.x=flr(rnd(120))
        this.y=8
        this.spr=4
        this.active=true
        this.dmg_frames=0
    end,
    update=function(this)
        this.y+=0.1
        if (this.y>112 and this.active) this.active = false seconds_left -= 10 spawn_enemy() for i=flr(this.x),flr(this.x+8) do points[i]-=5 end
        if (this.y>128) destroy_object(this)
    end,
    draw=function(this)
        palt(15,true)
        palt(0,false)
        if this.dmg_frames > 0 then
            this.dmg_frames-=1
            for c=1,16 do
                pal(c,8)
            end
        end
        rect(this.x-1,this.y-1,this.x+8,this.y+8,0)
        spr(this.spr,this.x,this.y)
        pal()
        palt(15,false)
        palt(0,true)
    end
}
add(types,king_enemy)

ninja_enemy =
{
    init=function(this)
        this.health=1
        this.x=flr(rnd(120))
        this.y=8
        this.spr=5
        this.active=true
        this.dmg_frames=0
    end,
    update=function(this)
        this.y+=1.5
        if (this.y>112 and this.active) this.active = false seconds_left -= 10 enemy_count-=1 spawn_enemy() for i=flr(this.x),flr(this.x+7) do points[i]-=7 end
        if (this.y>128) destroy_object(this)
    end,
    draw=function(this)
        palt(15,true)
        palt(0,false)
        if this.dmg_frames > 0 then
            this.dmg_frames-=1
            for c=1,16 do
                pal(c,8)
            end
        end
        rect(this.x-1,this.y-1,this.x+7,this.y+7,0)
        spr(this.spr,this.x,this.y)
        pal()
        palt(15,false)
        palt(0,true)
    end
}
add(types,ninja_enemy)

cannonball =
{
    init=function(this)
        this.spr = 2
        this.dir = {x=3*cos(cannon_r),y=-3*sin(cannon_r)}
        this.x += this.dir.x * 2
        this.y += this.dir.y * 2
    end,
    update=function(this)
        this.x += this.dir.x
        this.y += this.dir.y
        if (this.x < 0 or this.x > 128 or this.y < 0) destroy_object(this)

        local hit = this.collide(base_enemy,0,0) or this.collide(king_enemy,0,0) or this.collide(ninja_enemy,0,0)
        if hit ~= nil then
            sfx(8)
            hit.health -= 1
            hit.dmg_frames = 5
            if hit.health <= 0 then
                if (this.collide(base_enemy,0,0)~=nil) seconds_left+=10
                if (this.collide(king_enemy,0,0)~=nil) seconds_left+=20
                if (this.collide(ninja_enemy,0,0)~=nil) seconds_left+=15
                destroy_object(hit)
                enemy_count-=1
                spawn_enemy()
            end
            destroy_object(this)
        end
    end,
    draw=function(this)
        palt(15,true)
        palt(0,false)
        spr(this.spr,this.x,this.y)
        palt(15,false)
        palt(0,true)
    end
}
add(types,cannonball)

function init_object(type,x,y)
    local obj = {}
	obj.type = type
    obj.spr = type.tile
    obj.flip = {x=false,y=false}

	obj.x = x
	obj.y = y
	obj.hitbox = { x=0,y=0,w=8,h=8 }

	obj.spd = {x=0,y=0}

    obj.collide=function(type,ox,oy)
		local other
		for i=1,count(objects) do
			other=objects[i]
			if other ~=nil and other.type == type and other != obj and
				other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and 
				other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
				other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and 
				other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy then
				return other
			end
		end
		return nil
	end

    obj.check=function(type,ox,oy)
		return obj.collide(type,ox,oy) ~=nil
	end

    add(objects,obj)
	if obj.type.init~=nil then
		obj.type.init(obj)
	end
	return obj
end

function end_game()
    loop=false

end

function destroy_object(obj)
	del(objects,obj)
end

function _update()
    if music_timer>0 then
	    music_timer-=1
	    if music_timer<=0 then
	        music(1)
            music_timer=3200
	    end
	end
    if loop then

        frames=((frames+1)%30)
	    if frames==0 then
	    	seconds=((seconds+1)%60)
            seconds_left-=1
            if seconds_left < 0 then
                if minutes_left > 0 then
                    minutes_left -= 1
                    seconds_left += 60
                else
                    end_game()
                end
            end
            if (seconds_left>=60) minutes_left+=1 seconds_left-=60
            if (seconds%20==0) difficulty +=1
            if (seconds%5==0 and enemy_count<=1) spawn_enemy()
	    	if seconds==0 then
	    		minutes+=1
	    	end
	    end

        -- update each object
	    foreach(objects,function(obj)
	    	if obj.type.update~=nil then
	    		obj.type.update(obj) 
	    	end
	    end)
    end
    -- waves
    points[cannon_x]-=1
    dt = time()-t
    t = time()
end

-- delta time tracking
dt=0
t=0

function _draw()
    -- reset all palette values
	pal()
    cls(12)

    -- draw clouds
    draw_clouds(1,0,0,1,1,7,#clouds)

    -- draw objects
	foreach(objects, function(o)
		draw_object(o)
	end)

    if loop then
        draw_time_left(4,4)
    else
        -- game over screen
        rect(44,54,88,74,7)
        rectfill(45,55,87,73,0)
        draw_time(50,61)
        for o in all(objects) do
            o.y += 2
            if o.y > 128 then
                destroy_object(o)
            end
        end
    end

    drawupdatewater()
    waterreflections()
    for f in all(fres) do
        circfill(f-1,points[f]+112,0,7)
    end
    fres={}
   
end

function spawn_enemy()
    if enemy_count < 5 then
        for i=1,difficulty do
            local e = flr(rnd(4))
            if (e == 0) init_object(base_enemy,0,0) enemy_count+=1
            if (e == 1) then
                if difficulty>1 then init_object(king_enemy,0,0) enemy_count+=1 else init_object(base_enemy,0,0) init_object(base_enemy,0,0) enemy_count+=2 end
            end
            if (e == 2) then
                if difficulty>2 then init_object(ninja_enemy,0,0) else init_object(base_enemy,0,0) end
                enemy_count+=1
            end
        end
    end
end

function pt(i)
    local j=i
    if (j > #points-1) then
        return points[#points-1]
    end
    if (j < 1) then
        return points[1]
    end
    return points[j]
end

function drawupdatewater()
    for i=1,#points do
        local vel = (points[i]-prevpoints[i])*decel
        prevpoints[i] = points[i]
        if (points[i] > waterlvl) then
            vel += gravity
        else
            vel-= gravity
        end
        points[i]+=vel
       
        local diff = dampm * (pt(i+1) + pt(i-1)+pt(i+2) + pt(i-2)+pt(i+3) + pt(i-3)+pt(i+4) + pt(i-4)) * (-8*points[i])

        points[i] -= diff*damp*dt
       
        points[i]=mid(points[i],0,128)
       
        line(i-1,127,i-1,points[i]+112,1)
        if (vel > 1.25 or vel < -1.25) then
            add(fres,i)
        end
    end
end

function waterreflections()
    for x=0,127 do
        for y=0,16 do
            if pget(x,120-y)!=12 and pget(x,120-y)!=1 then
                if pget(x,120+y/2)==1 then
                    pset(x,120+y/2,13)
                end
            end
        end
    end
       
    for x=0,127 do
        for y=120,128 do
            pset(x+(sin(time()+(y/5))),y,pget(x,y))
        end
    end
end

function draw_object(obj)
	if obj.type.draw ~=nil then
		obj.type.draw(obj)
	elseif obj.spr > 0 then
		spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
	end
end

function draw_time(x,y)

	local s=seconds
	local m=minutes%60
	local h=flr(minutes/60)
	
	rectfill(x,y,x+32,y+6,0)
	print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,7)

end

function draw_time_left(x,y)

	local s=seconds_left
	local m=minutes_left%60
	local h=flr(minutes_left/60)
	
	rectfill(x,y,x+32,y+6,seconds_left<8 and minutes_left==0 and 8 or 0)
	print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,7)

end

function appr(val,target,amount)
 return val > target 
 	and max(val - amount, target) 
 	or min(val + amount, target)
end

function rspr(sx,sy,x,y,a,w)
    local ca,sa=cos(a),sin(a)
    local srcx,srcy,addr,pixel_pair
    local ddx0,ddy0=ca,sa
    local mask=shl(0xfff8,(w-1))
    w*=4
    ca*=w-0.5
    sa*=w-0.5
    local dx0,dy0=sa-ca+w,-ca-sa+w
    w=2*w-1
    for ix=0,w do
        srcx,srcy=dx0,dy0
        for iy=0,w do
            if band(bor(srcx,srcy),mask)==0 then
                local c=sget(sx+srcx,sy+srcy)
                sset(x+ix,y+iy,c)
            else
                sset(x+ix,y+iy,rspr_clear_col)
            end
            srcx-=ddy0
            srcy+=ddx0
        end
        dx0+=ddx0
        dy0+=ddy0
    end
end

function draw_clouds(scale,ox,oy,sx,sy,color,count)
  for i=1,count do
    local c=clouds[i]
    local s=c.s*scale
    local x,y=ox+((c.x)%(128+s)-s/2)*sx,oy+((c.y)%(128+s/2))*sy
    clip(x-s/2,y-s/2,s,s/2)
    circfill(x,y,s/3,color)
    if i%2==0 then
      circfill(x-s/3,y,s/5,color)
      circfill(x+s/3,y,s/6,color)
    end
    c.x+=(4-i%4)*0.25
  end
  clip(0,0,128,128)
end

__gfx__
0000000000000000f000000f00000000a00aa00affffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000005555000bbbbbb0aaaaaaaa2222222f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000000000055566500b5bb5b044dddd442ddddd2f00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000555565008bbbb8044444444244d442f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000000055555500b8888b0bd5dd5db255d552f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000000000055555500b7bb7b0b8dddd8b27ddd72f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000005555000b7bb7b0b888888b26d8d62f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000f000000f00000000bb7bb7bb2222222f00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006555555555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006665555556660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044555444455544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000045151544515154000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000045555544555554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005151500515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000555000055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01100000000001803000000000000000000230000000000000000002300000000000000000c3300c330000000c330000000c330000000000000330000000000000000003300000000000000000c3300c3300c330
63100000000000000018730000001c03011030000000000010030000001703000000170300000018030000000000000000180301c0300000011030117301173010030000000e030000000e030000001003000000
0110000000230000000000000000002300000000000000000c3300c330000000c330000000c330000000000000330000000000000000003300000000000000000c33000000103300000011330000000c33000000
0110000000230000000000000000002300000000000000000c3300c330000000c330000000c33000000000000033000000000000000000330000000e330000000e33000000000000e3300e330000000c3300c330
011000000c33500005000050c3350c335000050c3350c3350c335000050c335000050c3350000500005000050c33500005000050c3350c335000050c3350c3350c335000050c335000050c335000050000500005
011000000c33500005000050c3350c335000050c3350c3350c335000050c335000050c3350000500005000050b3350b335000050b3350b335000050c3350c3350c335000050b3350b33509335093350933500005
011000000c33500005000050c3350c335000050c3350c3350c335000050c335000050c3350000500005000050b3350b335000050b3350b335000050c3350c3350c3350c3350c3350c3350c335000050000500005
6303000000701007010070106761067610476104761047610476105701077610a7611076116761187611f76100701007010070100701007010070100701007010070100701007010070100701007010070100701
3f01000000000000000000013120181201a1201d1201e1201f1201f1201f1201d1202012023120241202612000000291202a1202a1202a12026120201201f1202212029120211202c1202c1201d1201c12019120
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705027050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 02434344
00 03424344
00 01024344
00 01034344
00 02424344
00 03424344
00 02424344
00 03404344
00 01024344
00 01034344
00 01024344
00 01034344
00 04424344
00 05424344
00 04424344
00 05424344
00 01024344
00 01034344
00 01024344
00 01034344
00 01020444
00 01030544
00 01020444
00 01030544
00 04424344
00 06424344

