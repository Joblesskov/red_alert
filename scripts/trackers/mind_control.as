#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "time_announcer_task.as"

class MindControl : Tracker {
	protected Metagame@ m_metagame;

	MindControl(Metagame@ metagame) {
		@m_metagame = @metagame;
	}
	
	protected void handleResultEvent(const XmlElement@ event) {

		string sourceKey = event.getStringAttribute("key");
		if (sourceKey != "mind_control") return;
		
		float range;
		uint count;

		// immune to mind control
		array<string> immuneKeys = {
			"wy_mind_control.weapon",
			"wy_mind_control_e.weapon",
			"wy_fist.weapon",
			"wy_fist_e.weapon"
			"ws_akm.weapon",
			"ws_akm_1.weapon",
			"wa_colt_m1911.weapon",
			"wa_colt_m1911_1.weapon",
			"wy_yuri.weapon",
			"dog.weapon"
		};

		// range
		dictionary dictR = {
			{"wy_mind_control.weapon", 2},
			{"wy_mind_control_e.weapon", 2.5},
			{"wy_yuri.weapon", 3}
		};

		// count
		dictionary dictC = {
			{"wy_mind_control.weapon", 1},
			{"wy_mind_control_e.weapon", 1},
			{"wy_yuri.weapon", 2}
		};

		// get controller
        int controllerId = event.getIntAttribute("character_id");
		Vector3 controlPos = stringToVector3(event.getStringAttribute("position"));
		const XmlElement@ controller = getCharacterInfo2(m_metagame, controllerId);
		int factionId = controller.getIntAttribute("faction_id");
		
		// get control type
		array<const XmlElement@>@ controller_equipment = controller.getElementsByTagName("item");
		if (controller_equipment.size() > 0) {
			string weaponC = controller_equipment[0].getStringAttribute("key");
			if (!dictR.exists(weaponC)) return;
			range = float(dictR[weaponC]);
			count = uint(dictC[weaponC]);
		}

		for (uint f = 0; f < 4; f++) {
			// skip own faction
			if (factionId == f) continue;

			// get all characters in range
			array<const XmlElement@>@ characters = getCharactersNearPosition(m_metagame, controlPos, f, range);

			// continue if no characters in range
			uint total_soldier_count = characters.length();

			// control only one character
			for (uint c = 0; c < count && c < total_soldier_count; c++) {
				int targetId = characters[c].getIntAttribute("id");
				const XmlElement@ target = getCharacterInfo2(m_metagame, targetId);

				// check if target is immune to mind control
				array<const XmlElement@>@ target_equipment = target.getElementsByTagName("item");
				if (target_equipment.size() > 0) {
					string weaponT = target_equipment[0].getStringAttribute("key");
					if (immuneKeys.find(weaponT) != -1) continue;
				}

				string targetPos = target.getStringAttribute("position");
				string targetGroup = target.getStringAttribute("soldier_group_name");
				int isWounded = target.getIntAttribute("wounded");
				int xp = target.getIntAttribute("xp");
				float xpReward = float(xp)*0.0005 + 0.0010;

				// kill target
				// string command1 =
				// 	"<command class='update_character' " +
				// 	"	id='" + targetId + "' " +
				// 	"	dead='1' " +
				// 	"/>"; 

				// create new character
				string command2 = 
					"<command class='create_instance' " +
					"	faction_id='" + factionId + "' " +
					"	position='" + targetPos + "' " +
					"	instance_class='character' " +
					"	instance_key='" + targetGroup + "' " +
					"/>";

				// reward xp
				string command3 =
					"<command class='xp_reward' " +
					"	character_id='" + controllerId + "' " +
					"	reward='" + xpReward + "' " +
					"/>";

				// m_metagame.getComms().send(command1);
				killCharacter(m_metagame, targetId, true);
				if (isWounded != 1) m_metagame.getComms().send(command2);
				m_metagame.getComms().send(command3);
			}
		}
	}
};
