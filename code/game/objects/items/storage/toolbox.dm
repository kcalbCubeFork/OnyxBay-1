/obj/item/storage/toolbox
	name = "toolbox"
	desc = "Bright red toolboxes like these are one of the most common sights in maintenance corridors on virtually every ship in the galaxy."
	description_info = "The toolbox is a general-purpose storage item with lots of space. With an item in your hand, click on it to store it inside."
	description_fluff = "No one remembers which company designed this particular toolbox. It's been mass-produced, retired, brought out of retirement, and counterfeited for decades."
	description_antag = "Carrying one of these and being bald tends to instill a certain primal fear in most people."
	icon = 'icons/obj/storage.dmi'
	icon_state = "red"
	item_state = "toolbox_red"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 15
	throwforce = 10
	throw_speed = 1
	throw_range = 7
	w_class = ITEM_SIZE_LARGE
	mod_weight = 1.6
	mod_reach = 0.75
	mod_handy = 0.75
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = DEFAULT_LARGEBOX_STORAGE //enough to hold all starting contents
	origin_tech = list(TECH_COMBAT = 1)
	attack_verb = list("robusted")

/obj/item/storage/toolbox/emergency
	name = "emergency toolbox"
	icon_state = "red"
	item_state = "toolbox_red"

/obj/item/storage/toolbox/emergency/New()
	..()
	new /obj/item/crowbar/red(src)
	new /obj/item/extinguisher/mini(src)
	var/item = pick(list(/obj/item/device/flashlight, /obj/item/device/flashlight/flare,  /obj/item/device/flashlight/glowstick/red))
	new item(src)
	new /obj/item/device/radio(src)

/obj/item/storage/toolbox/mechanical
	name = "mechanical toolbox"
	desc = "Bright blue toolboxes like these are one of the most common sights in maintenance corridors on virtually every ship in the galaxy."
	icon_state = "blue"
	item_state = "toolbox_blue"

/obj/item/storage/toolbox/mechanical/New()
	..()
	new /obj/item/screwdriver(src)
	new /obj/item/wrench(src)
	new /obj/item/weldingtool(src)
	new /obj/item/crowbar(src)
	new /obj/item/device/analyzer(src)
	new /obj/item/wirecutters(src)

/obj/item/storage/toolbox/electrical
	name = "electrical toolbox"
	desc = "Bright yellow toolboxes like these are one of the most common sights in maintenance corridors on virtually every ship in the galaxy."
	icon_state = "yellow"
	item_state = "toolbox_yellow"

/obj/item/storage/toolbox/electrical/New()
	..()
	new /obj/item/screwdriver(src)
	new /obj/item/wirecutters(src)
	new /obj/item/device/t_scanner(src)
	new /obj/item/crowbar(src)
	new /obj/item/stack/cable_coil/random(src,30)
	new /obj/item/stack/cable_coil/random(src,30)
	if(prob(5))
		new /obj/item/clothing/gloves/insulated(src)
	else
		new /obj/item/stack/cable_coil/random(src,30)

/obj/item/storage/toolbox/syndicate
	name = "black and red toolbox"
	desc = "A toolbox in black, with stylish red trim. This one feels particularly heavy."
	icon_state = "syndicate"
	item_state = "toolbox_syndi"
	origin_tech = list(TECH_COMBAT = 2, TECH_ILLEGAL = 1)
	force = 17.5 //Thatsa robusto toolboxo
	mod_weight = 1.75
	mod_reach = 0.75
	mod_handy = 1.0
	max_storage_space = 23

/obj/item/storage/toolbox/syndicate/New()
	..()
	new /obj/item/clothing/gloves/insulated(src)
	new /obj/item/screwdriver(src)
	new /obj/item/wrench(src)
	new /obj/item/weldingtool(src)
	new /obj/item/crowbar(src)
	new /obj/item/wirecutters(src)
	new /obj/item/device/multitool(src)
	new /obj/item/clothing/glasses/welding(src)
