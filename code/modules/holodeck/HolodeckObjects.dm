// Holographic Items!

// Holographic tables are in code/modules/tables/presets.dm
// Holographic racks are in code/modules/tables/rack.dm

/turf/simulated/floor/holofloor
	thermal_conductivity = 0

/turf/simulated/floor/holofloor/attackby(obj/item/W, mob/user)
	return
	// HOLOFLOOR DOES NOT GIVE A FUCK

/turf/simulated/floor/holofloor/set_flooring()
	return

/turf/simulated/floor/holofloor/carpet
	name = "brown carpet"
	icon = 'icons/turf/flooring/carpet.dmi'
	icon_state = "brown"
	initial_flooring = /decl/flooring/carpet

/turf/simulated/floor/holofloor/tiled
	name = "floor"
	icon = 'icons/turf/flooring/tiles.dmi'
	icon_state = "steel"
	initial_flooring = /decl/flooring/tiling

/turf/simulated/floor/holofloor/tiled/dark
	name = "dark floor"
	icon_state = "dark"
	initial_flooring = /decl/flooring/tiling/dark

/turf/simulated/floor/holofloor/lino
	name = "lino"
	icon = 'icons/turf/flooring/linoleum.dmi'
	icon_state = "lino"
	initial_flooring = /decl/flooring/linoleum

/turf/simulated/floor/holofloor/wood
	name = "wooden floor"
	icon = 'icons/turf/flooring/wood.dmi'
	icon_state = "wood"
	initial_flooring = /decl/flooring/wood

/turf/simulated/floor/holofloor/grass
	name = "lush grass"
	icon = 'icons/turf/flooring/grass.dmi'
	icon_state = "grass0"
	initial_flooring = /decl/flooring/grass

/turf/simulated/floor/holofloor/snow
	name = "snow"
	base_name = "snow"
	icon = 'icons/turf/floors.dmi'
	base_icon = 'icons/turf/floors.dmi'
	icon_state = "snow"
	base_icon_state = "snow"

/turf/simulated/floor/holofloor/space
	icon = 'icons/turf/space.dmi'
	name = "\proper space"
	icon_state = "0"

/turf/simulated/floor/holofloor/reinforced
	icon = 'icons/turf/flooring/tiles.dmi'
	initial_flooring = /decl/flooring/reinforced
	name = "reinforced holofloor"
	icon_state = "reinforced"

/turf/simulated/floor/holofloor/space/New()
	icon_state = "[((x + y) ^ ~(x * y) + z) % 25]"

/turf/simulated/floor/holofloor/beach
	desc = "Uncomfortably gritty for a hologram."
	base_desc = "Uncomfortably gritty for a hologram."
	icon = 'icons/misc/beach.dmi'
	base_icon = 'icons/misc/beach.dmi'
	initial_flooring = null

/turf/simulated/floor/holofloor/beach/sand
	name = "sand"
	icon_state = "desert0"
	base_icon_state = "desert0"

/turf/simulated/floor/holofloor/beach/coastline
	name = "coastline"
	icon = 'icons/misc/beach2.dmi'
	icon_state = "sandwater"
	base_icon_state = "sandwater"

/turf/simulated/floor/holofloor/beach/water
	name = "water"
	icon_state = "seashallow"
	base_icon_state = "seashallow"

/turf/simulated/floor/holofloor/desert
	name = "desert sand"
	base_name = "desert sand"
	desc = "Uncomfortably gritty for a hologram."
	base_desc = "Uncomfortably gritty for a hologram."
	icon_state = "sand0"
	base_icon_state = "sand0"
	icon = 'icons/turf/flooring/sand.dmi'
	base_icon = 'icons/turf/flooring/sand.dmi'
	initial_flooring = null

/turf/simulated/floor/holofloor/desert/New()
	..()
	if(prob(10))
		overlays += "asteroid[rand(0,9)]"

/obj/structure/holostool
	name = "stool"
	desc = "Apply butt."
	icon = 'icons/obj/furniture.dmi'
	icon_state = "stool_padded_preview"
	anchored = 1.0

/obj/item/clothing/gloves/boxing/hologlove
	name = "boxing gloves"
	desc = "Because you really needed another excuse to punch your crewmates."
	icon_state = "boxing"
	item_state = "boxing"

/obj/structure/window/reinforced/holowindow/Destroy()
	return ..()

/obj/structure/window/reinforced/holowindow/attackby(obj/item/W, mob/user)

	if(!istype(W) || W.item_flags & ITEM_FLAG_NO_BLUDGEON) return

	if(istype(W, /obj/item/screwdriver))
		to_chat(user, ("<span class='notice'>It's a holowindow, you can't unfasten it!</span>"))
	else if(istype(W, /obj/item/crowbar) && reinf && state <= 1)
		to_chat(user, ("<span class='notice'>It's a holowindow, you can't pry it!</span>"))
	else if(istype(W, /obj/item/wrench) && !anchored && (!state || !reinf))
		to_chat(user, ("<span class='notice'>It's a holowindow, you can't dismantle it!</span>"))
	else
		if(W.damtype == BRUTE || W.damtype == BURN)
			hit(W.force)
			if(health <= 7)
				anchored = 0
				update_nearby_icons()
				step(src, get_dir(user, src))
		else
			playsound(loc, GET_SFX(SFX_GLASS_HIT), 75, 1)
		..()
	return

/obj/structure/window/reinforced/holowindow/shatter(display_message = 1)
	playsound(src, SFX_BREAK_WINDOW, 70, 1)
	if(display_message)
		visible_message("[src] fades away as it shatters!")
	qdel(src)
	return

/obj/structure/window/reinforced/holowindow/disappearing/Destroy()
	return ..()

/obj/machinery/door/window/holowindoor/Destroy()
	return ..()

/obj/machinery/door/window/holowindoor/attackby(obj/item/I, mob/user)

	if (src.operating == 1)
		return

	if(density && user.a_intent == I_HURT && !(istype(I, /obj/item/card) || istype(I, /obj/item/device/pda)))
		var/aforce = I.force
		playsound(src.loc, GET_SFX(SFX_GLASS_HIT), 75, 1)
		visible_message("<span class='danger'>\The [src] was hit by \the [I].</span>")
		if(I.damtype == BRUTE || I.damtype == BURN)
			take_damage(aforce)
		return

	src.add_fingerprint(user)
	if (!src.requiresID())
		user = null

	if (src.allowed(user))
		if (src.density)
			open()
		else
			close()

	else if (src.density)
		flick(text("[]deny", src.base_state), src)

	return

/obj/machinery/door/window/holowindoor/shatter(display_message = 1)
	src.set_density(0)
	playsound(src, SFX_BREAK_WINDOW, 70, 1)
	if(display_message)
		visible_message("[src] fades away as it shatters!")
	qdel(src)

/obj/structure/bed/chair/holochair/Destroy()
	return ..()

/obj/structure/bed/chair/holochair/attackby(obj/item/W, mob/user)
	if(isWrench(W))
		to_chat(user, SPAN("notice", "It's a holochair, you can't dismantle it!"))
	return

/obj/structure/bed/chair/holochair/fold(mob/user)
	if(!foldable)
		return

	var/list/collapse_message = list(SPAN_WARNING("\The [name] has collapsed!"), null)

	if(buckled_mob)
		collapse_message = list(\
			SPAN_WARNING("[buckled_mob] falls down [user ? "as [user] collapses" : "from collapsing"] \the [name]!"),\
			user ? SPAN_NOTICE("You collapse \the [name] and made [buckled_mob] fall down!") : null)

		var/mob/living/occupant = unbuckle_mob()
		var/blocked = occupant.run_armor_check(BP_GROIN, "melee")

		occupant.apply_effect(4, STUN, blocked)
		occupant.apply_effect(4, WEAKEN, blocked)
		occupant.apply_damage(rand(5,10), BRUTE, BP_GROIN, blocked)
		playsound(src, 'sound/effects/fighting/punch1.ogg', 50, 1, -1)
	else if(user)
		collapse_message = list("[user] collapses \the [name].", "You collapse \the [name].")

	visible_message(collapse_message[1], collapse_message[2])
	var/obj/item/foldchair/holochair/O = new /obj/item/foldchair/holochair(get_turf(src))
	if(user)
		O.add_fingerprint(user)
	QDEL_IN(src, 0)

/obj/item/foldchair/holochair/attackby(obj/item/W, mob/user)
	if(isWrench(W))
		to_chat(user,SPAN("notice", "It's a holochair, you can't dismantle it!"))

/obj/item/foldchair/holochair/attack_self(mob/user)
	var/obj/structure/bed/chair/holochair/O = new /obj/structure/bed/chair/holochair(user.loc)
	O.add_fingerprint(user)
	O.dir = user.dir
	O.update_icon()
	visible_message("[user] unfolds \the [O.name].")
	qdel(src)

/obj/item/holo
	damtype = PAIN
	no_attack_log = 1

/obj/item/holo/esword
	name = "holosword"
	desc = "May the force be within you. Sorta."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "sword0"
	force = 3.0
	throw_speed = 1
	throw_range = 5
	throwforce = 0
	w_class = ITEM_SIZE_SMALL
	atom_flags = ATOM_FLAG_NO_BLOOD
	var/active = 0
	var/item_color

/obj/item/holo/esword/green
	New()
		item_color = "green"

/obj/item/holo/esword/red
	New()
		item_color = "red"

/obj/item/holo/esword/New()
	item_color = pick("red","blue","green","purple")

/obj/item/holo/esword/attack_self(mob/living/user)
	active = !active
	if (active)
		force = 30
		icon_state = "sword[item_color]"
		w_class = ITEM_SIZE_HUGE
		playsound(user, 'sound/weapons/saberon.ogg', 50, 1)
		to_chat(user, "<span class='notice'>[src] is now active.</span>")
	else
		force = 3
		icon_state = "sword0"
		w_class = ITEM_SIZE_SMALL
		playsound(user, 'sound/weapons/saberoff.ogg', 50, 1)
		to_chat(user, "<span class='notice'>[src] can now be concealed.</span>")

	update_held_icon()

	add_fingerprint(user)
	return

//BASKETBALL OBJECTS

/obj/item/beach_ball/holoball
	icon = 'icons/obj/basketball.dmi'
	icon_state = "basketball"
	name = "basketball"
	item_state = "basketball"
	desc = "Here's your chance, do your dance at the Space Jam."
	w_class = ITEM_SIZE_LARGE //Stops people from hiding it in their pockets

/obj/structure/holohoop
	name = "basketball hoop"
	desc = "Boom, Shakalaka!"
	icon = 'icons/obj/basketball.dmi'
	icon_state = "hoop"
	anchored = 1
	density = 1
	throwpass = 1

/obj/structure/holohoop/CanPass(atom/movable/mover, turf/target)
	if(istype(mover,/obj/item) && mover.throwing)
		var/obj/item/I = mover
		if(istype(I, /obj/item/projectile))
			return TRUE
		if(prob(50))
			I.forceMove(loc)
			visible_message("<span class='notice'>Swish! \the [I] lands in \the [src].</span>", 3)
		else
			visible_message("<span class='warning'>\The [I] bounces off of \the [src]'s rim!</span>", 3)
		return FALSE
	return ..()


/obj/machinery/readybutton
	name = "Ready Declaration Device"
	desc = "This device is used to declare ready. If all devices in an area are ready, the event will begin!"
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	layer = ABOVE_WINDOW_LAYER
	var/ready = 0
	var/area/currentarea = null
	var/eventstarted = 0

	anchored = 1.0
	power_channel = STATIC_ENVIRON

/obj/machinery/readybutton/attack_ai(mob/user)
	to_chat(user, "The AI is not to interact with these devices!")
	return

/obj/machinery/readybutton/New()
	..()


/obj/machinery/readybutton/attackby(obj/item/W, mob/user)
	to_chat(user, "The device is a holographic button, there's nothing you can do with it!")

/obj/machinery/readybutton/attack_hand(mob/user)

	if(user.stat)
		to_chat(src, "You are incapacitated.")
		return

	if(stat & BROKEN)
		to_chat(user, "This device is broken.")
		return

	if(!user.IsAdvancedToolUser())
		return 0

	currentarea = get_area(src.loc)
	if(!currentarea)
		qdel(src)

	if(eventstarted)
		to_chat(usr, "The event has already begun!")
		return

	ready = !ready

	update_icon()

	var/numbuttons = 0
	var/numready = 0
	for(var/obj/machinery/readybutton/button in currentarea)
		numbuttons++
		if (button.ready)
			numready++

	if(numbuttons == numready)
		begin_event()

/obj/machinery/readybutton/update_icon()
	if(ready)
		icon_state = "auth_on"
	else
		icon_state = "auth_off"

/obj/machinery/readybutton/proc/begin_event()

	eventstarted = 1

	for(var/obj/structure/window/reinforced/holowindow/disappearing/W in currentarea)
		qdel(W)

	for(var/mob/M in currentarea)
		to_chat(M, "FIGHT!")

//Holocarp

/mob/living/simple_animal/hostile/carp/holodeck
	icon = 'icons/mob/hologram.dmi'
	icon_state = "Carp"
	icon_living = "Carp"
	icon_dead = "Carp"
	alpha = 127
	icon_gib = null
	meat_amount = 0
	meat_type = null

/mob/living/simple_animal/hostile/carp/holodeck/New()
	..()
	set_light(0.5, 0.1, 2) //hologram lighting

/mob/living/simple_animal/hostile/carp/holodeck/proc/set_safety(safe)
	if (safe)
		faction = "neutral"
		melee_damage_lower = 0
		melee_damage_upper = 0
		environment_smash = 0
		destroy_surroundings = 0
	else
		faction = "carp"
		melee_damage_lower = initial(melee_damage_lower)
		melee_damage_upper = initial(melee_damage_upper)
		environment_smash = initial(environment_smash)
		destroy_surroundings = initial(destroy_surroundings)

/mob/living/simple_animal/hostile/carp/holodeck/gib()
	death()

/mob/living/simple_animal/hostile/carp/holodeck/death()
	..(null, "fades away!", "You have been destroyed.")
	qdel(src)
