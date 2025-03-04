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
	protected float m_delay = 1.2f;

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
			
			XmlElement command("command");
			command.setStringAttribute("class", "play_sound");
			command.setStringAttribute("filename", "sgenon.wav");
			command.setStringAttribute("position", targetPos);

			m_metagame.getComms().send(command);
			// do a delay to avoid friendly fire from geno bombs
			m_metagame.getTaskSequencer().add(CreateInstanceTask(@m_metagame, m_delay, factionId, targetPos, "character", "brute"));
			// reset the delay to spawn all brutes at the same time
			m_delay = 0.0f;
		}
	}

	void update(float time) {
		// increase the delay until the next genetic strike
		if (m_delay < 1.2f) m_delay += time * 0.3f;
	}
}

class CreateInstanceTask : Task {
	protected Metagame@ m_metagame;
	protected float m_time;
	protected int m_factionId;
	protected string m_position;
	protected string m_instanceClass;
	protected string m_instanceKey;

	CreateInstanceTask(Metagame@ metagame, float time, int factionId, string position, string instanceClass, string instanceKey) {
		@m_metagame = metagame;
		m_time = time;
		m_factionId = factionId;
		m_position = position;
		m_instanceClass = instanceClass;
		m_instanceKey = instanceKey;
	}

	// --------------------------------------------
	void start() {
		XmlElement command("command");
		command.setStringAttribute("class", "create_instance");
		command.setIntAttribute("faction_id", m_factionId);
		command.setStringAttribute("position", m_position);
		command.setStringAttribute("instance_class", m_instanceClass);
		command.setStringAttribute("instance_key", m_instanceKey);
		m_metagame.getComms().send(command);
	}

	// --------------------------------------------
	void update(float time) {
		m_time -= time;
	}

	// --------------------------------------------
	bool hasEnded() const {
		return m_time < 0.0f;
	}
}