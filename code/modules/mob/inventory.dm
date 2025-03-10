//This proc is called whenever someone clicks an inventory ui slot.
/mob/proc/attack_ui(slot)
	var/obj/item/I = get_active_hand()
	var/obj/item/E = get_equipped_item(slot)
	if (istype(E))
		if(istype(I))
			E.attackby(I, src)
		else
			E.attack_hand(src)
	else
		equip_to_slot_if_possible(I, slot)

/mob/proc/put_in_any_hand_if_possible(obj/item/W as obj, del_on_fail = 0, disable_warning = 1, redraw_mob = 1)
	if(equip_to_slot_if_possible(W, slot_l_hand, del_on_fail, disable_warning, redraw_mob))
		return 1
	else if(equip_to_slot_if_possible(W, slot_r_hand, del_on_fail, disable_warning, redraw_mob))
		return 1
	return 0

//This is a SAFE proc. Use this instead of equip_to_slot()!
//set del_on_fail to have it delete W if it fails to equip
//set disable_warning to disable the 'you are unable to equip that' warning.
//unset redraw_mob to prevent the mob from being redrawn at the end.
//set force to replace items in the slot and ignore blocking overwear
/mob/proc/equip_to_slot_if_possible(obj/item/W as obj, slot, del_on_fail = 0, disable_warning = 0, redraw_mob = 1, force = 0)
	if(!istype(W)) return 0

	if(!W.mob_can_equip(src, slot, disable_warning, force))
		if(del_on_fail)
			qdel(W)
		else
			if(!disable_warning)
				to_chat(src, "<span class='warning'>You are unable to equip that.</span>")//Only print if del_on_fail is false

		return 0

	equip_to_slot(W, slot, redraw_mob) //This proc should not ever fail.
	return 1

//This is an UNSAFE proc. It merely handles the actual job of equipping. All the checks on whether you can or can't eqip need to be done before! Use mob_can_equip() for that task.
//In most cases you will want to use equip_to_slot_if_possible()
/mob/proc/equip_to_slot(obj/item/W as obj, slot)
	return

//This is just a commonly used configuration for the equip_to_slot_if_possible() proc, used to equip people when the rounds tarts and when events happen and such.
/mob/proc/equip_to_slot_or_del(obj/item/W as obj, slot)
	return equip_to_slot_if_possible(W, slot, 1, 1, 0)

/mob/proc/equip_to_slot_or_store_or_drop(obj/item/W as obj, slot)
	var/store = equip_to_slot_if_possible(W, slot, 0, 1, 0)
	if(!store)
		return equip_to_storage_or_drop(W)
	return store

//The list of slots by priority. equip_to_appropriate_slot() uses this list. Doesn't matter if a mob type doesn't have a slot.
var/list/slot_equipment_priority = list( \
		slot_back,\
		slot_wear_id,\
		slot_w_uniform,\
		slot_wear_suit,\
		slot_wear_mask,\
		slot_head,\
		slot_shoes,\
		slot_gloves,\
		slot_l_ear,\
		slot_r_ear,\
		slot_glasses,\
		slot_belt,\
		slot_s_store,\
		slot_tie,\
		slot_l_store,\
		slot_r_store\
	)

//Checks if a given slot can be accessed at this time, either to equip or unequip I
/mob/proc/slot_is_accessible(slot, obj/item/I, mob/user=null)
	return 1

//puts the item "W" into an appropriate slot in a human's inventory
//returns 0 if it cannot, 1 if successful
/mob/proc/equip_to_appropriate_slot(obj/item/W)
	if(!istype(W)) return 0

	for(var/slot in slot_equipment_priority)
		if(equip_to_slot_if_possible(W, slot, del_on_fail=0, disable_warning=1, redraw_mob=1))
			return 1

	return 0

/mob/proc/equip_to_storage(obj/item/newitem)
	// Try put it in their backpack
	if(istype(src.back,/obj/item/storage))
		var/obj/item/storage/backpack = src.back
		if(backpack.can_be_inserted(newitem, null, 1))
			newitem.forceMove(src.back)
			return backpack

	// Try to place it in any item that can store stuff, on the mob.
	for(var/obj/item/storage/S in src.contents)
		if(S.can_be_inserted(newitem, null, 1))
			newitem.forceMove(S)
			return S

/mob/proc/equip_to_storage_or_drop(obj/item/newitem)
	var/stored = equip_to_storage(newitem)
	if(!stored && newitem)
		newitem.forceMove(loc)
	return stored

//These procs handle putting s tuff in your hand. It's probably best to use these rather than setting l_hand = ...etc
//as they handle all relevant stuff like adding it to the player's screen and updating their overlays.

//Returns the thing in our active hand
/mob/proc/get_active_hand()
	if(hand)	return l_hand
	else		return r_hand

//Returns the thing in our inactive hand
/mob/proc/get_inactive_hand()
	if(hand)	return r_hand
	else		return l_hand

//Puts the item into your l_hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_l_hand(obj/item/W)
	if(lying || !istype(W))
		return 0
	return 1

//Puts the item into your r_hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_r_hand(obj/item/W)
	if(lying || !istype(W))
		return 0
	return 1

//Puts the item into our active hand if possible. returns 1 on success.
/mob/proc/put_in_active_hand(obj/item/W)
	return 0 // Moved to human procs because only they need to use hands.

//Puts the item into our inactive hand if possible. returns 1 on success.
/mob/proc/put_in_inactive_hand(obj/item/W)
	return 0 // As above.

//Puts the item our active hand if possible. Failing that it tries our inactive hand. Returns 1 on success.
//If both fail it drops it on the floor and returns 0.
//This is probably the main one you need to know :)
/mob/proc/put_in_hands(obj/item/W)
	if(!W)
		return 0
	drop_from_inventory(W)
	return 0

// Removes an item from inventory and places it in the target atom.
// If canremove or other conditions need to be checked then use unEquip instead.
/mob/proc/drop_from_inventory(obj/item/W, atom/target = null)
	if(!W)
		return FALSE
	remove_from_mob(W, target)
	if(!W?.loc)
		return TRUE // self destroying objects (tk, grabs)
	update_icons()
	return TRUE

//Drops the item in our left hand
/mob/proc/drop_l_hand(atom/Target, force)
	return drop_from_inventory(l_hand, Target, force)

//Drops the item in our right hand
/mob/proc/drop_r_hand(atom/Target,force)
	return drop_from_inventory(r_hand, Target, force)

//Drops the item in our active hand. TODO: rename this to drop_active_hand or something
/mob/proc/drop_item(atom/Target, force = 0)
	if(hand)	return drop_l_hand(Target, force)
	else		return drop_r_hand(Target, force)

/mob/proc/drop_item_inactive_hand(atom/Target, force = 0)
	if(hand)	return drop_r_hand(Target, force)
	else		return drop_l_hand(Target, force)

/*
	Removes the object from any slots the mob might have, calling the appropriate icon update proc.
	Does nothing else.

	>>>> *** DO NOT CALL THIS PROC DIRECTLY *** <<<<

	It is meant to be called only by other inventory procs.
	It's probably okay to use it if you are transferring the item between slots on the same mob,
	but chances are you're safer calling remove_from_mob() or drop_from_inventory() anyways.

	As far as I can tell the proc exists so that mobs with different inventory slots can override
	the search through all the slots, without having to duplicate the rest of the item dropping.
*/
/mob/proc/u_equip(obj/W as obj)
	if (W == r_hand)
		r_hand = null
		update_inv_r_hand(0)
	else if (W == l_hand)
		l_hand = null
		update_inv_l_hand(0)
	else if (W == back)
		back = null
		update_inv_back(0)
	else if (W == wear_mask)
		wear_mask = null
		update_inv_wear_mask(0)
	return

/mob/proc/isEquipped(obj/item/I)
	if(!I)
		return 0
	return get_inventory_slot(I) != 0

/mob/proc/canUnEquip(obj/item/I)
	if(!I) //If there's nothing to drop, the drop is automatically successful.
		return TRUE
	var/slot = get_inventory_slot(I)
	if(!slot)
		return FALSE
	return I.mob_can_unequip(src, slot)

/mob/proc/get_inventory_slot(obj/item/I)
	var/slot = 0
	for(var/s in slot_first to slot_last) //kind of worries me
		if(get_equipped_item(s) == I)
			slot = s
			break
	return slot

//This differs from remove_from_mob() in that it checks if the item can be unequipped first.
/mob/proc/unEquip(obj/item/I, force = FALSE, atom/target = null) // Force overrides NODROP for things like wizarditis and admin undress.
	if(QDELETED(I))
		return
	if(force || canUnEquip(I))
		return drop_from_inventory(I, target)
	return FALSE

//Attemps to remove an object on a mob.
/mob/proc/remove_from_mob(obj/O, atom/target)
	if(!O) // Nothing to remove, so we succeed.
		return 1
	src.u_equip(O)
	if (src.client)
		src.client.screen -= O
	O.reset_plane_and_layer()
	O.screen_loc = null
	if(istype(O, /obj/item))
		var/obj/item/I = O
		if(target)
			I.forceMove(target)
		else
			I.dropInto(loc)
		I.dropped(src)
	return 1


//Returns the item equipped to the specified slot, if any.
/mob/proc/get_equipped_item(slot)
	switch(slot)
		if(slot_l_hand) return l_hand
		if(slot_r_hand) return r_hand
		if(slot_back) return back
		if(slot_wear_mask) return wear_mask
	return null

/mob/proc/get_equipped_items(include_carried = 0)
	. = list()
	if(back)      . += back
	if(wear_mask) . += wear_mask

	if(include_carried)
		if(l_hand) . += l_hand
		if(r_hand) . += r_hand

/mob/proc/delete_inventory(include_carried = FALSE)
	for(var/entry in get_equipped_items(include_carried))
		drop_from_inventory(entry)
		qdel(entry)

// Returns all currently covered body parts
/mob/proc/get_covered_body_parts()
	. = 0
	for(var/entry in get_equipped_items())
		var/obj/item/I = entry
		. |= I.body_parts_covered

// Returns the first item which covers any given body part
/mob/proc/get_covering_equipped_item(body_parts)
	for(var/entry in get_equipped_items())
		var/obj/item/I = entry
		if(I.body_parts_covered & body_parts)
			return I

// Returns all items which covers any given body part
/mob/proc/get_covering_equipped_items(body_parts)
	. = list()
	for(var/entry in get_equipped_items())
		var/obj/item/I = entry
		if(I.body_parts_covered & body_parts)
			. += I

// Returns true if the selected item is in the hands
/mob/proc/is_item_in_hands(atom/A)
	if(A && (l_hand == A || r_hand == A))
		return TRUE

/mob/proc/update_equipment_slowdown()
	return
