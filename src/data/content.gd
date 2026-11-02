class_name Content
## All game content as data (GDD §8–§14). Names/descriptions are translation keys,
## see i18n/content.csv. Order arrays define stable network type ids.

const STATS: Array[String] = [
	"max_hp", "hp_regen", "lifesteal", "damage", "melee", "ranged", "status",
	"attack_speed", "crit", "summon", "range", "armor", "dodge", "speed",
	"luck", "income", "pickup", "xp",
]

## Base values every character starts with (before character modifiers).
const BASE_STATS := {
	"max_hp": 15.0, "hp_regen": 0.0, "lifesteal": 0.0, "damage": 0.0, "melee": 0.0,
	"ranged": 0.0, "status": 0.0, "attack_speed": 0.0, "crit": 0.0, "summon": 0.0,
	"range": 0.0, "armor": 0.0, "dodge": 0.0, "speed": 0.0, "luck": 0.0,
	"income": 0.0, "pickup": 0.0, "xp": 0.0,
}

## Amount a single level-up adds to a stat.
const LEVELUP_AMOUNTS := {
	"max_hp": 5.0, "hp_regen": 3.0, "lifesteal": 2.0, "damage": 5.0, "melee": 2.0,
	"ranged": 2.0, "status": 2.0, "attack_speed": 5.0, "crit": 4.0, "summon": 2.0,
	"range": 25.0, "armor": 2.0, "dodge": 3.0, "speed": 4.0, "luck": 6.0,
	"income": 2.0, "pickup": 20.0, "xp": 8.0,
}

const PLAYER_BASE_SPEED := 220.0
const PLAYER_BASE_PICKUP := 80.0
const PLAYER_RADIUS := 16.0
const MAX_WEAPONS := 6
const DODGE_CAP := 60.0

# --- Characters (GDD §9) -----------------------------------------------------

const CHAR_ORDER: Array[String] = [
	"stadtbild", "sozialtourist", "buergergeld", "klimakleber",
	"lastenrad", "gewerkschaft", "antifa", "oma", "toechter",
]

const CHARACTERS := {
	"stadtbild": {"ult": "flashmob", "mods": {"max_hp": 2.0}, "weapon": "doener", "locked": false, "quote": "merz-01"},
	"sozialtourist": {"ult": "urlaubsantrag", "mods": {"max_hp": -3.0}, "weapon": "pfandflasche", "locked": false, "quote": "merz-06",
		"start_pfand": 30, "free_rerolls": 2},
	"buergergeld": {"ult": "antrag_gestellt", "mods": {"income": 8.0, "damage": -20.0}, "weapon": "gendersternchen", "locked": false, "quote": ""},
	"klimakleber": {"ult": "strassenblockade", "mods": {"speed": -10.0, "status": 3.0}, "weapon": "kleber", "locked": false, "quote": ""},
	"lastenrad": {"ult": "critical_mass", "mods": {"speed": 25.0}, "weapon": "megafon", "locked": false, "quote": "", "max_weapons": 7},
	"gewerkschaft": {"ult": "tarifrunde", "mods": {"summon": 2.0}, "weapon": "infostand", "locked": false, "quote": ""},
	"antifa": {"ult": "schwarzer_block", "mods": {"speed": 10.0, "damage": 10.0}, "weapon": "farbbeutel", "locked": false, "quote": ""},
	"oma": {"ult": "kaffee_und_kuchen", "mods": {"speed": -20.0, "max_hp": 15.0, "armor": 4.0}, "weapon": "stricknadeln", "locked": false, "quote": ""},
	"toechter": {"ult": "fragen_sie_uns", "mods": {}, "weapon": "transparent", "locked": true, "quote": "merz-02", "unlock": "ach_aufsichtsrat"},
}

# --- Weapons (GDD §11) -------------------------------------------------------
# kind: shot | cone | orbit | puddle | turret | lob | wall | mark | chain | beam | fan | swarm | thrust | trail
#       | tether | decoy | follower | patrol
# dmg: per tier 1..4; scale: stat -> coefficient added to damage.

const WEAPON_ORDER: Array[String] = [
	"gendersternchen", "pfandflasche", "megafon", "stricknadeln", "doener", "grundgesetz",
	"transparent", "mietspiegel", "tofu", "farbbeutel", "kleber", "infostand",
	"kartoffelbrei", "trillerpfeife", "brandmauer_ziegel", "normenkontrolle",
	"unterschriftenliste", "scheinwerfer", "neun_euro_ticket", "weisser_overall",
	"fahnenstange", "bierkiste", "strassenkreide",
	"kleine_anfrage", "lobbyregister", "faktencheck", "soli_sticker",
	"menschenkette", "pappkamerad", "demo_sanis", "lauti",
]

const WEAPONS := {
	"gendersternchen": {"kind": "shot", "dmg": [6, 10, 16, 26], "cd": 1.0, "range": 380.0, "speed": 620.0,
		"bounce": 1, "proj": "stern", "scale": {"ranged": 1.0}, "price": 20, "crit_mult": 2.0},
	"pfandflasche": {"kind": "shot", "dmg": [8, 13, 20, 32], "cd": 1.3, "range": 320.0, "speed": 520.0,
		"boomerang": true, "pierce": 99, "pfand_chance": 0.1, "proj": "flasche", "scale": {"ranged": 0.8}, "price": 18},
	"megafon": {"kind": "cone", "dmg": [5, 8, 13, 21], "cd": 1.1, "range": 200.0, "arc": 60.0, "knock": 40.0,
		"scale": {"ranged": 0.7}, "price": 22},
	"stricknadeln": {"kind": "shot", "dmg": [3, 5, 8, 13], "cd": 0.35, "range": 340.0, "speed": 760.0,
		"proj": "nadel", "scale": {"ranged": 1.0}, "price": 18},
	"doener": {"kind": "cone", "dmg": [12, 20, 32, 50], "cd": 0.9, "range": 130.0, "arc": 25.0, "knock": 30.0,
		"scale": {"melee": 1.0}, "price": 20, "melee": true},
	"grundgesetz": {"kind": "cone", "dmg": [9, 15, 24, 38], "cd": 1.2, "range": 120.0, "arc": 120.0, "knock": 140.0,
		"scale": {"melee": 0.8}, "price": 22, "melee": true},
	"transparent": {"kind": "cone", "dmg": [7, 12, 19, 30], "cd": 1.4, "range": 110.0, "arc": 360.0, "knock": 60.0,
		"scale": {"melee": 0.7}, "price": 24, "melee": true},
	"mietspiegel": {"kind": "orbit", "dmg": [6, 10, 16, 26], "cd": 0.5, "range": 90.0, "count": [1, 1, 2, 2],
		"scale": {"melee": 0.5}, "price": 26, "melee": true},
	"tofu": {"kind": "shot", "dmg": [3, 5, 8, 13], "cd": 1.0, "range": 340.0, "speed": 460.0, "proj": "tofu",
		"poison": [5, 8, 13, 21], "poison_time": 3.0, "scale": {"status": 1.0}, "price": 20},
	"farbbeutel": {"kind": "shot", "dmg": [7, 11, 18, 29], "cd": 1.3, "range": 360.0, "speed": 430.0, "proj": "farbe",
		"splash": 70.0, "slow": 0.4, "slow_time": 2.0, "scale": {"status": 0.8, "ranged": 0.4}, "price": 22},
	"kleber": {"kind": "puddle", "dmg": [4, 7, 11, 18], "cd": 2.2, "range": 300.0, "radius": 60.0, "life": 3.0,
		"slow": 0.7, "scale": {"status": 1.0}, "price": 24},
	"infostand": {"kind": "turret", "dmg": [5, 8, 12, 17], "cd": 5.0, "range": 300.0, "fire_cd": 0.6, "life": [10.0, 10.0, 15.0, 20.0],
		"max": [2, 2, 3, 4], "proj": "flugblatt", "speed": 520.0, "scale": {"summon": 0.8}, "price": 26,
		"bounce": [1, 1, 2, 2], "bounce_range": 140.0, "bounce_falloff": 0.2,   # leaflets jump on (D-115)
		"refill_cd": 1.0},   # below its stand cap a copy places the next stand after this (D-117)
	"kartoffelbrei": {"kind": "lob", "dmg": [18, 30, 48, 77], "cd": 3.0, "range": 340.0, "radius": 110.0,
		"delay": 0.8, "proj": "kartoffelbrei", "scale": {"ranged": 1.0}, "price": 26},
	"trillerpfeife": {"kind": "cone", "dmg": [5, 8, 13, 21], "cd": 2.0, "range": 150.0, "arc": 360.0, "knock": 0.0,
		"stun": 0.6, "scale": {"melee": 0.6}, "price": 22, "melee": true},
	"brandmauer_ziegel": {"kind": "wall", "dmg": [3, 5, 8, 13], "cd": 4.0, "range": 220.0, "width": 140.0,
		"life": 6.0, "slow": 0.4, "max": 2, "scale": {"summon": 1.0}, "price": 26},
	"normenkontrolle": {"kind": "mark", "dmg": [45, 75, 120, 193], "cd": 4.5, "range": 360.0, "delay": 3.0,
		"scale": {"status": 1.0}, "price": 28},
	"unterschriftenliste": {"kind": "chain", "dmg": [5, 8, 13, 21], "cd": 1.4, "range": 260.0, "jumps": 3,
		"jump_range": 120.0, "falloff": 0.2, "scale": {"ranged": 0.9}, "price": 22},
	"scheinwerfer": {"kind": "beam", "dmg": [14, 23, 37, 60], "cd": 2.2, "range": 400.0, "width": 22.0,
		"expose": 5.0, "expose_crit": 15.0, "scale": {"ranged": 1.0}, "price": 26},
	"neun_euro_ticket": {"kind": "fan", "dmg": [3, 5, 8, 13], "cd": 1.5, "range": 180.0, "count": 9, "count_late": 5,
		"late_wave": 4, "arc": 60.0, "speed": 520.0, "proj": "ticket", "scale": {"ranged": 0.5}, "price": 18},
	"weisser_overall": {"kind": "swarm", "dmg": [6, 10, 16, 26], "cd": 4.0, "range": 300.0, "count": 3,
		"splash_r": 55.0, "splash": 0.5, "scale": {"summon": 1.0}, "price": 24},   # splash on arrival (D-115)
	# More melee and zone weapons (GDD §11, D-080)
	"fahnenstange": {"kind": "thrust", "dmg": [10, 17, 27, 43], "cd": 1.0, "range": 190.0, "width": 18.0, "arc": 6.0,
		"knock": 50.0, "scale": {"melee": 0.9}, "price": 22, "melee": true},
	"bierkiste": {"kind": "cone", "dmg": [22, 37, 59, 95], "cd": 2.4, "range": 120.0, "arc": 360.0, "knock": 220.0,
		"stun": 0.3, "scale": {"melee": 1.2}, "price": 26, "melee": true},
	"strassenkreide": {"kind": "trail", "dmg": [9, 15, 24, 39], "cd": 0.35, "range": 60.0, "radius": 26.0, "life": 4.0,
		"spacing": 24.0, "still_radius": 60.0, "still_grow": 12.0, "scale": {"status": 0.8}, "price": 24},
	# Status and summon weapons (GDD §11 v0.3, D-091). Status effects: D-092.
	# Kleine Anfrage: "In Bearbeitung" (silence) for `silence` s; aims at enemies with an ability first.
	"kleine_anfrage": {"kind": "shot", "dmg": [12, 20, 32, 52], "cd": 1.2, "range": 360.0, "speed": 500.0, "pierce": 1,
		"proj": "akte", "silence": 3.0, "prefer_ability": true, "scale": {"status": 1.3}, "price": 24},
	# Lobbyregister: +1 "Aktenkundig" stack per hit (max `file`, +`file_vuln` damage each, `file_time` s);
	# a hit at max stacks is "Offengelegt": `burst` (+ burst_scale), stacks back to 0.
	"lobbyregister": {"kind": "shot", "dmg": [3, 5, 8, 13], "cd": 0.7, "range": 340.0, "speed": 700.0, "proj": "aktenblatt",
		"file": 5, "file_time": 5.0, "file_vuln": 0.05, "burst": [16, 27, 43, 69], "burst_scale": {"status": 1.2},
		"scale": {"status": 0.5}, "price": 26},
	# Faktencheck: "Rolle rückwärts" for `reverse` s, wipes enemy projectiles in the cone.
	"faktencheck": {"kind": "cone", "dmg": [10, 17, 27, 43], "cd": 1.6, "range": 170.0, "arc": 90.0, "knock": 0.0,
		"reverse": [1.2, 1.3, 1.4, 1.6], "clear_shots": true, "max_hits": 4, "scale": {"status": 1.2}, "price": 22},
	# Soli-Sticker: hit + sticker poison per s (flat + sticker_scale, × Wut); passes on once per
	# `spread_cd` to one sticker-free enemy within `spread_range`; at most `sticker_max` per player.
	"soli_sticker": {"kind": "shot", "dmg": [6, 10, 16, 26], "cd": 0.9, "range": 320.0, "speed": 520.0, "proj": "sticker",
		"sticker": [3.5, 6.0, 9.0, 15.0], "sticker_time": 4.0, "sticker_scale": {"status": 0.35}, "spread_range": 50.0,
		"spread_cd": 1.0, "sticker_max": 12, "scale": {"status": 0.6}, "price": 24},
	# Menschenkette: a chain from you to the nearest living teammate within `length` (else a
	# lamppost toward your target, at most `lamp_reach` away) for `life` s; damage every `tick` s.
	"menschenkette": {"kind": "tether", "dmg": [5, 8, 13, 21], "cd": 5.0, "range": 320.0, "length": 320.0,
		"lamp_reach": 220.0, "life": 6.0, "tick": 0.5, "width": 14.0, "knock": 120.0, "max": 1,
		"scale": {"summon": 0.8}, "price": 26},
	# Pappkamerad: decoy with HP (hp_base + hp_wave·wave + hp_summon·Ehrenamt), lures non-elites
	# within `lure`; confetti burst (dmg, radius burst_r) when it falls or runs out.
	"pappkamerad": {"kind": "decoy", "dmg": [14, 23, 37, 60], "cd": 7.0, "range": 220.0, "life": 8.0, "lure": 240.0,
		"burst_r": 90.0, "hp_base": 25.0, "hp_wave": 15.0, "hp_summon": 5.0, "max": 1, "scale": {"summon": 1.0}, "price": 24},
	# Demo-Sanis: a follower for the whole wave; every cd heals the most injured player within
	# `range` (heal + heal_scale) and shoves enemies within `shove_r` (dmg, knock).
	"demo_sanis": {"kind": "follower", "dmg": [3, 5, 8, 13], "cd": 3.0, "range": 160.0, "heal": [2, 3, 5, 8],
		"heal_scale": {"summon": 0.3}, "shove_r": 70.0, "knock": 100.0, "revive": 1.5, "scale": {"summon": 1.0}, "price": 24},
	# Lauti: a sound truck circling you (radius `range`) for `life` s; a pulse every `pulse_cd` s
	# hits every enemy within `pulse_r`.
	"lauti": {"kind": "patrol", "dmg": [12, 20, 32, 52], "cd": 6.0, "range": 90.0, "life": 10.0, "pulse_cd": 1.0,
		"pulse_r": 120.0, "max_hits": 4, "knock": 80.0, "orbit_speed": 1.3, "max": 1, "scale": {"summon": 1.2}, "price": 24},
}

## Ground weapons that land where Sim.place_mode says (balancing.md §9).
const PLACED_KINDS: Array[String] = ["puddle", "lob", "wall"]
## Weapon kinds that fire without needing a target in range.
const UNTARGETED_KINDS: Array[String] = ["trail", "tether", "follower", "patrol"]

const TIER_PRICE_MULT := [1.0, 1.8, 3.2, 5.5]

# --- Items (GDD §12) ---------------------------------------------------------

const ITEM_ORDER: Array[String] = [
	"schuldenbremse", "sondervermoegen", "bierdeckel", "faxgeraet", "db_ticket",
	"thermoskanne", "betriebsrat", "solibutton", "mate_kiste", "gewerkschaftsweste",
	"wut_tagebuch", "lautsprecherwagen", "strickliesel", "bolzenschneider", "schwarzfahrer_muetze",
	"deutschlandticket_abo", "pfandring", "minijob", "anruf_bei_mama", "signal_gruppe",
	"spendendose", "sekundenkleber", "vereinsheim", "fernglas", "mietendeckel",
	"erste_hilfe_kurs", "streikkasse", "spaeti_sonnenbrille", "taugenichts", "vogelschiss",
	"reichsausweis",
	"isomatte",
	"club_mate",
	"fahrradhelm",
	"frisbee",
	"taschenlampe",
	"flugblatt_stapel",
	"kirschkernkissen",
	"megafon_akku",
	"arbeitshandschuhe",
	"demosani_weste",
	"pfandrucksack",
	"protestschild",
	"kiezkarte",
	"lastenrad_anhaenger",
	"tarifvertrag",
	"volkskueche",
	"generalschluessel",
	"soli_konzert",
	"hausbesetzung",
	"wurfmaschine",
	"genossenschaftsanteil",
	"ehrenamtskarte",
	"kompost",
	"kritische_masse",
	"robin_hood",
	"tarnkappe",
]

const ITEMS := {
	"schuldenbremse": {"mods": {"damage": 15.0}, "flags": ["schuldenbremse"], "price": 25, "rarity": 2},
	"sondervermoegen": {"mods": {"income": 5.0}, "flags": ["sondervermoegen"], "price": 45, "rarity": 3},
	"bierdeckel": {"mods": {}, "flags": [], "price": 5, "rarity": 1},
	"faxgeraet": {"mods": {"damage": 40.0}, "flags": ["fax"], "price": 30, "rarity": 3},
	"db_ticket": {"mods": {"speed": 30.0}, "flags": ["db_ticket"], "price": 20, "rarity": 2},
	"thermoskanne": {"mods": {"hp_regen": 3.0}, "price": 16, "rarity": 1},
	"betriebsrat": {"mods": {"armor": 3.0, "speed": -3.0}, "price": 22, "rarity": 2},
	"solibutton": {"mods": {"max_hp": 10.0}, "price": 20, "rarity": 1},
	"mate_kiste": {"mods": {"attack_speed": 12.0, "max_hp": -3.0}, "price": 22, "rarity": 2},
	"gewerkschaftsweste": {"mods": {"armor": 2.0, "max_hp": 5.0}, "price": 24, "rarity": 2},
	"wut_tagebuch": {"mods": {"damage": 10.0}, "price": 24, "rarity": 2},
	"lautsprecherwagen": {"mods": {"ranged": 2.0, "range": 30.0}, "price": 24, "rarity": 2},
	"strickliesel": {"mods": {"ranged": 3.0}, "price": 18, "rarity": 1},
	"bolzenschneider": {"mods": {"crit": 5.0, "melee": 2.0}, "price": 24, "rarity": 2},
	"schwarzfahrer_muetze": {"mods": {"dodge": 8.0}, "price": 22, "rarity": 2},
	"deutschlandticket_abo": {"mods": {"speed": 10.0}, "price": 16, "rarity": 1},
	"pfandring": {"mods": {"pickup": 60.0}, "price": 12, "rarity": 1},
	"minijob": {"mods": {"income": 5.0}, "price": 20, "rarity": 1},
	"anruf_bei_mama": {"mods": {"luck": 15.0}, "price": 18, "rarity": 1},
	"signal_gruppe": {"mods": {"xp": 15.0}, "price": 18, "rarity": 1},
	"spendendose": {"mods": {"lifesteal": 2.0}, "price": 22, "rarity": 2},
	"sekundenkleber": {"mods": {"status": 3.0}, "price": 18, "rarity": 1},
	"vereinsheim": {"mods": {"summon": 3.0}, "price": 20, "rarity": 1},
	"fernglas": {"mods": {"range": 50.0}, "price": 18, "rarity": 1},
	"mietendeckel": {"mods": {"armor": 1.0}, "flags": ["mietendeckel"], "price": 20, "rarity": 2},
	"erste_hilfe_kurs": {"mods": {"max_hp": 5.0}, "flags": ["erste_hilfe"], "price": 18, "rarity": 2, "coop_only": true},
	"streikkasse": {"mods": {}, "flags": ["streikkasse"], "price": 28, "rarity": 3},
	"spaeti_sonnenbrille": {"mods": {"crit": 5.0, "luck": 5.0}, "price": 20, "rarity": 2},
	"taugenichts": {"mods": {"luck": 20.0, "attack_speed": -10.0}, "flags": ["taugenichts"], "price": 30, "rarity": 3},
	"vogelschiss": {"mods": {"damage": 1.0}, "price": 3, "rarity": 1, "hidden": true},
	"reichsausweis": {"mods": {}, "price": 0, "rarity": 1, "hidden": true, "no_shop": true},
	# green: one simple bonus
	"isomatte": {"mods": {"armor": 2.0}, "price": 12, "rarity": 1},
	"club_mate": {"mods": {"attack_speed": 6.0}, "price": 14, "rarity": 1},
	"fahrradhelm": {"mods": {"max_hp": 6.0}, "price": 10, "rarity": 1},
	"frisbee": {"mods": {"ranged": 2.0}, "price": 12, "rarity": 1},
	"taschenlampe": {"mods": {"crit": 3.0}, "price": 12, "rarity": 1},
	"flugblatt_stapel": {"mods": {"summon": 2.0}, "price": 12, "rarity": 1},
	"kirschkernkissen": {"mods": {"hp_regen": 2.0}, "price": 10, "rarity": 1},
	# blue: good, sometimes with a malus
	"megafon_akku": {"mods": {"ranged": 5.0, "attack_speed": -5.0}, "price": 26, "rarity": 2},
	"arbeitshandschuhe": {"mods": {"melee": 4.0, "armor": 2.0}, "price": 30, "rarity": 2},
	"demosani_weste": {"mods": {"hp_regen": 3.0, "max_hp": 5.0}, "price": 28, "rarity": 2},
	"pfandrucksack": {"mods": {"pickup": 60.0, "income": 3.0}, "price": 24, "rarity": 2},
	"protestschild": {"mods": {"damage": 10.0, "range": 15.0, "speed": -5.0}, "price": 28, "rarity": 2},
	"kiezkarte": {"mods": {"luck": 8.0, "xp": 8.0}, "price": 22, "rarity": 2},
	# purple: very good, malus when very very good
	"lastenrad_anhaenger": {"mods": {"speed": -10.0}, "flags": ["extra_slot"], "price": 55, "rarity": 3},
	"tarifvertrag": {"mods": {"damage": 25.0, "armor": 5.0, "attack_speed": -10.0}, "price": 60, "rarity": 3},
	"volkskueche": {"mods": {"hp_regen": 5.0, "lifesteal": 5.0}, "price": 50, "rarity": 3},
	"generalschluessel": {"mods": {"crit": 20.0, "max_hp": -10.0}, "price": 55, "rarity": 3},
	"soli_konzert": {"mods": {"attack_speed": 30.0, "luck": 10.0, "max_hp": -8.0}, "price": 65, "rarity": 3},
	# red: game-changing, only for specific builds
	"hausbesetzung": {"mods": {}, "flags": ["melee_build"], "price": 90, "rarity": 4},
	"wurfmaschine": {"mods": {}, "flags": ["ranged_build"], "price": 90, "rarity": 4},
	"genossenschaftsanteil": {"mods": {}, "flags": ["coop_economy"], "price": 80, "rarity": 4},
	"ehrenamtskarte": {"mods": {}, "flags": ["summon_build"], "price": 90, "rarity": 4},
	"kompost": {"mods": {}, "flags": ["status_build"], "price": 85, "rarity": 4},
	"kritische_masse": {"mods": {}, "flags": ["crit_build"], "price": 90, "rarity": 4},
	"robin_hood": {"mods": {}, "flags": ["lifesteal_build"], "price": 85, "rarity": 4},
	"tarnkappe": {"mods": {}, "flags": ["dodge_build"], "price": 85, "rarity": 4},
	# politics items (GDD §12 "Politics items")
	"erinnerungsluecke": {"mods": {"dodge": 15.0, "xp": -10.0}, "price": 50, "rarity": 3},
	"treuhandkonto": {"mods": {}, "flags": ["treuhand"], "price": 26, "rarity": 2},
	"aufhoeren_zu_produzieren": {"mods": {}, "flags": ["aufhoeren"], "price": 26, "rarity": 2},
	"wahlversprechen": {"mods": {}, "flags": ["wahlversprechen"], "price": 24, "rarity": 2},
	"maut_vertrag": {"mods": {}, "flags": ["maut"], "price": 20, "rarity": 3},
	"ber_eroeffnungstermin": {"mods": {}, "flags": ["ber"], "price": 50, "rarity": 3},
	"puma": {"mods": {"ranged": 25.0, "armor": 10.0}, "flags": ["puma"], "price": 60, "rarity": 3},
	"zweiter_wahlgang": {"mods": {"damage": -10.0}, "flags": ["zweiter_wahlgang"], "price": 55, "rarity": 3},
	"cumex_erstattung": {"mods": {}, "flags": ["cumex"], "price": 80, "rarity": 4},
	"doppelwumms": {"mods": {"armor": -15.0}, "flags": ["doppelwumms"], "price": 90, "rarity": 4},
	"brandmauer_fertigputz": {"mods": {"armor": 50.0, "speed": -30.0}, "flags": ["fertigputz"], "price": 90, "rarity": 4},
	"entlassungsurkunde": {"mods": {"crit": 20.0, "ranged": -15.0}, "flags": ["entlassung"], "price": 85, "rarity": 4},
}

## Item rarities (GDD §12): 1 green, 2 blue, 3 purple, 4 red.
const RARITY_COLORS := {1: Color("3f8f4f"), 2: Color("2e6db4"), 3: Color("8e44ad"), 4: Color("c0392b")}
const RED_BUILD := {"melee": 2.0, "melee_other": 0.5, "ranged_pierce": 1, "ranged_speed": 1.5, "ranged_other": 0.5,
	"coop_interest": 0.15, "coop_interest_max": 50, "coop_buys": 2, "summon": 1.5, "summon_life": 2.0, "summon_other": 0.6,
	"status": 2.0, "status_direct": 0.7, "status_spread": 100.0, "crit_extra": 1.5, "crit_other": 0.7,
	"lifesteal_heal": 3.0, "dodge_cap": 80.0,
	"treuhand_chance": 0.5, "treuhand_pfand": 30, "aufhoeren_after": 2.0, "aufhoeren_regen": 8.0, "aufhoeren_armor": 10.0,
	"wahl_time": 10.0, "wahl_early": 40.0, "wahl_late": -10.0, "maut_now": 60, "maut_wave": 8,
	"ber_wave": 10, "ber_early": -10.0, "ber_late_dmg": 40.0, "ber_late_as": 20.0,
	"puma_period": 18.0, "puma_down": 3.0, "second_round_hp": 0.5, "cumex_max": 40, "cumex_audit_wave": 15,
	"wumms_radius": 150.0, "wumms_delay": 0.35, "fertigputz_knock": 600.0, "entlassung_hp": 0.3}

## Shop weight of an item rarity at a given wave (luck shifts towards rarer tiers).
static func rarity_weight(rarity: int, wave: int, luck: float) -> float:
	var w := 0.0
	match rarity:
		1: w = 10.0
		2: w = 3.0 + 0.35 * wave
		3: w = maxf(0.0, (wave - 3) * 0.35)
		4: w = maxf(0.0, (wave - 7) * 0.12)
	return w * (1.0 + maxf(0.0, luck) / 100.0 * (rarity - 1) * 0.5)


# --- Enemies (GDD §13, §14) --------------------------------------------------
# faction: afd (spawns behind the Brandmauer) | union | kapital | elite
# ai: chase | ranged | voter | charger | zone | lob | flyer | bomb | sylt | boss

const ENEMY_ORDER: Array[String] = [
	"besorgter_buerger", "telegram_onkel", "identitaerer_hipster", "reichsbuerger",
	"ju_schnoesel", "hinterbaenkler", "lobbyist", "porsche_suv", "immobilienerbe",
	"golfclub_vorstand", "fdp_jungunternehmer", "startup", "privatjet",
	"sylt_member", "geschichtslehrer", "sauerlaender", "eidgenossin",
]

const ENEMIES := {
	"besorgter_buerger": {"faction": "afd", "ai": "chase", "hp": 8.0, "speed": 95.0, "dmg": 4.0, "radius": 16.0,
		"pfand": 1, "xp": 1.0, "from_wave": 1, "weight": 10, "say": ["SAY_BESORGT_1", "SAY_BESORGT_2"]},
	"telegram_onkel": {"faction": "afd", "ai": "ranged", "hp": 10.0, "speed": 80.0, "dmg": 3.0, "radius": 16.0,
		"pfand": 2, "xp": 2.0, "from_wave": 2, "weight": 5, "keep": 260.0, "fire_cd": 2.5, "proj": "kettenbrief",
		"proj_dmg": 4.0, "proj_speed": 260.0, "say": ["SAY_TELEGRAM_1"]},
	"identitaerer_hipster": {"faction": "afd", "ai": "chase", "hp": 14.0, "speed": 170.0, "dmg": 5.0, "radius": 15.0,
		"pfand": 2, "xp": 2.0, "from_wave": 6, "weight": 5, "push_up": 220.0, "say": ["SAY_HIPSTER_1"]},
	"reichsbuerger": {"faction": "afd", "ai": "chase", "hp": 70.0, "speed": 60.0, "dmg": 8.0, "radius": 26.0,
		"pfand": 4, "xp": 5.0, "from_wave": 11, "weight": 3, "immune": true, "say": ["SAY_REICHSBUERGER_1"]},
	"ju_schnoesel": {"faction": "union", "ai": "voter", "hp": 9.0, "speed": 150.0, "dmg": 3.0, "radius": 15.0,
		"pfand": 2, "xp": 2.0, "from_wave": 1, "weight": 4, "vote_time": 3.0, "say": ["SAY_JU_1"]},
	"hinterbaenkler": {"faction": "union", "ai": "chase", "hp": 20.0, "speed": 90.0, "dmg": 5.0, "radius": 18.0,
		"pfand": 2, "xp": 3.0, "from_wave": 6, "weight": 5, "buff_near_afd": true, "say": []},
	"lobbyist": {"faction": "kapital", "ai": "chase", "hp": 24.0, "speed": 85.0, "dmg": 4.0, "radius": 17.0,
		"pfand": 5, "xp": 3.0, "from_wave": 6, "weight": 3, "aura": 150.0, "say": ["SAY_LOBBY_1"]},
	"porsche_suv": {"faction": "kapital", "ai": "charger", "hp": 40.0, "speed": 90.0, "dmg": 10.0, "radius": 24.0,
		"pfand": 4, "xp": 4.0, "from_wave": 6, "weight": 3, "say": []},
	"immobilienerbe": {"faction": "kapital", "ai": "zone", "hp": 30.0, "speed": 70.0, "dmg": 4.0, "radius": 18.0,
		"pfand": 5, "xp": 4.0, "from_wave": 11, "weight": 3, "keep": 220.0, "say": ["SAY_ERBE_1"]},
	"golfclub_vorstand": {"faction": "kapital", "ai": "lob", "hp": 26.0, "speed": 70.0, "dmg": 3.0, "radius": 17.0,
		"pfand": 4, "xp": 4.0, "from_wave": 11, "weight": 3, "keep": 330.0, "fire_cd": 3.0, "proj_dmg": 7.0, "say": []},
	"fdp_jungunternehmer": {"faction": "kapital", "ai": "chase", "hp": 30.0, "speed": 100.0, "dmg": 5.0, "radius": 17.0,
		"pfand": 3, "xp": 3.0, "from_wave": 11, "weight": 3, "split": "startup", "say": ["SAY_FDP_1"]},
	"startup": {"faction": "kapital", "ai": "bomb", "hp": 6.0, "speed": 140.0, "dmg": 8.0, "radius": 11.0,
		"pfand": 0, "xp": 1.0, "from_wave": 99, "weight": 0, "fuse": 2.5, "say": []},
	"privatjet": {"faction": "kapital", "ai": "flyer", "hp": 50.0, "speed": 260.0, "dmg": 8.0, "radius": 26.0,
		"pfand": 6, "xp": 5.0, "from_wave": 16, "weight": 2, "say": []},
	"sylt_member": {"faction": "elite", "ai": "sylt", "hp": 260.0, "speed": 110.0, "dmg": 8.0, "radius": 20.0,
		"pfand": 15, "xp": 15.0, "from_wave": 99, "weight": 0, "fire_cd": 2.5, "proj_dmg": 6.0, "say": ["SAY_SYLT_1"]},
	"geschichtslehrer": {"faction": "elite", "ai": "boss", "hp": 2000.0, "speed": 70.0, "dmg": 10.0, "radius": 34.0,
		"pfand": 60, "xp": 40.0, "from_wave": 99, "weight": 0, "say": []},
	"sauerlaender": {"faction": "elite", "ai": "boss", "hp": 4000.0, "speed": 80.0, "dmg": 12.0, "radius": 38.0,
		"pfand": 90, "xp": 60.0, "from_wave": 99, "weight": 0, "say": []},
	"eidgenossin": {"faction": "elite", "ai": "boss", "hp": 6500.0, "speed": 90.0, "dmg": 14.0, "radius": 36.0,
		"pfand": 0, "xp": 0.0, "from_wave": 99, "weight": 0, "say": []},
}

## Factions the Töchter count as "old men in suits".
const SUIT_FACTIONS := ["union", "kapital"]

# --- Projectiles, pickups, hazards, summons (render type ids) ----------------

const PROJ_ORDER: Array[String] = [
	"stern", "flasche", "nadel", "tofu", "farbe", "flugblatt",
	"kettenbrief", "golfball", "champagner", "buch", "bierdeckel", "zirkusball",
	"fluegel", "goldbarren", "spiegel", "kartoffelbrei", "ticket",
	"akte", "aktenblatt", "sticker",
]
const PICKUP_ORDER: Array[String] = ["pfand", "passant", "geldschein", "stulle", "reichsausweis"]
const HAZARD_ORDER: Array[String] = [
	"kleber", "mietzone", "kerosin", "lob_marker", "sitzblockade", "explosion", "abschiebezone",
	"push_ring", "farbklecks", "brei_marker", "ziegel", "paragraf", "kreide",
	"kette", "abstimmung", "plenum", "kahlschlag", "kahlschlag_hit",
]
const SUMMON_ORDER: Array[String] = ["infostand", "oma", "turbine", "genosse", "overall",
	"laterne", "pappkamerad", "sani", "lauti"]

# --- Ultimates (GDD §9a): Space, once per wave ----------------------------------

const ULT_ORDER: Array[String] = [
	"flashmob", "urlaubsantrag", "antrag_gestellt", "strassenblockade", "critical_mass",
	"tarifrunde", "schwarzer_block", "kaffee_und_kuchen", "fragen_sie_uns",
]
const ULTS := {
	"flashmob": {"radius": 240.0, "stun": 2.0, "dmg": 20.0, "dmg_per_follower": 5.0, "knock": 260.0},
	"urlaubsantrag": {"time": 4.0, "heal_per_s": 0.08},
	"antrag_gestellt": {"time": 6.0, "slow": 0.6},
	"strassenblockade": {"time": 6.0, "slow": 0.85, "radius": 46.0, "spacing": 70.0, "dps": 4.0},
	"critical_mass": {"dash_time": 0.4, "dash_speed": 1250.0, "ram_mult": 3.0, "boost_time": 5.0, "boost": 2.0},
	"tarifrunde": {"time": 8.0, "damage": 0.5},
	"schwarzer_block": {"count": 6, "time": 6.0, "dmg": 6.0, "radius": 60.0},
	"kaffee_und_kuchen": {"regen_time": 10.0, "regen": 3.0, "revive_hp": 0.5},
	"fragen_sie_uns": {"stun": 2.0, "vuln_time": 6.0, "vuln": 2.0, "vuln_boss": 1.5},   # x1.5 on encounter units (D-102)
}

# --- Waves (GDD §4) ----------------------------------------------------------

const WAVE_COUNT := 20
const WAVE_LENGTHS := [30, 30, 35, 35, 40, 40, 45, 50, 55, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, -1]
const MAX_ENEMIES := 220

## Encounter per wave (GDD §14). Each tier is a pool; MVP has one entry each.
const ENCOUNTER_POOLS := {
	5: ["sylt_clique"],
	10: ["geschichtslehrer"],
	15: ["sauerlaender"],
	20: ["eidgenossin"],
}
const ENCOUNTER_ORDER: Array[String] = ["sylt_clique", "geschichtslehrer", "sauerlaender", "eidgenossin"]
const ENCOUNTERS := {
	"sylt_clique": {"units": ["sylt_member", "sylt_member", "sylt_member", "sylt_member"], "quote": "", "exit": "yacht",
		"achievement": "ach_doep", "hp_mult": 1.25},
	"geschichtslehrer": {"units": ["geschichtslehrer"], "quote": "hoecke-02", "exit": "abseits",
		"achievement": "ach_180", "hp_mult": 2.2, "slow_cap": 0.4},
	"sauerlaender": {"units": ["sauerlaender"], "quote": "merz-17", "exit": "jet", "achievement": "ach_aufsichtsrat",
		"hp_mult": 2.0, "slow_cap": 0.4},
	"eidgenossin": {"units": ["eidgenossin"], "quote": "weidel-05", "exit": "schweiz", "achievement": "ach_remigration",
		"hp_mult": 1.0, "slow_cap": 0.4, "ult_per_phase": true},
}
# hp_mult: encounter HP factor; slow_cap: max slow from any source (bosses and minibosses, not the
# Sylt-Clique); ult_per_phase: every player's ultimate recharges at each phase change (GDD §14, D-102)

## Boss casts (GDD §14, D-107, D-108): interruptible by a stun, shown in the boss bar.
## Append only: the snapshot sends 1 + index.
const BOSS_CASTS: Array[String] = ["wende", "abstimmung", "kahlschlag", "ansturm", "remigration"]

## Boss rules (GDD §14 "Boss rules", D-102 to D-112). Starting values for the balancing round.
## [a, b] pairs run linearly from Umfrage 10 % (level 0) to 35 % (level 5).
const BOSS := {
	# phases: lock at these HP fractions, Pressekonferenz between them (D-102, D-106)
	"phase_at": [0.66, 0.33], "phase_tempo": [1.0, 1.2, 1.4],
	"presse_time": 2.5, "presse_time_l4": 1.5,
	# random target every target_min..target_max s (D-103)
	"target_min": 4.0, "target_max": 7.0,
	# resistance (D-102, D-107)
	"stun_mult": 0.5, "standfest": 10.0, "standfest_l4": 15.0,
	# telegraphs (B8): × factor per Umfrage level, never below telegraph_floor of the base
	"telegraph_mult": [1.0, 0.95, 0.95, 0.9, 0.85, 0.8], "telegraph_floor": 0.75,
	# Geschichtslehrer: Wende um 180 Grad (D-104, D-112)
	"wende_first": 4.0, "wende_every": 10.0, "wende_warn": 1.5, "wende_time": 4.0, "wende_time_l4": 5.0,
	"wende_axis_from": 3, "wende_book_life": 4.0,
	# Sauerländer: Abstimmung, egal mit wem (D-104, D-109)
	"vote_every": 20.0, "vote_time": [3.0, 2.2], "vote_dmg": [0.06, 0.09], "vote_walk": 2.5, "vote_walk_max": 5.0,
	"vote_fail_stun": 1.5, "vote_adds": 4, "vote_adds_per_player": 2, "vote_double_from": 5,
	"plenum_radius": 70.0, "plenum_dist": 230.0, "plenum_spacing": 160.0,
	# Sauerländer: Kahlschlag (D-104, D-110)
	"kahl_from_phase": 1, "kahl_every": 14.0, "kahl_every_l3": 11.0, "kahl_warn": 1.2, "kahl_arc": 90.0,
	"kahl_reach": 380.0, "kahl_dmg": 1.5, "kahl_double_from": 5, "kahl_second_delay": 0.8, "kahl_second_turn": 60.0,
	# Remigrantin: Die Brandmauer hält (D-104, D-111)
	"band": 110.0, "band_l3": 150.0, "band_per_player": 10.0, "ring_every": [3.5, 2.6], "remig_warn": 2.0,
	"ansturm_warn": 0.8,   # her charge wind-up: a targeted impact needs 0.8 s (B8; was 0.7)
}

# --- Organisationen (GDD §10) ------------------------------------------------

const ORG_ORDER: Array[String] = ["gewerkschaft", "antifa", "omas"]

# --- Difficulty: Umfrage levels (GDD §17) ------------------------------------

const DIFFICULTY_PERCENT := [10, 15, 20, 25, 30, 35]

## Every balancing knob (docs/specs/balancing.md). Measured with tools/balance_matrix.sh.
const BALANCE := {
	# enemies: HP × (1 + hp_lin·w + hp_quad·w² + hp_cubic·w³), dmg × (dmg_base + dmg_lin·w)
	"hp_lin": 0.18, "hp_quad": 0.018, "hp_cubic": 0.0007, "dmg_base": 0.5, "dmg_lin": 0.095,
	"coop_hp": 0.10, "coop_spawn": 0.55,     # × (1 + k·(players − 1))
	"spawn_base": 0.32, "spawn_lin": 0.15,   # spawns per second: base + lin·wave
	"diff_hp": 0.15, "diff_dmg": 0.10, "diff_spawn": 0.08,   # Umfrage level L: × (1 + k·L)
	# elites and bosses
	"elite_base": 0.6, "elite_coop": 0.3,    # HP × (base + coop·(players − 1))
	"final_boss_mult": 4.5,                  # Die Remigrantin's HP on top
	"diff_boss_hp": 0.15,                    # encounter units only: × (1 + k·L) on top of diff_hp (D-102)
	"melee_vs_boss": 2.0,                   # melee weapons against encounter units (D-121)
	"elite_wave_exp": 0.6,                   # elite HP × (enemy HP curve(wave) / curve(5)) ^ this
	"boss_wave_spawn": 0.25,                 # regular spawn rate while an elite/boss is alive
	# economy: prices × (1 + price_lin·w + price_quad·w² + price_cubic·w³), w = wave − 1
	"price_lin": 0.08, "price_quad": 0.009, "price_cubic": 0.0004,
	"pfand_mult": 1.2,                      # Pfand per kill × this
	# Reichensteuer (co-op, balancing.md §5a): part above threshold × others' average is taxed
	# at a rate by player count and goes to the poorest first; givers keep reich_keep more
	"reich_threshold": 1.5, "reich_min": 5, "reich_rate": {2: 0.5, 3: 0.6, 4: 0.7}, "reich_keep": 0.1,
	"reich_benchmark": "poorer",              # "poorer": average of the poorer players; "others": of all others
	# level-ups: picks granted after a wave, from that wave on
	"levelup_schedule": [[1, 1], [5, 2], [12, 3]],
	"levelup_rarity_mult": [1.0, 2.0, 3.0, 5.0],
	# Umverteilung: % chance per point and hit to heal 1 HP (Brotato)
	"lifesteal_chance": 1.0,
	# ground weapons (puddle, lob, wall): where they land (balancing.md §9) and the lead time
	# for "lead" when the weapon has no delay of its own
	"place": "cluster", "place_lead": 0.5,
}

static func difficulty_mult(level: int) -> Dictionary:
	return {"hp": 1.0 + BALANCE["diff_hp"] * level, "dmg": 1.0 + BALANCE["diff_dmg"] * level,
		"spawn": 1.0 + BALANCE["diff_spawn"] * level}


## Enemy HP factor for a wave (balancing.md §3): 1 + lin·w + quad·w² + cubic·w³, w = wave − 1.
static func enemy_hp_curve(wave: int) -> float:
	var w := float(wave - 1)
	return 1.0 + BALANCE["hp_lin"] * w + BALANCE["hp_quad"] * w * w + BALANCE["hp_cubic"] * w * w * w


## Level-up picks granted after `wave` (balancing.md §4).
static func levelups_after_wave(wave: int) -> int:
	var n := 0
	for entry in BALANCE["levelup_schedule"]:
		if wave >= int(entry[0]):
			n = int(entry[1])
	return n

# --- Koalitionsvertrag (GDD §16) ---------------------------------------------
# Voted before waves 4, 8, 12, 16. Not unanimous -> highest badness wins.

const VERTRAG_WAVES := [4, 8, 12, 16]
const VERTRAG_ORDER: Array[String] = [
	"digitalpakt", "tempolimit", "mindestlohn", "buerokratieabbau", "aufruestung", "schuldenbremse", "sanktionen",
]
const VERTRAG := {
	"digitalpakt": {"badness": 0},
	"tempolimit": {"badness": 1, "player_speed": -10.0, "enemy_speed": -0.15},
	"mindestlohn": {"badness": 2, "income": 3, "enemy_hp": 0.10},
	"buerokratieabbau": {"badness": 2, "offers": -1, "xp": 25.0},
	"aufruestung": {"badness": 3, "damage": 20.0, "enemy_dmg": 0.20},
	"schuldenbremse": {"badness": 4, "price": -0.15, "no_regen": true},
	"sanktionen": {"badness": 5, "income_mult": 0.5, "pfand_drop": 0.3},
}

# --- Zusammenhalt (GDD §7) ---------------------------------------------------

const STAGE_LEVELS := [0, 3, 6, 10, 15]

static func xp_for_level(level: int) -> float:
	return 10.0 + 6.0 * level

static func stage_for_level(level: int) -> int:
	var stage := 0
	for i in STAGE_LEVELS.size():
		if level >= STAGE_LEVELS[i]:
			stage = i
	return stage

# --- Achievements (GDD §17) --------------------------------------------------

const ACHIEVEMENT_ORDER: Array[String] = [
	"ach_doep", "ach_180", "ach_aufsichtsrat", "ach_remigration", "ach_unmoeglich",
	"ach_faul_effizient", "ach_kassenwart", "ach_vogelschiss",
]

# --- Helpers -----------------------------------------------------------------

static func weapon_damage(id: String, tier: int) -> float:
	return float(WEAPONS[id]["dmg"][clampi(tier, 1, 4) - 1])

static func weapon_price(id: String, tier: int, wave: int) -> int:
	var base: float = WEAPONS[id]["price"] * TIER_PRICE_MULT[clampi(tier, 1, 4) - 1]
	return int(round(base * price_mult(wave)))

static func item_price(id: String, wave: int) -> int:
	return int(round(ITEMS[id]["price"] * price_mult(wave)))

## Shop price factor for a wave (balancing.md §5).
static func price_mult(wave: int) -> float:
	var w := float(wave - 1)
	return 1.0 + BALANCE["price_lin"] * w + BALANCE["price_quad"] * w * w + BALANCE["price_cubic"] * w * w * w

static func sell_price(id: String, tier: int, wave: int) -> int:
	return int(weapon_price(id, tier, wave) * 0.4)

static func reroll_price(wave: int, rerolls_done: int) -> int:
	return 1 + wave + rerolls_done * (int(ceil(wave / 2.0)) + 1)

static func repair_price(wave: int) -> int:
	return 15 + wave * 2

static func wave_length(wave: int) -> float:
	return float(WAVE_LENGTHS[clampi(wave, 1, WAVE_COUNT) - 1])

static func idx(order: Array[String], id: String) -> int:
	return order.find(id)
