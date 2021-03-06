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
		race_ttip : "",//TODO: fill this out
		race_tb_text : "Grapple with your jaws",
		race_ultra_name1 : ["Ultra 0 is not used","",""],//TODO: fill this out
		race_ultra_text1 : ["Ultra 0 is not used","",""],
		race_ultra_name2 : ["Ultra 1 is not used","",""],
		race_ultra_text2 : ["Ultra 1 is not used","",""],
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

//Character select sound
var _race = [];
for(var i = 0; i < maxp; i++) _race[i] = player_get_race(i);
while(true){
	for(var i = 0; i < maxp; i++){
		var this_race = player_get_race(i);
		if(_race[i] != this_race && this_race == "lizard"){
			sound_play(sndHalloweenWolf);
		}
		_race[i] = this_race;
	}
	wait(1);
}

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
	
#define game_start 
	with(instances_matching(CustomDraw, "belongsTo", mod_current)) instance_destroy();
	with(script_bind_draw(ultraicon, -10002)){
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
	//local sprite declarations
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
	
	//default player sounds mostly temp TODO: change these to something better
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
	
	//custom ability sounds mostly temp
	snd_throw = sndSnowBotThrow;//TODO: change this to something better 
	
	grab_offset = [0, 0, 0, 16, 8, 4]; // Happens along the X axis only
	grab_up_offset = [0, 0, 0, -12, -5, -2]; // Happens along the Y axis only
	grab_down_offset = [0, 0, 0, 18, 16, 10]; // Happens along the Y axis only
	grab_state = STATE_NEUTRAL;
	grab_object = -4;
	grab_object_index = -4;
	grab_object_sprite = mskNone;
	grab_index = 0;
	lastGrab = current_frame;
	
#define range //method for checking if a value is within the bounds of a range (inclusive)
	return argument0 >= min(argument1, argument2) && argument0 <= max(argument1, argument2);
#define step
	var mx = mouse_x[index], my = mouse_y[index];
	
	//how we might do smoke 
	//repeat(15) with(instance_create(x+random_range(-10, 10), y+random_range(-10, 10), choose(SmokeOLD, DustOLD)))
    //    depth -= 10;
    
    //trace();
	
	//reduce any enemy with a contact damage higher than 1 to 1
	with(enemy){
		//290 is crystaltype object_index we exclude them here to stop the player avoiding crystal contact damage
		if(self.meleedamage > 1 && self.object_index != 290){
			self.meleedamage = 1;
		}
	}

	if (canspec){
		if button_pressed(index,"spec"){
			if grab_state = STATE_NEUTRAL{//grab state change if we arent holding anything
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
				with(grab_object){//throw state change if we are holding something
					x = other.x;
					y = other.y;
					sprite_index = other.grab_object_sprite;
					image_index = 1;
					image_speed = 0;
					direction = point_direction(other.x, other.y, mx, my);
					mask_index = mskWepPickup;
					ind = other.grab_object_index;
					if(fork()){
						var t = other.team, spd = 18;
						while instance_exists(self){
							spd -= 0.5;
							if spd < 10 spd -= 0.5;
							speed = spd;
							image_angle += speed * 15;
							with(instances_matching_ne(hitme, "team", t)){
								if place_meeting(x, y, other) && nexthurt < current_frame{
									projectile_hit(self,5 + GameCont.level);
									nexthurt = current_frame + 5;
									spd --;
								}
							}
							if place_meeting(x + lengthdir_x(speed, direction), y + lengthdir_y(speed,direction), Wall){
								instance_change(ind, false);
								projectile_hit(self,8);
								image_speed = 0.4;
								image_angle = 0;
								exit;
							}
							if spd < 5{
								instance_change(ind, false);
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
				motion_add(point_direction(other.x, other.y, mx, my), 4)
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
		//insuring the player cant shoot if they dont have thronebutt
		if(!skill_get(5))
			canfire = false;
		if (grab_state != STATE_CARRY && grab_state != STATE_CARRY_HEAVY){
			speed = median(-maxspeed * 0.5, speed, maxspeed * 0.5);
		}else{
			if grab_state = STATE_CARRY_HEAVY{
				speed = median(-maxspeed * 0.6, speed, maxspeed * 0.6);
			}
		}
		grab_index = min(grab_index + (image_speed * current_time_scale), 6);
		switch(grab_state){//select the sprite to display based on the grab we are performing
			case STATE_GRAB_SIDE: sprite_index = spr_grab; break;
			case STATE_GRAB_UP: sprite_index = spr_grab_up; break;
			case STATE_GRAB_DOWN: sprite_index = spr_grab_down; break;
			case STATE_GRAB_UP_ANGLE: sprite_index = spr_grab_up_angle; break;
			case STATE_GRAB_DOWN_ANGLE: sprite_index = spr_grab_down_angle; break;
		}
		if range(floor(grab_index), 2, 3) && grab_object = -4{//handling actual grab detection here
			x_coeff = 0;
			y_coeff = 0;
			vert_offset_temp = grab_up_offset;
			switch(grab_state){
				case STATE_GRAB_SIDE:
					x_coeff = 1;
					break;
				case STATE_GRAB_UP://temp offset is already up
					y_coeff = 1;
				 	break;
				case STATE_GRAB_DOWN:
					y_coeff = 1;
					vert_offset_temp = grab_down_offset;
				 	break;
				case STATE_GRAB_UP_ANGLE://temp offset is already up
					x_coeff = 1;
					y_coeff = 1;
				 	break;
				case STATE_GRAB_DOWN_ANGLE:
					x_coeff = 1;
					y_coeff = 1;
					vert_offset_temp = grab_down_offset;
				 	break;
			}
			hori_offset = x_coeff * (grab_offset[floor(grab_index)] * right);
			vert_offset = y_coeff * (vert_offset_temp[floor(grab_index)]);
			with(collision_circle(x + hori_offset, y + vert_offset, 8, hitme, 0, 1)){
				trace(self.object_index);//Current list of excluded objects: 56 gen, 52 throne, 55  throne pillars
				if(self.object_index != 56 && self.object_index != 52 && self.object_index != 55){//excluding objects we want not to be grabbable here
				other.grab_object = self;
				other.grab_object_index = object_index;
				other.grab_object_sprite = spr_hurt;
		 		other.grab_object_size = size;
		 		instance_change(GameObject, false);
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