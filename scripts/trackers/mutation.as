#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "time_announcer_task.as"

class Mutation : Tracker {
	protected Metagame@ m_metagame;

    Mutation(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	protected void handleCharacterKillEvent(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		const XmlElement@ target = event.getFirstElementByTagName("target");
		string killKey = event.getStringAttribute("key");

		if (killer !is null && target !is null && killKey == "genobomb_sub.projectile") {
			string targetPos = target.getStringAttribute("position");
			int factionId = killer.getIntAttribute("faction_id");

            string c = 
                "<command class='create_instance' " +
                "	faction_id='" + factionId + "' " +
                "	position='" + targetPos + "' " +
                "	instance_class='character' " +
                "	instance_key='brute' " +
                "/>";
			
			XmlElement command("command");
			command.setStringAttribute("class", "play_sound");
			command.setStringAttribute("filename", "sgenon.wav");
			command.setStringAttribute("position", targetPos);
			m_metagame.getComms().send(command);
				
			m_metagame.getComms().send(c);
		}
	}
}