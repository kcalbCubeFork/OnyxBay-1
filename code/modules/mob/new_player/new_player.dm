//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/mob/new_player
	var/ready = 0
	var/spawning = 0//Referenced when you want to delete the new_player later on in the code.
	var/totalPlayers = 0		 //Player counts for the Lobby tab
	var/totalPlayersReady = 0
	var/datum/browser/panel
	var/show_invalid_jobs = 0
	universal_speak = 1

	invisibility = 101

	density = 0
	stat = DEAD

	movement_handlers = list()
	anchored = 1	//  don't get pushed around

	virtual_mob = null // Hear no evil, speak no evil

/mob/new_player/New()
	. = ..()
	verbs += /mob/proc/toggle_antag_pool
	verbs += /mob/proc/join_as_actor
	verbs += /mob/proc/join_response_team

/mob/new_player/proc/new_player_panel(forced = FALSE)
	if(!SScharacter_setup.initialized && !forced)
		return // Not ready yet.
	new_player_panel_proc()

/mob/new_player/proc/new_player_panel_proc()
	var/output = "<div align='center'>"
	output +="<hr>"
	output += "<p><a href='byond://?src=\ref[src];show_preferences=1'>Setup Character</A></p>"

	if(GAME_STATE <= RUNLEVEL_LOBBY)
		if(ready)
			output += "<p>\[ <span class='linkOn'><b>Ready</b></span> | <a href='byond://?src=\ref[src];ready=0'>Not Ready</a> \]</p>"
		else
			output += "<p>\[ <a href='byond://?src=\ref[src];ready=1'>Ready</a> | <span class='linkOn'><b>Not Ready</b></span> \]</p>"

	else
		output += "<a href='byond://?src=\ref[src];manifest=1'>View the Crew Manifest</A><br><br>"
		output += "<p><a href='byond://?src=\ref[src];late_join=1'>Join Game!</A></p>"

	output += "<p><a href='byond://?src=\ref[src];observe=1'>Observe</A></p>"

	output += "</div>"

	panel = new(src, "Welcome","Welcome", 210, 280, src)
	panel.set_window_options("can_close=0")
	panel.set_content(output)
	panel.open()
	return

/mob/new_player/Stat()
	. = ..()

	if(statpanel("Lobby"))
		if(check_rights(R_INVESTIGATE, 0, src))
			stat("Game Mode:", "[SSticker.mode ? SSticker.mode.name : SSticker.master_mode] ([SSticker.master_mode])")
		else
			stat("Game Mode:", PUBLIC_GAME_MODE)
		var/extra_antags = list2params(additional_antag_types)
		stat("Added Antagonists:", extra_antags ? extra_antags : "None")

		if(GAME_STATE <= RUNLEVEL_LOBBY)
			stat("Time To Start:", "[round(SSticker.pregame_timeleft/10)][SSticker.round_progressing ? "" : " (DELAYED)"]")
			stat("Players: [totalPlayers]", "Players Ready: [totalPlayersReady]")
			totalPlayers = 0
			totalPlayersReady = 0
			for(var/mob/new_player/player in GLOB.player_list)
				var/highjob
				if(player.client && player.client.prefs && player.client.prefs.job_high)
					highjob = " as [player.client.prefs.job_high]"
				stat("[player.key]", (player.ready)?("(Playing[highjob])"):(null))
				totalPlayers++
				if(player.ready)totalPlayersReady++

/mob/new_player/Topic(href, href_list[])
	if(!client)	return 0

	if (usr != src)
		href_exploit(usr.ckey, href)
		return 0

	if(href_list["show_preferences"])
		client.prefs.ShowChoices(src)
		return 1

	if(href_list["ready"])
		if(GAME_STATE <= RUNLEVEL_LOBBY) // Make sure we don't ready up after the round has started
			if(jobban_isbanned(src, "MALE") && jobban_isbanned(src, "FEMALE"))
				to_chat(src, "<span class='warning'>Only genderqueers allowed.</span>")
				return

			if(jobban_isbanned(src, "MALE") && client.prefs.gender == MALE)
				to_chat(src, "<span class='warning'>Only traps allowed.</span>")
				return

			if(jobban_isbanned(src, "FEMALE") && client.prefs.gender == FEMALE)
				to_chat(src, "<span class='warning'>No traps allowed.</span>")
				return

			var/value = text2num(href_list["ready"])
			if (value && !SSeams.CheckForAccess(client))
				return

			ready = value
		else
			ready = 0

	if(href_list["refresh"])
		panel.close()
		new_player_panel_proc()

	if(href_list["observe"])
		if(GAME_STATE < RUNLEVEL_LOBBY)
			to_chat(src, "<span class='warning'>Please wait for server initialization to complete...</span>")
			return

		if (!SSeams.CheckForAccess(client))
			return

		if(!config.respawn_delay || client.holder || alert(src,"Are you sure you wish to observe? You will have to wait [config.respawn_delay] minute\s before being able to respawn!","Player Setup","Yes","No") == "Yes")
			if(!client)	return 1
			var/mob/observer/ghost/observer = new()

			spawning = 1
			sound_to(src, sound(null, repeat = 0, wait = 0, volume = 85, channel = 1))// MAD JAMS cant last forever yo


			observer.started_as_observer = 1
			close_spawn_windows()
			var/obj/O = locate("landmark*Observer")
			if(istype(O))
				to_chat(src, "<span class='notice'>Now teleporting.</span>")
				observer.forceMove(O.loc)
			else
				to_chat(src, "<span class='danger'>Could not locate an observer spawn point. Use the Teleport verb to jump to the map.</span>")
			observer.timeofdeath = world.time // Set the time of death so that the respawn timer works correctly.

			if(isnull(client.holder))
				announce_ghost_joinleave(src)

			var/mob/living/carbon/human/dummy/mannequin = get_mannequin(client.ckey)
			if(mannequin)
				client.prefs.dress_preview_mob(mannequin)
				observer.set_appearance(mannequin)
				qdel(mannequin)

			if(client.prefs.be_random_name)
				client.prefs.real_name = random_name(client.prefs.gender)
			observer.real_name = client.prefs.real_name
			observer.SetName(observer.real_name)
			if(!client.holder && !config.antag_hud_allowed)           // For new ghosts we remove the verb from even showing up if it's not allowed.
				observer.verbs -= /mob/observer/ghost/verb/toggle_antagHUD        // Poor guys, don't know what they are missing!
			observer.key = key
			var/obj/screen/splash/S = new(observer.client, TRUE)
			S.Fade(TRUE, TRUE)
			qdel(src)

			return 1

	if(href_list["late_join"])

		if(GAME_STATE != RUNLEVEL_GAME)
			to_chat(usr, "<span class='warning'>The round is either not ready, or has already finished...</span>")
			return

		if (!SSeams.CheckForAccess(client))
			return

		if(jobban_isbanned(src, "MALE") && jobban_isbanned(src, "FEMALE"))
			to_chat(src, "<span class='warning'>Only genderqueers allowed.</span>")
			return

		if(jobban_isbanned(src, "MALE") && client.prefs.gender == MALE)
			to_chat(src, "<span class='warning'>Only traps allowed.</span>")
			return

		if(jobban_isbanned(src, "FEMALE") && client.prefs.gender == FEMALE)
			to_chat(src, "<span class='warning'>No traps allowed.</span>")
			return

		LateChoices() //show the latejoin job selection menu

	if(href_list["manifest"])
		ViewManifest()

	if(href_list["SelectedJob"])
		var/datum/job/job = job_master.GetJob(href_list["SelectedJob"])

		if(!job)
			to_chat(usr, "<span class='danger'>The job '[href_list["SelectedJob"]]' doesn't exist!</span>")
			return

		if (!SSeams.CheckForAccess(client))
			return

		//Prevents people rejoining as same character.
		for (var/mob/living/carbon/human/C in SSmobs.mob_list)
			var/char_name = client.prefs.real_name
			if(char_name == C.real_name)
				to_chat (usr, "<span class='danger'>There is a character that already exists with the same name: <b>[C.real_name]</b>, please join with a different one.</span>")
				return

		if(!config.enter_allowed)
			to_chat(usr, "<span class='notice'>There is an administrative lock on entering the game!</span>")
			return
		if(SSticker && SSticker.mode && SSticker.mode.explosion_in_progress)
			to_chat(usr, "<span class='danger'>The [station_name()] is currently exploding. Joining would go poorly.</span>")
			return

		var/datum/species/S = all_species[client.prefs.species]
		if(!check_species_allowed(S))
			return 0
		var/role = job.title
		if(role == "Captain" || role == "Head of Personnel" || role == "Chief Engineer" || role == "Chief Medical Officer" || role == "Research Director" || role == "Head of Security")
			SSwarnings.show_warning(client, WARNINGS_HEADS, "window=Warning;size=440x300;can_resize=0;can_minimize=0")

		AttemptLateSpawn(job, client.prefs.spawnpoint)
		return

	if(href_list["privacy_poll"])
		if(!establish_db_connection())
			return
		var/voted = 0

		//First check if the person has not voted yet.
		var/DBQuery/query = sql_query("SELECT * FROM erro_privacy WHERE ckey = $ckey", dbcon, list(ckey = ckey))
		while(query.NextRow())
			voted = 1
			break

		//This is a safety switch, so only valid options pass through
		var/option = "UNKNOWN"
		switch(href_list["privacy_poll"])
			if("signed")
				option = "SIGNED"
			if("anonymous")
				option = "ANONYMOUS"
			if("nostats")
				option = "NOSTATS"
			if("later")
				close_browser(usr, "window=privacypoll")
				return
			if("abstain")
				option = "ABSTAIN"

		if(option == "UNKNOWN")
			return

		if(!voted)
			sql_query("INSERT INTO erro_privacy VALUES (null, Now(), $ckey, $option)", dbcon, list(ckey = ckey, option = option))
			to_chat(usr, "<b>Thank you for your vote!</b>")
			close_browser(usr, "window=privacypoll")

	if(!ready && href_list["preference"])
		if(client)
			client.prefs.process_link(src, href_list)
	else if(!href_list["late_join"])
		new_player_panel()

	if(href_list["showpoll"])

		handle_player_polling()
		return

	if(href_list["pollid"])

		var/pollid = href_list["pollid"]
		if(istext(pollid))
			pollid = text2num(pollid)
		if(isnum(pollid))
			src.poll_player(pollid)
		return

	if(href_list["invalid_jobs"])
		show_invalid_jobs = !show_invalid_jobs
		LateChoices()

	if(href_list["votepollid"] && href_list["votetype"])
		var/pollid = text2num(href_list["votepollid"])
		var/votetype = href_list["votetype"]
		switch(votetype)
			if("OPTION")
				var/optionid = text2num(href_list["voteoptionid"])
				vote_on_poll(pollid, optionid)
			if("TEXT")
				var/replytext = href_list["replytext"]
				log_text_poll_reply(pollid, replytext)
			if("NUMVAL")
				var/id_min = text2num(href_list["minid"])
				var/id_max = text2num(href_list["maxid"])

				if( (id_max - id_min) > 100 )	//Basic exploit prevention
					to_chat(usr, "The option ID difference is too big. Please contact administration or the database admin.")
					return

				for(var/optionid = id_min; optionid <= id_max; optionid++)
					if(!isnull(href_list["o[optionid]"]))	//Test if this optionid was replied to
						var/rating
						if(href_list["o[optionid]"] == "abstain")
							rating = null
						else
							rating = text2num(href_list["o[optionid]"])
							if(!isnum(rating))
								return

						vote_on_numval_poll(pollid, optionid, rating)
			if("MULTICHOICE")
				var/id_min = text2num(href_list["minoptionid"])
				var/id_max = text2num(href_list["maxoptionid"])

				if( (id_max - id_min) > 100 )	//Basic exploit prevention
					to_chat(usr, "The option ID difference is too big. Please contact administration or the database admin.")
					return

				for(var/optionid = id_min; optionid <= id_max; optionid++)
					if(!isnull(href_list["option_[optionid]"]))	//Test if this optionid was selected
						vote_on_poll(pollid, optionid, 1)

/mob/new_player/proc/IsJobAvailable(datum/job/job)
	if(!job)	return 0
	if(!job.is_position_available()) return 0
	if(jobban_isbanned(src, job.title))	return 0
	if(!job.player_old_enough(src.client))	return 0

	return 1

/mob/new_player/proc/get_branch_pref()
	if(client)
		return client.prefs.char_branch

/mob/new_player/proc/get_rank_pref()
	if(client)
		return client.prefs.char_rank

/mob/new_player/proc/AttemptLateSpawn(datum/job/job, spawning_at)
	if(src != usr)
		return 0
	if(GAME_STATE != RUNLEVEL_GAME)
		to_chat(usr, "<span class='warning'>The round is either not ready, or has already finished...</span>")
		return 0
	if(!config.enter_allowed)
		to_chat(usr, "<span class='notice'>There is an administrative lock on entering the game!</span>")
		return 0

	if(!IsJobAvailable(job))
		alert("[job.title] is not available. Please try another.")
		return 0
	if(job.is_restricted(client.prefs, src))
		return

	var/datum/spawnpoint/spawnpoint = job_master.get_spawnpoint_for(client, job.title)
	var/turf/spawn_turf = pick(spawnpoint.turfs)
	if(job.latejoin_at_spawnpoints)
		var/obj/S = job_master.get_roundstart_spawnpoint(job.title)
		spawn_turf = get_turf(S)
	var/radlevel = SSradiation.get_rads_at_turf(spawn_turf)
	var/airstatus = IsTurfAtmosUnsafe(spawn_turf)
	if(airstatus || radlevel > 0 )
		var/reply = alert(usr, "Warning. Your selected spawn location seems to have unfavorable conditions. \
		You may die shortly after spawning. \
		Spawn anyway? More information: [airstatus] Radiation: [radlevel] Bq", "Atmosphere warning", "Abort", "Spawn anyway")
		if(reply == "Abort")
			return 0
		else
			// Let the staff know, in case the person complains about dying due to this later. They've been warned.
			log_and_message_admins("User [src] spawned at spawn point with dangerous atmosphere.")

		// Just in case someone stole our position while we were waiting for input from alert() proc
		if(!IsJobAvailable(job))
			to_chat(src, alert("[job.title] is not available. Please try another."))
			return 0

	job_master.AssignRole(src, job.title, 1)

	var/mob/living/character = create_character(spawn_turf)	//creates the human and transfers vars and mind
	if(!character)
		return 0

	character = job_master.EquipRank(character, job.title, 1)					//equips the human
	equip_custom_items(character)
	character.apply_traits()
	// AIs don't need a spawnpoint, they must spawn at an empty core
	if(character.mind.assigned_role == "AI")

		character = character.AIize(move=0) // AIize the character, but don't move them yet

			// IsJobAvailable for AI checks that there is an empty core available in this list
		var/obj/structure/AIcore/deactivated/C = empty_playable_ai_cores[1]
		empty_playable_ai_cores -= C

		character.forceMove(C.loc)
		var/mob/living/silicon/ai/A = character
		A.on_mob_init()

		AnnounceArrival(character.real_name, job)
		SSticker.mode.handle_latejoin(character)

		qdel(C)
		qdel(src)
		return

	SSticker.mode.handle_latejoin(character)
	GLOB.universe.OnPlayerLatejoin(character)
	if(job_master.ShouldCreateRecords(job.title))
		if(character.mind.assigned_role != "Cyborg")
			CreateModularRecord(character)
			SSticker.minds += character.mind//Cyborgs and AIs handle this in the transform proc.	//TODO!!!!! ~Carn

		AnnounceArrival(character.real_name, job, spawnpoint)

		matchmaker.do_matchmaking()
	log_and_message_admins("has joined the round as [character.mind.assigned_role].", character)
	qdel(src)

/mob/new_player/proc/AnnounceCyborg(mob/living/character, rank, join_message)
	if (GAME_STATE == RUNLEVEL_GAME)
		if(character.mind.role_alt_title)
			rank = character.mind.role_alt_title
		// can't use their name here, since cyborg namepicking is done post-spawn, so we'll just say "A new Cyborg has arrived"/"A new Android has arrived"/etc.
		GLOB.global_announcer.autosay("A new[rank ? " [rank]" : " visitor" ] [join_message ? join_message : "has arrived"].", get_announcement_computer())
		log_and_message_admins("has joined the round as [character.mind.assigned_role].", character)

/mob/new_player/proc/LateChoices()
	var/name = client.prefs.be_random_name ? "friend" : client.prefs.real_name

	var/list/dat = list("<html><meta charset=\"utf-8\"><body><center>")
	dat += "<b>Welcome, [name].<br></b>"
	dat += "Round Duration: [roundduration2text()]<br>"

	if(evacuation_controller.has_evacuated())
		dat += "<font color='red'><b>The [station_name()] has been evacuated.</b></font><br>"
	else if(evacuation_controller.is_evacuating())
		if(evacuation_controller.emergency_evacuation) // Emergency shuttle is past the point of no recall
			dat += "<font color='red'>The [station_name()] is currently undergoing evacuation procedures.</font><br>"
		else                                           // Crew transfer initiated
			dat += "<font color='red'>The [station_name()] is currently undergoing crew transfer procedures.</font><br>"

	dat += "Choose from the following open/valid positions:<br>"
	dat += "<a href='byond://?src=\ref[src];invalid_jobs=1'>[show_invalid_jobs ? "Hide":"Show"] unavailable jobs.</a><br>"
	dat += "<table>"
	for(var/datum/job/job in job_master.occupations)
		if(job && IsJobAvailable(job))
			if(job.minimum_character_age && (client.prefs.age < job.minimum_character_age))
				continue
			if(job.faction_restricted && (client.prefs.faction != GLOB.using_map.company_name || (client.prefs.nanotrasen_relation in COMPANY_OPPOSING)))
				continue

			var/active = 0
			// Only players with the job assigned and AFK for less than 10 minutes count as active
			for(var/mob/M in GLOB.player_list) if(M.mind && M.client && M.mind.assigned_role == job.title && M.client.inactivity <= 10 * 60 * 10)
				active++

			var/active_vacancies = 0
			if(job.open_vacancies && job.open_vacancies - job.filled_vacancies > 0)
				active_vacancies = job.open_vacancies - job.filled_vacancies

			if(job.is_restricted(client.prefs))
				if(show_invalid_jobs)
					dat += "<tr><td><a style='text-decoration: line-through' href='byond://?src=\ref[src];SelectedJob=[job.title]'>[job.title]</a></td><td>[job.current_positions]</td><td>(Active: [active])</td>[active_vacancies ? "<td><font color='[COLOR_CYAN_BLUE]'>(Vacancies: [active_vacancies])</font></td>" : null]</tr>"
			else
				dat += "<tr><td><a href='byond://?src=\ref[src];SelectedJob=[job.title]'>[job.title]</a></td><td>[job.current_positions]</td><td>(Active: [active])</td>[active_vacancies ? "<td><font color='[COLOR_CYAN_BLUE]'>(Vacancies: [active_vacancies])</font></td>" : null]</tr>"

	dat += "</table></center>"
	var/datum/browser/popup = new(src, "latechoices", "Late Join", 450, 640, src)
	popup.set_content(jointext(dat, null))
	popup.open()

/mob/new_player/proc/create_character(turf/spawn_turf)
	spawning = 1
	close_spawn_windows()

	var/mob/living/carbon/human/new_character

	var/datum/species/chosen_species
	if(client.prefs.species)
		chosen_species = all_species[client.prefs.species]

	if(!spawn_turf)
		var/datum/spawnpoint/spawnpoint = job_master.get_spawnpoint_for(client, get_rank_pref())
		spawn_turf = pick(spawnpoint.turfs)

	if(chosen_species)
		if(!check_species_allowed(chosen_species))
			spawning = 0 //abort
			return null
		new_character = new(spawn_turf, chosen_species.name)
		/*if(chosen_species.has_organ[BP_POSIBRAIN] && client && client.prefs.is_shackled)
			var/obj/item/organ/internal/posibrain/B = new_character.internal_organs_by_name[BP_POSIBRAIN]
			if(B)
				B.shackle(client.prefs.get_lawset())*/ // Removed until we get those cyberdummies working

	if(!new_character)
		new_character = new(spawn_turf)

	new_character.lastarea = get_area(spawn_turf)

	for(var/lang in client.prefs.alternate_languages)
		var/datum/language/chosen_language = all_languages[lang]
		if(chosen_language)
			var/is_species_lang = (chosen_language.name in new_character.species.secondary_langs)
			if(is_species_lang || ((!(chosen_language.flags & RESTRICTED) || has_admin_rights()) && is_alien_whitelisted(src, chosen_language)))
				new_character.add_language(lang)

	if(GLOB.random_players)
		new_character.gender = pick(MALE, FEMALE)
		client.prefs.real_name = random_name(new_character.gender)
		client.prefs.randomize_appearance_and_body_for(new_character)
	else
		if(jobban_isbanned(src, "NAME"))
			client.prefs.real_name = random_name(new_character.gender)

		if(jobban_isbanned(src, "APPEARANCE"))
			client.prefs.randomize_appearance_and_body_for(new_character)

		client.prefs.copy_to(new_character)

	sound_to(src, sound(null, repeat = 0, wait = 0, volume = 85, channel = 1))// MAD JAMS cant last forever yo

	if(mind)
		mind.active = 0					//we wish to transfer the key manually
		mind.original = new_character
		if(client.prefs.memory)
			mind.store_memory(client.prefs.memory)
		if(client.prefs.relations.len && mind.may_have_relations())
			for(var/T in client.prefs.relations)
				var/TT = matchmaker.relation_types[T]
				var/datum/relation/R = new TT
				R.holder = mind
				R.info = client.prefs.relations_info[T]
			mind.gen_relations_info = client.prefs.relations_info["general"]
		mind.traits = client.prefs.traits.Copy()
		mind.transfer_to(new_character)					//won't transfer key since the mind is not active

	new_character.apply_traits()
	new_character.SetName(real_name)
	new_character.dna.ready_dna(new_character)
	new_character.dna.b_type = client.prefs.b_type
	new_character.sync_organ_dna()
	if(client.prefs.disabilities)
		// Set defer to 1 if you add more crap here so it only recalculates struc_enzymes once. - N3X
		new_character.dna.SetSEState(GLOB.GLASSESBLOCK,1,0)
		new_character.disabilities |= NEARSIGHTED

	// Do the initial caching of the player's body icons.
	new_character.force_update_limbs()
	new_character.update_eyes()
	new_character.regenerate_icons()

	new_character.key = key		//Manually transfer the key to log them in
	var/obj/screen/splash/S = new(new_character.client, TRUE)
	S.Fade(TRUE, TRUE)

	// Give them their cortical stack if we're using them.
	if(config && config.use_cortical_stacks && new_character.client && new_character.client.prefs.has_cortical_stack /*&& new_character.should_have_organ(BP_BRAIN)*/)
		new_character.create_stack()

	return new_character

/mob/new_player/proc/ViewManifest()
	var/dat = "<div align='center'>"
	dat += html_crew_manifest(OOC = 1)
	//show_browser(src, dat, "window=manifest;size=370x420;can_close=1")
	var/datum/browser/popup = new(src, "Crew Manifest", "Crew Manifest", 370, 420, src)
	popup.set_content(dat)
	popup.open()

/mob/new_player/Move()
	return 0

/mob/new_player/proc/close_spawn_windows()
	show_browser(src, null, "window=latechoices") //closes late choices window
	panel.close()

/mob/new_player/has_admin_rights()
	return check_rights(R_ADMIN, 0, src)

/mob/new_player/proc/check_species_allowed(datum/species/S, show_alert=1)
	if (!(S.spawn_flags & SPECIES_CAN_JOIN) && !has_admin_rights())
		if (show_alert)
			alert(client, "Your current species, [client.prefs.species], is not available for play.")
		return 0
	if (!is_alien_whitelisted(src, S))
		if (show_alert)
			alert(client, "You are currently not whitelisted to play [client.prefs.species].")
		return 0
	if (jobban_isbanned(src, "SPECIES") && S.name != SPECIES_HUMAN)
		if (show_alert)
			alert(client, "You are currently banned to play species!")
		return 0
	return 1

/mob/new_player/get_species()
	var/datum/species/chosen_species
	if(client.prefs.species)
		chosen_species = all_species[client.prefs.species]

	if(!chosen_species || !check_species_allowed(chosen_species, 0))
		return SPECIES_HUMAN

	return chosen_species.name

/mob/new_player/get_gender()
	if(!client || !client.prefs) ..()
	return client.prefs.gender

/mob/new_player/is_ready()
	return ready && ..()

/mob/new_player/hear_say(message, verb = "says", datum/language/language = null, alt_name = "",italics = 0, mob/speaker = null)
	return

/mob/new_player/hear_radio(message, verb="says", datum/language/language=null, part_a, part_b, part_c, mob/speaker = null, hard_to_hear = 0)
	return

/mob/new_player/show_message(msg, type, alt, alt_type)
	return

/mob/new_player/MayRespawn()
	return 1

/mob/new_player/touch_map_edge()
	return

/mob/new_player/say(message)
	sanitize_and_communicate(/decl/communication_channel/ooc, client, message)

/mob/new_player/is_eligible_for_antag_spawn(antag_id)
	return TRUE
