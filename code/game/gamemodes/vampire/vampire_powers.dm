// Contains all /mob/procs that relate to vampire.
/mob/living/carbon/human/AltClickOn(atom/A)
	if(mind && mind.vampire && istype(A , /turf/simulated/floor) && (/mob/living/carbon/human/proc/vampire_veilstep in verbs))
		vampire_veilstep(A)
	..()

// Makes vampire's victim not get paralyzed, and remember the suckings
/mob/living/carbon/human/proc/vampire_alertness()
	set category = "Vampire"
	set name = "Victim Alertness"
	set desc = "Toggle whether you wish for your victims to forget your deeds."
	var/power_use_cost = 0
	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	vampire.stealth = !vampire.stealth
	if(vampire.stealth)
		to_chat(src, SPAN_NOTICE("Your victims will now forget your interactions."))
	else
		to_chat(src, SPAN_NOTICE("Your victims will now remember your interactions."))

// Drains the target's blood.
/mob/living/carbon/human/proc/vampire_drain_blood()
	set category = "Vampire"
	set name = "Drain Blood"
	set desc = "Drain the blood of a humanoid creature."
	var/power_use_cost = 0
	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	var/obj/item/grab/G = get_active_hand()
	if (!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a victim in your active hand to drain their blood."))
		return
	if(!G.can_absorb())
		to_chat(src, SPAN_WARNING("You must have a tighter grip on victim to drain their blood."))
		return

	var/mob/living/carbon/human/T = G.affecting
	if (!istype(T) || T.isSynthetic() || T.species.species_flags & SPECIES_FLAG_NO_BLOOD)
		//Added this to prevent vampires draining diona and IPCs
		//Diona have 'blood' but its really green sap and shouldn't help vampires
		//IPCs leak oil
		to_chat(src, SPAN_WARNING("[T] is not a creature you can drain useful blood from."))
		return
	if(T.head && (T.head.item_flags & ITEM_FLAG_AIRTIGHT))
		to_chat(src, SPAN_WARNING("[T]'s headgear is blocking the way to the neck."))
		return
	var/obj/item/blocked = check_mouth_coverage()
	if(blocked)
		to_chat(src, SPAN_WARNING("\The [blocked] is in the way of your fangs!"))
		return
	if (vampire.status & VAMP_DRAINING)
		to_chat(src, SPAN_WARNING("Your fangs are already sunk into a victim's neck!"))
		return

	var/datum/vampire/draining_vamp = null
	if (T.mind && T.mind.vampire)
		draining_vamp = T.mind.vampire

	var/target_aware = !!T.client

	var/blood = 0
	var/blood_total = 0
	var/blood_usable = 0
	var/blood_drained = 0

	vampire.status |= VAMP_DRAINING

	visible_message(SPAN_DANGER("[src.name] bites [T.name]'s neck!"), SPAN_DANGER("You bite [T.name]'s neck and begin to drain their blood."), SPAN_NOTICE("You hear a soft puncture and a wet sucking noise"))
	var/remembrance
	if(vampire.stealth)
		remembrance = "forgot"
	else
		remembrance = "remembered"
	admin_attack_log(src, T, "drained blood from [key_name(T)], who [remembrance] the encounter.", "had their blood drained by [key_name(src)] and [remembrance] the encounter.", "is draining blood from")

	to_chat(T, SPAN("warning", FONT_LARGE("You feel yourself falling into a pleasant dream, from which even a smile appeared on your face.")))
	T.paralysis = 3400

	playsound(src.loc, 'sound/effects/drain_blood.ogg', 50, 1)


	while (do_mob(src, T, 50))
		if (!mind.vampire)
			to_chat(src, SPAN_DANGER("Your fangs have disappeared!"))
			return
		if (blood_drained >= 115)
			to_chat(src, SPAN_DANGER("You can't drink even more blood!"))
			break
		blood_total = vampire.blood_total
		blood_usable = vampire.blood_usable

		if (!T.vessel.get_reagent_amount(/datum/reagent/blood))
			to_chat(src, SPAN_DANGER("[T] has no more blood left to give."))
			break

		if (!T.stunned)
			T.Stun(10)

		var/frenzy_lower_chance = 0

		// Alive and not of empty mind.
		if (check_drain_target_state(T))
			blood = min(15, T.vessel.get_reagent_amount(/datum/reagent/blood))
			vampire.blood_total += blood
			vampire.blood_usable += blood
			blood_drained += blood

			frenzy_lower_chance = 40

			if (draining_vamp)
				vampire.blood_vamp += blood
				// Each point of vampire blood will increase your chance to frenzy.
				vampire.frenzy += blood

				// And drain the vampire as well.
				draining_vamp.blood_usable -= min(blood, draining_vamp.blood_usable)
				vampire_check_frenzy()

				frenzy_lower_chance = 0
		// SSD/protohuman or dead.
		else
			blood = min(5, T.vessel.get_reagent_amount(/datum/reagent/blood))
			vampire.blood_usable += blood
			blood_drained += blood

			frenzy_lower_chance = 40

		if (prob(frenzy_lower_chance) && vampire.frenzy > 0)
			vampire.frenzy--

		if (blood_total != vampire.blood_total)
			var/update_msg = SPAN_NOTICE("You have accumulated [vampire.blood_total] [vampire.blood_total > 1 ? "units" : "unit"] of blood")
			if (blood_usable != vampire.blood_usable)
				update_msg += SPAN_NOTICE(" and have [vampire.blood_usable] left to use.")
			else
				update_msg += SPAN_NOTICE(".")
			to_chat(src, update_msg)

		if (blood_drained >= 70 && blood_drained < 85)
			to_chat(src, SPAN_WARNING("You have enough amount of drained blood."))


		check_vampire_upgrade()
		T.vessel.remove_reagent(/datum/reagent/blood, 15)

	vampire.status &= ~VAMP_DRAINING

	var/endsuckmsg = "You extract your fangs from [T.name]'s neck and stop draining them of blood."
	if(vampire.stealth)
		endsuckmsg += "They will remember nothing of this occurance, provided they survived."
	visible_message(SPAN_DANGER("[src.name] stops biting [T.name]'s neck!"), SPAN_NOTICE("[endsuckmsg]"))
	if(target_aware)
		T.paralysis = 0
		if(T.stat != DEAD && vampire.stealth)
			spawn()			//Spawned in the same manner the brain damage alert is, just so the proc keeps running without stops.
				alert(T, "You remember NOTHING about the cause of your blackout. Instead, you remember having a pleasant encounter with [src.name].", "Bitten by a vampire")
		else if(T.stat != DEAD)
			spawn()
				alert(T, "You remember everything that happened. Remember how blood was sucked from your neck. It gave you pleasure, like a pleasant dream. You feel great. How you react to [src.name]'s actions is up to you.", "Bitten by a vampire")
	verbs -= /mob/living/carbon/human/proc/vampire_drain_blood
	if(blood_drained <= 85)

		ADD_VERB_IN_IF(src, 1800, /mob/living/carbon/human/proc/vampire_drain_blood, CALLBACK(src, .proc/finish_vamp_timeout))
	else
		ADD_VERB_IN_IF(src, 2400, /mob/living/carbon/human/proc/vampire_drain_blood, CALLBACK(src, .proc/finish_vamp_timeout))

// Check that our target is alive, logged in, and any other special cases
/mob/living/carbon/human/proc/check_drain_target_state(mob/living/carbon/human/T)
	if(T.stat < DEAD && T.client)
		return TRUE

// Small area of effect stun.
/mob/living/carbon/human/proc/vampire_glare()
	set category = "Vampire"
	set name = "Glare"
	set desc = "Your eyes flash a bright light, stunning any who are watching."
	var/power_use_cost = 0

	if (!vampire_power(power_use_cost, 1))
		return
	if (eyecheck() > FLASH_PROTECTION_NONE)
		to_chat(src, SPAN_WARNING("You can't do that, because no one will see the light of your eyes!"))
		return

	visible_message(SPAN_DANGER("[src.name]'s eyes emit a blinding flash"))
	var/list/victims = list()
	for (var/mob/living/carbon/human/H in view(2))
		if (H == src)
			continue
		if (!vampire_can_affect_target(H, 0))
			continue
		if (eyecheck() > FLASH_PROTECTION_NONE)
			continue
		H.Weaken(8)
		H.Stun(6)
		H.stuttering = 20
		H.confused = 10
		to_chat(H, SPAN_DANGER("You are blinded by [src]'s glare!"))
		H.flash_eyes()
		victims += H

	admin_attacker_log_many_victims(src, victims, "used glare to stun", "was stunned by [key_name(src)] using glare", "used glare to stun")

	verbs -= /mob/living/carbon/human/proc/vampire_glare
	ADD_VERB_IN_IF(src, 800, /mob/living/carbon/human/proc/vampire_glare, CALLBACK(src, .proc/finish_vamp_timeout))

// Targeted stun ability, moderate duration.
/mob/living/carbon/human/proc/vampire_hypnotise()
	set category = "Vampire"
	set name = "Hypnotise (10)"
	set desc = "Through blood magic, you dominate the victim's mind and force them into a hypnotic transe."
	var/power_use_cost = 10

	var/datum/vampire/vampire = vampire_power(power_use_cost, 1)
	if (!vampire)
		return

	if (eyecheck() > FLASH_PROTECTION_NONE)
		to_chat(src, SPAN_WARNING("You can't do that, because no one will see your eyes!"))
		return

	var/list/victims = list()
	for (var/mob/living/carbon/human/H in view(3))
		if (H == src)
			continue
		if(H.eyecheck() > FLASH_PROTECTION_MODERATE)
			continue
		victims += H
	if (!victims.len)
		to_chat(src, SPAN_WARNING("No suitable targets."))
		return

	var/mob/living/carbon/human/T = input(src, "Select Victim") as null|mob in victims

	if (!vampire_can_affect_target(T))
		return

	to_chat(src, SPAN_NOTICE("You begin peering into [T.name]'s mind, looking for a way to render them useless."))

	if (do_mob(src, T, 50))
		to_chat(src, SPAN_DANGER("You dominate [T.name]'s mind and render them temporarily powerless to resist"))
		to_chat(T, SPAN_DANGER("You are captivated by [src.name]'s gaze, and find yourself unable to move or even speak."))
		T.Weaken(25)
		T.Stun(25)
		T.silent += 30

		vampire.use_blood(power_use_cost)
		admin_attack_log(src, T, "used hypnotise to stun [key_name(T)]", "was stunned by [key_name(src)] using hypnotise", "used hypnotise on")

		verbs -= /mob/living/carbon/human/proc/vampire_hypnotise
		ADD_VERB_IN_IF(src, 1200, /mob/living/carbon/human/proc/vampire_hypnotise, CALLBACK(src, .proc/finish_vamp_timeout))
	else
		to_chat(src, SPAN_WARNING("You broke your gaze."))

// Targeted teleportation, must be to a low-light tile.
/mob/living/carbon/human/proc/vampire_veilstep(turf/simulated/floor/T in view(7))
	set category = null
	set name = "Veil Step (20)"
	set desc = "For a moment, move through the Veil and emerge at a shadow of your choice."
	var/power_use_cost = 20

	if (!T || T.density || T.contains_dense_objects())
		to_chat(src, SPAN_WARNING("You cannot do that."))
		return

	var/datum/vampire/vampire = vampire_power(power_use_cost, 1)
	if (!vampire)
		return
	if (!istype(loc, /turf))
		to_chat(src, SPAN_WARNING("You cannot teleport out of your current location."))
		return
	if (T.z != src.z || get_dist(T, get_turf(src)) > world.view)
		to_chat(src, SPAN_WARNING("Your powers are not capable of taking you that far."))
		return
	if (T.get_lumcount() > 0.1)
		// Too bright, cannot jump into.
		to_chat(src, SPAN_WARNING("The destination is too bright."))
		return

	vampire_phase_out(get_turf(loc))
	vampire_phase_in(T)
	forceMove(T)

	for (var/obj/item/grab/G in contents)
		if (G.affecting && (vampire.status & VAMP_FULLPOWER))
			G.affecting.vampire_phase_out(get_turf(G.affecting.loc))
			G.affecting.vampire_phase_in(get_turf(G.affecting.loc))
			G.affecting.forceMove(locate(T.x + rand(-1,1), T.y + rand(-1,1), T.z))
		else
			qdel(G)

	log_and_message_admins("activated veil step.")

	vampire.use_blood(power_use_cost)
	verbs -= /mob/living/carbon/human/proc/vampire_veilstep
	ADD_VERB_IN_IF(src, 300, /mob/living/carbon/human/proc/vampire_veilstep, CALLBACK(src, .proc/finish_vamp_timeout))

// Summons bats.
/mob/living/carbon/human/proc/vampire_bats()
	set category = "Vampire"
	set name = "Summon Bats (60)"
	set desc = "You tear open the Veil for just a moment, in order to summon a pair of bats to assist you in combat."
	var/power_use_cost = 60

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	var/list/locs = list()

	for (var/direction in GLOB.alldirs)
		if (locs.len == 2)
			break

		var/turf/T = get_step(src, direction)
		if (AStar(src.loc, T, /turf/proc/AdjacentTurfs, /turf/proc/Distance, 1))
			locs += T

	var/list/spawned = list()
	if (locs.len)
		for (var/turf/to_spawn in locs)
			spawned += new /mob/living/simple_animal/hostile/scarybat(to_spawn, src)

		if (spawned.len != 2)
			spawned += new /mob/living/simple_animal/hostile/scarybat(src.loc, src)
	else
		spawned += new /mob/living/simple_animal/hostile/scarybat(src.loc, src)
		spawned += new /mob/living/simple_animal/hostile/scarybat(src.loc, src)

	if (!spawned.len)
		return

	for (var/mob/living/simple_animal/hostile/scarybat/bat in spawned)
		LAZYADD(bat.friends, src)

		if (vampire.thralls.len)
			LAZYADD(bat.friends, vampire.thralls)

	log_and_message_admins("summoned bats.")

	vampire.use_blood(power_use_cost)
	verbs -= /mob/living/carbon/human/proc/vampire_bats
	ADD_VERB_IN_IF(src, 1200, /mob/living/carbon/human/proc/vampire_bats, CALLBACK(src, .proc/finish_vamp_timeout))

// Chiropteran Screech
/mob/living/carbon/human/proc/vampire_screech()
	set category = "Vampire"
	set name = "Chiropteran Screech (70)"
	set desc = "Emit a powerful screech which shatters glass within a seven-tile radius, and stuns hearers in a four-tile radius."
	var/power_use_cost = 70

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	visible_message(SPAN_DANGER("[src.name] lets out an ear piercin shriek!"), SPAN_DANGER("You let out an ear-shattering shriek!"), SPAN_DANGER("You hear a painfully loud shriek!"))

	var/list/victims = list()

	for (var/mob/living/carbon/human/T in hearers(4, src))
		if (T == src)
			continue
		if (T.get_ear_protection() > 2)
			continue
		if (!vampire_can_affect_target(T, 0))
			continue

		to_chat(T, SPAN_DANGER("You hear an ear piercing shriek and feel your senses go dull!"))
		T.Weaken(5)
		T.ear_deaf = 20
		T.stuttering = 20
		T.Stun(5)

		victims += T

	for (var/obj/structure/window/W in view(7))
		W.shatter()

	for (var/obj/machinery/light/L in view(7))
		L.broken()

	playsound(src.loc, 'sound/effects/creepyshriek.ogg', 100, 1)
	vampire.use_blood(power_use_cost)

	if (victims.len)
		admin_attacker_log_many_victims(src, victims, "used chriopteran screech to stun", "was stunned by [key_name(src)] using chriopteran screech", "used chiropteran screech to stun")
	else
		log_and_message_admins("used chiropteran screech.")

	verbs -= /mob/living/carbon/human/proc/vampire_screech
	ADD_VERB_IN_IF(src, 3600, /mob/living/carbon/human/proc/vampire_screech, CALLBACK(src, .proc/finish_vamp_timeout))

// Enables the vampire to be untouchable and walk through walls and other solid things.
/mob/living/carbon/human/proc/vampire_veilwalk()
	set category = "Vampire"
	set name = "Toggle Veil Walking (80)"
	set desc = "You enter the veil, leaving only an incorporeal manifestation of you visible to the others."
	var/power_use_cost = 80

	var/datum/vampire/vampire = vampire_power(0, 0, 1)
	if (!vampire)
		return

	if (vampire.holder)
		vampire.holder.deactivate()
	else
		vampire = vampire_power(power_use_cost, 0, 1)
		if (!vampire)
			return

		var/obj/effect/dummy/veil_walk/holder = new /obj/effect/dummy/veil_walk(get_turf(loc))
		holder.activate(src)

		log_and_message_admins("activated veil walk.")

		vampire.use_blood(power_use_cost)

// Veilwalk's dummy holder
/obj/effect/dummy/veil_walk
	name = "a red ghost"
	desc = "A red, shimmering presence."
	icon = 'icons/mob/mob.dmi'
	icon_state = "blank"
	density = FALSE
	var/power_use_cost = 5

	var/last_valid_turf = null
	var/can_move = TRUE
	var/mob/owner_mob = null
	var/datum/vampire/owner_vampire = null
	var/warning_level = 0

/obj/effect/dummy/veil_walk/Destroy()
	eject_all()

	STOP_PROCESSING(SSprocessing, src)

	return ..()

/obj/effect/dummy/veil_walk/proc/eject_all()
	for (var/atom/movable/A in src)
		A.forceMove(loc)
		if (ismob(A))
			var/mob/M = A
			M.reset_view(null)

/obj/effect/dummy/veil_walk/relaymove(mob/user, direction)
	if (!can_move)
		return

	var/turf/new_loc = get_step(src, direction)
	if (new_loc.turf_flags & TURF_FLAG_NOJAUNT || istype(new_loc.loc, /area/chapel))
		to_chat(usr, SPAN_WARNING("Some strange aura is blocking the way!"))
		return

	forceMove(new_loc)
	var/turf/T = get_turf(loc)
	if (!T.contains_dense_objects())
		last_valid_turf = T

	can_move = 0
	addtimer(CALLBACK(src, .proc/unlock_move), 2, TIMER_UNIQUE)

/obj/effect/dummy/veil_walk/Process()
	if (owner_mob.stat)
		if (owner_mob.stat == 1)
			to_chat(owner_mob, SPAN_WARNING("You cannot maintain this form while unconcious."))
			addtimer(CALLBACK(src, .proc/kick_unconcious), 10, TIMER_UNIQUE)
		else
			deactivate()
			return

	if (owner_vampire.blood_usable >= 5)
		owner_vampire.use_blood(power_use_cost)

		switch (warning_level)
			if (0)
				if (owner_vampire.blood_usable <= 5 * 20)
					to_chat(owner_mob, SPAN_NOTICE("Your pool of blood is diminishing. You cannot stay in the veil for too long."))
					warning_level = 1
			if (1)
				if (owner_vampire.blood_usable <= 5 * 10)
					to_chat(owner_mob, SPAN_WARNING("You will be ejected from the veil soon, as your pool of blood is running dry."))
					warning_level = 2
			if (2)
				if (owner_vampire.blood_usable <= 5 * 5)
					to_chat(owner_mob, SPAN_DANGER("You cannot sustain this form for any longer!"))
					warning_level = 3
	else
		deactivate()

/obj/effect/dummy/veil_walk/proc/activate(mob/owner)
	if (!owner)
		qdel(src)
		return

	owner_mob = owner
	owner_vampire = owner.vampire_power()
	if (!owner_vampire)
		qdel(src)
		return

	owner_vampire.holder = src

	owner.vampire_phase_out(get_turf(owner.loc))

	icon_state = "shade"

	last_valid_turf = get_turf(owner.loc)
	owner.forceMove(src)

	desc += " Its features look faintly alike [owner.name]'s."

	START_PROCESSING(SSprocessing, src)

/obj/effect/dummy/veil_walk/proc/deactivate()
	STOP_PROCESSING(SSprocessing, src)

	can_move = 0

	icon_state = "blank"

	owner_mob.vampire_phase_in(get_turf(loc))

	eject_all()

	owner_mob = null

	owner_vampire.holder = null
	owner_vampire = null

	qdel(src)

/obj/effect/dummy/veil_walk/proc/unlock_move()
	can_move = 1

/obj/effect/dummy/veil_walk/proc/kick_unconcious()
	if (owner_mob && owner_mob.stat == 1)
		to_chat(owner_mob, SPAN_DANGER("You are ejected from the Veil."))
		deactivate()
		return

/obj/effect/dummy/veil_walk/ex_act(vars)
	return

/obj/effect/dummy/veil_walk/bullet_act(vars)
	return

// Heals the vampire at the cost of blood.
/mob/living/carbon/human/proc/vampire_bloodheal()
	set category = "Vampire"
	set name = "Blood Heal"
	set desc = "At the cost of blood and time, heal any injuries you have sustained."

	var/datum/vampire/vampire = vampire_power(0, 0)
	if (!vampire)
		return

	// Kick out of the already running loop.
	if (vampire.status & VAMP_HEALING)
		vampire.status &= ~VAMP_HEALING
		return
	else if (vampire.blood_usable < 15)
		to_chat(src, SPAN_WARNING("You do not have enough usable blood. 15 needed."))
		return

	vampire.status |= VAMP_HEALING
	to_chat(src, SPAN_NOTICE("You begin the process of blood healing. Do not move, and ensure that you are not interrupted."))

	log_and_message_admins("activated blood heal.")

	while (do_after(src, 20, 0))
		if (!(vampire.status & VAMP_HEALING))
			to_chat(src, SPAN_WARNING("Your concentration is broken! You are no longer regenerating!"))
			break

		var/tox_loss = getToxLoss()
		var/oxy_loss = getOxyLoss()
		var/ext_loss = getBruteLoss() + getFireLoss()
		var/clone_loss = getCloneLoss()

		var/blood_used = 0
		var/to_heal = 0

		if (tox_loss)
			to_heal = min(10, tox_loss)
			adjustToxLoss(0 - to_heal)
			blood_used += round(to_heal * 1.2)
		if (oxy_loss)
			to_heal = min(10, oxy_loss)
			adjustOxyLoss(0 - to_heal)
			blood_used += round(to_heal * 1.2)
		if (ext_loss)
			to_heal = min(20, ext_loss)
			heal_overall_damage(min(10, getBruteLoss()), min(10, getFireLoss()))
			blood_used += round(to_heal * 1.2)
		if (clone_loss)
			to_heal = min(10, clone_loss)
			adjustCloneLoss(0 - to_heal)
			blood_used += round(to_heal * 1.2)

		var/list/organs = get_damaged_organs(1, 1)
		if (organs.len)
			// Heal an absurd amount, basically regenerate one organ.
			heal_organ_damage(50, 50)
			blood_used += 12

		for(var/obj/item/organ/external/current_organ in organs)
			for(var/datum/wound/wound in current_organ.wounds)
				wound.embedded_objects.Cut()

			// remove embedded objects and drop them on the floor
			for(var/obj/implanted_object in current_organ.implants)
				if(!istype(implanted_object,/obj/item/implant))	// We don't want to remove REAL implants. Just shrapnel etc.
					implanted_object.loc = get_turf(src)
					current_organ.implants -= implanted_object

		for (var/A in organs)
			var/healed = FALSE
			var/obj/item/organ/external/E = A
			if(E.status & ORGAN_ARTERY_CUT)
				E.status &= ~ORGAN_ARTERY_CUT
				blood_used += 12
			if(E.status & ORGAN_TENDON_CUT)
				E.status &= ~ORGAN_TENDON_CUT
				blood_used += 12
			if(E.status & ORGAN_BROKEN)
				E.mend_fracture()
				E.stage = 0
				blood_used += 12
				healed = TRUE

			if (healed)
				break

		for(var/ID in virus2)
			var/datum/disease2/disease/V = virus2[ID]
			V.cure(src)

		var/list/emotes_lookers = list("[src]'s skin appears to liquefy for a moment, sealing up their wounds.",
									"[src]'s veins turn black as their damaged flesh regenerates before your eyes!",
									"[src]'s skin begins to split open. It turns to ash and falls away, revealing the wound to be fully healed.",
									"Whispering arcane things, [src]'s damaged flesh appears to regenerate.",
									"Thick globs of blood cover a wound on [src]'s body, eventually melding to be one with \his flesh.",
									"[src]'s body crackles, skin and bone shifting back into place.")
		var/list/emotes_self = list("Your skin appears to liquefy for a moment, sealing up your wounds.",
									"Your veins turn black as their damaged flesh regenerates before your eyes!",
									"Your skin begins to split open. It turns to ash and falls away, revealing the wound to be fully healed.",
									"Whispering arcane things, your damaged flesh appears to regenerate.",
									"Thick globs of blood cover a wound on your body, eventually melding to be one with your flesh.",
									"Your body crackles, skin and bone shifting back into place.")

		if (prob(20))
			visible_message(SPAN_DANGER("[pick(emotes_lookers)]"), SPAN_NOTICE("[pick(emotes_self)]"))

		if (vampire.blood_usable <= blood_used)
			vampire.blood_usable = 0
			vampire.status &= ~VAMP_HEALING
			to_chat(src, SPAN_WARNING("You ran out of blood, and are unable to continue!"))
			break
		else if (!blood_used)
			vampire.status &= ~VAMP_HEALING
			to_chat(src, SPAN_NOTICE("Your body has finished healing. You are ready to continue."))
			break

	// We broke out of the loop naturally. Gotta catch that.
	if (vampire.status & VAMP_HEALING)
		vampire.status &= ~VAMP_HEALING
		to_chat(src, SPAN_WARNING("Your concentration is broken! You are no longer regenerating!"))

	return

// Dominate a victim, imbed a thought into their mind.
/mob/living/carbon/human/proc/vampire_dominate()
	set category = "Vampire"
	set name = "Dominate (50)"
	set desc = "Dominate the mind of a victim, make them obey your will."
	var/power_use_cost = 50

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	var/list/victims = list()
	for (var/mob/living/carbon/human/H in view(7))
		if (H == src)
			continue
		victims += H

	if (!victims.len)
		to_chat(src, SPAN_WARNING("No suitable targets."))
		return

	var/mob/living/carbon/human/T = input(src, "Select Victim") as null|mob in victims

	if (!vampire_can_affect_target(T, 1, 1))
		return

	if (!(vampire.status & VAMP_FULLPOWER))
		to_chat(src, SPAN_NOTICE("You begin peering into [T]'s mind, looking for a way to gain control."))

		if (!do_mob(src, T, 50))
			to_chat(src, SPAN_WARNING("Your concentration is broken!"))
			return

		to_chat(src, SPAN_NOTICE("You succeed in dominating [T]'s mind. They are yours to command."))
	else
		to_chat(src, SPAN_NOTICE("You instantly dominate [T]'s mind, forcing them to obey your command."))

	var/command = input(src, "Command your victim.", "Your command.") as text|null

	if (!command)
		to_chat(src, "<span class='alert'>Cancelled.</span>")
		return

	command = sanitizeSafe(command, extra = 0)

	admin_attack_log(src, T, "used dominate on [key_name(T)]", "was dominated by [key_name(src)]", "used dominate and issued the command of '[command]' to")

	show_browser(T, "<HTML><meta charset=\"utf-8\"><center>You feel a strong presence enter your mind. For a moment, you hear nothing but what it says, <b>and are compelled to follow its direction without question or hesitation:</b><br>[command]</center></BODY></HTML>", "window=vampiredominate")
	to_chat(T, SPAN_NOTICE("You feel a strong presence enter your mind. For a moment, you hear nothing but what it says, and are compelled to follow its direction without question or hesitation:"))
	to_chat(T, "<span style='color: green;'><i><em>[command]</em></i></span>")
	to_chat(src, SPAN_NOTICE("You command [T], and they will obey."))
	emote("me", 1, "whispers.")

	vampire.use_blood(power_use_cost)
	verbs -= /mob/living/carbon/human/proc/vampire_dominate
	ADD_VERB_IN_IF(src, 1800, /mob/living/carbon/human/proc/vampire_dominate, CALLBACK(src, .proc/finish_vamp_timeout))

// Enthralls a person, giving the vampire a mortal slave.
/mob/living/carbon/human/proc/vampire_enthrall()
	set category = "Vampire"
	set name = "Enthrall (120)"
	set desc = "Bind a mortal soul with a bloodbond to obey your every command."
	var/power_use_cost = 120

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	var/obj/item/grab/G = get_active_hand()
	if (!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a victim in your active hand to enthrall them."))
		return
	if(!G.can_absorb())
		to_chat(src, SPAN_WARNING("You must have a tighter grip on victim to enthrall them."))
		return

	var/mob/living/carbon/human/T = G.affecting
	if(!istype(T) || T.isSynthetic())
		to_chat(src, SPAN_WARNING("[T] is not a creature you can enthrall."))
		return
	if (!vampire_can_affect_target(T, 1, 1))
		return
	if (!T.client || !T.mind)
		to_chat(src, SPAN_WARNING("[T]'s mind is empty and useless. They cannot be forced into a blood bond."))
		return
	if (vampire.status & VAMP_DRAINING)
		to_chat(src, SPAN_WARNING("Your fangs are already sunk into a victim's neck!"))
		return

	visible_message(SPAN_DANGER("[src] tears the flesh on their wrist, and holds it up to [T]. In a gruesome display, [T] starts lapping up the blood that's oozing from the fresh wound."), SPAN_WARNING("You inflict a wound upon yourself, and force them to drink your blood, thus starting the conversion process"))
	to_chat(T, SPAN_WARNING("You feel an irresistable desire to drink the blood pooling out of [src]'s wound. Against your better judgement, you give in and start doing so."))

	if (!do_mob(src, T, 50))
		visible_message(SPAN_WARNING("[src] yanks away their hand from [T]'s mouth as they're interrupted, the wound quickly sealing itself!"), SPAN_DANGER("You are interrupted!"))
		return

	to_chat(T, SPAN_DANGER("Your mind blanks as you finish feeding from [src]'s wrist."))
	GLOB.thralls.add_antagonist(T.mind, 1, 1, 0, 1, 1)

	T.mind.vampire.master = src
	vampire.thralls += T
	to_chat(T, SPAN_NOTICE("You have been forced into a blood bond by [T.mind.vampire.master], and are thus their thrall. While a thrall may feel a myriad of emotions towards their master, ranging from fear, to hate, to love; the supernatural bond between them still forces the thrall to obey their master, and to listen to the master's commands.<br><br>You must obey your master's orders, you must protect them, you cannot harm them."))
	to_chat(src, SPAN_NOTICE("You have completed the thralling process. They are now your slave and will obey your commands."))
	admin_attack_log(src, T, "enthralled [key_name(T)]", "was enthralled by [key_name(src)]", "successfully enthralled")

	vampire.use_blood(power_use_cost)
	verbs -= /mob/living/carbon/human/proc/vampire_enthrall
	ADD_VERB_IN_IF(src, 2800, /mob/living/carbon/human/proc/vampire_enthrall, CALLBACK(src, .proc/finish_vamp_timeout))

// Makes the vampire appear 'friendlier' to others.
/mob/living/carbon/human/proc/vampire_presence()
	set category = "Vampire"
	set name = "Presence (5)"
	set desc = "Influences those weak of mind to look at you in a friendlier light."
	var/power_use_cost = 5

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	if (vampire.status & VAMP_PRESENCE)
		vampire.status &= ~VAMP_PRESENCE
		to_chat(src, SPAN_WARNING("You are no longer influencing those weak of mind."))
		return
	else if (vampire.blood_usable < 10)
		to_chat(src, SPAN_WARNING("You do not have enough usable blood. 10 needed."))
		return

	to_chat(src, SPAN_NOTICE("You begin passively influencing the weak minded."))
	vampire.status |= VAMP_PRESENCE

	var/list/mob/living/carbon/human/affected = list()
	var/list/emotes = list("[src] looks trusthworthy.",
							"You feel as if [src] is a relatively friendly individual.",
							"You feel yourself paying more attention to what [src] is saying.",
							"[src] has your best interests at heart, you can feel it.",
							"A quiet voice tells you that [src] should be considered a friend.")

	vampire.use_blood(power_use_cost)

	log_and_message_admins("activated presence.")

	while (vampire.status & VAMP_PRESENCE)
		// Run every 20 seconds
		sleep(200)

		if (stat)
			to_chat(src, SPAN_WARNING("You cannot influence people around you while [stat == 1 ? "unconcious" : "dead"]."))
			vampire.status &= ~VAMP_PRESENCE
			break

		for (var/mob/living/carbon/human/T in view(5))
			if (T == src)
				continue
			if (!vampire_can_affect_target(T, 0, 1))
				continue
			if (!T.client)
				continue

			var/probability = 50
			if (!(T in affected))
				affected += T
				probability = 80

			if (prob(probability))
				to_chat(T, "<font color='green'><i>[pick(emotes)]</i></font>")

		vampire.use_blood(power_use_cost)

		if (vampire.blood_usable < 5)
			vampire.status &= ~VAMP_PRESENCE
			to_chat(src, SPAN_WARNING("You are no longer influencing those weak of mind."))
			break

/mob/living/carbon/human/proc/vampire_touch_of_life()
	set category = "Vampire"
	set name = "Touch of Life (30)"
	set desc = "You lay your hands on the target, transferring healing chemicals to them."
	var/power_use_cost = 30

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	var/obj/item/grab/G = get_active_hand()
	if (!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a victim in your active hand to touch them."))
		return

	var/mob/living/carbon/human/T = G.affecting
	if (T.isSynthetic() || T.species.species_flags & SPECIES_FLAG_NO_BLOOD)
		to_chat(src, SPAN_WARNING("[T] has no blood and can not be affected by your powers!"))
		return

	visible_message("<b>[src]</b> gently touches [T].")
	to_chat(T, SPAN_NOTICE("You feel pure bliss as [src] touches you."))
	vampire.use_blood(power_use_cost)

	T.reagents.add_reagent(/datum/reagent/rezadone, 3)
	T.reagents.add_reagent(/datum/reagent/tramadol/oxycodone, 0.15) //enough to get back onto their feet

// Convert a human into a vampire.
/mob/living/carbon/human/proc/vampire_embrace()
	set category = "Vampire"
	set name = "The Embrace"
	set desc = "Spread your corruption to an innocent soul, turning them into a spawn of the Veil, much akin to yourself."
	var/power_use_cost = 0

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	// Re-using blood drain code.
	var/obj/item/grab/G = get_active_hand()
	if (!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a victim in your active hand to drain their blood"))
		return
	if(!G.can_absorb())
		to_chat(src, SPAN_WARNING("You must have a tighter grip on victim to drain their blood."))
		return

	var/mob/living/carbon/human/T = G.affecting
	if (!vampire_can_affect_target(T, ignore_thrall = TRUE))
		return
	if (!T.client)
		to_chat(src, SPAN_WARNING("[T] is a mindless husk. The Veil has no purpose for them."))
		return
	if (T.stat == 2)
		to_chat(src, SPAN_WARNING("[T]'s body is broken and damaged beyond salvation. You have no use for them."))
		return
	if (T.isSynthetic() || T.species.species_flags & SPECIES_FLAG_NO_BLOOD)
		to_chat(src, SPAN_WARNING("[T] has no blood and can not be affected by your powers!"))
		return
	if (vampire.status & VAMP_DRAINING)
		to_chat(src, SPAN_WARNING("Your fangs are already sunk into a victim's neck!"))
		return

	if (T.mind.vampire)
		var/datum/vampire/draining_vamp = T.mind.vampire

		if (draining_vamp.status & VAMP_ISTHRALL)
			var/choice_text = ""
			var/denial_response = ""
			if (draining_vamp.master == src)
				choice_text = "[T] is your thrall. Do you wish to release them from the blood bond and give them the chance to become your equal?"
				denial_response = "You opt against giving [T] a chance to ascend, and choose to keep them as a servant."
			else
				choice_text = "You can feel the taint of another master running in the veins of [T]. Do you wish to release them of their blood bond, and convert them into a vampire, in spite of their master?"
				denial_response = "You choose not to continue with the Embrace, and permit [T] to keep serving their master."

			if (alert(src, choice_text, "Choices", "Yes", "No") == "No")
				to_chat(src, SPAN_NOTICE("[denial_response]"))
				return

			GLOB.thralls.remove_antagonist(T.mind, 0, 0)
			qdel(draining_vamp)
			draining_vamp = null
		else
			to_chat(src, SPAN_WARNING("You feel corruption running in [T]'s blood. Much like yourself, \he[T] is already a spawn of the Veil, and cannot be Embraced."))
			return

	vampire.status |= VAMP_DRAINING

	visible_message(SPAN_DANGER("[src] bites [T]'s neck!"), SPAN_DANGER("You bite [T]'s neck and begin to drain their blood, as the first step of introducing the corruption of the Veil to them."), SPAN_NOTICE("You hear a soft puncture and a wet sucking noise."))

	to_chat(T, SPAN_NOTICE("You are currently being turned into a vampire. You will die in the course of this, but you will be revived by the end. Please do not ghost out of your body until the process is complete."))

	while (do_mob(src, T, 50))
		if (!mind.vampire)
			to_chat(src, "<span class='alert'>Your fangs have disappeared!</span>")
			return
		if (!T.vessel.get_reagent_amount(/datum/reagent/blood))
			to_chat(src, "<span class='alert'>[T] is now drained of blood. You begin forcing your own blood into their body, spreading the corruption of the Veil to their body.</span>")
			break

		T.vessel.remove_reagent(/datum/reagent/blood, 50)

	T.revive()

	// You ain't goin' anywhere, bud.
	if (!T.client && T.mind)
		for (var/mob/observer/ghost/ghost in GLOB.ghost_mob_list)
			if (ghost.mind == T.mind)
				ghost.can_reenter_corpse = 1
				ghost.reenter_corpse()

				to_chat(T, SPAN_DANGER("A dark force pushes you back into your body. You find yourself somehow still clinging to life."))

	T.Weaken(15)
	T.Stun(15)
	GLOB.vampires.add_antagonist(T.mind, 1, 1, 0, 0, 1)

	admin_attack_log(src, T, "successfully embraced [key_name(T)]", "was successfully embraced by [key_name(src)]", "successfully embraced and turned into a vampire")

	to_chat(T, SPAN_DANGER("You awaken. Moments ago, you were dead, your conciousness still forced stuck inside your body. Now you live. You feel different, a strange, dark force now present within you. You have an insatiable desire to drain the blood of mortals, and to grow in power."))
	to_chat(src, SPAN_WARNING("You have corrupted another mortal with the taint of the Veil. Beware: they will awaken hungry and maddened; not bound to any master."))

	T.mind.vampire.blood_usable = 0
	T.mind.vampire.frenzy = 50
	T.vampire_check_frenzy()

	vampire.status &= ~VAMP_DRAINING

// Grapple a victim by leaping onto them.
/mob/living/carbon/human/proc/grapple()
	set category = "Vampire"
	set name = "Grapple"
	set desc = "Lunge towards a target like an animal, and grapple them."

	if (status_flags & LEAPING)
		return
	if (incapacitated())
		to_chat(src, SPAN_WARNING("You cannot lean in your current state."))
		return

	var/list/targets = list()
	for (var/mob/living/carbon/human/H in view(4, src))
		targets += H

	targets -= src

	if (!targets.len)
		to_chat(src, SPAN_WARNING("No valid targets visible or in range."))
		return

	var/mob/living/carbon/human/T = pick(targets)

	visible_message(SPAN_DANGER("[src] leaps at [T]!"))
	src.drop_item()
	throw_at(get_step(get_turf(T), get_turf(src)), 4, 1, src)
	status_flags |= LEAPING

	sleep(5)

	if (status_flags & LEAPING)
		status_flags &= ~LEAPING
	if (!src.Adjacent(T))
		to_chat(src, SPAN_WARNING("You miss!"))
		return

	T.Weaken(3)

	admin_attack_log(src, T, "lept at and grappled [key_name(T)]", "was lept at and grappled by [key_name(src)]", "lept at and grappled")


	src.visible_message(SPAN_WARNING("[src] seizes [T] aggressively!"))
	src.a_intent_change(I_GRAB)
	var/obj/item/grab/normal/G = new(src, T)
	src.put_in_active_hand(G)
	G.upgrade(TRUE)

	verbs -= /mob/living/carbon/human/proc/grapple
	ADD_VERB_IN_IF(src, 800, /mob/living/carbon/human/proc/grapple, CALLBACK(src, .proc/finish_vamp_timeout, VAMP_FRENZIED))

/mob/living/carbon/human/proc/night_vision()
	set category = "Vampire"
	set name = "Toggle Darkvision"
	set desc = "You're are able to see in the dark."
	var/power_use_cost = 0

	var/datum/vampire/vampire = vampire_power(power_use_cost, 0)
	if (!vampire)
		return

	var/mob/living/carbon/C = src
	C.seeDarkness = !C.seeDarkness
	if(C.seeDarkness)
		to_chat(C, SPAN("notice", "You're no longer need light to see."))
	else
		to_chat(C, SPAN("notice", "You're allow the shadows to return."))
	return TRUE
