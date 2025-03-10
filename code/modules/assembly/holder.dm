/obj/item/device/assembly_holder
	name = "Assembly"
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "holder"
	item_state = "assembly"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	throwforce = 5
	w_class = ITEM_SIZE_SMALL
	throw_speed = 3
	throw_range = 10

	var/secured = 0
	var/obj/item/device/assembly/a_left = null
	var/obj/item/device/assembly/a_right = null
	var/obj/special_assembly = null

/obj/item/device/assembly_holder/proc/attach(obj/item/device/D, obj/item/device/D2, mob/user)
	CAN_BE_REDEFINED(TRUE)
	return

/obj/item/device/assembly_holder/proc/attach_special(obj/O, mob/user)
	CAN_BE_REDEFINED(TRUE)
	return

/obj/item/device/assembly_holder/proc/process_activation(obj/item/device/D)
	CAN_BE_REDEFINED(TRUE)
	return

/obj/item/device/assembly_holder/proc/detached()
	CAN_BE_REDEFINED(TRUE)
	return


/obj/item/device/assembly_holder/IsAssemblyHolder()
	return 1

/obj/item/device/assembly_holder/attach(obj/item/device/assembly/D, obj/item/device/assembly/D2, mob/user)
	if(!istype(D) || !istype(D2))
		return FALSE
	if(D.secured || D2.secured)
		return FALSE
	if(user)
		user.remove_from_mob(D)
		user.remove_from_mob(D2)
	D.holder = src
	D2.holder = src
	D.loc = src
	D2.loc = src
	if(D.proximity_monitor)
		D.proximity_monitor.SetHost(src, D)
	if(D2.proximity_monitor)
		D2.proximity_monitor.SetHost(src, D2)
	a_left = D
	a_right = D2
	SetName("[D.name]-[D2.name] assembly")
	update_icon()
	user.put_in_hands(src)
	return 1

/obj/item/device/assembly_holder/attach_special(obj/O, mob/user)
	if(!O)	return
	if(!O.IsSpecialAssembly())	return 0
	return


/obj/item/device/assembly_holder/update_icon()
	overlays.Cut()
	if(a_left)
		overlays += "[a_left.icon_state]_left"
		for(var/O in a_left.attached_overlays)
			overlays += "[O]_l"
	if(a_right)
		src.overlays += "[a_right.icon_state]_right"
		for(var/O in a_right.attached_overlays)
			overlays += "[O]_r"
	if(master)
		master.update_icon()

/obj/item/device/assembly_holder/examine(mob/user)
	. = ..()
	if ((in_range(src, user) || src.loc == user))
		if (src.secured)
			. += "\n\The [src] is ready!"
		else
			. += "\n\The [src] can be attached!"
	return


/obj/item/device/assembly_holder/HasProximity(atom/movable/AM)
	if(a_left)
		a_left.HasProximity(AM)
	if(a_right)
		a_right.HasProximity(AM)
	if(special_assembly)
		special_assembly.HasProximity(AM)


/obj/item/device/assembly_holder/Crossed(atom/movable/AM as mob|obj)
	if(a_left)
		a_left.Crossed(AM)
	if(a_right)
		a_right.Crossed(AM)
	if(special_assembly)
		special_assembly.Crossed(AM)


/obj/item/device/assembly_holder/on_found(mob/finder as mob)
	if(a_left)
		a_left.on_found(finder)
	if(a_right)
		a_right.on_found(finder)
	if(special_assembly)
		if(istype(special_assembly, /obj/item))
			var/obj/item/S = special_assembly
			S.on_found(finder)


/obj/item/device/assembly_holder/Move()
	..()
	if(a_left && a_right)
		a_left.holder_movement()
		a_right.holder_movement()
	return


/obj/item/device/assembly_holder/attack_hand()//Perhapse this should be a holder_pickup proc instead, can add if needbe I guess
	if(a_left && a_right)
		a_left.holder_movement()
		a_right.holder_movement()
	..()
	return


/obj/item/device/assembly_holder/attackby(obj/item/W, mob/user)
	if(isScrewdriver(W))
		if(!a_left || !a_right)
			to_chat(user, "<span class='warning'>BUG:Assembly part missing, please report this!</span>")
			return
		a_left.toggle_secure()
		a_right.toggle_secure()
		secured = !secured
		if(secured)
			to_chat(user, "<span class='notice'>\The [src] is ready!</span>")
		else
			to_chat(user, "<span class='notice'>\The [src] can now be taken apart!</span>")
		update_icon()
		return
	else if(W.IsSpecialAssembly())
		attach_special(W, user)
	else
		..()
	return


/obj/item/device/assembly_holder/attack_self(mob/user as mob)
	src.add_fingerprint(user)
	if(src.secured)
		if(!a_left || !a_right)
			to_chat(user, "<span class='warning'>Assembly part missing!</span>")
			return
		if(istype(a_left,a_right.type))//If they are the same type it causes issues due to window code
			switch(alert("Which side would you like to use?",,"Left","Right"))
				if("Left")	a_left.attack_self(user)
				if("Right")	a_right.attack_self(user)
			return
		else
			if(!istype(a_left,/obj/item/device/assembly/igniter))
				a_left.attack_self(user)
			if(!istype(a_right,/obj/item/device/assembly/igniter))
				a_right.attack_self(user)
	else
		var/turf/T = get_turf(src)
		if(!T)	return 0
		if(a_left)
			a_left.holder = null
			a_left.loc = T
			if(a_left.proximity_monitor)
				a_left.proximity_monitor.SetHost(a_left, a_left)
		if(a_right)
			a_right.holder = null
			a_right.loc = T
			if(a_right.proximity_monitor)
				a_right.proximity_monitor.SetHost(a_right, a_right)
		spawn(0)
			qdel(src)
	return


/obj/item/device/assembly_holder/process_activation(obj/D, normal = 1, special = 1)
	if(!D)	return 0
	if(!secured)
		visible_message("\icon[src] *beep* *beep*", "*beep* *beep*")
	if((normal) && (a_right) && (a_left))
		if(a_right != D)
			a_right.pulsed(0)
		if(a_left != D)
			a_left.pulsed(0)
	if(master)
		master.receive_signal()
	return 1


/obj/item/device/assembly_holder/New()
	..()
	GLOB.listening_objects += src

/obj/item/device/assembly_holder/Destroy()
	GLOB.listening_objects -= src
	return ..()

/obj/item/device/assembly_holder/hear_talk(mob/living/M as mob, msg, verb, datum/language/speaking)
	if(a_right)
		a_right.hear_talk(M,msg,verb,speaking)
	if(a_left)
		a_left.hear_talk(M,msg,verb,speaking)


/obj/item/device/assembly_holder/timer_igniter
	name = "timer-igniter assembly"

	New()
		..()

		var/obj/item/device/assembly/igniter/ign = new(src)
		ign.secured = 1
		ign.holder = src
		var/obj/item/device/assembly/timer/tmr = new(src)
		tmr.time=5
		tmr.secured = 1
		tmr.holder = src
		START_PROCESSING(SSobj, tmr)
		a_left = tmr
		a_right = ign
		secured = 1
		update_icon()
		SetName(initial(name) + " ([tmr.time] secs)")

		loc.verbs += /obj/item/device/assembly_holder/timer_igniter/verb/configure

	detached()
		loc.verbs -= /obj/item/device/assembly_holder/timer_igniter/verb/configure
		..()

	verb/configure()
		set name = "Set Timer"
		set category = "Object"
		set src in usr

		if ( !(usr.stat || usr.restrained()) )
			var/obj/item/device/assembly_holder/holder
			if(istype(src,/obj/item/grenade/chem_grenade))
				var/obj/item/grenade/chem_grenade/gren = src
				holder=gren.detonator
			var/obj/item/device/assembly/timer/tmr = holder.a_left
			if(!istype(tmr,/obj/item/device/assembly/timer))
				tmr = holder.a_right
			if(!istype(tmr,/obj/item/device/assembly/timer))
				to_chat(usr, "<span class='notice'>This detonator has no timer.</span>")
				return

			if(tmr.timing)
				to_chat(usr, "<span class='notice'>Clock is ticking already.</span>")
			else
				var/ntime = input("Enter desired time in seconds", "Time", "5") as num
				if (ntime>0 && ntime<1000)
					tmr.time = ntime
					SetName(initial(name) + "([tmr.time] secs)")
					to_chat(usr, "<span class='notice'>Timer set to [tmr.time] seconds.</span>")
				else
					to_chat(usr, "<span class='notice'>Timer can't be [ntime<=0?"negative":"more than 1000 seconds"].</span>")
		else
			to_chat(usr, "<span class='notice'>You cannot do this while [usr.stat?"unconscious/dead":"restrained"].</span>")
