////////////////////////////////////////////////////////////////////////////////
/// Pills.
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/pill
	name = "pill"
	desc = "A pill."
	icon = 'icons/obj/chemical.dmi'
	icon_state = null
	item_state = "pill"
	randpixel = 7
	possible_transfer_amounts = null
	w_class = ITEM_SIZE_TINY
	slot_flags = SLOT_EARS
	volume = 30

/obj/item/reagent_containers/pill/Initialize()
	. = ..()
	if(!icon_state)
		icon_state = "pill[rand(1, 5)]" //preset pills only use colour changing or unique icons

/obj/item/reagent_containers/pill/attack(mob/M as mob, mob/user as mob, def_zone)
		//TODO: replace with standard_feed_mob() call.

	if(M == user)
		if(!M.can_eat(src))
			return

		to_chat(M, "<span class='notice'>You swallow \the [src].</span>")
		M.drop_from_inventory(src) //icon update
		if(reagents.total_volume)
			reagents.trans_to_mob(M, reagents.total_volume, CHEM_INGEST)
		qdel(src)
		return 1

	else if(istype(M, /mob/living/carbon/human))
		if(!M.can_force_feed(user, src))
			return

		user.visible_message("<span class='warning'>[user] attempts to force [M] to swallow \the [src].</span>")
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		if(!do_mob(user, M))
			return

		if(user.get_active_hand() != src)
			return

		user.drop_from_inventory(src) //icon update
		user.visible_message("<span class='warning'>[user] forces [M] to swallow \the [src].</span>")
		var/contained = reagentlist()
		admin_attack_log(user, M, "Fed the victim with [name] (Reagents: [contained])", "Was fed [src] (Reagents: [contained])", "used [src] (Reagents: [contained]) to feed")
		if(reagents.total_volume)
			reagents.trans_to_mob(M, reagents.total_volume, CHEM_INGEST)
		qdel(src)
		return 1

	return 0

/obj/item/reagent_containers/pill/afterattack(obj/target, mob/user, proximity)
	if(!proximity) return

	if(target.is_open_container() && target.reagents)
		if(!target.reagents.total_volume)
			to_chat(user, "<span class='notice'>[target] is empty. Can't dissolve \the [src].</span>")
			return
		to_chat(user, "<span class='notice'>You dissolve \the [src] in [target].</span>")

		admin_attacker_log(user, "spiked \a [target] with a pill. Reagents: [reagentlist()]")
		reagents.trans_to(target, reagents.total_volume)
		for(var/mob/O in viewers(2, user))
			O.show_message("<span class='warning'>[user] puts something in \the [target].</span>", 1)
		qdel(src)
	return

////////////////////////////////////////////////////////////////////////////////
/// Pills. END
////////////////////////////////////////////////////////////////////////////////

//We lied - it's pills all the way down
/obj/item/reagent_containers/pill/tox
	name = "toxins pill"
	desc = "Highly toxic."
	icon_state = "pill4"
/obj/item/reagent_containers/pill/tox/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin, 30)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/cyanide
	name = "strange pill"
	desc = "It's marked 'KCN'. Smells vaguely of almonds."
	icon_state = "pill9"
/obj/item/reagent_containers/pill/cyanide/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin/cyanide, 30)


/obj/item/reagent_containers/pill/adminordrazine
	name = "Adminordrazine pill"
	desc = "It's magic. We don't have to explain it."
	icon_state = "pillA"
/obj/item/reagent_containers/pill/adminordrazine/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/adminordrazine, 30)


/obj/item/reagent_containers/pill/stox
	name = "Soporific (15u)"
	desc = "Commonly used to treat insomnia."
	icon_state = "pill3"
/obj/item/reagent_containers/pill/stox/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/soporific, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/kelotane
	name = "Kelotane (15u)"
	desc = "Used to treat burns."
	icon_state = "pill2"
/obj/item/reagent_containers/pill/kelotane/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/kelotane, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/paracetamol
	name = "Paracetamol (15u)"
	desc = "A painkiller for the ages. Chewables!"
	icon_state = "pill3"
/obj/item/reagent_containers/pill/paracetamol/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/paracetamol, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/tramadol
	name = "Tramadol (15u)"
	desc = "A simple painkiller."
	icon_state = "pill3"
/obj/item/reagent_containers/pill/tramadol/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tramadol, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/inaprovaline
	name = "Inaprovaline (30u)"
	desc = "Used to stabilize patients."
	icon_state = "pill1"
/obj/item/reagent_containers/pill/inaprovaline/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/inaprovaline, 30)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/dexalin
	name = "Dexalin (15u)"
	desc = "Used to treat oxygen deprivation."
	icon_state = "pill1"
/obj/item/reagent_containers/pill/dexalin/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/dexalin, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/dexalin_plus
	name = "Dexalin Plus (15u)"
	desc = "Used to treat extreme oxygen deprivation."
	icon_state = "pill2"
/obj/item/reagent_containers/pill/dexalin_plus/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/dexalinp, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/dermaline
	name = "Dermaline (15u)"
	desc = "Used to treat burn wounds."
	icon_state = "pill2"
/obj/item/reagent_containers/pill/dermaline/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/dermaline, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/dylovene
	name = "Dylovene (15u)"
	desc = "A broad-spectrum anti-toxin."
	icon_state = "pill1"
/obj/item/reagent_containers/pill/dylovene/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/dylovene, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/bicaridine
	name = "Bicaridine (20u)"
	desc = "Used to treat physical injuries."
	icon_state = "pill2"
/obj/item/reagent_containers/pill/bicaridine/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/bicaridine, 20)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/happy
	name = "happy pill"
	desc = "Happy happy joy joy!"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/happy/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/space_drugs, 15)
	reagents.add_reagent(/datum/reagent/sugar, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/zoom
	name = "zoom pill"
	desc = "Zoooom!"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/zoom/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/impedrezene, 10)
	reagents.add_reagent(/datum/reagent/synaptizine, 5)
	reagents.add_reagent(/datum/reagent/hyperzine, 5)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/spaceacillin
	name = "Spaceacillin (10u)"
	desc = "Contains antiviral agents."
	icon_state = "pill3"
/obj/item/reagent_containers/pill/spaceacillin/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/spaceacillin, 10)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/diet
	name = "diet pill"
	desc = "Guaranteed to get you slim!"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/diet/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/lipozine, 2)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/noexcutite
	name = "Noexcutite (15u)"
	desc = "Feeling jittery? This should calm you down."
	icon_state = "pill4"
/obj/item/reagent_containers/pill/noexcutite/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/noexcutite, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/antidexafen
	name = "Antidexafen (15u)"
	desc = "Common cold mediciation. Safe for babies!"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/antidexafen/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/antidexafen, 10)
	reagents.add_reagent(/datum/reagent/drink/juice/lemon, 5)
	reagents.add_reagent(/datum/reagent/menthol, REM*0.2)
	color = reagents.get_color()

//Psychiatry pills.
/obj/item/reagent_containers/pill/methylphenidate
	name = "Methylphenidate (15u)"
	desc = "Improves the ability to concentrate."
	icon_state = "pill2"
/obj/item/reagent_containers/pill/methylphenidate/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/methylphenidate, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/citalopram
	name = "Citalopram (15u)"
	desc = "Mild anti-depressant."
	icon_state = "pill4"
/obj/item/reagent_containers/pill/citalopram/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/citalopram, 15)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/paroxetine
	name = "Paroxetine (10u)"
	desc = "Before you swallow a bullet: try swallowing this!"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/paroxetine/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/paroxetine, 10)
	color = reagents.get_color()

/obj/item/reagent_containers/pill/hyronalin
	name = "Hyronalin (10u)"
	desc = "Got some rads? Eat this!"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/hyronalin/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/hyronalin, 10)
	color = reagents.get_color()


/obj/item/reagent_containers/pill/glucose
	name = "Glucose (20u)"
	desc = "Used to treat blood loss"
	icon_state = "pill4"
/obj/item/reagent_containers/pill/glucose/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/glucose, 20)
	color = reagents.get_color()


//Mining pills.
/obj/item/reagent_containers/pill/leporazine
	name = "Thermostabilizine"
	desc = "Contents 15u of leporazine. Effectively stabilizes body temperature."
	icon_state = "pill2"
/obj/item/reagent_containers/pill/leporazine/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/leporazine, 15)
	color = reagents.get_color()

//Not actually a pill, but pills type provide everything needed for this
/obj/item/reagent_containers/pill/sugar_cube
	name = "sugar cube"
	desc = "Sugar pressed together in block shape that is used to sweeten drinks."
	icon_state = "sugar_cubes"

/obj/item/reagent_containers/pill/sugar_cube/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/sugar, 5)
	color = reagents.get_color()
