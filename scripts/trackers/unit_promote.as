#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

class UnitPromote : Tracker {
    protected Metagame@ m_metagame;
	protected uint currentWeaponId = 0;
	protected uint currentExp = 0;

	protected array<string> eliteWeapons = {
		"null.weapon",
		"wa_awp_e.weapon",
		"wa_chrono_e.weapon",
		"wa_m60_e.weapon",
		"wa_mp5sd_e.weapon",
		"wa_p90_e.weapon",
		"wa_rocketeer_e.weapon",
		"wa_stoner_lmg_e.weapon",
		"ws_desolator_e.weapon",
		"ws_flak_e.weapon",
		"ws_knife_e.weapon",
		"ws_ppsh41_e.weapon",
		"ws_tesla_e.weapon",
		"wy_fist_e.weapon",
		"wy_mind_control_e.weapon",
		"wy_psychic_jab_e.weapon",
		"wy_virus_e.weapon"
	};

	protected array<uint> requiredExp = {
		0,
		400,
		500,
		200,
		400,
		400,
		500,
		200,
		500,
		200,
		200,
		200,
		400,
		200,
		500,
		200,
		500
	};

	protected dictionary weaponId = {
		{"wa_awp.weapon", 1},
		{"wa_awp_v.weapon", 1},
		{"wa_chrono.weapon", 2},
		{"wa_chrono_v.weapon", 2},
		{"wa_m60.weapon", 3},
		{"wa_m60_v.weapon", 3},
		{"wa_mp5sd.weapon", 4},
		{"wa_mp5sd_v.weapon", 4},
		{"wa_p90.weapon", 5},
		{"wa_p90_v.weapon", 5},
		{"wa_rocketeer.weapon", 6},
		{"wa_rocketeer_v.weapon", 6},
		{"wa_stoner_lmg.weapon", 7},
		{"wa_stoner_lmg_v.weapon", 7},
		{"wa_ump40.weapon", 3},
		{"wa_ump40_v.weapon", 3},
		{"ws_desolator.weapon", 8},
		{"ws_desolator_v.weapon", 8},
		{"ws_flak.weapon", 9},
		{"ws_flak_v.weapon", 9},
		{"ws_knife.weapon", 10},
		{"ws_knife_v.weapon", 10},
		{"ws_ppsh41.weapon", 11},
		{"ws_ppsh41_v.weapon", 11},
		{"ws_tesla.weapon", 12},
		{"ws_tesla_v.weapon", 12},
		{"wy_fist.weapon", 13},
		{"wy_fist_v.weapon", 13},
		{"wy_mind_control.weapon", 14},
		{"wy_mind_control_v.weapon", 14},
		{"wy_psychic_jab.weapon", 15},
		{"wy_psychic_jab_v.weapon", 15},
		{"wy_virus.weapon", 16},
		{"wy_virus_v.weapon", 16}
	};

	protected dictionary enemyExp = {
		{"dog", 20},
		{"engineer", 30},
		{"medic", 15},
		{"conscript", 20},
		{"conscript_e", 40},
		{"initiate", 20},
		{"initiate_e", 40},
		{"gi", 20},
		{"gi_e", 40},
		{"flak", 25},
		{"flak_e", 50},
		{"ggi", 25},
		{"ggi_e", 50},
		{"brute", 25},
		{"brute_e", 50},
		{"ivan", 30},
		{"ivan_e", 60},
		{"seal", 40},
		{"seal_e", 80},
		{"sniper", 40},
		{"sniper_e", 80},
		{"tesla", 40},
		{"tesla_e", 80},
		{"desolator", 45},
		{"desolator_e", 90},
		{"rocketeer", 50},
		{"rocketeer_e", 100},
		{"virus", 50},
		{"virus_e", 100},
		{"spy", 60},
		{"spy_e", 120},
		{"psicorp", 70},
		{"psicorp_e", 140},
		{"chrono", 70},
		{"chrono_e", 140},
		{"yuri", 150},
		{"tanya", 150},
		{"boris", 150}
	};

    UnitPromote(Metagame@ metagame) {
        @m_metagame = @metagame;
    }
	/*
	TagName=character_kill key=wa_awp_v.weapon method_hint=hit
	TagName=killer block=11 17 dead=0 faction_id=1 id=408 leader=0 
		name=Michael Stein player_id=-1 position=383.287 6.73623 592.631 rp=1000 
		soldier_group_name=sniper squad_size=0 wounded=0 xp=1     
	TagName=target block=11 17 dead=0 faction_id=0 id=148 leader=0 
		name=Peter Phillips player_id=-1 position=385.281 6.78942 587.467 rp=1000 
		soldier_group_name=rocketeer squad_size=0 wounded=0 xp=1 
	*/
	protected void handleCharacterKillEvent(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		const XmlElement@ target = event.getFirstElementByTagName("target");

		if (killer !is null and target !is null) {
			uint kfaction = killer.getIntAttribute("faction_id");
			uint tfaction = target.getIntAttribute("faction_id");

			if (kfaction == tfaction) return;

			int playerId = killer.getIntAttribute("player_id");
			string position = killer.getStringAttribute("position");
			const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
			if (player !is null) {
				// get player info
				int characterId = player.getIntAttribute("character_id");
				const XmlElement@ characterInfo = getCharacterInfo2(m_metagame, characterId);
				array<const XmlElement@>@ characterItem = characterInfo.getElementsByTagName("item");
				if (characterItem.size() > 0) {
					string weapon = characterItem[0].getStringAttribute("key");
					string method = event.getStringAttribute("method_hint");
					string kill_weapon = event.getStringAttribute("key");

					uint weaponid = uint(weaponId[weapon]);

					// kill through the weapon or stab
					if (method != "stab" && uint(weaponId[kill_weapon]) != weaponid) return;

					// using different weapon
					if (currentWeaponId != weaponid) {
						currentExp = 0;
						currentWeaponId = weaponid;
					}

					// get exp
					string targetGroup = target.getStringAttribute("soldier_group_name");
					uint experience = uint(enemyExp[targetGroup]);
					
					_log("CHECKTHIS");
					
					currentExp += experience;
					if (currentExp >= requiredExp[weaponid]) {
						// give elite weapon to player
						Resource@ rewardWeapon = Resource(eliteWeapons[weaponid], "weapon");

						dictionary a;
						a["%weapon_name"] = getResourceName(m_metagame, rewardWeapon.m_key, rewardWeapon.m_type);

						sendFactionMessageKeySaidAsCharacter(m_metagame, 0, characterId, "unit promoted");
						sendPrivateMessageKey(m_metagame, playerId, "unit promoted reward", a);

						XmlElement c("command");
						c.setStringAttribute("class", "update_inventory");
						c.setIntAttribute("character_id", characterId); 
						c.setStringAttribute("container_type_class", "stash");
								XmlElement i("item"); 
								i.setStringAttribute("class", rewardWeapon.m_type); 
								i.setStringAttribute("key", rewardWeapon.m_key); 
								c.appendChild(i); 
						m_metagame.getComms().send(c);

						XmlElement command("command");
						command.setStringAttribute("class", "play_sound");
						command.setStringAttribute("filename", "gupgrad1.wav");
						command.setStringAttribute("position", position);
						m_metagame.getComms().send(command);

						// reset exp
						currentExp = 0;
					}
				}
			}
		}		
	}

	protected void handlePlayerDieEvent(const XmlElement@ event) {
		currentExp = 0;
	}
}
