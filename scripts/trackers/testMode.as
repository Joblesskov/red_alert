// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"

#include "debug_reporter.as"

//Author： rst
//便利测试脚本

class testMode : Tracker{
    protected Metagame@ m_metagame;
    protected bool m_ended;

    //--------------------------------------------
    testMode(Metagame@ metagame){
        @m_metagame = @metagame;
        m_ended = false;
    }
    // --------------------------------------------
    void update(float time) {
    }
    // --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    

    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
	}
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
        message = message.toLowerCase();
        int pid = event.getIntAttribute("player_id");
        const XmlElement@ player = getPlayerInfo(m_metagame,pid);
        if(player is null){return;}
        int cid = player.getIntAttribute("character_id");
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){return;}
        
        array<string> word = MassageBreakUp(message, " ", -1);
		int ws = word.size();
		if (ws == 0) return;

        if(message == "/dead") {
			string command =
                "<command class='update_character'" +
                "	id='" + cid + "'" +	
                "   dead='1'>" + 
                "</command>";
            m_metagame.getComms().send(command);
		}
        if(message == "0_win"){
            m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
        }
        if(message == "1_win"){
            m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='0' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='1' />");
        }
        if(message == "1_lose"){
            m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
        }
        if (matchString(word[0], "grp")) {
			if(ws == 2){
				string num = word[1];
				string command =
					"<command class='rp_reward'" +
					"	character_id='" + cid + "'" +
					"	reward='"+ num +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
			}
		} else if (matchString(word[0], "gxp")){
			if(ws == 2){
				string num = word[1];
				string command =
					"<command class='xp_reward'" +
					"	character_id='" + cid + "'" +
					"	reward='"+ num +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
				}
		}else if(matchString(word[0], "promote")){
				float xpnum = 1000;
				float rpnum = 1000000;
				string command =
					"<command class='xp_reward'" +
					"	character_id='" + cid + "'" +
					"	reward='"+ xpnum +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
				command =
					"<command class='rp_reward'" +
					"	character_id='" + cid + "'" +
					"	reward='"+ rpnum +"'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
		}
        // 生成各类物品
		if (matchString(word[0], "v")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceNearPlayer(pid, key + ".vehicle", "vehicle");
			} 
		} else if (matchString(word[0], "w")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceAtbackpack(pid, key + ".weapon", "weapon");
			} else if (ws == 3){
			spawnInstanceAtbackpack(pid, key + ".weapon", "weapon", word[2]);
			}
		}else if (matchString(word[0], "p")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceAtbackpack(pid, key + ".projectile", "projectile");
			} else if (ws == 3){
			spawnInstanceAtbackpack(pid, key + ".projectile", "projectile", word[2]);
			}
		}else if (matchString(word[0], "c")) {
			if (ws == 1){return;}
			string key = word[1];
			if (ws == 2){
			spawnInstanceAtbackpack(pid, key , "carry_item");
			} else if (ws == 3){
			spawnInstanceAtbackpack(pid, key , "carry_item", word[2]);
			}
		}
        if(message == "/god"){
            spawnInstanceNearPlayer(pid, "god_vest.carry_item", "carry_item"); 
        }
        if(message == "/squad"){
            int spawnTime = 10;
            while(spawnTime > 0){
                spawnInstanceNearPlayer(pid, "default_ai", "soldier", 0);
                spawnTime--;
            }
        }
        if(message == "/esquad"){
            int spawnTime = 10;
            while(spawnTime > 0){
                spawnInstanceNearPlayer(pid, "default_ai", "soldier", 1);
                spawnTime--;
            }
        }
        if(message == "/wound"){
            string command =
                "<command class='update_character'" +
                "	id='" + cid + "'" +	
                "   wounded='1'>" + 
                "</command>";
            m_metagame.getComms().send(command);
        }
    }
    array<string> MassageBreakUp(string message, string command, int preNumber) {
        string s = message.trim().substr(command.length() + preNumber + 1);
        array<string> a = s.split(" ");
        return a;
    }
    // ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0, bool skydive = false) {
		_log("spawnInstanceNearPlayer");
		_log("pid ="+senderId+" name="+g_playerInfoBuck.getNameByPid(senderId));
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		if (playerInfo !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
				pos.m_values[0] += 5.0;
				if (skydive) {
					pos.m_values[1] += 50.0;
				}
				string c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
				m_metagame.getComms().send(c);
			}
		}
	}
    // ------------------------------------------------------
	protected void spawnInstanceAtbackpack(int senderId, string key, string type, string num = "1"){
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		int cid = playerInfo.getIntAttribute("character_id");
		if(type == "vehicle"){
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "can't spawn vehicle"}};
			m_metagame.getComms().send(XmlElement(dict));
			return;
		}
		float number = parseFloat(num);
		for(float a = 1; a <= number ; a++){
			string command = 
				"<command class='update_inventory' character_id='" + cid + "' container_type_class='backpack'>" + 
					"<item class='" + type + "' key='" + key + "' />" +
				"</command>";
			m_metagame.getComms().send(command);	
		}
	}
}