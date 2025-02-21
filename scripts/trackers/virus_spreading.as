#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "time_announcer_task.as"

class VirusSpreading : Tracker {
	protected Metagame@ m_metagame;

    VirusSpreading(Metagame@ metagame) {
		@m_metagame = @metagame;
	}


	array<string> virusKeys = {
		"wy_virus.weapon",
		"wy_virus_e.weapon",
		"vw_magnetron_mg.weapon",
		"virus_cloud_sub.projectile",
		"toxic_bomb_sub.projectile"
	};

	protected void handleCharacterKillEvent(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		const XmlElement@ target = event.getFirstElementByTagName("target");
        string killKey = event.getStringAttribute("key");
		string targetGroup = target.getStringAttribute("soldier_group_name");

		bool checkKey = (virusKeys.find(killKey) != -1);
		bool checkGroup = targetGroup != "virus";
		if (killer !is null && target !is null && checkKey && checkGroup) {
			
			string command1 = 
				"<command "+
				"class='create_instance' "+
				"faction_id='" + killer.getIntAttribute("faction_id") + "' "+
				"position='" + target.getStringAttribute("position") + "' "+
				"instance_class='grenade' "+
				"instance_key='virus_cloud.projectile' "+
                "character_id='" + killer.getIntAttribute("id") + "' "+
				"/>";
            
            string command2 =
            	"<command "+
				"class='create_instance' "+
				"faction_id='" + killer.getIntAttribute("faction_id") + "' "+
				"position='" + target.getStringAttribute("position") + "' "+
				"instance_class='grenade' "+
				"instance_key='virus_cloud_sub.projectile' "+
                "character_id='" + killer.getIntAttribute("id") + "' "+
				"/>";
				
			m_metagame.getComms().send(command1);
			m_metagame.getComms().send(command2);
		}
	}
}