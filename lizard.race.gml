#define init
	global.gce = 0;

	global.sprite = {
		portrait: sprite_add("Sprites/sprLizardPortrait.png",1,0,220),
		menu_button: sprite_add("Sprites/sprLizardMenuButton.png",1,0,0),
		idle: sprite_add("Sprites/sprLizardIdle.png",6,24,24),
		walk: sprite_add("Sprites/sprLizardWalk.png",6,24,24),
		hurt: sprite_add("Sprites/sprLizardHurt.png",3,24,24),
		dead: sprite_add("Sprites/sprLizardDead.png",8,24,24),
		grab: sprite_add("Sprites/sprLizardGrabSide.png",6,24,24),
		grab_up: sprite_add("Sprites/sprLizardGrabUp.png",6,24,24),
		grab_down: sprite_add("Sprites/sprLizardGrabDown.png",6,24,24),
		grab_up_angle: sprite_add("Sprites/sprLizardGrabUpAngle.png",6,24,24),
		grab_down_angle: sprite_add("Sprites/sprLizardGrabDownAngle.png",6,24,24),
		hand: sprite_add("Sprites/sprHandSide.png",0,4,4),
		hand_up: sprite_add("Sprites/sprHandUp.png",0,12,5),
	}
	global.info = {
		race_name : "LIZARD",
		race_text : "CAN GRAPPLE" + "#LESS @rCONTACT DAMAGE",
		race_ttip : "",
		race_tb_text : "",
		race_ultra_name : ["Ultra 0 is not used","",""],
		race_ultra_text : ["Ultra 0 is not used","",""]
	}
	with(instances_matching(Player,"race",mod_current)) create();

#macro SPRITE global.sprite
#macro INFO global.info
#macro DEBUG false
#macro STATE_NEUTRAL 0
#macro STATE_GRAB_SIDE 1
#macro STATE_GRAB_UP 2
#macro STATE_GRAB_DOWN 3
#macro STATE_GRAB_UP_ANGLE 4
#macro STATE_GRAB_DOWN_ANGLE 5
#macro STATE_CARRY 6
#macro STATE_CARRY_HEAVY 7

#define race_portrait
	return SPRITE.portrait;
#define race_name 
	return INFO.race_name;
#define race_menu_button
	sprite_index = SPRITE.menu_button;
#define race_text 
	return INFO.race_text;
#define race_ttip 
	return INFO.race_ttip;
#define race_tb_text 
	return INFO.race_tb_text;

#define race_tb_take
	isThroneeButt = true;
	
#define game_start 
	with(instances_matching(CustomDraw,"belongsTo",mod_current)) instance_destroy();
	with(script_bind_draw(ultraicon,-10002)){
		persistent = true;
		belongsTo = mod_current;
	}
	
#define trace_debug
	if(DEBUG){
		var str = "";
		for(var i = 0;i<argument_count;i++){
			str += string(argument[i]) + " ";
		}
		trace(str);
	}
#define create 
	spr_idle = SPRITE.idle;
	spr_walk = SPRITE.walk;
	spr_hurt = SPRITE.hurt;
	spr_dead = SPRITE.dead;
	spr_grab = SPRITE.grab;
	spr_grab_up = SPRITE.grab_up;
	spr_grab_down = SPRITE.grab_down;
	spr_grab_up_angle = SPRITE.grab_up_angle;
	spr_grab_down_angle = SPRITE.grab_down_angle;
	spr_hand = SPRITE.hand;
	spr_hand_up = SPRITE.hand_up;

	
	spr_hand_down = SPRITE.hand_up; // Temporary
	
	maxhealth = 10;
	
	isThroneButt = false;
	
	snd_hurt = sndSalamanderHurt;
	snd_dead = sndSalamanderDead;
	snd_lowh = sndSalamanderHurt;
	snd_lowa = sndSalamanderHurt;
	snd_wrld = sndSalamanderDead;
	snd_cptn = sndSalamanderHurt;
	snd_thrn = sndSalamanderHurt;
	snd_valt = sndSalamanderHurt;
	snd_crwn = sndSalamanderHurt;
	snd_wrld = sndSalamanderHurt;
	snd_chst = sndSalamanderHurt;
	snd_spch = sndSalamanderHurt;
	snd_idpd = sndSalamanderHurt;
	
	snd_throw = sndSnowBotThrow; // Temporary
	
	grab_offset = [0, 0, 0, 16, 8, 4]; // Happens along the X axis only
	grab_up_offset = [0, 0, 0, -12, -5, -2]; // Happens along the Y axis only
	grab_down_offset = [0, 0, 0, 18, 16, 10]; // Happens along the Y axis only
	grab_state = STATE_NEUTRAL;
	grab_object = -4;
	grab_object_index = -4;
	grab_object_sprite = mskNone;
	grab_index = 0;
	lastGrab = current_frame;
	
#define range
	return argument0 >= min(argument1, argument2) && argument0 <= max(argument1, argument2);
#define step
	var mx = mouse_x[index], my = mouse_y[index];
	if (canspec){
		if button_pressed(index,"spec"){
			if grab_state = STATE_NEUTRAL{
				grab_index = 0;
				image_index = 0;
				if range(gunangle, 90 + 30, 90 - 30){
					grab_state = STATE_GRAB_UP;
				}else if range(gunangle, 270 + 30, 270 - 30){
					grab_state = STATE_GRAB_DOWN;
				}else if range(gunangle, 120, 120 + 30) || range(gunangle, 60, 60 - 30){
					grab_state = STATE_GRAB_UP_ANGLE;
				}else if range(gunangle, 300, 300 + 30) || range(gunangle, 240, 240 - 30){
					grab_state = STATE_GRAB_DOWN_ANGLE;
				}else grab_state = STATE_GRAB_SIDE;
				lastGrab = current_frame;
				canaim = false;
			}else if grab_state = STATE_CARRY || grab_state = STATE_CARRY_HEAVY{
				with(grab_object){
					x = other.x;
					y = other.y;
					sprite_index = other.grab_object_sprite;
					image_index = 1;
					image_speed = 0;
					direction = point_direction(other.x,other.y,mx,my);
					mask_index = mskWepPickup;
					ind = other.grab_object_index;
					if(fork()){
						var t = other.team, spd = 18;
						while instance_exists(self){
							spd -= 0.5;
							if spd < 10 spd -= 0.5;
							speed = spd;
							image_angle += speed * 15;
							with(instances_matching_ne(hitme,"team",t)){
								if place_meeting(x,y,other) && nexthurt < current_frame{
									projectile_hit(self,5 + GameCont.level);
									nexthurt = current_frame + 5;
									spd --;
								}
							}
							if place_meeting(x + lengthdir_x(speed, direction), y + lengthdir_y(speed,direction), Wall){
								instance_change(ind,false);
								projectile_hit(self,8);
								exit;
							}
							if spd < 5{
								instance_change(ind,false);
								image_speed = 0.4;
								image_angle = 0;
								exit;
							}
							wait 1;
						}
						exit;
					}
				}
				grab_object = -4;
				grab_object_index = -4;
				grab_object_sprite = mskNone;
				grab_state = STATE_NEUTRAL;
				image_alpha = 1;
				motion_add(point_direction(other.x,other.y,mx,my), 4)
				sound_play(snd_throw);
			}
		}
	}
	if sprite_index = spr_hurt && grab_state = STATE_NEUTRAL{
		// Drops grabbed objects
		grab_object = -4;
		grab_object_index = -4;
		grab_object_sprite = mskNone;
		grab_object_size = 0;
	}
	if grab_state != STATE_NEUTRAL{
		if(!isThroneButt)
			canfire = false;//insuring the player cant shoot if they dont have thronebutt
		if (grab_state != STATE_CARRY && grab_state != STATE_CARRY_HEAVY){
			speed = median(-maxspeed * 0.5, speed, maxspeed * 0.5);
		}else{
			if grab_state = STATE_CARRY_HEAVY{
				speed = median(-maxspeed * 0.6, speed, maxspeed * 0.6);
			}
		}
		grab_index = min(grab_index + (image_speed * current_time_scale), 6);
		switch(grab_state){
			case STATE_GRAB_SIDE: sprite_index = spr_grab; break;
			case STATE_GRAB_UP: sprite_index = spr_grab_up; break;
			case STATE_GRAB_DOWN: sprite_index = spr_grab_down; break;
			case STATE_GRAB_UP_ANGLE: sprite_index = spr_grab_up_angle; break;
			case STATE_GRAB_DOWN_ANGLE: sprite_index = spr_grab_down_angle; break;
		}
		if range(floor(grab_index),2,3) && grab_object = -4{
			if grab_state = STATE_GRAB_SIDE{
				with(collision_circle(x + grab_offset[floor(grab_index)] * right, y, 8, enemy, 0, 1)){
					other.grab_object = self;
					other.grab_object_index = object_index;
					other.grab_object_sprite = spr_hurt;
					other.grab_object_size = size;
					instance_change(GameObject,false);
				}
			}else{
				var ar = grab_up_offset;
				if grab_state = STATE_GRAB_DOWN{
					ar = grab_down_offset;
				}
				with(collision_circle(x,y + ar[floor(grab_index)],8,enemy, 0, 1)){
					other.grab_object = self;
					other.grab_object_index = object_index;
					other.grab_object_sprite = spr_hurt;
					other.grab_object_size = size;
					instance_change(GameObject,false);
				}
			}
		}
		if grab_index >= 6 && (grab_state != STATE_CARRY && grab_state != STATE_CARRY_HEAVY){
			// Temporarily defaulting to neutral
			if grab_object = -4{
				grab_state = STATE_NEUTRAL;
				sprite_index = spr_idle;
				image_alpha = 1;
				image_index = 0;
				canaim = true;
			}else{
				if grab_object_size < 2{
					grab_state = STATE_CARRY;
				}else grab_state = STATE_CARRY_HEAVY;
				sprite_index = spr_idle;
				image_index = 0;
				canaim = true;
				image_index = 0;
			}
		}
	}else{
		image_alpha = 1;
		canfire = true;
	} 
	
#define draw
	if grab_state != STATE_NEUTRAL{
		image_alpha = 0;
		if grab_state = STATE_CARRY || grab_state = STATE_CARRY_HEAVY{
			draw_sprite_ext(grab_object_sprite, 1, x, y - 12, right, 1, 0, c_white, 1); 
			draw_sprite(SPRITE.hand_up, 0, x, y - 8); 
			draw_sprite_ext(sprite_index,image_index,x,y,right * image_xscale, image_yscale, angle, image_blend, visible);
		}else{
			var xoffset = 0, yoffset = 0;
			if grab_state = STATE_GRAB_UP{
				yoffset = grab_up_offset[floor(grab_index)];
			}
			if grab_state = STATE_GRAB_DOWN{
				yoffset = grab_down_offset[floor(grab_index)];
			}
			if grab_state = STATE_GRAB_SIDE{
				xoffset = grab_offset[floor(grab_index)];
			}
			if grab_index > 4{
				if grab_state = STATE_GRAB_UP{
					draw_sprite(SPRITE.hand_up, 0, x, y + yoffset);
				}
				// Drawn below player and grapple objects
				if grab_state = STATE_GRAB_SIDE{
					draw_sprite_ext(SPRITE.hand, 0, x + ((xoffset - 2) * right), y, right, 1, 0, image_blend, visible);
				}
			}
			if grab_object_sprite != mskNone && grab_state = STATE_GRAB_UP{
				draw_sprite_ext(grab_object_sprite, 1, x + (((xoffset + ((grab_state < 3) * 4)) * right) * (grab_state == STATE_GRAB_SIDE)), y + yoffset - 6 - ((grab_state > 3) * 12), right, 1, 0, c_white, 1); 
			}
			
			draw_sprite_ext(sprite_index,grab_index,x,y,right * image_xscale, image_yscale, angle, image_blend, visible);
			
			if grab_object_sprite != mskNone && grab_state != STATE_GRAB_UP{
				draw_sprite_ext(grab_object_sprite, 1, x + (((xoffset + ((grab_state < 3) * 4)) * right) * (grab_state == STATE_GRAB_SIDE)), y + yoffset - ((grab_state > 3) * 12), right, 1, 0, c_white, 1); 
			}
			if grab_index > 4{
				if grab_state = STATE_GRAB_DOWN{
					draw_sprite(SPRITE.hand_up, 0, x, y + yoffset);
				}
				// Drawn above player and grapple objects
				if grab_state = STATE_GRAB_SIDE{
					draw_sprite_ext(SPRITE.hand, 0, x + (xoffset * right), y + 2, right, 1, 0, image_blend, visible);
				}
			}
		}
	}