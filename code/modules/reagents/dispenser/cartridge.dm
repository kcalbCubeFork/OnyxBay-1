/obj/item/reagent_containers/chem_disp_cartridge
	name = "chemical dispenser cartridge"
	desc = "This goes in a chemical dispenser."
	icon_state = "cartridge"

	w_class = ITEM_SIZE_NORMAL

	volume = CARTRIDGE_VOLUME_LARGE
	amount_per_transfer_from_this = 50
	// Large, but inaccurate. Use a chem dispenser or beaker for accuracy.
	possible_transfer_amounts = "50;100"
	unacidable = 1
	// Save the chemists from being bald.
	effect_flags = EFFECT_FLAG_RAD_SHIELDED

	var/spawn_reagent = null
	var/label = ""

/obj/item/reagent_containers/chem_disp_cartridge/Initialize()
	. = ..()
	if(spawn_reagent)
		reagents.add_reagent(spawn_reagent, volume)
		var/datum/reagent/R = spawn_reagent
		setLabel(initial(R.name))

/obj/item/reagent_containers/chem_disp_cartridge/examine(mob/user)
	. = ..()
	. += "\nIt has a capacity of [volume] units."
	if(reagents.total_volume <= 0)
		. += "\nIt is empty."
	else
		. += "\nIt contains [reagents.total_volume] units of liquid."
	if(!is_open_container())
		. += "\nThe cap is sealed."

/obj/item/reagent_containers/chem_disp_cartridge/verb/verb_set_label()
	set name = "Set Cartridge Label"
	set category = "Object"
	set src in usr

	var/L = sanitizeSafe(input(usr, "Set Cartridge Label", "Cartridge Label", label) as null|text)
	if(CanPhysicallyInteract(usr))
		setLabel(L, usr)

/obj/item/reagent_containers/chem_disp_cartridge/proc/setLabel(L, mob/user = null)
	if(L)
		if(user)
			to_chat(user, "<span class='notice'>You set the label on \the [src] to '[L]'.</span>")

		label = L
		SetName("[initial(name)] - '[L]'")
	else
		if(user)
			to_chat(user, "<span class='notice'>You clear the label on \the [src].</span>")
		label = ""
		SetName(initial(name))

/obj/item/reagent_containers/chem_disp_cartridge/attack_self()
	..()
	if (is_open_container())
		to_chat(usr, "<span class = 'notice'>You put the cap on \the [src].</span>")
		atom_flags ^= ATOM_FLAG_OPEN_CONTAINER
	else
		to_chat(usr, "<span class = 'notice'>You take the cap off \the [src].</span>")
		atom_flags |= ATOM_FLAG_OPEN_CONTAINER

/obj/item/reagent_containers/chem_disp_cartridge/afterattack(obj/target, mob/user , flag)
	if(!is_open_container() || !flag)
		return

	else if(istype(target, /obj/structure/reagent_dispensers) || istype(target, /obj/item/backwear/reagent)) //A dispenser. Transfer FROM it TO us.
		target.add_fingerprint(user)

		if(!target.reagents.total_volume && target.reagents)
			to_chat(user, "<span class='warning'>\The [target] is empty.</span>")
			return

		if(reagents.total_volume >= reagents.maximum_volume)
			to_chat(user, "<span class='warning'>\The [src] is full.</span>")
			return

		var/trans = target.reagents.trans_to(src, target:amount_per_transfer_from_this)
		to_chat(user, "<span class='notice'>You fill \the [src] with [trans] units of the contents of \the [target].</span>")

	else if(target.is_open_container() && target.reagents) //Something like a glass. Player probably wants to transfer TO it.

		if(!reagents.total_volume)
			to_chat(user, "<span class='warning'>\The [src] is empty.</span>")
			return

		if(target.reagents.total_volume >= target.reagents.maximum_volume)
			to_chat(user, "<span class='warning'>\The [target] is full.</span>")
			return

		var/trans = src.reagents.trans_to(target, amount_per_transfer_from_this)
		to_chat(user, "<span class='notice'>You transfer [trans] units of the solution to \the [target].</span>")

	else
		return ..()
