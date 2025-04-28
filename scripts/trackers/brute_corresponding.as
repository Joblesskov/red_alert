#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

class BruteCorresponding : Tracker {
    protected Metagame@ m_metagame;
    protected float m_interval = 2.0f;
    protected bool m_started = true;
    protected bool m_ended = false;

    BruteCorresponding(Metagame@ metagame) {
        @m_metagame = @metagame;
    }

    protected void trigger() {
        array<const XmlElement@>@ players = getPlayers(m_metagame);
        if (players.size() > 0) {
            for (int i = 0; i < players.size(); i++) {
                const XmlElement@ player = players[i];
                int characterId = player.getIntAttribute("character_id");
                const XmlElement@ characterInfo = getCharacterInfo2(m_metagame, characterId);
                array<const XmlElement@>@ characterItem = characterInfo.getElementsByTagName("item");

                if (characterItem.size() > 0) {
                    string weapon = characterItem[0].getStringAttribute("key");
                    string vest = characterItem[4].getStringAttribute("key");
                    bool is_weapon_brute = (weapon == "wy_fist.weapon" || weapon == "wy_fist_v.weapon" || weapon == "wy_fist_e.weapon");
                    bool is_vest_brute = startsWith(vest, "vest_b");
                    if (is_weapon_brute && !is_vest_brute){
                        XmlElement c("command");
                        c.setStringAttribute("class", "update_inventory");
                        c.setIntAttribute("character_id", characterId); 
                        c.setIntAttribute("container_type_id", 4);
                        {
                            XmlElement j("item");
                            j.setStringAttribute("class", "carry_item");
                            j.setStringAttribute("key", "vest_brute.carry_item");
                            c.appendChild(j);
                        }
                        m_metagame.getComms().send(c);
                    } else if (!is_weapon_brute && is_vest_brute){
                        XmlElement c("command");
                        c.setStringAttribute("class", "update_inventory");
                        c.setIntAttribute("character_id", characterId); 
                        c.setIntAttribute("container_type_id", 4);
                        {
                            XmlElement j("item");
                            j.setStringAttribute("class", "carry_item");
                            j.setStringAttribute("key", "unarmored.carry_item");
                            c.appendChild(j);
                        }
                        m_metagame.getComms().send(c);
                    }
                }
            }
        }
    }

    void update(float time) {
        m_interval -= time;
        if (m_interval < 0.0f) {
            trigger();
            m_interval = 2.0f;
        }
    }

	bool hasEnded() const {
		return m_ended;
	}

	bool hasStarted() const {
		return m_started;
	}
}
