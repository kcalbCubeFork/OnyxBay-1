// /mob/var/stat things.
#define CONSCIOUS   0
#define UNCONSCIOUS 1
#define DEAD        2

// Bitflags defining which status effects could be or are inflicted on a mob.
#define CANSTUN     0x1
#define CANWEAKEN   0x2
#define CANPARALYSE 0x4
#define CANPUSH     0x8
#define LEAPING     0x10
#define PASSEMOTES  0x32    // Mob has a cortical borer or holders inside of it that need to see emotes.
#define GODMODE     0x1000
#define FAKEDEATH   0x2000  // Replaces stuff like changeling.changeling_fakedeath.
#define NO_ANTAG    0x4000  // Players are restricted from gaining antag roles when occupying this mob
#define XENO_HOST   0x8000  // Tracks whether we're gonna be a baby alien's mummy.

// Grab Types
#define GRAB_NORMAL			"normal"
#define GRAB_NAB			"nab"
#define GRAB_NAB_SPECIAL	"special nab"

// Grab levels.
#define NORM_PASSIVE    "normal passive"
#define NORM_STRUGGLE   "normal struggle"
#define NORM_AGGRESSIVE "normal aggressive"
#define NORM_NECK       "normal neck"
#define NORM_KILL       "normal kill"

#define NAB_PASSIVE		"nab passive"
#define NAB_AGGRESSIVE	"nab aggressive"
#define NAB_KILL		"nab kill"

#define BORGMESON 0x1
#define BORGTHERM 0x2
#define BORGXRAY  0x4
#define BORGMATERIAL  8
//silicon vision modes
#define SEC_VISION 1 //Security Vision mode
#define MED_VISION 2 //Medical Vision mode
#define MESON_VISION 3 //Meson Vision mode
#define SCIENCE_VISION 4 //Science Vision mode
#define NVG_VISION 5 //Night vision Vision mode
#define MATERIAL_VISION 6 //Material Vision mode
#define THERMAL_VISION 7 //Thermal Vision mode
#define XRAY_VISION 8 //XRAY Vision mode
#define FLASH_PROTECTION_VISION 9 //Flash protection mode

#define HOSTILE_STANCE_IDLE      1
#define HOSTILE_STANCE_ALERT     2
#define HOSTILE_STANCE_ATTACK    3
#define HOSTILE_STANCE_ATTACKING 4
#define HOSTILE_STANCE_TIRED     5
#define HOSTILE_STANCE_INSIDE    6

#define LEFT  0x1
#define RIGHT 0x2
#define UNDER 0x4

// Pulse levels, very simplified.
#define PULSE_NONE    0 // So !M.pulse checks would be possible.
#define PULSE_SLOW    1 // <60     bpm
#define PULSE_NORM    2 //  60-90  bpm
#define PULSE_FAST    3 //  90-120 bpm
#define PULSE_2FAST   4 // >120    bpm
#define PULSE_THREADY 5 // Occurs during hypovolemic shock
#define GETPULSE_HAND 0 // Less accurate. (hand)
#define GETPULSE_TOOL 1 // More accurate. (med scanner, sleeper, etc.)

//intent flags, why wasn't this done the first time?
#define I_HELP		"help"
#define I_DISARM	"disarm"
#define I_GRAB		"grab"
#define I_HURT		"harm"

// Movement flags. For fuck's sake, we were using "run"s and "walk"s till 2021
#define M_RUN  "run"
#define M_WALK "walk"

//These are used Bump() code for living mobs, in the mob_bump_flag, mob_swap_flags, and mob_push_flags vars to determine whom can bump/swap with whom.
#define HUMAN 1
#define MONKEY 2
#define ALIEN 4
#define ROBOT 8
#define METROID 16
#define SIMPLE_ANIMAL 32
#define HEAVY 64
#define ALLMOBS (HUMAN|MONKEY|ALIEN|ROBOT|METROID|SIMPLE_ANIMAL|HEAVY)

// Robot AI notifications
#define ROBOT_NOTIFICATION_NEW_UNIT 1
#define ROBOT_NOTIFICATION_NEW_NAME 2
#define ROBOT_NOTIFICATION_NEW_MODULE 3
#define ROBOT_NOTIFICATION_MODULE_RESET 4
#define ROBOT_NOTIFICATION_SIGNAL_LOST 5

// Appearance change flags
#define APPEARANCE_UPDATE_DNA  0x1
#define APPEARANCE_RACE       (0x2|APPEARANCE_UPDATE_DNA)
#define APPEARANCE_GENDER     (0x4|APPEARANCE_UPDATE_DNA)
#define APPEARANCE_BODY_BUILD  0x8
#define APPEARANCE_SKIN        0x10
#define APPEARANCE_HAIR        0x20
#define APPEARANCE_HAIR_COLOR  0x40
#define APPEARANCE_FACIAL_HAIR 0x80
#define APPEARANCE_FACIAL_HAIR_COLOR 0x100
#define APPEARANCE_EYE_COLOR 0x200
#define APPEARANCE_ALL_HAIR (APPEARANCE_HAIR|APPEARANCE_HAIR_COLOR|APPEARANCE_FACIAL_HAIR|APPEARANCE_FACIAL_HAIR_COLOR)
#define APPEARANCE_ALL       0xFFFF

//Individual logging defines
#define INDIVIDUAL_SAY_LOG "Say log"
#define INDIVIDUAL_OOC_LOG "OOC log"
#define INDIVIDUAL_SHOW_ALL_LOG "All logs"

// Click cooldown
#define DEFAULT_ATTACK_COOLDOWN 8 //Default timeout for aggressive actions
#define DEFAULT_QUICK_COOLDOWN  4

#define FAST_WEAPON_COOLDOWN 3
#define DEFAULT_WEAPON_COOLDOWN 5
#define SLOW_WEAPON_COOLDOWN 10

#define MIN_SUPPLIED_LAW_NUMBER 15
#define MAX_SUPPLIED_LAW_NUMBER 50

// NT's alignment towards the character
#define COMPANY_LOYAL 			"Loyal"
#define COMPANY_SUPPORTATIVE	"Supportive"
#define COMPANY_NEUTRAL 		"Neutral"
#define COMPANY_SKEPTICAL		"Skeptical"
#define COMPANY_OPPOSED			"Opposed"

#define COMPANY_OPPOSING		list(COMPANY_SKEPTICAL,COMPANY_OPPOSED)
#define COMPANY_ALIGNMENTS		list(COMPANY_LOYAL,COMPANY_SUPPORTATIVE,COMPANY_NEUTRAL,COMPANY_SKEPTICAL,COMPANY_OPPOSED)

// Awareness about syndicate, it`s agents and equipment
#define SYNDICATE_UNAWARE            0
#define SYNDICATE_AWARE              1
#define SYNDICATE_GREATLY_AWARE      2
#define SYNDICATE_SUSPICIOUSLY_AWARE 3

// Defines mob sizes, used by lockers and to determine what is considered a small sized mob, etc.
#define MOB_LARGE  		40
#define MOB_MEDIUM 		20
#define MOB_SMALL 		10
#define MOB_TINY 		5
#define MOB_MINISCULE	1

// Defines how strong the species is compared to humans. Think like strength in D&D
#define STR_VHIGH       2
#define STR_HIGH        1
#define STR_MEDIUM      0
#define STR_LOW        -1
#define STR_VLOW       -2

// Gluttony levels.
#define GLUT_TINY 1       // Eat anything tiny and smaller
#define GLUT_SMALLER 2    // Eat anything smaller than we are
#define GLUT_ANYTHING 4   // Eat anything, ever

#define GLUT_ITEM_TINY 8         // Eat items with a w_class of small or smaller
#define GLUT_ITEM_NORMAL 16      // Eat items with a w_class of normal or smaller
#define GLUT_ITEM_ANYTHING 32    // Eat any item
#define GLUT_PROJECTILE_VOMIT 64 // When vomitting, does it fly out?

// Devour speeds, returned by can_devour()
#define DEVOUR_SLOW 1
#define DEVOUR_FAST 2

#define TINT_NONE 0
#define TINT_MODERATE 1
#define TINT_HEAVY 2
#define TINT_BLIND 3

#define FLASH_PROTECTION_VULNERABLE -2
#define FLASH_PROTECTION_REDUCED -1
#define FLASH_PROTECTION_NONE 0
#define FLASH_PROTECTION_MODERATE 1
#define FLASH_PROTECTION_MAJOR 2


#define ANIMAL_SPAWN_DELAY  round(config.respawn_delay / 6)
#define DRONE_SPAWN_DELAY   round(config.respawn_delay / 3)
#define DEAD_ANIMAL_DELAY   round(config.respawn_delay / 3)

// Incapacitation flags, used by the mob/proc/incapacitated() proc
#define INCAPACITATION_NONE 0
#define INCAPACITATION_RESTRAINED 1
#define INCAPACITATION_BUCKLED_PARTIALLY 2
#define INCAPACITATION_BUCKLED_FULLY 4
#define INCAPACITATION_STUNNED 8
#define INCAPACITATION_FORCELYING 16 //needs a better name - represents being knocked down BUT still conscious.
#define INCAPACITATION_KNOCKOUT 32

#define INCAPACITATION_KNOCKDOWN (INCAPACITATION_KNOCKOUT|INCAPACITATION_FORCELYING)
#define INCAPACITATION_DISABLED (INCAPACITATION_KNOCKDOWN|INCAPACITATION_STUNNED)
#define INCAPACITATION_DEFAULT (INCAPACITATION_RESTRAINED|INCAPACITATION_BUCKLED_FULLY|INCAPACITATION_DISABLED)
#define INCAPACITATION_ALL (~INCAPACITATION_NONE)

// Organs.
#define BP_MOUTH    "mouth"
#define BP_EYES     "eyes"
#define BP_HEART    "heart"
#define BP_LUNGS    "lungs"
#define BP_TRACH	"tracheae"
#define BP_BRAIN    "brain"
#define BP_LIVER    "liver"
#define BP_KIDNEYS  "kidneys"
#define BP_STOMACH  "stomach"
#define BP_APPENDIX "appendix"
#define BP_CELL     "cell"
#define BP_HIVE     "hive node"
#define BP_NUTRIENT "nutrient vessel"
#define BP_ACID     "acid gland"
#define BP_EGG      "egg sac"
#define BP_RESIN    "resin spinner"
#define BP_STRATA   "neural strata"
#define BP_RESPONSE "response node"
#define BP_GBLADDER "gas bladder"
#define BP_POLYP    "polyp segment"
#define BP_ANCHOR   "anchoring ligament"
#define BP_PLASMA   "plasma vessel"
#define BP_CHANG    "biostructure"
#define BP_CANCER   "cancer"
#define BP_EMBRYO   "alien embryo"
#define BP_GANGLION "spinal ganglion"

// Robo Organs.
#define BP_POSIBRAIN	"posibrain"
#define BP_VOICE		"vocal synthesiser"
#define BP_STACK		"stack"
#define BP_OPTICS		"optics"

// Limbs.
#define BP_L_FOOT "l_foot"
#define BP_R_FOOT "r_foot"
#define BP_L_LEG  "l_leg"
#define BP_R_LEG  "r_leg"
#define BP_L_HAND "l_hand"
#define BP_R_HAND "r_hand"
#define BP_L_ARM  "l_arm"
#define BP_R_ARM  "r_arm"
#define BP_HEAD   "head"
#define BP_CHEST  "chest"
#define BP_GROIN  "groin"
#define BP_ALL_LIMBS list(BP_CHEST, BP_GROIN, BP_HEAD, BP_L_ARM, BP_R_ARM, BP_L_HAND, BP_R_HAND, BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT)
#define BP_BY_DEPTH list(BP_HEAD, BP_L_HAND, BP_R_HAND, BP_L_ARM, BP_R_ARM, BP_L_FOOT, BP_R_FOOT, BP_L_LEG, BP_R_LEG, BP_GROIN, BP_CHEST)
#define BP_FEET list(BP_L_FOOT, BP_R_FOOT)

// Prosthetic helpers.
#define BP_IS_ROBOTIC(org)  (org.status & ORGAN_ROBOTIC)
#define BP_IS_ASSISTED(org) (org.status & ORGAN_ASSISTED)

#define SYNTH_BLOOD_COLOUR "#030303"
#define SYNTH_FLESH_COLOUR "#575757"

#define MOB_PULL_NONE 0
#define MOB_PULL_SMALLER 1
#define MOB_PULL_SAME 2
#define MOB_PULL_LARGER 3

//carbon taste sensitivity defines, used in mob/living/carbon/proc/ingest
#define TASTE_HYPERSENSITIVE 3 //anything below 5%
#define TASTE_SENSITIVE 2 //anything below 7%
#define TASTE_NORMAL 1 //anything below 15%
#define TASTE_DULL 0.5 //anything below 30%
#define TASTE_NUMB 0.1 //anything below 150%

//Used by show_message() and emotes
#define VISIBLE_MESSAGE 1
#define AUDIBLE_MESSAGE 2

//used for getting species temp values
#define COLD_LEVEL_1 -1
#define COLD_LEVEL_2 -2
#define COLD_LEVEL_3 -3
#define HEAT_LEVEL_1 1
#define HEAT_LEVEL_2 2
#define HEAT_LEVEL_3 3

//Synthetic human temperature vals
#define SYNTH_COLD_LEVEL_1 50
#define SYNTH_COLD_LEVEL_2 -1
#define SYNTH_COLD_LEVEL_3 -1
#define SYNTH_HEAT_LEVEL_1 500
#define SYNTH_HEAT_LEVEL_2 1000
#define SYNTH_HEAT_LEVEL_3 2000

#define CORPSE_CAN_REENTER 1
#define CORPSE_CAN_REENTER_AND_RESPAWN 2

#define SPECIES_HUMAN       "Human"
#define SPECIES_TAJARA      "Tajara"
#define SPECIES_DIONA       "Diona"
#define SPECIES_VOX         "Vox"
#define SPECIES_IPC         "Machine"
#define SPECIES_UNATHI      "Unathi"
#define SPECIES_SKRELL      "Skrell"
#define SPECIES_NABBER      "Giant Armoured Serpentid"
#define SPECIES_PROMETHEAN  "Promethean"
#define SPECIES_EGYNO       "Egyno"
#define SPECIES_MONKEY      "Monkey"
#define SPECIES_GOLEM       "Golem"

// Ayyy IDs.
#define SPECIES_XENO                 "Xenomorph"
#define SPECIES_XENO_DRONE           "Xenomorph Drone"
#define SPECIES_XENO_HUNTER          "Xenomorph Hunter"
#define SPECIES_XENO_SENTINEL        "Xenomorph Sentinel"
#define SPECIES_XENO_QUEEN           "Xenomorph Queen"
#define SPECIES_XENO_DRONE_VILE      "Xenomorph Vile Drone"
#define SPECIES_XENO_HUNTER_FERAL    "Xenomorph Feral Hunter"
#define SPECIES_XENO_SENTINEL_PRIMAL "Xenomorph Primal Sentinel"

#define SURGERY_CLOSED 0
#define SURGERY_OPEN 1
#define SURGERY_RETRACTED 2
#define SURGERY_ENCASED 3

#define STASIS_MISC     "misc"
#define STASIS_CRYOBAG  "cryobag"
#define STASIS_COLD     "cold"

#define AURA_CANCEL 1
#define AURA_FALSE  2
#define AURA_TYPE_BULLET "Bullet"
#define AURA_TYPE_WEAPON "Weapon"
#define AURA_TYPE_THROWN "Thrown"
#define AURA_TYPE_LIFE   "Life"

#define METROID_EVOLUTION_THRESHOLD 10

//Used in mob/proc/get_input

#define MOB_INPUT_TEXT "text"
#define MOB_INPUT_MESSAGE "message"
#define MOB_INPUT_NUM "num"

#define MARKING_TARGET_SKIN 0 // Draw a datum/sprite_accessory/marking to the mob's body, eg. tattoos
#define MARKING_TARGET_HAIR 1 // Draw a datum/sprite_accessory/marking to the mob's hair, eg. color fades
#define MARKING_TARGET_HEAD 2 // Draw a datum/sprite_accessory/marking to the mob's head after their hair, eg. ears, horns (To Be Implemented since tajarans dropping ears because of radiation is cringe)

#define STOMACH_FULLNESS_SUPER_LOW  25
#define STOMACH_FULLNESS_LOW        125
#define STOMACH_FULLNESS_MEDIUM     250
#define STOMACH_FULLNESS_HIGH       425
#define STOMACH_FULLNESS_SUPER_HIGH 550

#define STOMACH_CAPACITY_LOW    0.75 // Slim people
#define STOMACH_CAPACITY_NORMAL 1.0  // Normal human beings
#define STOMACH_CAPACITY_HIGH   1.45 // Spherical boiz

#define HUMAN_POWER_NONE    "None"
#define HUMAN_POWER_SPIT    "Spit"
#define HUMAN_POWER_LEAP    "Leap"
#define HUMAN_POWER_TACKLE  "Tackle"

#define HUMAN_MAX_POISE     75 // 100% healthy, non-druged human being with magboots and heavy armor.
#define HUMAN_HIGH_POISE    60
#define HUMAN_DEFAULT_POISE 50 // 100% healthy, non-drugged human being.
#define HUMAN_LOW_POISE     45
#define HUMAN_MIN_POISE     25 // Some balancing stuff here. Even drunk pirates should be able to fight.
