//Food items that are eaten normally and don't leave anything behind.
/obj/item/reagent_containers/food/snacks
	name = "snack"
	desc = "Yummy!"
	icon = 'icons/obj/food.dmi'
	icon_state = null
	var/bitesize = 1
	var/bitecount = 0
	var/slice_path
	var/slices_num
	var/dried_type = null
	var/dry = 0
	var/nutriment_amt = 0
	var/list/nutriment_desc = list("food" = 1)
	center_of_mass = "x=16;y=16"
	w_class = ITEM_SIZE_SMALL

/obj/item/reagent_containers/food/snacks/Initialize()
	. = ..()
	if(nutriment_amt)
		reagents.add_reagent(/datum/reagent/nutriment,nutriment_amt,nutriment_desc)

	//Placeholder for effect that trigger on eating that aren't tied to reagents.
/obj/item/reagent_containers/food/snacks/proc/On_Consume(mob/M)
	if(!reagents.total_volume)
		M.visible_message("<span class='notice'>[M] finishes eating \the [src].</span>","<span class='notice'>You finish eating \the [src].</span>")

		M.drop_item()
		if(trash)
			if(ispath(trash,/obj/item))
				var/obj/item/TrashItem = new trash(get_turf(M))
				M.put_in_hands(TrashItem)
			else if(istype(trash,/obj/item))
				M.put_in_hands(trash)
		if(istype(loc, /obj/item/organ))
			var/obj/item/organ/O = loc
			O.organ_eaten(M)
		qdel(src)
	return

/obj/item/reagent_containers/food/snacks/attack_self(mob/user)
	return

/obj/item/reagent_containers/food/snacks/attack(mob/M, mob/user, def_zone)
	if(!reagents.total_volume)
		to_chat(user, SPAN("danger", "None of [src] left!"))
		user.drop_from_inventory(src)
		qdel(src)
		return FALSE

	if(!is_open_container())
		to_chat(user, SPAN("danger", "[src] must be opened first!"))
		return FALSE

	if(istype(M, /mob/living/carbon))
		//TODO: replace with standard_feed_mob() call.
		var/mob/living/carbon/C = M
		var/fullness = C.get_fullness()
		if(C == user)								//If you're eating it yourself
			if(ishuman(C))
				var/mob/living/carbon/human/H = M
				if(!H.check_has_mouth())
					to_chat(user, "Where do you intend to put \the [src]? You don't have a mouth!")
					return
				var/obj/item/blocked = H.check_mouth_coverage()
				if(blocked)
					to_chat(user, SPAN("warning", "\The [blocked] is in the way!"))
					return
				fullness /= H.body_build.stomach_capacity // Here we take body build into consideration

			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN) //puts a limit on how fast people can eat/drink things
			if(fullness <= STOMACH_FULLNESS_SUPER_LOW)
				to_chat(C, SPAN("danger", "You hungrily chew out a piece of [src] and gobble it!"))
			if(fullness > STOMACH_FULLNESS_SUPER_LOW && fullness <= STOMACH_FULLNESS_LOW)
				to_chat(C, SPAN("notice", "You hungrily begin to eat [src]."))
			if(fullness > STOMACH_FULLNESS_LOW && fullness <= STOMACH_FULLNESS_MEDIUM)
				to_chat(C, SPAN("notice", "You take a bite of [src]."))
			if(fullness > STOMACH_FULLNESS_MEDIUM && fullness <= STOMACH_FULLNESS_HIGH)
				to_chat(C, SPAN("notice", "You unwillingly chew a bit of [src]."))
			if(fullness > STOMACH_FULLNESS_HIGH && fullness <= STOMACH_FULLNESS_SUPER_HIGH)
				to_chat(C, SPAN("danger", "You force yourself to swallow some [src]."))
			if(fullness > STOMACH_FULLNESS_SUPER_HIGH)
				to_chat(C, SPAN("danger", "You cannot force any more of [src] to go down your throat."))
				return FALSE
		else
			if(!M.can_force_feed(user, src))
				return

			if(fullness <= STOMACH_FULLNESS_SUPER_HIGH)
				user.visible_message(SPAN("danger", "[user] attempts to feed [M] [src]."))
			else
				user.visible_message(SPAN("danger", "[user] cannot force anymore of [src] down [M]'s throat."))
				return FALSE

			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
			if(!do_mob(user, M))
				return

			if(user.get_active_hand() != src)
				return

			var/contained = reagentlist()
			admin_attack_log(user, M, "Fed the victim with [name] (Reagents: [contained])", "Was fed [src] (Reagents: [contained])", "used [src] (Reagents: [contained]) to feed")
			user.visible_message(SPAN("danger", "[user] feeds [M] [src]."))

		if(reagents)								//Handle ingestion of the reagent.
			playsound(M.loc, SFX_EAT, rand(45, 60), FALSE)
			if(reagents.total_volume)
				if(reagents.total_volume > bitesize)
					reagents.trans_to_mob(M, bitesize, CHEM_INGEST)
				else
					reagents.trans_to_mob(M, reagents.total_volume, CHEM_INGEST)
				bitecount++
				update_icon()
				On_Consume(M)
			return TRUE

	return FALSE

/obj/item/reagent_containers/food/snacks/proc/get_bitecount()
	if (bitecount==0)
		return
	else if (bitecount==1)
		return SPAN_NOTICE("\n\The [src] was bitten by someone!")
	else if (bitecount<=3)
		return SPAN_NOTICE("\n\The [src] was bitten [bitecount] time\s!")
	else
		return SPAN_NOTICE("\n\The [src] was bitten multiple times!")

/obj/item/reagent_containers/food/snacks/examine(mob/user)
	. = ..()
	if(get_dist(src, user) > 1)
		return
	. += get_bitecount()

/obj/item/reagent_containers/food/snacks/throw_impact(atom/hit_atom, speed, thrown_with, target_zone)
	var/mob/living/carbon/human/H = hit_atom
	if(!istype(H) || !istype(thrown_with, /obj/item/gun/launcher) || target_zone != BP_MOUTH || !reagents.total_volume || !is_open_container() || !H.check_has_mouth() || H.check_mouth_coverage() || H.get_fullness() >= STOMACH_FULLNESS_SUPER_HIGH)
		return ..(hit_atom, speed)

	if(reagents.total_volume > bitesize * 2)
		reagents.trans_to_mob(H, bitesize * 2, CHEM_INGEST)
	else
		reagents.trans_to_mob(H, reagents.total_volume, CHEM_INGEST)
	bitecount++
	throwing = FALSE
	update_icon()
	On_Consume(H)

	playsound(H.loc, SFX_EAT, rand(45, 60), FALSE)
	if(H.stat == CONSCIOUS)
		to_chat(H, SPAN("notice", "You take a bite of [src]."))

/obj/item/reagent_containers/food/snacks/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/storage))
		..() // -> item/attackby()
		return

	// Eating with forks
	if(istype(W,/obj/item/material/kitchen/utensil))
		var/obj/item/material/kitchen/utensil/U = W
		if(U.scoop_food)
			if(!U.reagents)
				U.create_reagents(5)

			if (U.reagents.total_volume > 0)
				to_chat(user, "<span class='warning'>You already have something on your [U].</span>")
				return

			user.visible_message( \
				"\The [user] scoops up some [src] with \the [U]!", \
				"<span class='notice'>You scoop up some [src] with \the [U]!</span>" \
			)

			src.bitecount++
			U.overlays.Cut()
			U.loaded = "[src]"
			var/image/I = new(U.icon, "loadedfood")
			I.color = src.filling_color
			U.overlays += I

			if(!reagents)
				crash_with("[type] doesnt has a reagent holder [W.type]! Well, it will be [QDELETED(src) ? "" : "not"] deleted.")
			else
				reagents.trans_to_obj(U, min(reagents.total_volume,5))
				if (reagents.total_volume <= 0)
					qdel(src)

			return

	if(is_sliceable())
		//these are used to allow hiding edge items in food that is not on a table/tray
		var/can_slice_here = isturf(src.loc) && ((locate(/obj/structure/table) in src.loc) || (locate(/obj/machinery/optable) in src.loc) || (locate(/obj/item/tray) in src.loc))
		var/hide_item = !has_edge(W) || !can_slice_here

		if(hide_item)
			if(W.w_class >= src.w_class || is_robot_module(W))
				return
			if(length(contents) > 3)
				to_chat(user, SPAN_WARNING("There's too much stuff inside!"))
				return

			to_chat(user, "<span class='warning'>You slip \the [W] inside \the [src].</span>")
			user.drop_from_inventory(W, src)
			add_fingerprint(user)
			contents += W
			return

		if (has_edge(W))
			if (!can_slice_here)
				to_chat(user, "<span class='warning'>You cannot slice \the [src] here! You need a table or at least a tray to do it.</span>")
				return

			var/slices_lost = 0
			if (W.w_class > 3)
				user.visible_message("<span class='notice'>\The [user] crudely slices \the [src] with [W]!</span>", "<span class='notice'>You crudely slice \the [src] with your [W]!</span>")
				slices_lost = rand(1, min(1, round(slices_num / 2)))
			else
				user.visible_message("<span class='notice'>\The [user] slices \the [src]!</span>", "<span class='notice'>You slice \the [src]!</span>")

			var/reagents_per_slice = reagents.total_volume / slices_num
			for(var/i = 1 to (slices_num - slices_lost))
				var/obj/slice = new slice_path(src.loc)
				reagents.trans_to_obj(slice, reagents_per_slice)
			qdel(src)
			return

/obj/item/reagent_containers/food/snacks/proc/is_sliceable()
	return (slices_num && slice_path && slices_num > 0)

/obj/item/reagent_containers/food/snacks/Destroy()
	if(contents)
		for(var/atom/movable/something in contents)
			something.dropInto(loc)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
/// FOOD END
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/food/snacks/attack_generic(mob/living/user)
	if(!isanimal(user) && !isalien(user))
		return
	user.visible_message("<b>[user]</b> nibbles away at \the [src].","You nibble away at \the [src].")
	bitecount++
	if(reagents && user.reagents)
		reagents.trans_to_mob(user, bitesize, CHEM_INGEST)
	spawn(5)
		if(!src && !user.client)
			user.custom_emote(1,"[pick("burps", "cries for more", "burps twice", "looks at the area where the food was")]")
			qdel(src)
	On_Consume(user)

//////////////////////////////////////////////////
////////////////////////////////////////////Snacks
//////////////////////////////////////////////////
//Items in the "Snacks" subcategory are food items that people actually eat. The key points are that they are created
//	already filled with reagents and are destroyed when empty. Additionally, they make a "munching" noise when eaten.

//Notes by Darem: Food in the "snacks" subtype can hold a maximum of 50 units Generally speaking, you don't want to go over 40
//	total for the item because you want to leave space for extra condiments. If you want effect besides healing, add a reagent for
//	it. Try to stick to existing reagents when possible (so if you want a stronger healing effect, just use Tricordrazine). On use
//	effect (such as the old officer eating a donut code) requires a unique reagent (unless you can figure out a better way).

//The nutriment reagent and bitesize variable replace the old heal_amt and amount variables. Each unit of nutriment is equal to
//	2 of the old heal_amt variable. Bitesize is the rate at which the reagents are consumed. So if you have 6 nutriment and a
//	bitesize of 2, then it'll take 3 bites to eat. Unlike the old system, the contained reagents are evenly spread among all
//	the bites. No more contained reagents = no more bites.

//Here is an example of the new formatting for anyone who wants to add more food items.
///obj/item/reagent_containers/food/snacks/xenoburger			//Identification path for the object.
//	name = "Xenoburger"													//Name that displays in the UI.
//	desc = "Smells caustic. Tastes like heresy."						//Duh
//	icon_state = "xburger"												//Refers to an icon in food.dmi
//	New()																//Don't mess with this.
//		..()															//Same here.
//		reagents.add_reagent(/datum/reagent/xenomicrobes, 10)						//This is what is in the food item. you may copy/paste
//		reagents.add_reagent(/datum/reagent/nutriment, 2)							//	this line of code for all the contents.
//		bitesize = 3													//This is the amount each bite consumes.




/obj/item/reagent_containers/food/snacks/aesirsalad
	name = "Aesir salad"
	desc = "Probably too incredible for mortal men to fully enjoy."
	icon_state = "aesirsalad"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#468c00"
	center_of_mass = "x=17;y=11"
	nutriment_amt = 8
	nutriment_desc = list("apples" = 3,"salad" = 5)

/obj/item/reagent_containers/food/snacks/aesirsalad/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/doctor_delight, 8)
	reagents.add_reagent(/datum/reagent/tricordrazine, 8)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/candy_corn
	name = "candy corn"
	desc = "It's a handful of candy corn. Cannot be stored in a detective's hat, alas."
	icon_state = "candy_corn"
	filling_color = "#fffcb0"
	center_of_mass = "x=14;y=10"
	nutriment_amt = 4
	nutriment_desc = list("candy corn" = 4)

/obj/item/reagent_containers/food/snacks/candy_corn/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 4)
	reagents.add_reagent(/datum/reagent/sugar, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/cookie
	name = "cookie"
	desc = "COOKIE!!!"
	icon_state = "COOKIE!!!"
	filling_color = "#dbc94f"
	center_of_mass = "x=17;y=18"
	nutriment_amt = 5
	nutriment_desc = list("sweetness" = 3, "cookie" = 2)

/obj/item/reagent_containers/food/snacks/cookie/Initialize()
	. = ..()
	bitesize = 1

/obj/item/reagent_containers/food/snacks/chocolatebar
	name = "Chocolate Bar"
	desc = "Such sweet, fattening food."
	icon_state = "chocolatebar"
	filling_color = "#7d5f46"
	center_of_mass = "x=15;y=15"
	nutriment_amt = 2
	nutriment_desc = list("chocolate" = 5)

/obj/item/reagent_containers/food/snacks/chocolatebar/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/sugar, 2)
	reagents.add_reagent(/datum/reagent/nutriment/coco, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/chocolateegg
	name = "Chocolate Egg"
	desc = "Such sweet, fattening food."
	icon_state = "chocolateegg"
	filling_color = "#7d5f46"
	center_of_mass = "x=16;y=13"
	nutriment_amt = 3
	nutriment_desc = list("chocolate" = 5)

/obj/item/reagent_containers/food/snacks/chocolateegg/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/sugar, 2)
	reagents.add_reagent(/datum/reagent/nutriment/coco, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/donut
	name = "donut"
	desc = "Goes great with Robust Coffee."
	icon_state = "donut1"
	filling_color = "#d9c386"
	var/overlay_state = "box-donut1"
	center_of_mass = "x=13;y=16"
	nutriment_desc = list("sweetness", "donut")

/obj/item/reagent_containers/food/snacks/donut/normal
	name = "donut"
	desc = "Goes great with Robust Coffee."
	icon_state = "donut1"
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/donut/normal/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 1)
	src.bitesize = 3
	if(prob(30))
		src.icon_state = "donut2"
		src.overlay_state = "box-donut2"
		src.SetName("frosted donut")
		reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 2)
		center_of_mass = "x=19;y=16"

/obj/item/reagent_containers/food/snacks/donut/chaos
	name = "Chaos Donut"
	desc = "Like life, it never quite tastes the same."
	icon_state = "donut1"
	filling_color = "#ed11e6"
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/donut/chaos/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 1)
	bitesize = 10
	var/chaosselect = pick(1,2,3,4,5,6,7,8,9,10)
	switch(chaosselect)
		if(1)
			reagents.add_reagent(/datum/reagent/nutriment, 3)
		if(2)
			reagents.add_reagent(/datum/reagent/capsaicin, 3)
		if(3)
			reagents.add_reagent(/datum/reagent/frostoil, 3)
		if(4)
			reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 3)
		if(5)
			reagents.add_reagent(/datum/reagent/toxin/plasma, 3)
		if(6)
			reagents.add_reagent(/datum/reagent/nutriment/coco, 3)
		if(7)
			reagents.add_reagent(/datum/reagent/metroidjelly, 3)
		if(8)
			reagents.add_reagent(/datum/reagent/drink/juice/banana, 3)
		if(9)
			reagents.add_reagent(/datum/reagent/drink/juice/berry, 3)
		if(10)
			reagents.add_reagent(/datum/reagent/tricordrazine, 3)
	if(prob(30))
		src.icon_state = "donut2"
		src.overlay_state = "box-donut2"
		src.SetName("Frosted Chaos Donut")
		reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 2)


/obj/item/reagent_containers/food/snacks/donut/jelly
	name = "Jelly Donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ed1169"
	center_of_mass = "x=16;y=11"
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/donut/jelly/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 1)
	reagents.add_reagent(/datum/reagent/drink/juice/berry, 5)
	bitesize = 5
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.SetName("Frosted Jelly Donut")
		reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 2)

/obj/item/reagent_containers/food/snacks/donut/metroidjelly
	name = "Jelly Donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ed1169"
	center_of_mass = "x=16;y=11"
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/donut/metroidjelly/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 1)
	reagents.add_reagent(/datum/reagent/metroidjelly, 5)
	bitesize = 5
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.SetName("Frosted Jelly Donut")
		reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 2)

/obj/item/reagent_containers/food/snacks/donut/cherryjelly
	name = "Jelly Donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ed1169"
	center_of_mass = "x=16;y=11"
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/donut/cherryjelly/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 1)
	reagents.add_reagent(/datum/reagent/nutriment/cherryjelly, 5)
	bitesize = 5
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.SetName("Frosted Jelly Donut")
		reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 2)

/obj/item/reagent_containers/food/snacks/vegg
	name = "vegg"
	desc = "So... It's more like a seed, right?"
	icon_state = "egg-vegan"
	filling_color = "#70bf70"
	volume = 10
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/egg/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 3)

/obj/item/reagent_containers/food/snacks/egg
	name = "egg"
	desc = "An egg!"
	icon_state = "egg"
	filling_color = "#fdffd1"
	volume = 10
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/egg/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein/egg, 3)

/obj/item/reagent_containers/food/snacks/egg/afterattack(obj/O as obj, mob/user as mob, proximity)
	if(istype(O,/obj/machinery/microwave))
		return ..()
	if(!(proximity && O.is_open_container()))
		return
	to_chat(user, "You crack \the [src] into \the [O].")
	reagents.trans_to(O, reagents.total_volume)
	user.drop_from_inventory(src)
	qdel(src)

/obj/item/reagent_containers/food/snacks/egg/throw_impact(atom/hit_atom)
	..()
	if(QDELETED(src))
		return // Could be happened hitby()
	new /obj/effect/decal/cleanable/egg_smudge(src.loc)
	src.reagents.splash(hit_atom, src.reagents.total_volume)
	src.visible_message("<span class='warning'>\The [src] has been squashed!</span>","<span class='warning'>You hear a smack.</span>")
	qdel(src)

/obj/item/reagent_containers/food/snacks/egg/attackby(obj/item/W as obj, mob/user as mob)
	if(istype( W, /obj/item/pen/crayon ))
		var/obj/item/pen/crayon/C = W
		var/clr = C.colourName

		if(!(clr in list("blue","green","mime","orange","purple","rainbow","red","yellow")))
			to_chat(usr, "<span class='notice'>The egg refuses to take on this color!</span>")
			return

		to_chat(usr, "<span class='notice'>You color \the [src] [clr]</span>")
		icon_state = "egg-[clr]"
	else
		..()

/obj/item/reagent_containers/food/snacks/egg/randomcolor/Initialize()
	. = ..()
	var/clr = pick("blue","green","mime","orange","purple","rainbow","red","yellow")
	icon_state = "egg-[clr]"

/obj/item/reagent_containers/food/snacks/egg/blue
	icon_state = "egg-blue"

/obj/item/reagent_containers/food/snacks/egg/green
	icon_state = "egg-green"

/obj/item/reagent_containers/food/snacks/egg/mime
	icon_state = "egg-mime"

/obj/item/reagent_containers/food/snacks/egg/orange
	icon_state = "egg-orange"

/obj/item/reagent_containers/food/snacks/egg/purple
	icon_state = "egg-purple"

/obj/item/reagent_containers/food/snacks/egg/rainbow
	icon_state = "egg-rainbow"

/obj/item/reagent_containers/food/snacks/egg/red
	icon_state = "egg-red"

/obj/item/reagent_containers/food/snacks/egg/yellow
	icon_state = "egg-yellow"

/obj/item/reagent_containers/food/snacks/egg/robot
	name = "robot egg"
	icon_state = "egg-robot"

/obj/item/reagent_containers/food/snacks/egg/robot/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nanites, 1)

/obj/item/reagent_containers/food/snacks/egg/golden
	name = "golden egg"
	icon_state = "egg-golden"

/obj/item/reagent_containers/food/snacks/egg/golden/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/gold, 3)

/obj/item/reagent_containers/food/snacks/egg/plasma
	name = "plasma egg"
	icon_state = "egg-plasma"

/obj/item/reagent_containers/food/snacks/egg/plasma/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin/plasma, 3)

/obj/item/reagent_containers/food/snacks/friedegg
	name = "Fried egg"
	desc = "A fried egg, with a touch of salt and pepper."
	icon_state = "friedegg"
	filling_color = "#ffdf78"
	center_of_mass = "x=16;y=14"

/obj/item/reagent_containers/food/snacks/friedegg/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	reagents.add_reagent(/datum/reagent/blackpepper, 1)
	bitesize = 1

/obj/item/reagent_containers/food/snacks/boiledegg
	name = "Boiled egg"
	desc = "A hard boiled egg."
	icon_state = "egg"
	filling_color = "#ffffff"

/obj/item/reagent_containers/food/snacks/boiledegg/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)

/obj/item/reagent_containers/food/snacks/organ
	name = "organ"
	desc = "It's good for you."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "appendix"
	filling_color = "#e00d34"
	center_of_mass = "x=16;y=16"

/obj/item/reagent_containers/food/snacks/organ/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, rand(3,5))
	reagents.add_reagent(/datum/reagent/toxin, rand(1,3))
	src.bitesize = 3

/obj/item/reagent_containers/food/snacks/tofu
	name = "Tofu"
	icon_state = "tofu"
	desc = "We all love tofu."
	filling_color = "#fffee0"
	center_of_mass = "x=17;y=10"
	nutriment_amt = 3
	nutriment_desc = list("tofu" = 3, "goeyness" = 3)

/obj/item/reagent_containers/food/snacks/tofu/Initialize()
	. = ..()
	src.bitesize = 3

/obj/item/reagent_containers/food/snacks/tofurkey
	name = "Tofurkey"
	desc = "A fake turkey made from tofu."
	icon_state = "tofurkey"
	filling_color = "#fffee0"
	center_of_mass = "x=16;y=8"
	nutriment_amt = 12
	nutriment_desc = list("turkey" = 3, "tofu" = 5, "goeyness" = 4)

/obj/item/reagent_containers/food/snacks/tofurkey/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/stuffing
	name = "Stuffing"
	desc = "Moist, peppery breadcrumbs for filling the body cavities of dead birds. Dig in!"
	icon_state = "stuffing"
	filling_color = "#c9ac83"
	center_of_mass = "x=16;y=10"
	nutriment_amt = 3
	nutriment_desc = list("dryness" = 2, "bread" = 2)

/obj/item/reagent_containers/food/snacks/stuffing/Initialize()
	. = ..()
	bitesize = 1

/obj/item/reagent_containers/food/snacks/carpmeat
	name = "carp fillet"
	desc = "A fillet of spess carp meat."
	icon_state = "fishfillet"
	filling_color = "#ffdefe"
	center_of_mass = "x=17;y=13"

/obj/item/reagent_containers/food/snacks/carpmeat/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/toxin/carpotoxin, 6)
	src.bitesize = 6

/obj/item/reagent_containers/food/snacks/fishfingers
	name = "Fish Fingers"
	desc = "A finger of fish."
	icon_state = "fishfingers"
	filling_color = "#ffdefe"
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/fishfingers/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/hugemushroomslice
	name = "huge mushroom slice"
	desc = "A slice from a huge mushroom."
	icon_state = "hugemushroomslice"
	filling_color = "#e0d7c5"
	center_of_mass = "x=17;y=16"
	nutriment_amt = 3
	nutriment_desc = list("raw" = 2, "mushroom" = 2)

/obj/item/reagent_containers/food/snacks/hugemushroomslice/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/psilocybin, 3)
	src.bitesize = 6

/obj/item/reagent_containers/food/snacks/tomatomeat
	name = "tomato slice"
	desc = "A slice from a huge tomato."
	icon_state = "tomatomeat"
	filling_color = "#db0000"
	center_of_mass = "x=17;y=16"
	nutriment_amt = 3
	nutriment_desc = list("raw" = 2, "tomato" = 3)

/obj/item/reagent_containers/food/snacks/tomatomeat/Initialize()
	. = ..()
	src.bitesize = 6

/obj/item/reagent_containers/food/snacks/bearmeat
	name = "bear meat"
	desc = "A very manly slab of meat."
	icon_state = "bearmeat"
	filling_color = "#db0000"
	center_of_mass = "x=16;y=10"

/obj/item/reagent_containers/food/snacks/bearmeat/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 12)
	reagents.add_reagent(/datum/reagent/hyperzine, 5)
	src.bitesize = 3

/obj/item/reagent_containers/food/snacks/faggot
	name = "faggot"
	desc = "A great meal all round."
	icon_state = "faggot"
	filling_color = "#db0000"
	center_of_mass = "x=16;y=16"

/obj/item/reagent_containers/food/snacks/faggot/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/sausage
	name = "Sausage"
	desc = "A piece of mixed, long meat."
	icon_state = "sausage"
	filling_color = "#db0000"
	center_of_mass = "x=16;y=16"

/obj/item/reagent_containers/food/snacks/sausage/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/donkpocket
	name = "Donk-pocket"
	desc = "The food of choice for the seasoned traitor."
	icon_state = "donkpocket"
	filling_color = "#dedeab"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("heartiness" = 1, "dough" = 2)
	nutriment_amt = 2
	var/warm = 0
	var/list/heated_reagents = list(/datum/reagent/tricordrazine = 5)

/obj/item/reagent_containers/food/snacks/donkpocket/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)

/obj/item/reagent_containers/food/snacks/donkpocket/proc/heat()
	if(warm)
		return
	warm = 1
	for(var/reagent in heated_reagents)
		reagents.add_reagent(reagent, heated_reagents[reagent])
	bitesize = 6
	SetName("Warm " + name)
	cooltime()

/obj/item/reagent_containers/food/snacks/donkpocket/proc/cooltime()
	if (warm)
		addtimer(CALLBACK(src, .proc/cooling, warm), 4200)
	return

/obj/item/reagent_containers/food/snacks/donkpocket/proc/cooling(warm)
	if(!warm)
		return
	warm = 0
	for(var/reagent in heated_reagents)
		reagents.del_reagent(reagent)
	SetName(initial(name))

/obj/item/reagent_containers/food/snacks/donkpocket/sinpocket
	name = "\improper Sin-pocket"
	desc = "The food of choice for the veteran. Do <B>NOT</B> overconsume."
	filling_color = "#6d6d00"
	heated_reagents = list(/datum/reagent/tricordrazine = 5, /datum/reagent/drink/doctor_delight = 5, /datum/reagent/hyperzine = 0.75, /datum/reagent/synaptizine = 0.25)
	var/has_been_heated = 0

/obj/item/reagent_containers/food/snacks/donkpocket/sinpocket/Initialize()
	. = ..()
	bitesize = 5

/obj/item/reagent_containers/food/snacks/donkpocket/sinpocket/attack_self(mob/user)
	if(has_been_heated)
		to_chat(user, "<span class='notice'>The heating chemicals have already been spent.</span>")
		return
	has_been_heated = 1
	user.visible_message("<span class='notice'>[user] crushes \the [src] package.</span>", "You crush \the [src] package and feel a comfortable heat build up.")
	addtimer(CALLBACK(src, .proc/heat, user), 200)

/obj/item/reagent_containers/food/snacks/donkpocket/sinpocket/heat(user)
	if(user)
		to_chat(user, "You think \the [src] is ready to eat about now.")
	. = ..()

/obj/item/reagent_containers/food/snacks/brainburger
	name = "brainburger"
	desc = "A strange looking burger. It looks almost sentient."
	icon_state = "brainburger"
	filling_color = "#f2b6ea"
	center_of_mass = "x=15;y=11"

/obj/item/reagent_containers/food/snacks/brainburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	reagents.add_reagent(/datum/reagent/alkysine, 6)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/ghostburger
	name = "Ghost Burger"
	desc = "Spooky! It doesn't look very filling."
	icon_state = "ghostburger"
	filling_color = "#fff2ff"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("buns" = 3, "spookiness" = 3)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/ghostburger/Initialize()
	. = ..()
	bitesize = 2


/obj/item/reagent_containers/food/snacks/human
	var/hname = ""
	var/job = null
	filling_color = "#d63c3c"

/obj/item/reagent_containers/food/snacks/human/burger
	name = "-burger"
	desc = "A bloody burger."
	icon_state = "hburger"
	center_of_mass = "x=16;y=11"

/obj/item/reagent_containers/food/snacks/human/burger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/cheeseburger
	name = "cheeseburger"
	desc = "The cheese adds a good flavor."
	icon_state = "cheeseburger"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("cheese" = 2, "bun" = 2)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/cheeseburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)

/obj/item/reagent_containers/food/snacks/plainburger
	name = "burger"
	desc = "The cornerstone of every nutritious breakfast."
	icon_state = "hburger"
	filling_color = "#d63c3c"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("bun" = 2)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/plainburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/fishburger
	name = "Fillet -o- Carp Sandwich"
	desc = "Almost like a carp is yelling somewhere... Give me back that fillet -o- carp, give me that carp."
	icon_state = "fishburger"
	filling_color = "#ffdefe"
	center_of_mass = "x=16;y=10"

/obj/item/reagent_containers/food/snacks/fishburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/tofuburger
	name = "Tofu Burger"
	desc = "What.. is that meat?"
	icon_state = "tofuburger"
	filling_color = "#fffee0"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("bun" = 2, "pseudo-soy meat" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/tofuburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/roburger
	name = "roburger"
	desc = "The lettuce is the only organic component. Beep."
	icon_state = "roburger"
	filling_color = "#cccccc"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("bun" = 2, "metal" = 3)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/roburger/Initialize()
	. = ..()
	if(prob(5))
		reagents.add_reagent(/datum/reagent/nanites, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/roburgerbig
	name = "roburger"
	desc = "This massive patty looks like poison. Beep."
	icon_state = "roburger"
	filling_color = "#cccccc"
	volume = 100
	center_of_mass = "x=16;y=11"

/obj/item/reagent_containers/food/snacks/roburgerbig/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nanites, 100)
	bitesize = 0.1

/obj/item/reagent_containers/food/snacks/xenoburger
	name = "xenoburger"
	desc = "Smells caustic. Tastes like heresy."
	icon_state = "xburger"
	filling_color = "#43de18"
	center_of_mass = "x=16;y=11"

/obj/item/reagent_containers/food/snacks/xenoburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 8)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/clownburger
	name = "Clown Burger"
	desc = "This tastes funny..."
	icon_state = "clownburger"
	filling_color = "#ff00ff"
	center_of_mass = "x=17;y=12"
	nutriment_desc = list("bun" = 2, "clown shoe" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/clownburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/mimeburger
	name = "Mime Burger"
	desc = "Its taste defies language."
	icon_state = "mimeburger"
	filling_color = "#ffffff"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("bun" = 2, "mime paint" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/mimeburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/omelette
	name = "Omelette Du Fromage"
	desc = "That's all you can say!"
	icon_state = "omelette"
	trash = /obj/item/trash/dish/plate
	filling_color = "#fff9a8"
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/omelette/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 8)
	bitesize = 1

/obj/item/reagent_containers/food/snacks/muffin
	name = "Muffin"
	desc = "A delicious and spongy little cake."
	icon_state = "muffin"
	filling_color = "#e0cf9b"
	center_of_mass = "x=17;y=4"
	nutriment_desc = list("sweetness" = 3, "muffin" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/muffin/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/pie
	name = "Banana Cream Pie"
	desc = "Just like back home, on clown planet! HONK!"
	icon_state = "pie"
	trash = /obj/item/trash/dish/plate
	filling_color = "#fbffb8"
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("pie" = 3, "cream" = 2)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/pie/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/banana,5)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/pie/throw_impact(atom/hit_atom)
	..()
	new /obj/effect/decal/cleanable/pie_smudge(src.loc)
	src.visible_message("<span class='danger'>\The [src.name] splats.</span>","<span class='danger'>You hear a splat.</span>")
	qdel(src)

/obj/item/reagent_containers/food/snacks/berryclafoutis
	name = "Berry Clafoutis"
	desc = "No black birds, this is a good sign."
	icon_state = "berryclafoutis"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("sweetness" = 2, "pie" = 3)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/berryclafoutis/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/berry, 5)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/waffles
	name = "waffles"
	desc = "Mmm, waffles."
	icon_state = "waffles"
	trash = /obj/item/trash/dish/baking_sheet
	filling_color = "#e6deb5"
	center_of_mass = "x=15;y=11"
	nutriment_desc = list("waffle" = 8)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/waffles/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/pancakes
	name = "pancakes"
	desc = "Pancakes with blueberries, delicious."
	icon_state = "pancakes"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=11"
	nutriment_desc = list("pancake" = 8)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/pancakes/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/eggplantparm
	name = "Eggplant Parmigiana"
	desc = "The only good recipe for eggplant."
	icon_state = "eggplantparm"
	trash = /obj/item/trash/dish/plate
	filling_color = "#4d2f5e"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("cheese" = 3, "eggplant" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/eggplantparm/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/soylentgreen
	name = "Soylent Green"
	desc = "Not made of people. Honest." //Totally people.
	icon_state = "soylent_green"
	trash = /obj/item/trash/dish/baking_sheet
	filling_color = "#b8e6b5"
	center_of_mass = "x=15;y=11"

/obj/item/reagent_containers/food/snacks/soylentgreen/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/soylenviridians
	name = "Soylen Virdians"
	desc = "Not made of people. Honest." //Actually honest for once.
	icon_state = "soylent_yellow"
	trash = /obj/item/trash/dish/baking_sheet
	filling_color = "#e6fa61"
	center_of_mass = "x=15;y=11"

	nutriment_desc = list("some sort of protein" = 10) //seasoned VERY well.
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/soylenviridians/Initialize()
	. = ..()
	bitesize = 2


/obj/item/reagent_containers/food/snacks/meatpie
	name = "Meat-pie"
	icon_state = "meatpie"
	desc = "An old barber recipe, very delicious!"
	trash = /obj/item/trash/dish/plate
	filling_color = "#948051"
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/meatpie/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/tofupie
	name = "Tofu-pie"
	icon_state = "meatpie"
	desc = "A delicious tofu pie."
	trash = /obj/item/trash/dish/plate
	filling_color = "#fffee0"
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("tofu" = 2, "pie" = 8)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/tofupie/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/amanita_pie
	name = "amanita pie"
	desc = "Sweet and tasty poison pie."
	icon_state = "amanita_pie"
	filling_color = "#ffcccc"
	center_of_mass = "x=17;y=9"
	nutriment_desc = list("sweetness" = 3, "mushroom" = 3, "pie" = 2)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/amanita_pie/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin/amatoxin, 3)
	reagents.add_reagent(/datum/reagent/psilocybin, 1)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/plump_pie
	name = "plump pie"
	desc = "I bet you love stuff made out of plump helmets!"
	icon_state = "plump_pie"
	filling_color = "#b8279b"
	center_of_mass = "x=17;y=9"
	nutriment_desc = list("heartiness" = 2, "mushroom" = 3, "pie" = 3)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/plump_pie/Initialize()
	. = ..()
	if(prob(10))
		name = "exceptional plump pie"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump pie!"
		reagents.add_reagent(/datum/reagent/tricordrazine, 5)
		bitesize = 2

/obj/item/reagent_containers/food/snacks/xemeatpie
	name = "Xeno-pie"
	icon_state = "xenomeatpie"
	desc = "A delicious meatpie. Probably heretical."
	trash = /obj/item/trash/dish/plate
	filling_color = "#43de18"
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/xemeatpie/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/wingfangchu
	name = "Wing Fang Chu"
	desc = "A savory dish of alien wing wang in soy."
	icon_state = "wingfangchu"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#43de18"
	center_of_mass = "x=17;y=9"

/obj/item/reagent_containers/food/snacks/wingfangchu/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	bitesize = 2


/obj/item/reagent_containers/food/snacks/meatkabob
	name = "Meat-kabob"
	icon_state = "kabob"
	desc = "Delicious meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#a85340"
	center_of_mass = "x=17;y=15"

/obj/item/reagent_containers/food/snacks/meatkabob/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 8)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/tofukabob
	name = "Tofu-kabob"
	icon_state = "kabob"
	desc = "Vegan meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#fffee0"
	center_of_mass = "x=17;y=15"
	nutriment_desc = list("tofu" = 3, "metal" = 1)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/tofukabob/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/cubancarp
	name = "Cuban Carp"
	desc = "A sandwich that burns your tongue and then leaves it numb!"
	icon_state = "cubancarp"
	trash = /obj/item/trash/dish/plate
	filling_color = "#e9adff"
	center_of_mass = "x=12;y=5"
	nutriment_desc = list("toasted bread" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/cubancarp/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/capsaicin, 3)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/popcorn
	name = "Popcorn"
	desc = "Now let's find some cinema."
	icon_state = "popcorn"
	trash = /obj/item/trash/popcorn
	var/unpopped = 0
	filling_color = "#fffad4"
	center_of_mass = "x=16;y=8"
	nutriment_desc = list("popcorn" = 3)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/popcorn/Initialize()
	. = ..()
	unpopped = rand(1,10)
	bitesize = 0.1 //this snack is supposed to be eating during looooong time. And this it not dinner food! --rastaf0
/obj/item/reagent_containers/food/snacks/popcorn/On_Consume()
	if(prob(unpopped))	//lol ...what's the point?
		to_chat(usr, "<span class='warning'>You bite down on an un-popped kernel!</span>")
		unpopped = max(0, unpopped-1)
	..()

/obj/item/reagent_containers/food/snacks/spacetwinkie
	name = "Space Twinkie"
	icon_state = "space_twinkie"
	desc = "Guaranteed to survive longer then you will."
	filling_color = "#ffe591"
	center_of_mass = "x=15;y=11"

/obj/item/reagent_containers/food/snacks/spacetwinkie/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/sugar, 4)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/loadedbakedpotato
	name = "Loaded Baked Potato"
	desc = "Totally baked."
	icon_state = "loadedbakedpotato"
	filling_color = "#9c7a68"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("baked potato" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/loadedbakedpotato/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/fries
	name = "Space Fries"
	desc = "AKA: French Fries, Freedom Fries, etc."
	icon_state = "fries"
	trash = /obj/item/trash/dish/plate
	filling_color = "#eddd00"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("fresh fries" = 4)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/fries/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/onionrings
	name = "Onion Rings"
	desc = "Like circular fries but better."
	icon_state = "onionrings"
	trash = /obj/item/trash/dish/plate
	filling_color = "#eddd00"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("fried onions" = 5)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/onionrings/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/soydope
	name = "Soy Dope"
	desc = "Dope from a soy."
	icon_state = "soydope"
	trash = /obj/item/trash/dish/plate
	filling_color = "#c4bf76"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("slime" = 2, "soy" = 2)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/soydope/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/spagetti
	name = "Spaghetti"
	desc = "A bundle of raw spaghetti."
	icon_state = "spagetti"
	filling_color = "#eddd00"
	center_of_mass = "x=16;y=16"
	nutriment_desc = list("noodles" = 2)
	nutriment_amt = 1

/obj/item/reagent_containers/food/snacks/spagetti/Initialize()
	. = ..()
	bitesize = 1

/obj/item/reagent_containers/food/snacks/cheesyfries
	name = "Cheesy Fries"
	desc = "Fries. Covered in cheese. Duh."
	icon_state = "cheesyfries"
	trash = /obj/item/trash/dish/plate
	filling_color = "#eddd00"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("fresh fries" = 3, "cheese" = 3)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/cheesyfries/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/fortunecookie
	name = "Fortune cookie"
	desc = "A true prophecy in each cookie!"
	icon_state = "fortune_cookie"
	filling_color = "#e8e79e"
	center_of_mass = "x=15;y=14"
	nutriment_desc = list("fortune cookie" = 2)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/fortunecookie/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/badrecipe
	name = "Burned mess"
	desc = "Someone should be demoted from chef for this."
	icon_state = "badrecipe"
	filling_color = "#211f02"
	center_of_mass = "x=16;y=12"

/obj/item/reagent_containers/food/snacks/badrecipe/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin, 1)
	reagents.add_reagent(/datum/reagent/carbon, 3)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/meatsteak
	name = "Meat steak"
	desc = "A piece of hot spicy meat."
	icon_state = "meatstake"
	trash = /obj/item/trash/dish/plate
	filling_color = "#7a3d11"
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/meatsteak/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	reagents.add_reagent(/datum/reagent/blackpepper, 1)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/loadedsteak
	name = "Loaded steak"
	desc = "A steak slathered in sauce with sauteed onions and mushrooms."
	icon_state = "meatstake"
	trash = /obj/item/trash/dish/plate
	filling_color = "#7a3d11"
	center_of_mass = "x=16;y=13"

	nutriment_desc = list("onion" = 2, "mushroom" = 2)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/loadedsteak/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)
	reagents.add_reagent(/datum/reagent/nutriment/garlicsauce, 2)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/spacylibertyduff
	name = "Spacy Liberty Duff"
	desc = "Jello gelatin, from Alfred Hubbard's cookbook."
	icon_state = "spacylibertyduff"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#42b873"
	center_of_mass = "x=16;y=8"
	nutriment_desc = list("mushroom" = 6)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/spacylibertyduff/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/psilocybin, 6)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/amanitajelly
	name = "Amanita Jelly"
	desc = "Looks curiously toxic."
	icon_state = "amanitajelly"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#ed0758"
	center_of_mass = "x=16;y=5"
	nutriment_desc = list("jelly" = 3, "mushroom" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/amanitajelly/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin/amatoxin, 6)
	reagents.add_reagent(/datum/reagent/psilocybin, 3)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/poppypretzel
	name = "Poppy pretzel"
	desc = "It's all twisted up!"
	icon_state = "poppypretzel"
	bitesize = 2
	filling_color = "#916e36"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("poppy seeds" = 2, "pretzel" = 3)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/poppypretzel/Initialize()
	. = ..()
	bitesize = 2


/obj/item/reagent_containers/food/snacks/faggotsoup
	name = "Faggot soup"
	desc = "You've got balls kid, BALLS!"
	icon_state = "faggotsoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#785210"
	center_of_mass = "x=16;y=8"

/obj/item/reagent_containers/food/snacks/faggotsoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 8)
	reagents.add_reagent(/datum/reagent/water, 5)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/fathersoup
	name = "Father's soup"
	desc = "A hellish meal. It's better to refuse politely."
	icon_state = "fathersoup"
	trash = /obj/item/trash/pan
	filling_color = "#f85210"
	center_of_mass = "x=16;y=16"
	bitesize = 5

/obj/item/reagent_containers/food/snacks/fathersoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 8)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/thermite, 2)
	reagents.add_reagent(/datum/reagent/capsaicin, 5)

/obj/item/reagent_containers/food/snacks/metroidsoup
	name = "metroid soup"
	desc = "If no water is available, you may substitute tears."
	icon_state = "rorosoup"
	filling_color = "#c4dba0"

/obj/item/reagent_containers/food/snacks/metroidsoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/metroidjelly, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/bloodsoup
	name = "Tomato soup"
	desc = "Smells like copper."
	icon_state = "tomatosoup"
	filling_color = "#ff0000"
	center_of_mass = "x=16;y=7"

/obj/item/reagent_containers/food/snacks/bloodsoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)
	reagents.add_reagent(/datum/reagent/blood, 10)
	reagents.add_reagent(/datum/reagent/water, 5)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/clownstears
	name = "Clown's Tears"
	desc = "Not very funny."
	icon_state = "clownstears"
	filling_color = "#c4fbff"
	center_of_mass = "x=16;y=7"
	nutriment_desc = list("salt" = 1, "the worst joke" = 3)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/clownstears/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/banana, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/vegetablesoup
	name = "Vegetable soup"
	desc = "A highly nutritious blend of vegetative goodness. Guaranteed to leave you with a, er, \"souped-up\" sense of wellbeing."
	icon_state = "vegetablesoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#afc4b5"
	center_of_mass = "x=16;y=8"
	nutriment_desc = list("carrot" = 2, "corn" = 2, "eggplant" = 2, "potato" = 2)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/vegetablesoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/water, 5)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/nettlesoup
	name = "Nettle soup"
	desc = "A mean, green, calorically lean dish derived from a poisonous plant. It has a rather acidic bite to its taste."
	icon_state = "nettlesoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#afc4b5"
	center_of_mass = "x=16;y=7"
	nutriment_desc = list("salad" = 4, "egg" = 2, "potato" = 2)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/nettlesoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/water, 5)
	reagents.add_reagent(/datum/reagent/tricordrazine, 5)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/mysterysoup
	name = "Mystery soup"
	desc = "The mystery is, why aren't you eating it?"
	icon_state = "mysterysoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#f082ff"
	center_of_mass = "x=16;y=6"
	nutriment_desc = list("backwash" = 1)
	nutriment_amt = 1

/obj/item/reagent_containers/food/snacks/mysterysoup/Initialize()
	. = ..()
	var/mysteryselect = pick(1,2,3,4,5,6,7,8,9,10)
	switch(mysteryselect)
		if(1)
			reagents.add_reagent(/datum/reagent/nutriment, 6)
			reagents.add_reagent(/datum/reagent/capsaicin, 3)
			reagents.add_reagent(/datum/reagent/drink/juice/tomato, 2)
		if(2)
			reagents.add_reagent(/datum/reagent/nutriment, 6)
			reagents.add_reagent(/datum/reagent/frostoil, 3)
			reagents.add_reagent(/datum/reagent/drink/juice/tomato, 2)
		if(3)
			reagents.add_reagent(/datum/reagent/nutriment, 5)
			reagents.add_reagent(/datum/reagent/water, 5)
			reagents.add_reagent(/datum/reagent/tricordrazine, 5)
		if(4)
			reagents.add_reagent(/datum/reagent/nutriment, 5)
			reagents.add_reagent(/datum/reagent/water, 10)
		if(5)
			reagents.add_reagent(/datum/reagent/nutriment, 2)
			reagents.add_reagent(/datum/reagent/drink/juice/banana, 10)
		if(6)
			reagents.add_reagent(/datum/reagent/nutriment, 6)
			reagents.add_reagent(/datum/reagent/blood, 10)
		if(7)
			reagents.add_reagent(/datum/reagent/metroidjelly, 10)
			reagents.add_reagent(/datum/reagent/water, 10)
		if(8)
			reagents.add_reagent(/datum/reagent/carbon, 10)
			reagents.add_reagent(/datum/reagent/toxin, 10)
		if(9)
			reagents.add_reagent(/datum/reagent/nutriment, 5)
			reagents.add_reagent(/datum/reagent/drink/juice/tomato, 10)
		if(10)
			reagents.add_reagent(/datum/reagent/nutriment, 6)
			reagents.add_reagent(/datum/reagent/drink/juice/tomato, 5)
			reagents.add_reagent(/datum/reagent/imidazoline, 5)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/wishsoup
	name = "Wish Soup"
	desc = "I wish this was soup."
	icon_state = "wishsoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#d1f4ff"
	center_of_mass = "x=16;y=11"

/obj/item/reagent_containers/food/snacks/wishsoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/water, 10)
	bitesize = 5
	if(prob(25))
		src.desc = "A wish come true!"
		reagents.add_reagent(/datum/reagent/nutriment, 8, list("something good" = 8))

/obj/item/reagent_containers/food/snacks/hotchili
	name = "Hot Chili"
	desc = "A five alarm Texan Chili!"
	icon_state = "hotchili"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#ff3c00"
	center_of_mass = "x=15;y=9"
	nutriment_desc = list("chilli peppers" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/hotchili/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/capsaicin, 3)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 2)
	bitesize = 5


/obj/item/reagent_containers/food/snacks/coldchili
	name = "Cold Chili"
	desc = "This slush is barely a liquid!"
	icon_state = "coldchili"
	filling_color = "#2b00ff"
	center_of_mass = "x=15;y=9"
	nutriment_desc = list("ice peppers" = 3)
	nutriment_amt = 3
	trash = /obj/item/trash/dish/bowl

/obj/item/reagent_containers/food/snacks/coldchili/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/frostoil, 3)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 2)
	bitesize = 5

/obj/item/reagent_containers/food/snacks/monkeycube
	name = "monkey cube"
	desc = "Just add water!"
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	icon_state = "monkeycube"
	bitesize = 12
	filling_color = "#adac7f"
	center_of_mass = "x=16;y=14"

	var/wrapped = 0
	var/growing = 0
	var/monkey_type = /mob/living/carbon/human/monkey

/obj/item/reagent_containers/food/snacks/monkeycube/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)

/obj/item/reagent_containers/food/snacks/monkeycube/attack_self(mob/user)
	if(wrapped)
		Unwrap(user)

/obj/item/reagent_containers/food/snacks/monkeycube/proc/Expand()
	if(!growing)
		growing = 1
		src.visible_message("<span class='notice'>\The [src] expands!</span>")
		var/mob/monkey = new monkey_type
		monkey.dropInto(src.loc)
		qdel(src)

/obj/item/reagent_containers/food/snacks/monkeycube/proc/Unwrap(mob/user)
	icon_state = "monkeycube"
	desc = "Just add water!"
	to_chat(user, "You unwrap the cube.")
	playsound(src, 'sound/effects/using/wrapper/unwrap1.ogg', rand(50, 75), TRUE)
	wrapped = 0
	atom_flags |= ATOM_FLAG_OPEN_CONTAINER

/obj/item/reagent_containers/food/snacks/monkeycube/On_Consume(mob/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.visible_message("<span class='warning'>A screeching creature bursts out of [M]'s chest!</span>")
		var/obj/item/organ/external/organ = H.get_organ(BP_CHEST)
		organ.take_external_damage(50, 0, 0, "Animal escaping the ribcage")
	Expand()

/obj/item/reagent_containers/food/snacks/monkeycube/on_reagent_change()
	if(reagents.has_reagent(/datum/reagent/water))
		Expand()

/obj/item/reagent_containers/food/snacks/monkeycube/wrapped
	desc = "Still wrapped in some paper."
	icon_state = "monkeycubewrap"
	item_flags = 0
	obj_flags = 0
	wrapped = 1

/obj/item/reagent_containers/food/snacks/monkeycube/farwacube
	name = "farwa cube"
	monkey_type = /mob/living/carbon/human/farwa

/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/farwacube
	name = "farwa cube"
	monkey_type = /mob/living/carbon/human/farwa

/obj/item/reagent_containers/food/snacks/monkeycube/stokcube
	name = "stok cube"
	monkey_type = /mob/living/carbon/human/stok

/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/stokcube
	name = "stok cube"
	monkey_type = /mob/living/carbon/human/stok

/obj/item/reagent_containers/food/snacks/monkeycube/neaeracube
	name = "neaera cube"
	monkey_type = /mob/living/carbon/human/neaera

/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/neaeracube
	name = "neaera cube"
	monkey_type = /mob/living/carbon/human/neaera

/obj/item/reagent_containers/food/snacks/monkeycube/punpuncube
	name = "compressed Pun Pun"
	desc = "What's up, little buddy? You look dehydrated."
	monkey_type = /mob/living/carbon/human/monkey/punpun

/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/punpuncube
	name = "Pun Pun"
	desc = "What's up, little buddy? You look dehydrated."
	monkey_type = /mob/living/carbon/human/monkey/punpun

/obj/item/reagent_containers/food/snacks/spellburger
	name = "Spell Burger"
	desc = "This is absolutely Ei Nath."
	icon_state = "spellburger"
	filling_color = "#d505ff"
	nutriment_desc = list("magic" = 3, "buns" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/spellburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/bigbiteburger
	name = "Big Bite Burger"
	desc = "Forget the Big Mac. THIS is the future!"
	icon_state = "bigbiteburger"
	filling_color = "#e3d681"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("buns" = 4)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/bigbiteburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/enchiladas
	name = "Enchiladas"
	desc = "Viva La Mexico!"
	icon_state = "enchiladas"
	trash = /obj/item/trash/dish/tray
	filling_color = "#a36a1f"
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("tortilla" = 3, "corn" = 3)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/enchiladas/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	reagents.add_reagent(/datum/reagent/capsaicin, 6)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/monkeysdelight
	name = "monkey's Delight"
	desc = "Eeee Eee!"
	icon_state = "monkeysdelight"
	trash = /obj/item/trash/dish/tray
	filling_color = "#5c3c11"
	center_of_mass = "x=16;y=13"

/obj/item/reagent_containers/food/snacks/monkeysdelight/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	reagents.add_reagent(/datum/reagent/drink/juice/banana, 5)
	reagents.add_reagent(/datum/reagent/blackpepper, 1)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	bitesize = 6

/obj/item/reagent_containers/food/snacks/baguette
	name = "Baguette"
	desc = "Bon appetit!"
	icon_state = "baguette"
	filling_color = "#e3d796"
	center_of_mass = "x=18;y=12"
	nutriment_desc = list("french bread" = 6)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/baguette/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/blackpepper, 1)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/fishandchips
	name = "Fish and Chips"
	desc = "I do say so myself chap."
	icon_state = "fishandchips"
	filling_color = "#e3d796"
	center_of_mass = "x=16;y=16"
	nutriment_desc = list("salt" = 1, "chips" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/fishandchips/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/sandwich
	name = "Sandwich"
	desc = "A grand creation of meat, cheese, bread, and several leaves of lettuce! Arthur Dent would be proud."
	icon_state = "sandwich"
	trash = /obj/item/trash/dish/plate
	filling_color = "#d9be29"
	center_of_mass = "x=16;y=4"
	nutriment_desc = list("bread" = 3, "cheese" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/sandwich/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/toastedsandwich
	name = "Toasted Sandwich"
	desc = "Now if you only had a pepper bar."
	icon_state = "toastedsandwich"
	trash = /obj/item/trash/dish/plate
	filling_color = "#d9be29"
	center_of_mass = "x=16;y=4"
	nutriment_desc = list("toasted bread" = 3, "cheese" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/toastedsandwich/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/carbon, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/grilledcheese
	name = "Grilled Cheese Sandwich"
	desc = "Goes great with Tomato soup!"
	icon_state = "toastedsandwich"
	trash = /obj/item/trash/dish/plate
	filling_color = "#d9be29"
	nutriment_desc = list("toasted bread" = 3, "cheese" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/grilledcheese/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/pelmeni
	name = "Pelmeni"
	desc = "Meat wrapped in thin uneven dough."
	icon_state = "pelmeni"
	filling_color = "#d9be29"
	center_of_mass = "x=16;y=4"
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/pelmeni/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/boiledpelmeni
	name = "Boiled pelmeni"
	desc = "We don't know what was Siberia, but these tasty pelmeni definitely arrived from there."
	icon_state = "boiledpelmeni"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#d9be29"
	center_of_mass = "x=16;y=4"
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/boiledpelmeni/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/tomatosoup
	name = "Tomato Soup"
	desc = "Drinking this feels like being a vampire! A tomato vampire..."
	icon_state = "tomatosoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#d92929"
	center_of_mass = "x=16;y=7"
	nutriment_desc = list("soup" = 5)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/tomatosoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 10)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/rofflewaffles
	name = "Roffle Waffles"
	desc = "Waffles from Roffle. Co."
	icon_state = "rofflewaffles"
	trash = /obj/item/trash/dish/baking_sheet
	filling_color = "#ff00f7"
	center_of_mass = "x=15;y=11"
	nutriment_desc = list("waffle" = 7, "sweetness" = 1)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/rofflewaffles/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/psilocybin, 8)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/stew
	name = "Stew"
	desc = "A nice and warm stew. Healthy and strong."
	icon_state = "stew"
	filling_color = "#9e673a"
	center_of_mass = "x=16;y=5"
	nutriment_desc = list("tomato" = 2, "potato" = 2, "carrot" = 2, "eggplant" = 2, "mushroom" = 2)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/stew/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 5)
	reagents.add_reagent(/datum/reagent/imidazoline, 5)
	reagents.add_reagent(/datum/reagent/water, 5)
	bitesize = 10

/obj/item/reagent_containers/food/snacks/jelliedtoast
	name = "Jellied Toast"
	desc = "A slice of bread covered with delicious jam."
	icon_state = "jellytoast"
	trash = /obj/item/trash/dish/plate
	filling_color = "#b572ab"
	center_of_mass = "x=16;y=8"
	nutriment_desc = list("toasted bread" = 2)
	nutriment_amt = 1

/obj/item/reagent_containers/food/snacks/jelliedtoast/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/jelliedtoast/cherry/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/cherryjelly, 5)

/obj/item/reagent_containers/food/snacks/jelliedtoast/metroid/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/metroidjelly, 5)

/obj/item/reagent_containers/food/snacks/jellyburger
	name = "Jelly Burger"
	desc = "Culinary delight..?"
	icon_state = "jellyburger"
	filling_color = "#b572ab"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("buns" = 5)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/jellyburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/jellyburger/metroid/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/metroidjelly, 5)

/obj/item/reagent_containers/food/snacks/jellyburger/cherry/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/cherryjelly, 5)

/obj/item/reagent_containers/food/snacks/milosoup
	name = "Milosoup"
	desc = "The universes best soup! Yum!!!"
	icon_state = "milosoup"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=16;y=7"
	nutriment_desc = list("soy" = 8)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/milosoup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/water, 5)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/stewedsoymeat
	name = "Stewed Soy Meat"
	desc = "Even non-vegetarians will LOVE this!"
	icon_state = "stewedsoymeat"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("soy" = 4, "tomato" = 4)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/stewedsoymeat/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/boiledspagetti
	name = "Boiled Spaghetti"
	desc = "A plain dish of noodles, this sucks."
	icon_state = "spagettiboiled"
	trash = /obj/item/trash/dish/plate
	filling_color = "#fcee81"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("noodles" = 2)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/boiledspagetti/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/boiledrice
	name = "Boiled Rice"
	desc = "A boring dish of boring rice."
	icon_state = "boiledrice"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#fffbdb"
	center_of_mass = "x=17;y=11"
	nutriment_desc = list("rice" = 2)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/boiledrice/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/ricepudding
	name = "Rice Pudding"
	desc = "Where's the jam?"
	icon_state = "rpudding"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#fffbdb"
	center_of_mass = "x=17;y=11"
	nutriment_desc = list("rice" = 2)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/ricepudding/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/pastatomato
	name = "Spaghetti"
	desc = "Spaghetti and crushed tomatoes. Just like your abusive father used to make!"
	icon_state = "pastatomato"
	trash = /obj/item/trash/dish/plate
	filling_color = "#de4545"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("tomato" = 3, "noodles" = 3)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/pastatomato/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 10)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/faggotspagetti
	name = "Spaghetti & Faggots"
	desc = "Now thats a nic'e faggot!"
	icon_state = "faggotspagetti"
	trash = /obj/item/trash/dish/plate
	filling_color = "#de4545"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("noodles" = 4)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/faggotspagetti/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/spesslaw
	name = "Spesslaw"
	desc = "A lawyers favourite."
	icon_state = "spesslaw"
	filling_color = "#de4545"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("noodles" = 4)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/spesslaw/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/carrotfries
	name = "Carrot Fries"
	desc = "Tasty fries from fresh Carrots."
	icon_state = "carrotfries"
	trash = /obj/item/trash/dish/plate
	filling_color = "#faa005"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("carrot" = 3, "salt" = 1)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/carrotfries/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/imidazoline, 3)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/superbiteburger
	name = "Super Bite Burger"
	desc = "This is a mountain of a burger. FOOD!"
	icon_state = "superbiteburger"
	filling_color = "#cca26a"
	center_of_mass = "x=16;y=3"
	nutriment_desc = list("buns" = 25)
	nutriment_amt = 25

/obj/item/reagent_containers/food/snacks/superbiteburger/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 25)
	bitesize = 10

/obj/item/reagent_containers/food/snacks/candiedapple
	name = "Candied Apple"
	desc = "An apple coated in sugary sweetness."
	icon_state = "candiedapple"
	filling_color = "#f21873"
	center_of_mass = "x=15;y=13"
	nutriment_desc = list("apple" = 3, "caramel" = 3, "sweetness" = 2)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/candiedapple/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/applepie
	name = "Apple Pie"
	desc = "A pie containing sweet sweet love... or apple."
	icon_state = "applepie"
	filling_color = "#e0edc5"
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("sweetness" = 2, "apple" = 2, "pie" = 2)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/applepie/Initialize()
	. = ..()
	bitesize = 3


/obj/item/reagent_containers/food/snacks/cherrypie
	name = "Cherry Pie"
	desc = "Taste so good, make a grown man cry."
	icon_state = "cherrypie"
	filling_color = "#ff525a"
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("sweetness" = 2, "cherry" = 2, "pie" = 2)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/cherrypie/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/twobread
	name = "Two Bread"
	desc = "It is very bitter and winy."
	icon_state = "twobread"
	filling_color = "#dbcc9a"
	center_of_mass = "x=15;y=12"
	nutriment_desc = list("sourness" = 2, "bread" = 2)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/twobread/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/threebread
	name = "Three Bread"
	desc = "Is such a thing even possible?"
	icon_state = "threebread"
	filling_color = "#dbcc9a"
	center_of_mass = "x=15;y=12"
	nutriment_desc = list("sourness" = 2, "bread" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/threebread/Initialize()
	. = ..()
	bitesize = 4

/obj/item/reagent_containers/food/snacks/jellysandwich
	name = "Jelly Sandwich"
	desc = "You wish you had some peanut butter to go with this..."
	icon_state = "jellysandwich"
	trash = /obj/item/trash/dish/plate
	filling_color = "#9e3a78"
	center_of_mass = "x=16;y=8"
	nutriment_desc = list("bread" = 2)
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/jellysandwich/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/jellysandwich/metroid/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/metroidjelly, 5)

/obj/item/reagent_containers/food/snacks/jellysandwich/cherry/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/cherryjelly, 5)

/obj/item/reagent_containers/food/snacks/boiledmetroidcore
	name = "Boiled metroid Core"
	desc = "A boiled red thing."
	icon_state = "boiledrorocore"

/obj/item/reagent_containers/food/snacks/boiledmetroidcore/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/metroidjelly, 5)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/mint
	name = "mint"
	desc = "it is only wafer thin."
	icon_state = "mint"
	filling_color = "#f2f2f2"
	center_of_mass = "x=16;y=14"

/obj/item/reagent_containers/food/snacks/mint/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/mint, 1)
	bitesize = 1

/obj/item/reagent_containers/food/snacks/mushroomsoup
	name = "chantrelle soup"
	desc = "A delicious and hearty mushroom soup."
	icon_state = "mushroomsoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#e386bf"
	center_of_mass = "x=17;y=10"
	nutriment_desc = list("mushroom" = 8, "milk" = 2)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/mushroomsoup/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/plumphelmetbiscuit
	name = "plump helmet biscuit"
	desc = "This is a finely-prepared plump helmet biscuit. The ingredients are exceptionally minced plump helmet, and well-minced dwarven wheat flour."
	icon_state = "phelmbiscuit"
	filling_color = "#cfb4c4"
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("mushroom" = 4)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/plumphelmetbiscuit/Initialize()
	. = ..()
	if(prob(10))
		name = "exceptional plump helmet biscuit"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump helmet biscuit!"
		reagents.add_reagent(/datum/reagent/nutriment, 3)
		reagents.add_reagent(/datum/reagent/tricordrazine, 5)
		bitesize = 2

/obj/item/reagent_containers/food/snacks/chawanmushi
	name = "chawanmushi"
	desc = "A legendary egg custard that makes friends out of enemies. Probably too hot for a cat to eat."
	icon_state = "chawanmushi"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#f0f2e4"
	center_of_mass = "x=17;y=10"

/obj/item/reagent_containers/food/snacks/chawanmushi/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	bitesize = 1

/obj/item/reagent_containers/food/snacks/beetsoup
	name = "beet soup"
	desc = "Wait, how do you spell it again..?"
	icon_state = "beetsoup"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#fac9ff"
	center_of_mass = "x=15;y=8"
	nutriment_desc = list("tomato" = 4, "beet" = 4)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/beetsoup/Initialize()
	. = ..()
	name = pick(list("borsch","bortsch","borstch","borsh","borshch","borscht"))
	bitesize = 2

/obj/item/reagent_containers/food/snacks/tossedsalad
	name = "tossed salad"
	desc = "A proper salad, basic and simple, with little bits of carrot, tomato and apple intermingled. Vegan!"
	icon_state = "herbsalad"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#76b87f"
	center_of_mass = "x=17;y=11"
	nutriment_desc = list("salad" = 2, "tomato" = 2, "carrot" = 2, "apple" = 2)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/tossedsalad/Initialize()
	. = ..()
	bitesize = 3

/obj/item/reagent_containers/food/snacks/validsalad
	name = "valid salad"
	desc = "It's just a salad of questionable 'herbs' with faggots and fried potato slices. Nothing suspicious about it."
	icon_state = "validsalad"
	trash = /obj/item/trash/dish/bowl
	filling_color = "#76b87f"
	center_of_mass = "x=17;y=11"
	nutriment_desc = list("100% real salad")
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/validsalad/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/appletart
	name = "golden apple streusel tart"
	desc = "A tasty dessert that won't make it through a metal detector."
	icon_state = "gappletart"
	trash = /obj/item/trash/dish/plate
	filling_color = "#ffff00"
	center_of_mass = "x=16;y=18"
	nutriment_desc = list("apple" = 8)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/appletart/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/gold, 5)
	bitesize = 3

/////////////////////////////////////////////////Sliceable////////////////////////////////////////
// All the food items that can be sliced into smaller bits like Meatbread and Cheesewheels

// sliceable is just an organization type path, it doesn't have any additional code or variables tied to it.

/obj/item/reagent_containers/food/snacks/sliceable
	w_class = ITEM_SIZE_NORMAL //Whole pizzas and cakes shouldn't fit in a pocket, you can slice them if you want to do that.

/**
 *  A food item slice
 *
 *  This path contains some extra code for spawning slices pre-filled with
 *  reagents.
 */
/obj/item/reagent_containers/food/snacks/slice
	name = "slice of... something"
	var/whole_path  // path for the item from which this slice comes
	var/filled = FALSE  // should the slice spawn with any reagents

/**
 *  Spawn a new slice of food
 *
 *  If the slice's filled is TRUE, this will also fill the slice with the
 *  appropriate amount of reagents. Note that this is done by spawning a new
 *  whole item, transferring the reagents and deleting the whole item, which may
 *  have performance implications.
 */
/obj/item/reagent_containers/food/snacks/slice/Initialize()
	. = ..()
	if(filled)
		var/obj/item/reagent_containers/food/snacks/whole = new whole_path()
		if(whole && whole.slices_num)
			var/reagent_amount = whole.reagents.total_volume/whole.slices_num
			whole.reagents.trans_to_obj(src, reagent_amount)

		qdel(whole)

/obj/item/reagent_containers/food/snacks/sliceable/meatbread
	name = "meatbread loaf"
	desc = "The culinary base of every self-respecting eloquen/tg/entleman."
	icon_state = "meatbread"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/meatbread
	slices_num = 5
	filling_color = "#ff7575"
	center_of_mass = "x=19;y=9"
	nutriment_desc = list("bread" = 10)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/meatbread/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 20)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/meatbread
	name = "meatbread slice"
	desc = "A slice of delicious meatbread."
	icon_state = "meatbreadslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#ff7575"
	bitesize = 2
	center_of_mass = "x=16;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/meatbread

/obj/item/reagent_containers/food/snacks/slice/meatbread/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/xenomeatbread
	name = "xenomeatbread loaf"
	desc = "The culinary base of every self-respecting eloquent gentleman. Extra Heretical."
	icon_state = "xenomeatbread"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/xenomeatbread
	slices_num = 5
	filling_color = "#8aff75"
	center_of_mass = "x=16;y=9"
	nutriment_desc = list("bread" = 10)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/xenomeatbread/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 20)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/xenomeatbread
	name = "xenomeatbread slice"
	desc = "A slice of delicious meatbread. Extra Heretical."
	icon_state = "xenobreadslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#8aff75"
	bitesize = 2
	center_of_mass = "x=16;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/xenomeatbread


/obj/item/reagent_containers/food/snacks/slice/xenomeatbread/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/bananabread
	name = "Banana-nut bread"
	desc = "A heavenly and filling treat."
	icon_state = "bananabread"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/bananabread
	slices_num = 5
	filling_color = "#ede5ad"
	center_of_mass = "x=16;y=9"
	nutriment_desc = list("bread" = 10)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/bananabread/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/banana, 20)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/bananabread
	name = "Banana-nut bread slice"
	desc = "A slice of delicious banana bread."
	icon_state = "bananabreadslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#ede5ad"
	bitesize = 2
	center_of_mass = "x=16;y=8"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/bananabread

/obj/item/reagent_containers/food/snacks/slice/bananabread/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/tofubread
	name = "Tofubread"
	icon_state = "Like meatbread but for vegetarians. Not guaranteed to give superpowers."
	icon_state = "tofubread"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/tofubread
	slices_num = 5
	filling_color = "#f7ffe0"
	center_of_mass = "x=16;y=9"
	nutriment_desc = list("tofu" = 10)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/tofubread/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/tofubread
	name = "Tofubread slice"
	desc = "A slice of delicious tofubread."
	icon_state = "tofubreadslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#f7ffe0"
	bitesize = 2
	center_of_mass = "x=16;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/tofubread

/obj/item/reagent_containers/food/snacks/slice/tofubread/filled
	filled = TRUE


/obj/item/reagent_containers/food/snacks/sliceable/carrotcake
	name = "Carrot Cake"
	desc = "A favorite desert of a certain wascally wabbit. Not a lie."
	icon_state = "carrotcake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/carrotcake
	slices_num = 5
	filling_color = "#ffd675"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "carrot" = 15)
	nutriment_amt = 25

/obj/item/reagent_containers/food/snacks/sliceable/carrotcake/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/imidazoline, 10)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/carrotcake
	name = "Carrot Cake slice"
	desc = "Carrotty slice of Carrot Cake, carrots are good for your eyes! Also not a lie."
	icon_state = "carrotcake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#ffd675"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/carrotcake

/obj/item/reagent_containers/food/snacks/slice/carrotcake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/braincake
	name = "Brain Cake"
	desc = "A squishy cake-thing."
	icon_state = "braincake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/braincake
	slices_num = 5
	filling_color = "#e6aedb"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "slime" = 15)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/sliceable/braincake/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 25)
	reagents.add_reagent(/datum/reagent/alkysine, 10)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/braincake
	name = "Brain Cake slice"
	desc = "Lemme tell you something about prions. THEY'RE DELICIOUS."
	icon_state = "braincakeslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#e6aedb"
	bitesize = 2
	center_of_mass = "x=16;y=12"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/braincake

/obj/item/reagent_containers/food/snacks/slice/braincake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/cheesecake
	name = "Cheese Cake"
	desc = "DANGEROUSLY cheesy."
	icon_state = "cheesecake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/cheesecake
	slices_num = 5
	filling_color = "#faf7af"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "cream" = 10, "cheese" = 15)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/cheesecake/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 15)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/cheesecake
	name = "Cheese Cake slice"
	desc = "Slice of pure cheestisfaction."
	icon_state = "cheesecake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#faf7af"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/cheesecake

/obj/item/reagent_containers/food/snacks/slice/cheesecake/filled
	filled = TRUE



/obj/item/reagent_containers/food/snacks/sliceable/plaincake
	name = "Vanilla Cake"
	desc = "A plain cake, not a lie."
	icon_state = "plaincake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/plaincake
	slices_num = 5
	filling_color = "#f7edd5"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "vanilla" = 15)
	nutriment_amt = 20

/obj/item/reagent_containers/food/snacks/slice/plaincake
	name = "Vanilla Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "plaincake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#f7edd5"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/plaincake

/obj/item/reagent_containers/food/snacks/slice/plaincake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/orangecake
	name = "Orange Cake"
	desc = "A cake with added orange."
	icon_state = "orangecake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/orangecake
	slices_num = 5
	filling_color = "#fada8e"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "orange" = 15)
	nutriment_amt = 20

/obj/item/reagent_containers/food/snacks/slice/orangecake
	name = "Orange Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "orangecake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#fada8e"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/orangecake

/obj/item/reagent_containers/food/snacks/slice/orangecake/filled
	filled = TRUE


/obj/item/reagent_containers/food/snacks/sliceable/limecake
	name = "Lime Cake"
	desc = "A cake with added lime."
	icon_state = "limecake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/limecake
	slices_num = 5
	filling_color = "#cbfa8e"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "lime" = 15)
	nutriment_amt = 20


/obj/item/reagent_containers/food/snacks/slice/limecake
	name = "Lime Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "limecake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#cbfa8e"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/limecake

/obj/item/reagent_containers/food/snacks/slice/limecake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/lemoncake
	name = "Lemon Cake"
	desc = "A cake with added lemon."
	icon_state = "lemoncake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/lemoncake
	slices_num = 5
	filling_color = "#fafa8e"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "lemon" = 15)
	nutriment_amt = 20


/obj/item/reagent_containers/food/snacks/slice/lemoncake
	name = "Lemon Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "lemoncake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#fafa8e"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/lemoncake

/obj/item/reagent_containers/food/snacks/slice/lemoncake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/chocolatecake
	name = "Chocolate Cake"
	desc = "A cake with added chocolate."
	icon_state = "chocolatecake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/chocolatecake
	slices_num = 5
	filling_color = "#805930"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "chocolate" = 15)
	nutriment_amt = 20

/obj/item/reagent_containers/food/snacks/slice/chocolatecake
	name = "Chocolate Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "chocolatecake_slice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#805930"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/chocolatecake

/obj/item/reagent_containers/food/snacks/slice/chocolatecake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/cheesewheel
	name = "Cheese wheel"
	desc = "A big wheel of delcious Cheddar."
	icon_state = "cheesewheel"
	slice_path = /obj/item/reagent_containers/food/snacks/cheesewedge
	slices_num = 5
	filling_color = "#fff700"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cheese" = 10)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/cheesewheel/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/cheesewedge
	name = "Cheese wedge"
	desc = "A wedge of delicious Cheddar. The cheese wheel it was cut from can't have gone far."
	icon_state = "cheesewedge"
	filling_color = "#fff700"
	bitesize = 2
	center_of_mass = "x=16;y=10"

/obj/item/reagent_containers/food/snacks/sliceable/birthdaycake
	name = "Birthday Cake"
	desc = "Happy Birthday..."
	icon_state = "birthdaycake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/birthdaycake
	slices_num = 5
	filling_color = "#ffd6d6"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10)
	nutriment_amt = 20

/obj/item/reagent_containers/food/snacks/sliceable/birthdaycake/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/sprinkles, 10)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/slice/birthdaycake
	name = "Birthday Cake slice"
	desc = "A slice of your birthday."
	icon_state = "birthdaycakeslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#ffd6d6"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/birthdaycake

/obj/item/reagent_containers/food/snacks/slice/birthdaycake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/bread
	name = "Bread"
	icon_state = "Some plain old Earthen bread."
	icon_state = "bread"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/bread
	slices_num = 5
	filling_color = "#ffe396"
	center_of_mass = "x=16;y=9"
	nutriment_desc = list("bread" = 6)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/sliceable/bread/Initialize()
	. = ..()
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/bread
	name = "Bread slice"
	desc = "A slice of home."
	icon_state = "breadslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#d27332"
	bitesize = 2
	center_of_mass = "x=16;y=4"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/bread

/obj/item/reagent_containers/food/snacks/slice/bread/filled
	filled = TRUE


/obj/item/reagent_containers/food/snacks/sliceable/creamcheesebread
	name = "Cream Cheese Bread"
	desc = "Yum yum yum!"
	icon_state = "creamcheesebread"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/creamcheesebread
	slices_num = 5
	filling_color = "#fff896"
	center_of_mass = "x=16;y=9"
	nutriment_desc = list("bread" = 6, "cream" = 3, "cheese" = 3)
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/sliceable/creamcheesebread/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 15)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/creamcheesebread
	name = "Cream Cheese Bread slice"
	desc = "A slice of yum!"
	icon_state = "creamcheesebreadslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#fff896"
	bitesize = 2
	center_of_mass = "x=16;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/creamcheesebread


/obj/item/reagent_containers/food/snacks/slice/creamcheesebread/filled
	filled = TRUE


/obj/item/reagent_containers/food/snacks/watermelonslice
	name = "Watermelon Slice"
	desc = "A slice of watery goodness."
	icon_state = "watermelonslice"
	filling_color = "#ff3867"
	bitesize = 2
	center_of_mass = "x=16;y=10"


/obj/item/reagent_containers/food/snacks/sliceable/applecake
	name = "Apple Cake"
	desc = "A cake centred with apples."
	icon_state = "applecake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/applecake
	slices_num = 5
	filling_color = "#ebf5b8"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "apple" = 15)
	nutriment_amt = 15

/obj/item/reagent_containers/food/snacks/slice/applecake
	name = "Apple Cake slice"
	desc = "A slice of heavenly cake."
	icon_state = "applecakeslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#ebf5b8"
	bitesize = 2
	center_of_mass = "x=16;y=14"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/applecake

/obj/item/reagent_containers/food/snacks/slice/applecake/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/pumpkinpie
	name = "Pumpkin Pie"
	desc = "A delicious treat for the autumn months."
	icon_state = "pumpkinpie"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/pumpkinpie
	slices_num = 5
	filling_color = "#f5b951"
	center_of_mass = "x=16;y=10"
	nutriment_desc = list("pie" = 5, "cream" = 5, "pumpkin" = 5)
	nutriment_amt = 15

/obj/item/reagent_containers/food/snacks/slice/pumpkinpie
	name = "Pumpkin Pie slice"
	desc = "A slice of pumpkin pie, with whipped cream on top. Perfection."
	icon_state = "pumpkinpieslice"
	trash = /obj/item/trash/dish/plate
	filling_color = "#f5b951"
	bitesize = 2
	center_of_mass = "x=16;y=12"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/pumpkinpie

/obj/item/reagent_containers/food/snacks/slice/pumpkinpie/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/cracker
	name = "Cracker"
	desc = "It's a salted cracker."
	icon_state = "cracker"
	filling_color = "#f5deb8"
	center_of_mass = "x=17;y=6"
	nutriment_desc = list("salt" = 1, "cracker" = 2)
	nutriment_amt = 1



/////////////////////////////////////////////////PIZZA////////////////////////////////////////

/obj/item/reagent_containers/food/snacks/sliceable/pizza
	slices_num = 6
	filling_color = "#baa14c"

/obj/item/reagent_containers/food/snacks/sliceable/pizza/margherita
	name = "Margherita"
	desc = "The golden standard of pizzas."
	icon_state = "pizzamargherita"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/margherita
	slices_num = 6
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 15)
	nutriment_amt = 35

/obj/item/reagent_containers/food/snacks/sliceable/pizza/margherita/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 6)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/margherita
	name = "Margherita slice"
	desc = "A slice of the classic pizza."
	icon_state = "pizzamargheritaslice"
	filling_color = "#baa14c"
	bitesize = 2
	center_of_mass = "x=18;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/pizza/margherita

/obj/item/reagent_containers/food/snacks/slice/margherita/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/pizza/meatpizza
	name = "Meatpizza"
	desc = "A pizza with meat topping."
	icon_state = "meatpizza"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/meatpizza
	slices_num = 6
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 15)
	nutriment_amt = 10

/obj/item/reagent_containers/food/snacks/sliceable/pizza/meatpizza/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 34)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 6)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/meatpizza
	name = "Meatpizza slice"
	desc = "A slice of a meaty pizza."
	icon_state = "meatpizzaslice"
	filling_color = "#baa14c"
	bitesize = 2
	center_of_mass = "x=18;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/pizza/meatpizza

/obj/item/reagent_containers/food/snacks/slice/meatpizza/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/pizza/mushroompizza
	name = "Mushroompizza"
	desc = "Very special pizza."
	icon_state = "mushroompizza"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/mushroompizza
	slices_num = 6
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 5, "mushroom" = 10)
	nutriment_amt = 35

/obj/item/reagent_containers/food/snacks/sliceable/pizza/mushroompizza/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/mushroompizza
	name = "Mushroompizza slice"
	desc = "Maybe it is the last slice of pizza in your life."
	icon_state = "mushroompizzaslice"
	filling_color = "#baa14c"
	bitesize = 2
	center_of_mass = "x=18;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/pizza/mushroompizza

/obj/item/reagent_containers/food/snacks/slice/mushroompizza/filled
	filled = TRUE

/obj/item/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza
	name = "Vegetable pizza"
	desc = "No one of Tomato Sapiens were harmed during making this pizza."
	icon_state = "vegetablepizza"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/vegetablepizza
	slices_num = 6
	center_of_mass = "x=16;y=11"
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 5, "eggplant" = 5, "carrot" = 5, "corn" = 5)
	nutriment_amt = 25

/obj/item/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 6)
	reagents.add_reagent(/datum/reagent/imidazoline, 12)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/slice/vegetablepizza
	name = "Vegetable pizza slice"
	desc = "A slice of the most green pizza of all pizzas not containing green ingredients."
	icon_state = "vegetablepizzaslice"
	filling_color = "#baa14c"
	bitesize = 2
	center_of_mass = "x=18;y=13"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza

/obj/item/reagent_containers/food/snacks/slice/vegetablepizza/filled
	filled = TRUE

/obj/item/pizzabox
	name = "pizza box"
	desc = "A box suited for pizzas."
	icon = 'icons/obj/food.dmi'
	icon_state = "pizzabox1"

	var/open = 0 // Is the box open?
	var/ismessy = 0 // Fancy mess on the lid
	var/obj/item/reagent_containers/food/snacks/sliceable/pizza/pizza // Content pizza
	var/list/boxes = list() // If the boxes are stacked, they come here
	var/boxtag = ""

/obj/item/pizzabox/update_icon()

	overlays = list()

	// Set appropriate description
	if( open && pizza )
		desc = "A box suited for pizzas. It appears to have a [pizza.name] inside."
	else if( boxes.len > 0 )
		desc = "A pile of boxes suited for pizzas. There appears to be [boxes.len + 1] boxes in the pile."

		var/obj/item/pizzabox/topbox = boxes[boxes.len]
		var/toptag = topbox.boxtag
		if( toptag != "" )
			desc = "[desc] The box on top has a tag, it reads: '[toptag]'."
	else
		desc = "A box suited for pizzas."

		if( boxtag != "" )
			desc = "[desc] The box has a tag, it reads: '[boxtag]'."

	// Icon states and overlays
	if( open )
		if( ismessy )
			icon_state = "pizzabox_messy"
		else
			icon_state = "pizzabox_open"

		if( pizza )
			var/image/pizzaimg = image("food.dmi", icon_state = pizza.icon_state)
			pizzaimg.pixel_y = -3
			overlays += pizzaimg

		return
	else
		// Stupid code because byondcode sucks
		var/doimgtag = 0
		if( boxes.len > 0 )
			var/obj/item/pizzabox/topbox = boxes[boxes.len]
			if( topbox.boxtag != "" )
				doimgtag = 1
		else
			if( boxtag != "" )
				doimgtag = 1

		if( doimgtag )
			var/image/tagimg = image("food.dmi", icon_state = "pizzabox_tag")
			tagimg.pixel_y = boxes.len * 3
			overlays += tagimg

	icon_state = "pizzabox[boxes.len+1]"

/obj/item/pizzabox/attack_hand( mob/user as mob )

	if( open && pizza )
		user.put_in_hands( pizza )

		to_chat(user, "<span class='warning'>You take \the [src.pizza] out of \the [src].</span>")
		src.pizza = null
		update_icon()
		return

	if( boxes.len > 0 )
		if( user.get_inactive_hand() != src )
			..()
			return

		var/obj/item/pizzabox/box = boxes[boxes.len]
		boxes -= box

		user.put_in_hands( box )
		to_chat(user, "<span class='warning'>You remove the topmost [src] from your hand.</span>")
		box.update_icon()
		update_icon()
		return
	..()

/obj/item/pizzabox/attack_self( mob/user as mob )

	if( boxes.len > 0 )
		return

	open = !open

	if( open && pizza )
		ismessy = 1

	update_icon()

/obj/item/pizzabox/attackby( obj/item/I as obj, mob/user as mob )
	if( istype(I, /obj/item/pizzabox/) )
		var/obj/item/pizzabox/box = I

		if( !box.open && !src.open )
			// Make a list of all boxes to be added
			var/list/boxestoadd = list()
			boxestoadd += box
			for(var/obj/item/pizzabox/i in box.boxes)
				boxestoadd += i

			if( (boxes.len+1) + boxestoadd.len <= 5 )
				user.drop_item()

				box.loc = src
				box.boxes = list() // Clear the box boxes so we don't have boxes inside boxes. - Xzibit
				src.boxes.Add( boxestoadd )

				box.update_icon()
				update_icon()

				to_chat(user, "<span class='warning'>You put \the [box] ontop of \the [src]!</span>")
			else
				to_chat(user, "<span class='warning'>The stack is too high!</span>")
		else
			to_chat(user, "<span class='warning'>Close \the [box] first!</span>")

		return

	if( istype(I, /obj/item/reagent_containers/food/snacks/sliceable/pizza/) ) // Long ass fucking object name

		if( src.open )
			user.drop_item()
			I.loc = src
			src.pizza = I

			update_icon()

			to_chat(user, "<span class='warning'>You put \the [I] in \the [src]!</span>")
		else
			to_chat(user, "<span class='warning'>You try to push \the [I] through the lid but it doesn't work!</span>")
		return

	if( istype(I, /obj/item/pen/) )

		if( src.open )
			return

		var/t = sanitize(input("Enter what you want to add to the tag:", "Write", null, null) as text, 30)

		var/obj/item/pizzabox/boxtotagto = src
		if( boxes.len > 0 )
			boxtotagto = boxes[boxes.len]

		boxtotagto.boxtag = copytext("[boxtotagto.boxtag][t]", 1, 30)

		update_icon()
		return
	..()

/obj/item/pizzabox/margherita/New()
	pizza = new /obj/item/reagent_containers/food/snacks/sliceable/pizza/margherita(src)
	boxtag = "Margherita Deluxe"

/obj/item/pizzabox/vegetable/New()
	pizza = new /obj/item/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza(src)
	boxtag = "Gourmet Vegatable"

/obj/item/pizzabox/mushroom/New()
	pizza = new /obj/item/reagent_containers/food/snacks/sliceable/pizza/mushroompizza(src)
	boxtag = "Mushroom Special"

/obj/item/pizzabox/meat/New()
	pizza = new /obj/item/reagent_containers/food/snacks/sliceable/pizza/meatpizza(src)
	boxtag = "Meatlover's Supreme"

/obj/item/reagent_containers/food/snacks/dionaroast
	name = "roast diona"
	desc = "It's like an enormous, leathery carrot. With an eye."
	icon_state = "dionaroast"
	trash = /obj/item/trash/dish/plate
	filling_color = "#75754b"
	center_of_mass = "x=16;y=7"
	nutriment_desc = list("a chorus of flavor" = 6)
	nutriment_amt = 6

/obj/item/reagent_containers/food/snacks/dionaroast/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/radium, 2)
	bitesize = 2




///////////////////////////////////////////
// new old food stuff from bs12
///////////////////////////////////////////
/obj/item/reagent_containers/food/snacks/dough
	name = "dough"
	desc = "A piece of dough."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "dough"
	bitesize = 2
	center_of_mass = "x=16;y=13"
	nutriment_desc = list("dough" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/dough/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 1)

// Dough + rolling pin = flat dough
/obj/item/reagent_containers/food/snacks/dough/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/material/kitchen/rollingpin))
		new /obj/item/reagent_containers/food/snacks/sliceable/flatdough(src)
		to_chat(user, "You flatten the dough.")
		qdel(src)
	else if (istype(W,/obj/item/reagent_containers/food/snacks/faggot))
		new /obj/item/reagent_containers/food/snacks/pelmeni(src)
		to_chat(user, "You make some pelmeni.")
		qdel(src)
		qdel(W)

// slicable into 3xdoughslices
/obj/item/reagent_containers/food/snacks/sliceable/flatdough
	name = "flat dough"
	desc = "A flattened dough."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "flat dough"
	slice_path = /obj/item/reagent_containers/food/snacks/doughslice
	slices_num = 3
	center_of_mass = "x=16;y=16"

/obj/item/reagent_containers/food/snacks/sliceable/flatdough/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 1)
	reagents.add_reagent(/datum/reagent/nutriment, 3)

/obj/item/reagent_containers/food/snacks/doughslice
	name = "dough slice"
	desc = "A building block of an impressive dish."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "doughslice"
	slice_path = /obj/item/reagent_containers/food/snacks/spagetti
	slices_num = 1
	bitesize = 2
	center_of_mass = "x=17;y=19"
	nutriment_desc = list("dough" = 1)
	nutriment_amt = 1


/obj/item/reagent_containers/food/snacks/bun
	name = "bun"
	desc = "A base for any self-respecting burger."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "bun"
	bitesize = 2
	center_of_mass = "x=16;y=12"
	nutriment_desc = list("bun" = 4)
	nutriment_amt = 4


/obj/item/reagent_containers/food/snacks/bun/attackby(obj/item/W as obj, mob/user as mob)
	// Bun + faggot = burger
	if(istype(W,/obj/item/reagent_containers/food/snacks/faggot))
		new /obj/item/reagent_containers/food/snacks/plainburger(src)
		to_chat(user, "You make a burger.")
		qdel(W)
		qdel(src)

	// Bun + cutlet = hamburger
	else if(istype(W,/obj/item/reagent_containers/food/snacks/cutlet))
		new /obj/item/reagent_containers/food/snacks/plainburger(src)
		to_chat(user, "You make a burger.")
		qdel(W)
		qdel(src)

	// Bun + sausage = hotdog
	else if(istype(W,/obj/item/reagent_containers/food/snacks/sausage))
		new /obj/item/reagent_containers/food/snacks/hotdog(src)
		to_chat(user, "You make a hotdog.")
		qdel(W)
		qdel(src)

// Burger + cheese wedge = cheeseburger
/obj/item/reagent_containers/food/snacks/plainburger/attackby(obj/item/reagent_containers/food/snacks/cheesewedge/W as obj, mob/user as mob)
	if(istype(W))// && !istype(src,/obj/item/reagent_containers/food/snacks/cheesewedge))
		new /obj/item/reagent_containers/food/snacks/cheeseburger(src)
		to_chat(user, "You make a cheeseburger.")
		qdel(W)
		qdel(src)
		return
	else
		..()

// Human Burger + cheese wedge = cheeseburger
/obj/item/reagent_containers/food/snacks/human/burger/attackby(obj/item/reagent_containers/food/snacks/cheesewedge/W as obj, mob/user as mob)
	if(istype(W))
		new /obj/item/reagent_containers/food/snacks/cheeseburger(src)
		to_chat(user, "You make a cheeseburger.")
		qdel(W)
		qdel(src)
		return
	else
		..()

/obj/item/reagent_containers/food/snacks/bunbun
	name = "\improper Bun Bun"
	desc = "A small bread monkey fashioned from two burger buns."
	icon_state = "bunbun"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=8)
	nutriment_desc = list("bun" = 8)
	nutriment_amt = 8

/obj/item/reagent_containers/food/snacks/taco
	name = "taco"
	desc = "Take a bite!"
	icon_state = "taco"
	bitesize = 3
	center_of_mass = "x=21;y=12"
	nutriment_desc = list("cheese" = 2,"taco shell" = 2)
	nutriment_amt = 4

/obj/item/reagent_containers/food/snacks/taco/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)

/obj/item/reagent_containers/food/snacks/rawcutlet
	name = "raw cutlet"
	desc = "A thin piece of raw meat."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawcutlet"
	bitesize = 1
	center_of_mass = "x=17;y=20"

/obj/item/reagent_containers/food/snacks/rawcutlet/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 1)

/obj/item/reagent_containers/food/snacks/cutlet
	name = "cutlet"
	desc = "A tasty meat slice."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "cutlet"
	bitesize = 2
	center_of_mass = "x=17;y=20"

/obj/item/reagent_containers/food/snacks/cutlet/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)

/obj/item/reagent_containers/food/snacks/rawfaggot
	name = "raw faggot"
	desc = "A raw faggot."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawfaggot"
	bitesize = 2
	center_of_mass = "x=16;y=15"

/obj/item/reagent_containers/food/snacks/rawfaggot/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)

/obj/item/reagent_containers/food/snacks/hotdog
	name = "hotdog"
	desc = "Unrelated to dogs, maybe."
	icon_state = "hotdog"
	bitesize = 2
	center_of_mass = "x=16;y=17"

/obj/item/reagent_containers/food/snacks/hotdog/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)

/obj/item/reagent_containers/food/snacks/classichotdog
	name = "classic hotdog"
	desc = "Going literal."
	icon_state = "hotcorgi"
	bitesize = 6
	center_of_mass = "x=16;y=17"

/obj/item/reagent_containers/food/snacks/classichotdog/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 16)

/obj/item/reagent_containers/food/snacks/flatbread
	name = "flatbread"
	desc = "Bland but filling."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "flatbread"
	bitesize = 2
	center_of_mass = "x=16;y=16"
	nutriment_desc = list("bread" = 3)
	nutriment_amt = 3

// potato + knife = raw sticks
/obj/item/reagent_containers/food/snacks/grown/potato/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/material/kitchen/utensil/knife))
		new /obj/item/reagent_containers/food/snacks/rawsticks(src)
		to_chat(user, "You cut the potato.")
		qdel(src)
	else
		..()

/obj/item/reagent_containers/food/snacks/rawsticks
	name = "raw potato sticks"
	desc = "Raw fries, not very tasty."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawsticks"
	bitesize = 2
	center_of_mass = "x=16;y=12"
	nutriment_desc = list("raw potato" = 3)
	nutriment_amt = 3

/obj/item/reagent_containers/food/snacks/liquidfood
	name = "\improper LiquidFood MRE"
	desc = "A prepackaged grey slurry for all of the essential nutrients a soldier requires to survive. No expiration date is visible..."
	icon_state = "liquidfood"
	trash = /obj/item/trash/liquidfood
	filling_color = "#a8a8a8"
	center_of_mass = "x=16;y=15"
	nutriment_desc = list("chalk" = 6)
	nutriment_amt = 20

/obj/item/reagent_containers/food/snacks/liquidfood/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/iron, 3)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/smokedsausage
	name = "Smoked sausage"
	desc = "Piece of smoked sausage. Oh, really?"
	icon_state = "smokedsausage"
	center_of_mass = "x=16;y=9"


/obj/item/reagent_containers/food/snacks/smokedsausage/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 12)
	bitesize = 3


/obj/item/reagent_containers/food/snacks/julienne
	name = "Julienne"
	desc = "This is not the Julien, which you can think of, but also nice."
	icon_state = "julienne"
	center_of_mass = "x=15;y=15"
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/julienne/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	reagents.add_reagent(/datum/reagent/drink/juice/onion, 2)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	bitesize = 3


/obj/item/reagent_containers/food/snacks/ricewithmeat
	name = "Rice with meat"
	desc = "This is rice and..'pork'."
	icon_state = "ricewithmeat"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=15;y=15"
	nutriment_amt = 5

/obj/item/reagent_containers/food/snacks/ricewithmeat/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	bitesize = 3



/obj/item/reagent_containers/food/snacks/eggbowl
	name = "Eggbowl"
	desc = "Bowl of eggs. Of course."
	icon_state = "eggbowl"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/eggbowl/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 10)
	bitesize = 3


/obj/item/reagent_containers/food/snacks/meatbun
	name = "Meatbun"
	desc = "Has the potential to not be a dog."
	icon_state = "meatbun"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/meatbun/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 2)
	reagents.add_reagent(/datum/reagent/nutriment, 6)
	bitesize = 4


/obj/item/reagent_containers/food/snacks/eggsbenedict
	name = "Eggs Benedict"
	desc = "It's has only one egg, how rough."
	icon_state = "eggsbenedict"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/eggsbenedict/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)
	reagents.add_reagent(/datum/reagent/nutriment, 6)
	bitesize = 4




/obj/item/reagent_containers/food/snacks/sliceable/salami
	name = "Salami"
	desc = "Not the best for sandwiches."
	icon_state = "salami"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/salami
	slices_num = 6
	center_of_mass = "x=15;y=15"
	nutriment_amt = 2

/obj/item/reagent_containers/food/snacks/sliceable/salami/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 12)

/obj/item/reagent_containers/food/snacks/slice/salami
	name = "Salami's slice"
	desc = "A slice of salami. The best for sandwiches"
	icon_state = "salami_s"
	bitesize = 2
	center_of_mass = "x=15;y=15"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/salami

/obj/item/reagent_containers/food/snacks/slice/salami/filled
	filled = TRUE




/obj/item/reagent_containers/food/snacks/sliceable/sushi
	name = "Sushi"
	desc = "Konnichiwa!"
	icon_state = "sushi"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/sushi
	slices_num = 5
	center_of_mass = "x=15;y=15"


/obj/item/reagent_containers/food/snacks/sliceable/sushi/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/toxin/carpotoxin, 2)
	reagents.add_reagent(/datum/reagent/nutriment, 5)

/obj/item/reagent_containers/food/snacks/slice/sushi
	name = "Sushi's slice"
	desc = "A slice of sushi. Smaller konnichiwa."
	icon_state = "sushi_s"
	bitesize = 2
	center_of_mass = "x=15;y=15"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/sushi

/obj/item/reagent_containers/food/snacks/slice/sushi/filled
	filled = TRUE




/obj/item/reagent_containers/food/snacks/fruitcup
	name = "Dina's fruit cup"
	desc = "Single salad with edible plate"
	icon_state = "fruitcup"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/fruitcup/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/watermelon, 5)
	reagents.add_reagent(/datum/reagent/drink/juice/orange, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 3)
	bitesize = 4


/obj/item/reagent_containers/food/snacks/fruitsalad
	name = "Fruit salad"
	desc = "So sweety!"
	icon_state = "fruitsalad"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/fruitsalad/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/watermelon, 3)
	reagents.add_reagent(/datum/reagent/drink/juice/orange, 3)
	reagents.add_reagent(/datum/reagent/nutriment, 6)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/junglesalad
	name = "Jungle salad"
	desc = "From the depths of the jungle."
	icon_state = "junglesalad"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/junglesalad/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/watermelon, 3)
	reagents.add_reagent(/datum/reagent/nutriment, 6)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/delightsalad
	name = "Delight salad"
	desc = "Truly citrus delight."
	icon_state = "delightsalad"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/delightsalad/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/juice/lime, 4)
	reagents.add_reagent(/datum/reagent/drink/juice/lemon, 4)
	reagents.add_reagent(/datum/reagent/drink/juice/orange, 4)
	reagents.add_reagent(/datum/reagent/nutriment, 3)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/chowmein
	name = "Chowmein"
	desc = "Nihao!"
	icon_state = "chowmein"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/chowmein/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 6)
	reagents.add_reagent(/datum/reagent/nutriment, 6)
	bitesize = 3


/obj/item/reagent_containers/food/snacks/beefnoodles
	name = "Beef noodles"
	desc = "So simple, but so yummy!"
	icon_state = "beefnoodles"
	trash = /obj/item/trash/dish/bowl
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/beefnoodles/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment/protein, 7)
	reagents.add_reagent(/datum/reagent/nutriment, 4)
	bitesize = 2


/obj/item/reagent_containers/food/snacks/tortilla
	name = "Tortilla"
	desc = "Hasta la vista, baby"
	icon_state = "tortilla"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/tortilla/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 4)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/nachos
	name = "Nachos"
	desc = "Hola!"
	icon_state = "nachos"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/nachos/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/cheesenachos
	name = "Cheese nachos"
	desc = "Cheese hola!"
	icon_state = "cheesenachos"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/cheesenachos/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 7)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/cubannachos
	name = "Cuban nachos"
	desc = "Very hot hola!"
	icon_state = "cubannachos"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/cubannachos/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 7)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 1)
	reagents.add_reagent(/datum/reagent/capsaicin, 3)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/eggwrap
	name = "Egg Wrap"
	desc = "Eggs, cabbage, and soy. Interesting."
	icon_state = "eggwrap"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/eggwrap/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/nutriment/soysauce, 10)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/cheeseburrito
	name = "Cheese burrito"
	desc = "Is it really necessary to say something here?"
	icon_state = "cheeseburrito"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/cheeseburrito/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 10)
	reagents.add_reagent(/datum/reagent/nutriment/soysauce, 2)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/sundae
	name = "Sundae"
	desc = "Creamy satisfaction"
	icon_state = "sundae"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/sundae/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 4)
	reagents.add_reagent(/datum/reagent/drink/juice/banana, 4)
	reagents.add_reagent(/datum/reagent/drink/milk/cream, 3)

	bitesize = 5

/obj/item/reagent_containers/food/snacks/burrito
	name = "Burrito"
	desc = "Some really tasty."
	icon_state = "burrito"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/burrito/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 8)
	reagents.add_reagent(/datum/reagent/nutriment/soysauce, 2)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/carnaburrito
	name = "Carna de Asada burrito"
	desc = "Like a classical burrito, but with some meat."
	icon_state = "carnaburrito"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/carnaburrito/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 8)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/nutriment/soysauce, 1)

	bitesize = 4

/obj/item/reagent_containers/food/snacks/plasmaburrito
	name = "Fuego Plasma Burrito"
	desc = "Very hot, amigos."
	icon_state = "plasmaburrito"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/plasmaburrito/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 8)
	reagents.add_reagent(/datum/reagent/capsaicin, 4)
	bitesize = 4

/obj/item/reagent_containers/food/snacks/risotto
	name = "Risotto"
	desc = "An offer you daga kotowaru."
	icon_state = "risotto"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/risotto/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/ethanol/wine, 5)
	bitesize = 3

/obj/item/reagent_containers/food/snacks/bruschetta
	name = "Bruschetta"
	desc = "..."
	icon_state = "bruschetta"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/bruschetta/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 7)
	reagents.add_reagent(/datum/reagent/sodiumchloride, 2)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 2)
	reagents.add_reagent(/datum/reagent/drink/juice/garlic, 1)

	bitesize = 4

/obj/item/reagent_containers/food/snacks/quiche
	name = "Quiche"
	desc = "Makes you feel more intelligent. Give to lower lifeforms!"
	icon_state = "quiche"
	trash = /obj/item/trash/dish/plate
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/quiche/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 9)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 2)
	reagents.add_reagent(/datum/reagent/drink/juice/garlic, 1)

	bitesize = 4

/obj/item/reagent_containers/food/snacks/lasagna
	name = "Lasagna"
	desc = "You can hide a bomb in the lasagna"
	icon_state = "lasagna"
	center_of_mass = "x=15;y=15"

/obj/item/reagent_containers/food/snacks/lasagna/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 10)
	reagents.add_reagent(/datum/reagent/drink/juice/tomato, 5)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 4)

	bitesize = 4


/obj/item/reagent_containers/food/snacks/sliceable/noel
	name = "Buche de Noel"
	desc = "What?"
	icon_state = "noel"
	trash = /obj/item/trash/dish/tray
	slice_path = /obj/item/reagent_containers/food/snacks/slice/noel
	slices_num = 5
	center_of_mass = "x=15;y=15"


/obj/item/reagent_containers/food/snacks/sliceable/noel/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/drink/milk/cream, 3)
	reagents.add_reagent(/datum/reagent/nutriment, 8)
	reagents.add_reagent(/datum/reagent/sugar, 3)
	reagents.add_reagent(/datum/reagent/drink/juice/berry, 3)
	reagents.add_reagent(/datum/reagent/nutriment/coco, 2)

/obj/item/reagent_containers/food/snacks/slice/noel
	name = "Noel's slice"
	desc = "Slice of what?"
	icon_state = "noel_s"
	trash = /obj/item/trash/dish/plate
	bitesize = 2
	center_of_mass = "x=15;y=15"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/noel

/obj/item/reagent_containers/food/snacks/slice/noel/filled
	filled = TRUE



/obj/item/reagent_containers/food/snacks/sliceable/choccherrycake
	name = "Chocolate - cherry cake"
	desc = "Another cake. However."
	icon_state = "choccherrycake"
	slice_path = /obj/item/reagent_containers/food/snacks/slice/choccherrycake
	slices_num = 6
	center_of_mass = "x=15;y=15"


/obj/item/reagent_containers/food/snacks/sliceable/choccherrycake/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/nutriment, 10)
	reagents.add_reagent(/datum/reagent/sugar, 3)
	reagents.add_reagent(/datum/reagent/nutriment/coco, 4)

/obj/item/reagent_containers/food/snacks/slice/choccherrycake
	name = "Chocolate - cherry cake's slice"
	desc = "Slice of another cake. Wait, what?"
	icon_state = "choccherrycake_s"
	trash = /obj/item/trash/dish/plate
	bitesize = 2
	center_of_mass = "x=15;y=15"
	whole_path = /obj/item/reagent_containers/food/snacks/sliceable/choccherrycake

/obj/item/reagent_containers/food/snacks/slice/choccherrycake/filled
	filled = TRUE
