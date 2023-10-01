player_init_circle=12
player_min_circle=8
player_max_circle=16
player_circle=-1
player_angle=0
enemy_circle=48
enemies={}

enemy_gen_timer=0
enemy_gen_timeout_min=180
enemy_gen_timeout_max=240
enemy_gen_timeout_factor=300
enemy_gen_timeout_factor_speed=3/60
enemy_gen_timeout_factor_max=900
enemy_gen_pending=30

player_bullets={}
player_bullets_timer=0
player_bullets_timeout=10
player_bullet_speed=1

enemy_bullets={}
enemy_bullet_speed=0.5
enemy_bullet_timeout_min=120
enemy_bullet_timeout_max=120

player_speed=0.5/48
player_lo_speed=0.05/48
enemy_speed=0.025/48
screen_center=64

time=0
time_frame=0
fps=60

player_hit_timer=0

effects={}

result_circle_shrink_timer=0
result_circle_shrink_timeout=4

function x_from_ap(a,p)
	return screen_center+sin(a)*p
end

function y_from_ap(a,p)
	return screen_center-cos(a)*p
end

function rnd_between(l,r)
	return l+rnd(r-l)
end

function lpad(s,c,count)
	local result=s
	while #result<count do
		result=c..result
	end
	return result
end

function distance(x1,y1,x2,y2)
	local sqr_d=(x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)
	if sqr_d<0 then
		return 32767.99999
	end
	return sqrt(sqr_d)
end

function create_enemy()
	return {
		angle=rnd(1),
		direction=flr(rnd(2))*2-1,
		life=3,
		hit_timer=0,
		bullets_timer=rnd_between(enemy_bullet_timeout_min,enemy_bullet_timeout_max),
		pending_timer=enemy_gen_pending,
	}
end

function create_enemy_bullet(x,y,direction)
	return {
		x=x,
		y=y,
		direction=direction,
	}
end

function add_effect(x,y,r,count,color,speed,life)
	local random=rnd(1)
	for i=1,count do
		add(effects,{
			x=x,
			y=y,
			r=r,
			dir=(i+random)/count,
			color=color,
			speed=speed,
			life=life,
		})
	end
end

function switch_mode(init,update,draw)
	init()
	_update60=update
	_draw=draw
end

function main_init()
	player_circle=player_init_circle
	enemies={}
	enemy_gen_timer=0
	enemy_gen_timeout_factor=300
	player_bullets={}
	player_bullets_timer=0
	enemy_bullets={}
	time=0
	time_frame=0
	player_hit_timer=0
	effects={}
end

function result_init()
end

function title_init()
	for i=1,4 do
		add(enemies,create_enemy())
	end
	for enemy in all(enemies) do
		enemy.pending_timer=0
	end
end

function enemy_update(emit_bullet)
	for enemy in all(enemies) do
		if enemy.pending_timer>0 then
			enemy.pending_timer-=1
		else
			enemy.angle+=enemy.direction*enemy_speed
			enemy.hit_timer=max(enemy.hit_timer-1,0)
			if emit_bullet then
				enemy.bullets_timer-=1
				if enemy.bullets_timer<=0 then
					enemy.bullets_timer=rnd_between(enemy_bullet_timeout_min,enemy_bullet_timeout_max)
					local x=x_from_ap(enemy.angle,enemy_circle)
					local y=y_from_ap(enemy.angle,enemy_circle)
					local r=rnd(1)
					for i=1,8 do
						add(enemy_bullets,create_enemy_bullet(x,y,(i+r)/8))
					end
				end
			end
		end
	end
end

function bullet_update()
	-- player bullet
	for bullet in all(player_bullets) do
		bullet.radius+=player_bullet_speed
		if bullet.radius>128 then
			del(player_bullets,bullet)
		end
	end

	-- enemy bullet
	for bullet in all(enemy_bullets) do
		bullet.x+=sin(bullet.direction)*enemy_bullet_speed
		bullet.y-=cos(bullet.direction)*enemy_bullet_speed
		if abs(bullet.x-screen_center)>128 then
			del(enemy_bullets,bullet)
		end
		if abs(bullet.y-screen_center)>128 then
			del(enemy_bullets,bullet)
		end
	end
end

function collision_update(has_player)
	-- collision enemy bullet to player
	if has_player then
		local player_x=x_from_ap(player_angle,player_circle)
		local player_y=y_from_ap(player_angle,player_circle)
		for bullet in all(enemy_bullets) do
			if distance(bullet.x,bullet.y,player_x,player_y)<=2 then
				del(enemy_bullets,bullet)
				sfx(1)
				if player_circle<=player_min_circle then
					switch_mode(result_init,result_update,result_draw)
					add_effect(player_x,player_y,2,16,11,1,30)
				else
					player_circle=max(player_circle-1,player_min_circle)
					player_hit_timer=3
				end
			end
		end
	end

	-- collision player bullet to enemy
	for bullet in all(player_bullets) do
		for enemy in all(enemies) do
			if enemy.pending_timer<=0 then
				local b_x=x_from_ap(bullet.angle,bullet.radius)
				local b_y=y_from_ap(bullet.angle,bullet.radius)
				local e_x=x_from_ap(enemy.angle,enemy_circle)
				local e_y=y_from_ap(enemy.angle,enemy_circle)
				if distance(b_x,b_y,e_x,e_y)<=4 then
					del(player_bullets,bullet)
					enemy.life-=1
					enemy.hit_timer=3
					sfx(2)
					if enemy.life<=0 then
						player_circle=min(player_circle+1,player_max_circle)
						del(enemies,enemy)
						add_effect(e_x,e_y,2,16,15,1,30)
					end
				end
			end
		end
	end
end

function effect_update()
	for effect in all(effects) do
		effect.life-=1
		if effect.life<=0 then
			del(effects,effect)
		end
		effect.r+=effect.speed
	end
end

function main_update()
	-- player
	local speed=player_speed
	if (btn(4)) then
		speed=player_lo_speed
		if player_bullets_timer<=0 then
			player_bullets_timer=player_bullets_timeout
			sfx(0)
			add(player_bullets,{angle=player_angle,radius=player_circle})
		end
		player_bullets_timer-=1
	else
		player_bullets_timer=0
	end
	if (btn(0)) then
		player_angle+=speed
	end
	if (btn(1)) then
		player_angle-=speed
	end

	local player_x=x_from_ap(player_angle,player_circle)
	local player_y=y_from_ap(player_angle,player_circle)

	player_hit_timer=max(player_hit_timer-1,0)

	-- enemy gen
	enemy_gen_timeout_factor=min(enemy_gen_timeout_factor_max,enemy_gen_timeout_factor+enemy_gen_timeout_factor_speed)
	if enemy_gen_timer<=0 then
		if #enemies<20 then
			add(enemies,create_enemy())
		end
		enemy_gen_timer=rnd_between(enemy_gen_timeout_min,enemy_gen_timeout_max)/(enemy_gen_timeout_factor/300)
	end
	enemy_gen_timer-=1

	-- enemy update
	enemy_update(true)

	-- bullet
	bullet_update()

	-- collision
	collision_update(true)

	-- timer
	time_frame+=1
	if time_frame>=fps then
		time+=1
		time_frame=0
	end

	--effect
	effect_update()
end


function result_update()
	-- retry
	if (btnp(5)) then
		switch_mode(main_init,main_update,main_draw)
	end

	-- shrink player circle
	if result_circle_shrink_timer<=0 then
		result_circle_shrink_timer=result_circle_shrink_timeout
		player_circle=max(player_circle-1,-1)
	end
	result_circle_shrink_timer-=1

	-- enemy update
	enemy_update(false)

	-- bullet
	bullet_update()

	-- collision
	collision_update(false)

	--effect
	effect_update()
end

function title_update()
	-- play
	if (btnp(5)) then
		switch_mode(main_init,main_update,main_draw)
	end

	-- enemy update
	enemy_update(false)
end

function r_circ(a,p,r,c)
	local x=x_from_ap(a,p)
	local y=y_from_ap(a,p)
	circ(x,y,r,c)
end

function r_circfill(a,p,r,c)
	local x=x_from_ap(a,p)
	local y=y_from_ap(a,p)
	circfill(x,y,r,c)
end


function draw_bg()
	circ(screen_center,screen_center,player_circle,5)
	circ(screen_center,screen_center,enemy_circle,5)
end


function draw_non_player()
	-- enemy
	for enemy in all(enemies) do
		if enemy.pending_timer<=0 then
			local color=14
			if enemy.hit_timer>0 then
				color=15
			end
			r_circfill(enemy.angle,enemy_circle,4,color)
		end
	end
	for enemy in all(enemies) do
		if enemy.pending_timer>0 then
			local color=14
			if enemy.pending_timer%6-3>=0 then
				color=15
			end
			r_circ(enemy.angle,enemy_circle,4,color)
		end
	end

	-- player bullet
	for bullet in all(player_bullets) do
		r_circfill(bullet.angle,bullet.radius,1,6)
	end

	-- enemy bullet
	for bullet in all(enemy_bullets) do
		circfill(bullet.x,bullet.y,1,8)
	end

	-- effect
	for effect in all(effects) do
		local x=effect.x+sin(effect.dir)*effect.r
		local y=effect.y-cos(effect.dir)*effect.r
		pset(x,y,effect.color)
	end
end

function draw_time(x,y)
	print(lpad(tostr(flr(time/60))," ",2)..":"..lpad(tostr(time%60),"0",2),x,y,7)
end

function main_draw()
	cls()

	-- bg
	draw_bg()

	-- player
	local player_color=12
	if player_hit_timer>0 then
		player_color=11
	end
	local player_x=x_from_ap(player_angle,player_circle)
	local player_y=y_from_ap(player_angle,player_circle)
	circfill(player_x,player_y,2,player_color)

	-- other
	draw_non_player()

	-- timer
	draw_time(55,1)
end

function result_draw()
	cls()

	-- bg
	draw_bg()

	-- other
	draw_non_player()

	-- result
	print("game over",47,49,7)
	print("time:",43,61,7)
	draw_time(63,61)
	print("retry: ❎",45,73,7)
end

function title_draw()
	cls()

	-- bg
	draw_bg()

	-- other
	draw_non_player()

	-- text
	print("orbit",55,53,7)
	print("❎ to play",43,67,7)

end


_update60=main_update
_draw=main_draw

function _init()
	switch_mode(title_init,title_update,title_draw)
end