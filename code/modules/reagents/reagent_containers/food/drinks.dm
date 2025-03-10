////////////////////////////////////////////////////////////////////////////////
/// Drinks.
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/food/drinks
	name = "drink"
	desc = "Yummy!"
	icon = 'icons/obj/drinks.dmi'
	icon_state = null
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	amount_per_transfer_from_this = 5
	volume = 50
	var/filling_states   // List of percentages full that have icons
	var/base_name = null // Name to put in front of drinks, i.e. "[base_name] of [contents]"
	var/base_icon = null // Base icon name for fill states
	pickup_sound = SFX_PICKUP_BOTTLE
	pull_sound = SFX_PULL_GLASS
	can_be_splashed = TRUE

/obj/item/reagent_containers/food/drinks/Initialize()
	. = ..()
	if(is_open_container())
		verbs += .verb/drink_whole

/obj/item/reagent_containers/food/drinks/on_reagent_change()
	update_icon()
	return

/obj/item/reagent_containers/food/drinks/attack_self(mob/user as mob)
	if(!is_open_container())
		open(user)

/obj/item/reagent_containers/food/drinks/proc/open(mob/user)
	playsound(loc,'sound/effects/canopen.ogg', rand(10,50), 1)
	to_chat(user, "<span class='notice'>You open \the [src] with an audible pop!</span>")
	atom_flags |= ATOM_FLAG_OPEN_CONTAINER
	verbs += .verb/drink_whole

/obj/item/reagent_containers/food/drinks/attack(mob/M as mob, mob/user as mob, def_zone)
	if(force && !(item_flags & ITEM_FLAG_NO_BLUDGEON) && user.a_intent == I_HURT)
		return ..()

	if(standard_feed_mob(user, M))
		return

	return 0

/obj/item/reagent_containers/food/drinks/afterattack(obj/target, mob/user, proximity)
	if(!is_open_container() || !proximity)
		return

	if(standard_dispenser_refill(user, target))
		return
	if(standard_pour_into(user, target))
		return
	return ..()

/obj/item/reagent_containers/food/drinks/standard_feed_mob(mob/user, mob/target)
	if(!is_open_container())
		to_chat(user, "<span class='notice'>You need to open \the [src]!</span>")
		return 1
	return ..()

/obj/item/reagent_containers/food/drinks/standard_dispenser_refill(mob/user, obj/structure/reagent_dispensers/target)
	if(!is_open_container())
		to_chat(user, "<span class='notice'>You need to open \the [src]!</span>")
		return 1
	return ..()

/obj/item/reagent_containers/food/drinks/standard_pour_into(mob/user, atom/target)
	if(!is_open_container())
		to_chat(user, "<span class='notice'>You need to open \the [src]!</span>")
		return 1
	return ..()

/obj/item/reagent_containers/food/drinks/self_feed_message(mob/user)
	to_chat(user, "<span class='notice'>You swallow a gulp from \the [src].</span>")

/obj/item/reagent_containers/food/drinks/examine(mob/user)
	. = ..()
	if(get_dist(src, user) > 1)
		return
	if(!reagents || reagents.total_volume == 0)
		. += "\n<span class='notice'>\The [src] is empty!</span>"
	else if (reagents.total_volume <= volume * 0.25)
		. += "\n<span class='notice'>\The [src] is almost empty!</span>"
	else if (reagents.total_volume <= volume * 0.66)
		. += "\n<span class='notice'>\The [src] is half full!</span>"
	else if (reagents.total_volume <= volume * 0.90)
		. += "\n<span class='notice'>\The [src] is almost full!</span>"
	else
		. += "\n<span class='notice'>\The [src] is full!</span>"

/obj/item/reagent_containers/food/drinks/proc/get_filling_state()
	var/percent = round((reagents.total_volume / volume) * 100)
	for(var/k in cached_number_list_decode(filling_states))
		if(percent <= k)
			return k

/obj/item/reagent_containers/food/drinks/update_icon()
	overlays.Cut()
	if(reagents.reagent_list.len > 0)
		if(base_name)
			var/datum/reagent/R = reagents.get_master_reagent()
			SetName("[base_name] of [R.glass_name ? R.glass_name : "something"]")
			desc = R.glass_desc ? R.glass_desc : initial(desc)
		if(filling_states)
			var/image/filling = image(icon, src, "[base_icon][get_filling_state()]")
			filling.color = reagents.get_color()
			overlays += filling
	else
		SetName(initial(name))
		desc = initial(desc)

/obj/item/reagent_containers/food/drinks/verb/drink_whole()
	set category = "Object"
	set name = "Drink Down"

	var/mob/living/carbon/C = usr
	if(!iscarbon(C))
		return

	if(!istype(C.get_active_hand(), src))
		to_chat(C, SPAN_WARNING("You need to hold \the [src] in hands!"))
		return

	if(is_open_container())
		if(!C.check_has_mouth())
			to_chat(C, SPAN_WARNING("How do you intend to drink \the [src]? You don't have a mouth!"))
			return
		var/obj/item/blocked = C.check_mouth_coverage()
		if(blocked)
			to_chat(C, SPAN_WARNING("\The [blocked] is in the way!"))
			return

		if(reagents.total_volume > 30) // 30 equates to 3 SECONDS.
			C.visible_message(\
				SPAN_NOTICE("[C] prepares to drink down [src]."),\
				SPAN_NOTICE("You prepare to drink down [src]."))
			playsound(C, 'sound/items/drinking.ogg', reagents.total_volume, 1)

		if(!do_after(C, reagents.total_volume))
			if(!Adjacent(C)) return
			standard_splash_mob(src, src)
			C.visible_message(\
				SPAN_DANGER("[C] splashed \the [src]'s contents on self while trying drink it down."),\
				SPAN_DANGER("You splash \the [src]'s contents on yourself!"))
			return

		else
			if(!Adjacent(C)) return
			C.visible_message(\
				SPAN_NOTICE("[C] drinked down the whole [src]!"),\
				SPAN_NOTICE("You drink down the whole [src]!"))
			playsound(C, 'sound/items/drinking_after.ogg', reagents.total_volume, 1)
			reagents.trans_to_mob(C, reagents.total_volume, CHEM_INGEST)
	else
		to_chat(C, SPAN_NOTICE("You need to open \the [src] first!"))

////////////////////////////////////////////////////////////////////////////////
/// Drinks. END
////////////////////////////////////////////////////////////////////////////////

/obj/item/reagent_containers/food/drinks/golden_cup
	desc = "A golden cup."
	name = "golden cup"
	icon_state = "golden_cup"
	item_state = "" //nope :(
	w_class = ITEM_SIZE_HUGE
	force = 14
	throwforce = 10
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = null
	volume = 150
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	obj_flags = OBJ_FLAG_CONDUCTIBLE

///////////////////////////////////////////////Drinks
//Notes by Darem: Drinks are simply containers that start preloaded. Unlike condiments, the contents can be ingested directly
//	rather then having to add it to something else first. They should only contain liquids. They have a default container size of 50.
//	Formatting is the same as food.

/obj/item/reagent_containers/food/drinks/milk
	name = "milk carton"
	desc = "It's milk. White and nutritious goodness!"
	icon_state = "milk"
	item_state = "carton"
	center_of_mass = "x=16;y=9"

/obj/item/reagent_containers/food/drinks/milk/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/milk, 50)

/obj/item/reagent_containers/food/drinks/soymilk
	name = "soymilk carton"
	desc = "It's soy milk. White and nutritious goodness!"
	icon_state = "soymilk"
	item_state = "carton"
	center_of_mass = "x=16;y=9"

/obj/item/reagent_containers/food/drinks/soymilk/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/milk/soymilk, 50)

/obj/item/reagent_containers/food/drinks/milk/smallcarton
	name = "small milk carton"
	volume = 30
	icon_state = "mini-milk"

/obj/item/reagent_containers/food/drinks/milk/smallcarton/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/milk, 30)

/obj/item/reagent_containers/food/drinks/milk/smallcarton/chocolate
	name = "small chocolate milk carton"
	desc = "It's milk! This one is in delicious chocolate flavour."

/obj/item/reagent_containers/food/drinks/milk/smallcarton/chocolate/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/milk/chocolate, 30)


/obj/item/reagent_containers/food/drinks/coffee
	name = "\improper Robust Coffee"
	desc = "Careful, the beverage you're about to enjoy is extremely hot."
	icon_state = "coffee"
	center_of_mass = "x=15;y=10"

/obj/item/reagent_containers/food/drinks/coffee/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/coffee, 30)

/obj/item/reagent_containers/food/drinks/tea
	name = "cup of Duke Purple Tea"
	desc = "An insult to Duke Purple is an insult to the Space Queen! Any proper gentleman will fight you, if you sully this tea."
	icon_state = "teacup"
	item_state = "coffee"
	center_of_mass = "x=16;y=14"
	filling_states = "100"
	base_name = "cup"
	base_icon = "teacup"

/obj/item/reagent_containers/food/drinks/tea/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/tea, 30)

/obj/item/reagent_containers/food/drinks/ice
	name = "cup of ice"
	desc = "Careful, cold ice, do not chew."
	icon_state = "coffee"
	center_of_mass = "x=15;y=10"

/obj/item/reagent_containers/food/drinks/ice/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/ice, 30)

/obj/item/reagent_containers/food/drinks/h_chocolate
	name = "cup of Dutch hot coco"
	desc = "Made in Space South America."
	icon_state = "hot_coco"
	item_state = "coffee"
	center_of_mass = "x=15;y=13"

/obj/item/reagent_containers/food/drinks/h_chocolate/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/hot_coco, 30)

/obj/item/reagent_containers/food/drinks/dry_ramen
	name = "cup ramen"
	gender = PLURAL
	desc = "Just add 10ml water, self heats! A taste that reminds you of your school years."
	icon_state = "ramen"
	center_of_mass = "x=16;y=11"

/obj/item/reagent_containers/food/drinks/dry_ramen/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/dry_ramen, 30)

/obj/item/reagent_containers/food/drinks/chickensoup
	name = "cup of chicken soup"
	desc = "Just add 10ml water, self heats! Keep yourself warm!"
	icon_state = "chickensoup"
	item_state = "ramen"
	center_of_mass = "x=16;y=11"

/obj/item/reagent_containers/food/drinks/chickensoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/chicken_powder, 30)

/obj/item/reagent_containers/food/drinks/sillycup
	name = "paper cup"
	desc = "A paper water cup."
	icon_state = "water_cup_e"
	possible_transfer_amounts = null
	volume = 10
	center_of_mass = "x=16;y=12"

/obj/item/reagent_containers/food/drinks/sillycup/on_reagent_change()
	if(reagents.total_volume)
		icon_state = "water_cup"
	else
		icon_state = "water_cup_e"


//////////////////////////drinkingglass and shaker//
//Note by Darem: This code handles the mixing of drinks. New drinks go in three places: In Chemistry-Reagents.dm (for the drink
//	itself), in Chemistry-Recipes.dm (for the reaction that changes the components into the drink), and here (for the drinking glass
//	icon states.

/obj/item/reagent_containers/food/drinks/shaker
	name = "shaker"
	desc = "A metal shaker to mix drinks in."
	icon_state = "shaker"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = "5;10;15;25;30;60" //Professional bartender should be able to transfer as much as needed
	volume = 120
	center_of_mass = "x=17;y=10"

/obj/item/reagent_containers/food/drinks/teapot
	name = "teapot"
	desc = "An elegant teapot. It simply oozes class."
	icon_state = "teapot"
	item_state = "teapot"
	amount_per_transfer_from_this = 10
	volume = 120
	center_of_mass = "x=17;y=7"

/obj/item/reagent_containers/food/drinks/pitcher
	name = "pitcher"
	desc = "Everyone's best friend in the morning."
	icon_state = "pitcher"
	volume = 120
	amount_per_transfer_from_this = 10
	center_of_mass = "x=16;y=9"
	filling_states = "15;30;50;70;85;100"
	base_icon = "pitcher"

/obj/item/reagent_containers/food/drinks/flask
	name = "\improper Captain's flask"
	desc = "A metal flask belonging to the captain."
	icon_state = "flask"
	volume = 60
	center_of_mass = "x=17;y=7"

/obj/item/reagent_containers/food/drinks/flask/shiny
	name = "shiny flask"
	desc = "A shiny metal flask. It appears to have a Greek symbol inscribed on it."
	icon_state = "shinyflask"

/obj/item/reagent_containers/food/drinks/flask/lithium
	name = "lithium flask"
	desc = "A flask with a Lithium Atom symbol on it."
	icon_state = "lithiumflask"

/obj/item/reagent_containers/food/drinks/flask/detflask
	name = "\improper Detective's flask"
	desc = "A metal flask with a leather band and golden badge belonging to the detective."
	icon_state = "detflask"
	volume = 60
	center_of_mass = "x=17;y=8"

/obj/item/reagent_containers/food/drinks/flask/barflask
	name = "flask"
	desc = "For those who can't be bothered to hang out at the bar to drink."
	icon_state = "barflask"
	volume = 60
	center_of_mass = "x=17;y=7"

/obj/item/reagent_containers/food/drinks/flask/vacuumflask
	name = "vacuum flask"
	desc = "Keeping your drinks at the perfect temperature since 1892."
	icon_state = "vacuumflask"
	volume = 60
	center_of_mass = "x=15;y=4"

/obj/item/reagent_containers/food/drinks/coffeecup
	name = "coffee cup"
	desc = "A plain white coffee cup."
	icon_state = "coffeecup"
	item_state = "coffee"
	volume = 30
	center_of_mass = "x=15;y=13"
	filling_states = "40;80;100"
	base_name = "cup"
	base_icon = "coffeecup"

/obj/item/reagent_containers/food/drinks/coffeecup/black
	name = "black coffee cup"
	desc = "A sleek black coffee cup."
	icon_state = "coffeecup_black"
	base_name = "black cup"

/obj/item/reagent_containers/food/drinks/coffeecup/green
	name = "green coffee cup"
	desc = "A pale green and pink coffee cup."
	icon_state = "coffeecup_green"
	base_name = "green cup"

/obj/item/reagent_containers/food/drinks/coffeecup/heart
	name = "heart coffee cup"
	desc = "A white coffee cup, it prominently features a red heart."
	icon_state = "coffeecup_heart"
	base_name = "heart cup"

/obj/item/reagent_containers/food/drinks/coffeecup/SCG
	name = "SCG coffee cup"
	desc = "A blue coffee cup emblazoned with the crest of the Sol Central Government."
	icon_state = "coffeecup_SCG"
	base_name = "SCG cup"

/obj/item/reagent_containers/food/drinks/coffeecup/NT
	name = "NT coffee cup"
	desc = "A red NanoTrasen coffee cup. 90% Guaranteed to not be laced with mind-control drugs."
	icon_state = "coffeecup_NT"
	base_name = "NT cup"

/obj/item/reagent_containers/food/drinks/coffeecup/one
	name = "#1 coffee cup"
	desc = "A white coffee cup, prominently featuring a #1."
	icon_state = "coffeecup_one"
	base_name = "#1 cup"

/obj/item/reagent_containers/food/drinks/coffeecup/punitelli
	name = "#1 monkey coffee cup"
	desc = "A white coffee cup, prominently featuring a \"#1 monkey\"."
	icon_state = "coffeecup_punitelli"
	base_name = "#1 monkey cup"

/obj/item/reagent_containers/food/drinks/coffeecup/punitelli/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/banana, 30)
	update_icon()

/obj/item/reagent_containers/food/drinks/coffeecup/rainbow
	name = "rainbow coffee cup"
	desc = "A rainbow coffee cup. The colors are almost as blinding as a welder."
	icon_state = "coffeecup_rainbow"
	base_name = "rainbow cup"

/obj/item/reagent_containers/food/drinks/coffeecup/metal
	name = "metal coffee cup"
	desc = "A metal coffee cup. You're not sure which metal."
	icon_state = "coffeecup_metal"
	base_name = "metal cup"
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	obj_flags = OBJ_FLAG_CONDUCTIBLE

/obj/item/reagent_containers/food/drinks/coffeecup/STC
	name = "TCC coffee cup"
	desc = "A coffee cup adorned with the flag of the Terran Colonial Confederation, for when you need some espionage charges to go with your morning coffee."
	icon_state = "coffeecup_STC"
	base_name = "TCC cup"

/obj/item/reagent_containers/food/drinks/coffeecup/pawn
	name = "pawn coffee cup"
	desc = "A black coffee cup adorned with the image of a red chess pawn."
	icon_state = "coffeecup_pawn"
	base_name = "pawn cup"

/obj/item/reagent_containers/food/drinks/coffeecup/diona
	name = "diona nymph coffee cup"
	desc = "A green coffee cup featuring the image of a diona nymph."
	icon_state = "coffeecup_diona"
	base_name = "diona cup"

/obj/item/reagent_containers/food/drinks/coffeecup/britcup
	name = "british coffee cup"
	desc = "A coffee cup with the British flag emblazoned on it."
	icon_state = "coffeecup_brit"
	base_name = "british cup"

/obj/item/reagent_containers/food/drinks/coffeecup/tall
	name = "tall coffee cup"
	desc = "An unreasonably tall coffee cup, for when you really need to wake up in the morning."
	icon_state = "coffeecup_tall"
	volume = 60
	center_of_mass = "x=15;y=19"
	filling_states = "50;70;90;100"
	base_name = "tall cup"
	base_icon = "coffeecup_tall"

/obj/item/reagent_containers/food/drinks/skullgoblet
	name = "skull goblet"
	desc = "Great for dancing on the barrows of your enemies."
	icon_state = "skullcup"
	item_state = "skullmask"
	w_class = ITEM_SIZE_NORMAL
	volume = 50
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	obj_flags = OBJ_FLAG_CONDUCTIBLE

/obj/item/reagent_containers/food/drinks/skullgoblet/gold
	name = "golden skull goblet"
	desc = "<b>Perfect</b> for dancing on the barrows of your enemies."
	icon_state = "skullcup_gold"
