//Amount of time in deciseconds to wait before deleting all drawn segments of a projectile.
#define SEGMENT_DELETION_DELAY 5

/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = 1
	unacidable = 1
	anchored = 1 //There's a reason this is here, Mport. God fucking damn it -Agouri. Find&Fix by Pete. The reason this is here is to stop the curving of emitter shots.
	pass_flags = PASS_FLAG_TABLE
	mouse_opacity = 0

	check_armour = "bullet" //Defines what armor to use when it hits things.  Must be set to bullet, laser, energy,or bomb	//Cael - bio and rad are also valid

	var/bumped = 0		//Prevents it from hitting more than one guy at once
	var/def_zone = ""	//Aiming at
	var/mob/firer = null//Who shot it
	var/silenced = 0	//Attack message
	var/yo = null
	var/xo = null
	var/current = null
	var/shot_from = "" // name of the object which shot us
	var/atom/original = null // the target clicked (not necessarily where the projectile is headed). Should probably be renamed to 'target' or something.
	var/turf/previous = null // the projectile's previous turf updated on each move
	var/turf/starting = null // the projectile's starting turf
	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again
	var/list/segments = list() //For hitscan projectiles with tracers.

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/accuracy = 0
	var/dispersion = 0.0
	var/blockable = TRUE

	var/damage = 10
	var/damage_type = BRUTE //BRUTE, BURN, TOX, OXY, CLONE, PAIN are the only things that should be in here
	var/nodamage = 0 //Determines if the projectile will skip any damage inflictions
	var/projectile_type = /obj/item/projectile
	var/penetrating = 0 //If greater than zero, the projectile will pass through dense objects as specified by on_penetrate()
	var/kill_count = 50 //This will de-increment every process(). When 0, it will delete the projectile.
		//Effects
	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/agony = 0
	var/embed = 0 // whether or not the projectile can embed itself in the mob
	var/penetration_modifier = 0.2 //How much internal damage this projectile can deal, as a multiplier.
	var/tasing = 0 //Whether or not it will stun the target once they reach the pain limit

	var/hitscan = 0		// whether the projectile should be hitscan
	var/step_delay = 1	// the delay between iterations if not a hitscan projectile

	// effect types to be used
	var/muzzle_type
	var/tracer_type
	var/impact_type

	var/ricochet_id = 0

	var/fire_sound

	var/vacuum_traversal = 1 //Determines if the projectile can exist in vacuum, if false, the projectile will be deleted if it enters vacuum.

	var/datum/plot_vector/trajectory	// used to plot the path of the projectile
	var/datum/vector_loc/location		// current location of the projectile in pixel space
	var/matrix/effect_transform			// matrix to rotate and scale projectile effects - putting it here so it doesn't
										//  have to be recreated multiple times

	var/projectile_light = FALSE        // whether the projectile should emit light at all
	var/projectile_max_bright    = 1.0 // brightness of light, must be no greater than 1.
	var/projectile_inner_range   = 0.3 // inner range of light, can be negative
	var/projectile_outer_range   = 1.5 // outer range of light, can be negative
	var/projectile_falloff_curve = 6.0
	var/projectile_brightness_color = "#fff3b2"

/obj/item/projectile/Initialize()
	damtype = damage_type //TODO unify these vars properly
	if(!hitscan)
		animate_movement = SLIDE_STEPS
	if(config.projectile_basketball)
		anchored = 0
		mouse_opacity = 1
	else
		animate_movement = NO_STEPS

	if(projectile_light)
		layer = ABOVE_LIGHTING_LAYER
		plane = EFFECTS_ABOVE_LIGHTING_PLANE
		set_light(projectile_max_bright, projectile_inner_range, projectile_outer_range, projectile_falloff_curve, projectile_brightness_color)
	. = ..()

/obj/item/projectile/Destroy()
	return ..()

/obj/item/projectile/forceMove()
	..()
	if(istype(loc, /turf/space/) && istype(loc.loc, /area/space))
		qdel(src)

//TODO: make it so this is called more reliably, instead of sometimes by bullet_act() and sometimes not
/obj/item/projectile/proc/on_hit(atom/target, blocked = 0, def_zone = null)
	if(blocked >= 100)		return 0//Full block
	if(!isliving(target))	return 0
	if(isanimal(target))	return 0

	var/mob/living/L = target

	L.apply_effects(0, weaken, paralyze, 0, stutter, eyeblur, drowsy, 0, blocked)
	L.stun_effect_act(stun, agony, def_zone, src)
	//radiation protection is handled separately from other armour types.
	L.apply_effect(irradiate, IRRADIATE, L.getarmor(null, "rad"))
	return 1

//called when the projectile stops flying because it collided with something
/obj/item/projectile/proc/on_impact(atom/A, use_impact = TRUE)
	if(use_impact)
		impact_effect(effect_transform)		// generate impact effect, if projectile is in the same loc as shoot start loc, that will cause bugs.
	if(damage && damage_type == BURN)
		var/turf/T = get_turf(A)
		if(T)
			T.hotspot_expose(700, 5)

//Checks if the projectile is eligible for embedding. Not that it necessarily will.
/obj/item/projectile/proc/can_embed()
	//embed must be enabled and damage type must be brute
	if(!embed || damage_type != BRUTE)
		return 0
	return 1

/obj/item/projectile/proc/get_structure_damage()
	if(damage_type == BRUTE || damage_type == BURN)
		return damage
	return 0

//return 1 if the projectile should be allowed to pass through after all, 0 if not.
/obj/item/projectile/proc/check_penetrate(atom/A)
	return 1

/obj/item/projectile/proc/check_fire(atom/target as mob, mob/living/user as mob)  //Checks if you can hit them or not.
	check_trajectory(target, user, pass_flags, item_flags, obj_flags)

//sets the click point of the projectile using mouse input params
/obj/item/projectile/proc/set_clickpoint(params)
	var/list/mouse_control = params2list(params)
	if(mouse_control["icon-x"])
		p_x = text2num(mouse_control["icon-x"])
	if(mouse_control["icon-y"])
		p_y = text2num(mouse_control["icon-y"])

	//randomize clickpoint a bit based on dispersion
	if(dispersion)
		var/radius = round((dispersion*0.443)*world.icon_size*0.8) //0.443 = sqrt(pi)/4 = 2a, where a is the side length of a square that shares the same area as a circle with diameter = dispersion
		p_x = between(0, p_x + rand(-radius, radius), world.icon_size)
		p_y = between(0, p_y + rand(-radius, radius), world.icon_size)

//called to launch a projectile
/obj/item/projectile/proc/launch(atom/target, target_zone, x_offset=0, y_offset=0, angle_offset=0)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if (!istype(targloc) || !istype(curloc))
		return 1

	if(targloc == curloc) //Shooting something in the same turf
		target.bullet_act(src, target_zone)
		on_impact(target, FALSE) //location is null in that case, todo: fix it.
		qdel(src)
		return 0

	original = target
	def_zone = target_zone
	previous = get_turf(loc)

	addtimer(CALLBACK(src, .proc/finalize_launch, curloc, targloc, x_offset, y_offset, angle_offset),0)
	return 0

/obj/item/projectile/proc/finalize_launch(turf/curloc, turf/targloc, x_offset, y_offset, angle_offset)
	setup_trajectory(curloc, targloc, x_offset, y_offset, angle_offset) //plot the initial trajectory
	Process()
	spawn(SEGMENT_DELETION_DELAY) //running this from a proc wasn't working.
		QDEL_NULL_LIST(segments)

//called to launch a projectile from a gun
/obj/item/projectile/proc/launch_from_gun(atom/target, mob/user, obj/item/gun/launcher, target_zone, x_offset=0, y_offset=0)
	if(user == target) //Shooting yourself
		user.bullet_act(src, target_zone)
		qdel(src)
		return 0

	loc = get_turf(user) //move the projectile out into the world

	firer = user
	shot_from = launcher.name
	silenced = launcher.silenced

	return launch(target, target_zone, x_offset, y_offset)

//Used to change the direction of the projectile in flight.
/obj/item/projectile/proc/redirect(new_x, new_y, atom/starting_loc, mob/new_firer=null)
	var/turf/new_target = locate(new_x, new_y, src.z)

	original = new_target
	if(new_firer)
		firer = src

	setup_trajectory(starting_loc, new_target)

//Called when the projectile intercepts a mob. Returns 1 if the projectile hit the mob, 0 if it missed and should keep flying.
/obj/item/projectile/proc/attack_mob(mob/living/target_mob, distance, miss_modifier=0)
	if(!istype(target_mob))
		return

	//roll to-hit
	miss_modifier = max(15*(distance-2) - round(15*accuracy) + miss_modifier + target_mob.get_evasion(), 0)
	var/hit_zone = get_zone_with_miss_chance(def_zone, target_mob, miss_modifier, ranged_attack=(distance > 1 || original != target_mob)) //if the projectile hits a target we weren't originally aiming at then retain the chance to miss

	var/result = PROJECTILE_FORCE_MISS
	if(hit_zone)
		def_zone = hit_zone //set def_zone, so if the projectile ends up hitting someone else later (to be implemented), it is more likely to hit the same part
		if(!target_mob.aura_check(AURA_TYPE_BULLET, src,def_zone))
			return 1
		result = target_mob.bullet_act(src, def_zone)

	if(result == PROJECTILE_FORCE_MISS)
		if(!silenced)
			target_mob.visible_message("<span class='notice'>\The [src] misses [target_mob] narrowly!</span>")
		return 0

	//sometimes bullet_act() will want the projectile to continue flying
	if(result == PROJECTILE_CONTINUE)
		return 0

	if(result == PROJECTILE_FORCE_BLOCK)
		if(!no_attack_log)
			if(istype(firer, /mob))
				var/attacker_message = "shot with \a [src.type] (blocked)"
				var/victim_message = "shot with \a [src.type] (blocked)"
				var/admin_message = "shot (\a [src.type], blocked)"
				admin_attack_log(firer, target_mob, attacker_message, victim_message, admin_message)
			else
				admin_victim_log(target_mob, "was shot by an <b>UNKNOWN SUBJECT (No longer exists)</b> using \a [src] (blocked)")
		return 1

	var/impacted_organ = parse_zone(def_zone)
	if(istype(target_mob, /mob/living/simple_animal))
		var/mob/living/simple_animal/SM = target_mob
		var/decl/simple_animal_bodyparts/body_plan = SM.bodyparts
		if(body_plan != decls_repository.get_decl(/decl/simple_animal_bodyparts/humanoid)) // No need to override
			if(length(body_plan.hit_zones))
				impacted_organ = pick(body_plan.hit_zones)
			else
				impacted_organ = null

	//hit messages
	if(silenced)
		if(impacted_organ)
			to_chat(target_mob, SPAN("danger", "You've been hit in the [impacted_organ] by \the [src]!"))
		else
			to_chat(target_mob, SPAN("danger", "You've been hit by \the [src]!"))
	else
		if(impacted_organ)
			target_mob.visible_message(SPAN("danger", "\The [target_mob] is hit by \the [src] in the [impacted_organ]!"))//X has fired Y is now given by the guns so you cant tell who shot you if you could not see the shooter
		else
			target_mob.visible_message(SPAN("danger", "\The [target_mob] is hit by \the [src]!"))

		new /obj/effect/effect/hitmarker(target_mob.loc)
		for(var/mob/O in hearers(7, get_turf(target_mob)))
			if(O.client)
				if(O.get_preference_value(/datum/client_preference/play_hitmarker) == GLOB.PREF_YES)
					O.playsound_local(target_mob, 'sound/effects/weapons/misc/hitmarker.ogg', 50, 1)

	//admin logs
	if(!no_attack_log)
		if(istype(firer, /mob))

			var/attacker_message = "shot with \a [src.type]"
			var/victim_message = "shot with \a [src.type]"
			var/admin_message = "shot (\a [src.type])"

			admin_attack_log(firer, target_mob, attacker_message, victim_message, admin_message)
		else
			admin_victim_log(target_mob, "was shot by an <b>UNKNOWN SUBJECT (No longer exists)</b> using \a [src]")

	return 1

/obj/item/projectile/Bump(atom/A, forced = FALSE)
	if(A == src)
		return 0 //no

	if(A == firer)
		loc = A.loc
		return 0 //cannot shoot yourself

	if((bumped && !forced) || (A in permutated))
		return 0

	var/passthrough = 0 //if the projectile should continue flying
	var/distance = get_dist(starting,loc)

	bumped = 1
	if(ismob(A))
		var/mob/M = A
		if(istype(A, /mob/living))
			//if they have a neck grab on someone, that person gets hit instead
			var/obj/item/grab/G = locate() in M
			if(G && G.shield_assailant())
				visible_message("<span class='danger'>\The [M] uses [G.affecting] as a shield!</span>")
				if(Bump(G.affecting, forced=1))
					return //If Bump() returns 0 (keep going) then we continue on to attack M.

			passthrough = !attack_mob(M, distance)
		else
			passthrough = 1 //so ghosts don't stop bullets
	else
		passthrough = (A.bullet_act(src, def_zone) == PROJECTILE_CONTINUE) //backwards compatibility
		if(isturf(A))
			for(var/obj/O in A)
				O.bullet_act(src)
			for(var/mob/living/M in A)
				attack_mob(M, distance)

	//penetrating projectiles can pass through things that otherwise would not let them
	if(!passthrough && penetrating > 0)
		if(check_penetrate(A))
			passthrough = 1
		penetrating--

	//the bullet passes through a dense object!
	if(passthrough)
		//move ourselves onto A so we can continue on our way.
		if(A)
			if(istype(A, /turf))
				loc = A
			else
				loc = A.loc
			permutated.Add(A)
		bumped = 0 //reset bumped variable!
		return 0

	//stop flying
	on_impact(A)

	set_density(0)
	set_invisibility(101)

	qdel(src)
	return 1

/obj/item/projectile/ex_act()
	return //explosions probably shouldn't delete projectiles

/obj/item/projectile/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return 1

/obj/item/projectile/Process()
	var/first_step = 1
	var/i = 0
	spawn while(src && src.loc)
		if (++i > 512)
			var/turf/T = src.loc
			qdel(src)
			throw EXCEPTION("Projectile stuck! Type: [type], Shot from: [shot_from], Position: [PRINT_ATOM(T)], Source location: [PRINT_ATOM(trajectory.source)], Target location: [PRINT_ATOM(trajectory.target)], Trajectory offset: ([trajectory.offset_x], [trajectory.offset_y])")
		if(kill_count-- < 1)
			on_impact(src.loc) //for any final impact behaviours
			qdel(src)
			return
		if((!( current ) || loc == current))
			current = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z)
		if((x == 1 || x == world.maxx || y == 1 || y == world.maxy))
			qdel(src)
			return

		trajectory.increment()	// increment the current location
		location = trajectory.return_location(location)		// update the locally stored location data

		if(!location)
			qdel(src)	// if it's left the world... kill it
			return

		if (is_below_sound_pressure(get_turf(src)) && !vacuum_traversal) //Deletes projectiles that aren't supposed to bein vacuum if they leave pressurised areas
			qdel(src)
			return

		before_move()
		previous = loc
		Move(location.return_turf())

		if(!bumped && !isturf(original))
			if(loc == get_turf(original))
				if(!(original in permutated))
					if(Bump(original))
						return

		if(first_step)
			muzzle_effect(effect_transform)
			first_step = 0
		else if(!bumped && kill_count > 0)
			tracer_effect(effect_transform)
		if(!hitscan)
			sleep(step_delay)    //add delay between movement iterations if it's not a hitscan weapon

/obj/item/projectile/proc/before_move()
	return 0

/obj/item/projectile/proc/setup_trajectory(turf/startloc, turf/targloc, x_offset = 0, y_offset = 0)
	// setup projectile state
	starting = startloc
	current = startloc
	yo = round(targloc.y - startloc.y + y_offset, 1)
	xo = round(targloc.x - startloc.x + x_offset, 1)

	// trajectory dispersion
	var/offset = 0
	if(dispersion)
		var/radius = round(dispersion*9, 1)
		offset = rand(-radius, radius)

	// plot the initial trajectory
	trajectory = new()
	trajectory.setup(starting, original, pixel_x, pixel_y, angle_offset=offset)

	// generate this now since all visual effects the projectile makes can use it
	effect_transform = new()
	effect_transform.Scale(round(trajectory.return_hypotenuse() + 0.005, 0.001) , 1) //Seems like a weird spot to truncate, but it minimizes gaps.
	effect_transform.Turn(round(-trajectory.return_angle(), 0.1))		//no idea why this has to be inverted, but it works

	transform = turn(transform, -(trajectory.return_angle() + 90)) //no idea why 90 needs to be added, but it works

/obj/item/projectile/proc/muzzle_effect(matrix/T)
	if(silenced)
		return

	if(ispath(muzzle_type))
		var/obj/effect/projectile/M = new muzzle_type(get_turf(src))

		if(istype(M))
			M.set_transform(T)
			M.pixel_x = round(location.pixel_x, 1)
			M.pixel_y = round(location.pixel_y, 1)
			if(!hitscan) //Bullets don't hit their target instantly, so we can't link the deletion of the muzzle flash to the bullet's Destroy()
				QDEL_IN(M,1)
			else
				segments += M

/obj/item/projectile/proc/tracer_effect(matrix/M)
	if(ispath(tracer_type))
		var/obj/effect/projectile/P = new tracer_type(location.loc)

		if(istype(P))
			P.set_transform(M)
			P.pixel_x = round(location.pixel_x, 1)
			P.pixel_y = round(location.pixel_y, 1)
			if(!hitscan)
				QDEL_IN(M,1)
			else
				segments += P

/obj/item/projectile/proc/impact_effect(matrix/M)
	if(ispath(impact_type))
		var/obj/effect/projectile/P = new impact_type(location.loc)

		if(istype(P))
			P.set_transform(M)
			P.pixel_x = round(location.pixel_x, 1)
			P.pixel_y = round(location.pixel_y, 1)
			segments += P

//"Tracing" projectile
/obj/item/projectile/test //Used to see if you can hit them.
	invisibility = 101 //Nope!  Can't see me!
	yo = null
	xo = null
	var/result = 0 //To pass the message back to the gun.

/obj/item/projectile/test/Bump(atom/A, forced = FALSE)
	if(A == firer)
		loc = A.loc
		return //cannot shoot yourself
	if(istype(A, /obj/item/projectile))
		return
	if(istype(A, /mob/living) || istype(A, /obj/mecha) || istype(A, /obj/vehicle))
		result = 2 //We hit someone, return 1!
		return
	result = 1
	return

/obj/item/projectile/test/launch(atom/target)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if(!curloc || !targloc)
		return 0

	original = target

	//plot the initial trajectory
	setup_trajectory(curloc, targloc)
	return Process(targloc)

/obj/item/projectile/test/Process(turf/targloc)
	var/i = 0
	while(src) //Loop on through!
		if (++i > 512)
			var/turf/T = src.loc
			qdel(src)
			throw EXCEPTION("Projectile stuck! Type: [type], Shot from: [shot_from], Position: [PRINT_ATOM(T)], Source location: [PRINT_ATOM(trajectory.source)], Target location: [PRINT_ATOM(trajectory.target)], Trajectory offset: ([trajectory.offset_x], [trajectory.offset_y])")

		if(result)
			return (result - 1)
		if((!( targloc ) || loc == targloc))
			targloc = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z) //Finding the target turf at map edge

		trajectory.increment()	// increment the current location
		location = trajectory.return_location(location)		// update the locally stored location data

		Move(location.return_turf())

		var/mob/living/M = locate() in get_turf(src)
		if(istype(M)) //If there is someting living...
			return 1 //Return 1
		else
			M = locate() in get_step(src,targloc)
			if(istype(M))
				return 1

//Helper proc to check if you can hit them or not.
/proc/check_trajectory(atom/target as mob|obj, atom/firer as mob|obj, pass_flags=PASS_FLAG_TABLE|PASS_FLAG_GLASS|PASS_FLAG_GRILLE, item_flags = null, obj_flags = null)
	if(!istype(target) || !istype(firer))
		return 0

	var/obj/item/projectile/test/trace = new /obj/item/projectile/test(get_turf(firer)) //Making the test....

	//Set the flags and pass flags to that of the real projectile...
	if(!isnull(item_flags))
		trace.item_flags = item_flags
	if(!isnull(obj_flags))
		trace.obj_flags = obj_flags
	trace.pass_flags = pass_flags

	var/output = trace.launch(target) //Test it!
	qdel(trace) //No need for it anymore
	return output //Send it back to the gun!


