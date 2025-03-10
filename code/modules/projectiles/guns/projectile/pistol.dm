/obj/item/gun/projectile/pistol
	fire_delay = 5.5
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	load_method = MAGAZINE
	fire_sound = 'sound/effects/weapons/gun/fire_45.ogg'
	mag_insert_sound = 'sound/effects/weapons/gun/pistol_magin.ogg'
	mag_eject_sound = 'sound/effects/weapons/gun/pistol_magout.ogg'

/obj/item/gun/projectile/pistol/secgun
	name = ".45 pistol"
	desc = "The NT Mk58 is a cheap, ubiquitous sidearm, produced by a NanoTrasen subsidiary. This one has a sweet wooden grip, among other modifications. Uses .45 rounds."
	icon_state = "secguncomp"
	magazine_type = /obj/item/ammo_magazine/c45m
	allowed_magazines = /obj/item/ammo_magazine/c45m
	caliber = ".45"
/obj/item/gun/projectile/pistol/secgun/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "secguncomp"
	else
		icon_state = "secguncomp-e"

/obj/item/gun/projectile/pistol/secgun/flash
	name = ".45 signal pistol"
	magazine_type = /obj/item/ammo_magazine/c45m/flash

/obj/item/gun/projectile/pistol/secgun/wood
	desc = "The NT Mk58 is a cheap, ubiquitous sidearm, produced by a NanoTrasen subsidiary. This one has a sweet wooden grip, among other modifications. Uses .45 rounds."
	name = "custom .45 Pistol"
	icon_state = "secgundark"
	accuracy = 0

/obj/item/gun/projectile/pistol/secgun/wood/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "secgundark"
	else
		icon_state = "secgundark-e"

/obj/item/gun/projectile/pistol/colt
	name = "vintage .45 pistol"
	desc = "A cheap Martian knock-off of a Colt M1911. Uses .45 rounds."
	icon_state = "colt"
	magazine_type = /obj/item/ammo_magazine/c45m
	allowed_magazines = /obj/item/ammo_magazine/c45m
	caliber = ".45"
	fire_sound = 'sound/effects/weapons/gun/fire_colt2.ogg'

/obj/item/gun/projectile/pistol/colt/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "colt"
	else
		icon_state = "colt-e"

/obj/item/gun/projectile/pistol/colt/officer
	name = "military .45 pistol"
	desc = "The WT45 - a mass produced kinetic sidearm well-known in films and entertainment programming for being the daily carry choice issued to officers of the Sol Central Government Defense Forces. Uses .45 rounds."
	icon_state = "usp"
	accuracy = 0.35
	fire_delay = 6.5

/obj/item/gun/projectile/pistol/colt/officer/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "usp"
	else
		icon_state = "usp-e"

/obj/item/gun/projectile/pistol/vp78
	name = "VP78"
	desc = "The VT78 pistol is a common and reliable sidearm, used by security forces and colonial marshalls all over the world. Uses .45 rounds."
	icon_state = "VP78"
	item_state = "vp78"
	magazine_type = /obj/item/ammo_magazine/c45m/stun
	allowed_magazines = /obj/item/ammo_magazine/c45m
	caliber = ".45"
	accuracy = -0.35

/obj/item/gun/projectile/pistol/vp78/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "VP78"
	else
		icon_state = "VP78-e"

/obj/item/gun/projectile/pistol/vp78/wood
	name = "VP78 Special"
	desc = "The VT78 pistol is a common and reliable sidearm, used by security forces and colonial marshalls all over the world. This one has a sweet wooden grip, among other modifications. Uses .45 rounds."
	icon_state = "VP78wood"
	accuracy = 0.35
	fire_delay = 4.5

/obj/item/gun/projectile/pistol/vp78/wood/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "VP78wood"
	else
		icon_state = "VP78wood-e"

/obj/item/gun/projectile/pistol/vp78/tactical
	name = "VP78 Tactical"
	desc = "The VT78 pistol is a common and reliable sidearm, used by security forces and colonial marshalls all over the world. This one is heavily modified and painted in green camo. Uses .45 rounds."
	icon_state = "VP78tactic"
	magazine_type = /obj/item/ammo_magazine/c45m
	auto_eject = 1
	auto_eject_sound = 'sound/effects/weapons/misc/smg_empty_alarm.ogg'
	fire_delay = 6.5

/obj/item/gun/projectile/pistol/vp78/tactical/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "VP78tactic"
	else
		icon_state = "VP78tactic-e"

/obj/item/gun/projectile/pistol/silenced
	name = "silenced pistol"
	desc = "A handgun with an integral silencer. Uses .45 rounds."
	icon_state = "silenced_pistol"
	w_class = ITEM_SIZE_NORMAL
	caliber = ".45"
	silenced = 1
	fire_sound = SFX_SILENT_FIRE
	mod_weight = 0.7
	mod_reach = 0.5
	mod_handy = 1.0
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 8)
	magazine_type = /obj/item/ammo_magazine/c45m
	allowed_magazines = /obj/item/ammo_magazine/c45m

/obj/item/gun/projectile/pistol/magnum_pistol
	name = ".50 magnum pistol"
	desc = "The HelTek Magnus, a robust terran handgun that uses .50 AE ammo."
	icon_state = "magnum"
	item_state = "revolver"
	force = 12.0
	mod_weight = 0.9
	mod_reach = 0.65
	mod_handy = 1.0
	caliber = ".50"
	fire_delay = 12
	screen_shake = 2
	magazine_type = /obj/item/ammo_magazine/a50
	allowed_magazines = /obj/item/ammo_magazine/a50
	fire_sound = 'sound/effects/weapons/gun/fire2.ogg'

/obj/item/gun/projectile/pistol/magnum_pistol/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "magnum"
	else
		icon_state = "magnum-e"

/obj/item/gun/projectile/pistol/gyropistol
	name = "gyrojet pistol"
	desc = "A bulky pistol designed to fire self propelled rounds."
	icon_state = "gyropistol"
	max_shells = 8
	caliber = "75"
	mod_weight = 0.9
	mod_reach = 0.65
	mod_handy = 1.0
	origin_tech = list(TECH_COMBAT = 3)
	ammo_type = /obj/item/ammo_casing/a75
	magazine_type = /obj/item/ammo_magazine/a75
	fire_delay = 25
	auto_eject = 1
	auto_eject_sound = 'sound/effects/weapons/misc/smg_empty_alarm.ogg'
	fire_sound = 'sound/effects/weapons/gun/fire3.ogg'

/obj/item/gun/projectile/pistol/gyropistol/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "gyropistolloaded"
	else
		icon_state = "gyropistol"

/obj/item/gun/projectile/pistol/det_m9
	name = "T9 Patrol"
	desc = "A relatively cheap and reliable knock-off of a Beretta M9. Uses 9mm rounds. Used to be a standart-issue gun in almost every security company."
	icon_state = "det-m9"
	w_class = ITEM_SIZE_NORMAL
	caliber = "9mm"
	fire_delay = 1
	mod_weight = 0.65
	mod_reach = 0.5
	mod_handy = 1.0
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2,)
	magazine_type = /obj/item/ammo_magazine/mc9mm
	allowed_magazines = /obj/item/ammo_magazine/mc9mm
	fire_sound = 'sound/effects/weapons/gun/fire_9mm.ogg'

/obj/item/gun/projectile/pistol/det_m9/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "det-m9"
	else
		icon_state = "det-m9_e"

/obj/item/gun/projectile/pistol/holdout
	name = "holdout pistol"
	desc = "The Lumoco Arms P3 Whisper. A small, easily concealable gun. Uses 9mm rounds."
	icon_state = "pistol"
	item_state = null
	w_class = ITEM_SIZE_SMALL
	caliber = "9mm"
	silenced = 0
	fire_delay = 1
	fire_sound = 'sound/effects/weapons/gun/fire_9mm2.ogg'
	mod_weight = 0.65
	mod_reach = 0.5
	mod_handy = 1.0
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 2)
	magazine_type = /obj/item/ammo_magazine/mc9mm
	allowed_magazines = /obj/item/ammo_magazine/mc9mm

/obj/item/gun/projectile/pistol/holdout/flash
	name = "holdout signal pistol"
	magazine_type = /obj/item/ammo_magazine/mc9mm/flash

/obj/item/gun/projectile/pistol/holdout/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)
		if(silenced)
			if(user.l_hand != src && user.r_hand != src)
				..()
				return
			to_chat(user, "<span class='notice'>You unscrew [silenced] from [src].</span>")
			user.put_in_hands(silenced)
			silenced = initial(silenced)
			w_class = initial(w_class)
			fire_sound = 'sound/effects/weapons/gun/fire_9mm2.ogg'
			update_icon()
			return
	..()

/obj/item/gun/projectile/pistol/holdout/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I, /obj/item/silencer))
		if(user.l_hand != src && user.r_hand != src)	//if we're not in his hands
			to_chat(user, "<span class='notice'>You'll need [src] in your hands to do that.</span>")
			return
		user.drop_item()
		to_chat(user, "<span class='notice'>You screw [I] onto [src].</span>")
		silenced = I	//dodgy?
		w_class = ITEM_SIZE_NORMAL
		I.forceMove(src)		//put the silencer into the gun
		update_icon()
		fire_sound = SFX_SILENT_FIRE
		return
	..()

/obj/item/gun/projectile/pistol/holdout/update_icon()
	..()
	if(silenced)
		icon_state = "pistol-silencer"
	else
		icon_state = "pistol"
	if(!(ammo_magazine && ammo_magazine.stored_ammo.len))
		icon_state = "[icon_state]-e"

/obj/item/silencer
	name = "silencer"
	desc = "A silencer."
	icon = 'icons/obj/gun.dmi'
	icon_state = "silencer"
	w_class = ITEM_SIZE_SMALL

/obj/item/gun/projectile/pirate
	name = "zip gun"
	desc = "Little more than a barrel, handle, and firing mechanism, cheap makeshift firearms like this one are not uncommon in frontier systems."
	icon_state = "zipgun"
	item_state = "sawnshotgun"
	handle_casings = CYCLE_CASINGS //player has to take the old casing out manually before reloading
	load_method = SINGLE_CASING
	mod_weight = 1.1
	mod_reach = 1.0
	mod_handy = 1.0
	max_shells = 1 //literally just a barrel
	fire_sound = 'sound/effects/weapons/gun/fire6.ogg'

	var/global/list/ammo_types = list(
		/obj/item/ammo_casing/a357              = ".357",
		/obj/item/ammo_casing/a762              = "7.62mm",
		/obj/item/ammo_casing/a556              = "5.56mm"
		)

/obj/item/gun/projectile/pirate/New()
	ammo_type = pick(ammo_types)
	desc += " Uses [ammo_types[ammo_type]] rounds."

	var/obj/item/ammo_casing/ammo = ammo_type
	caliber = initial(ammo.caliber)
	..()

// Zip gun construction.
/obj/item/zipgunframe
	name = "zip gun frame"
	desc = "A half-finished zip gun."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "zipgun0"
	item_state = "zipgun-solid"
	force = 8.0
	mod_weight = 1.0
	mod_reach = 1.0
	mod_handy = 0.75
	var/buildstate = 0

/obj/item/zipgunframe/update_icon()
	icon_state = "zipgun[buildstate]"

/obj/item/zipgunframe/examine(mob/user)
	. = ..()
	switch(buildstate)
		if(1) . += "\nIt has a barrel loosely fitted to the stock."
		if(2) . += "\nIt has a barrel that has been secured to the stock with tape."
		if(3) . += "\nIt has a trigger and firing pin assembly loosely fitted into place."

/obj/item/zipgunframe/attackby(obj/item/thing, mob/user)
	if(istype(thing,/obj/item/pipe) && buildstate == 0)
		user.drop_from_inventory(thing)
		qdel(thing)
		user.visible_message("<span class='notice'>\The [user] fits \the [thing] to \the [src] as a crude barrel.</span>")
		add_fingerprint(user)
		buildstate++
		update_icon()
		return
	else if(istype(thing,/obj/item/tape_roll) && buildstate == 1)
		user.visible_message("<span class='notice'>\The [user] secures the assembly with \the [thing].</span>")
		add_fingerprint(user)
		buildstate++
		update_icon()
		return
	else if(istype(thing,/obj/item/device/assembly/mousetrap) && buildstate == 2)
		user.drop_from_inventory(thing)
		qdel(thing)
		user.visible_message("<span class='notice'>\The [user] takes apart \the [thing] and uses the parts to construct a crude trigger and firing mechanism inside the assembly.</span>")
		add_fingerprint(user)
		buildstate++
		update_icon()
		return
	else if(isScrewdriver(thing) && buildstate == 3)
		user.visible_message("<span class='notice'>\The [user] secures the trigger assembly with \the [thing].</span>")
		playsound(loc, 'sound/items/Screwdriver.ogg', 50, 1)
		var/obj/item/gun/projectile/pirate/zipgun
		zipgun = new /obj/item/gun/projectile/pirate { starts_loaded = 0 } (loc)
		if(ismob(loc))
			var/mob/M = loc
			M.drop_from_inventory(src)
			M.put_in_hands(zipgun)
		transfer_fingerprints_to(zipgun)
		qdel(src)
		return
	else
		..()
