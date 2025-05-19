#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

class AutoHeal : Tracker {
    protected Metagame@ m_metagame;
    protected float m_interval = 5.0f;
    protected bool m_started = true;
    protected bool m_ended = false;

    AutoHeal(Metagame@ metagame) {
        @m_metagame = @metagame;
    }

    protected void trigger() {
        array<const XmlElement@>@ players = getPlayers(m_metagame);
        if (players.size() > 0) {
            for (uint i = 0; i < players.size(); i++) {
                // get player info
                const XmlElement@ player = players[i];
                int characterId = player.getIntAttribute("character_id");
                const XmlElement@ characterInfo = getCharacterInfo2(m_metagame, characterId);
                
                if (characterInfo.getIntAttribute("wounded") == 1 || characterInfo.getIntAttribute("dead") == 1) return;

                array<const XmlElement@>@ characterItem = characterInfo.getElementsByTagName("item");

                if (characterItem.size() > 0) {
                    // check vest type
                    string vest = characterItem[4].getStringAttribute("key");
                    uint untransform_count = 1;

                    if (startsWith(vest, "vest_flak3")) {
                        m_interval += 1.0f;
                    } else if (startsWith(vest, "vest_plate3")) {
                        m_interval -= 1.0f;
                    } else if (startsWith(vest, "vest_b")) {
                        m_interval -= 2.0f;
                    } else {
                        return;
                    }

                    XmlElement c("command");
                    c.setStringAttribute("class", "update_inventory");
                    c.setIntAttribute("character_id", characterId); 
                    c.setIntAttribute("untransform_count", untransform_count);
                    m_metagame.getComms().send(c);
                }
            }
        }
    }

    void update(float time) {
        m_interval -= time;
        if (m_interval < 0.0f) {
            m_interval = 5.0f;
            trigger();
        }
    }

	bool hasEnded() const {
		return m_ended;
	}

	bool hasStarted() const {
		return m_started;
	}
}
