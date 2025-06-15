#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

class SellBuiding : Tracker{
    protected Metagame@ m_metagame;

    SellBuiding(Metagame@ metagame) {
        @m_metagame = @metagame;
    }

    protected void handleResultEvent(const XmlElement@ event) {
        // check trigger
        if (event.getStringAttribute("key") != "sell_building") return;

        // get character
        int characterId = event.getIntAttribute("character_id");
        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
        if (character is null) return;

        // get player
        int playerId = character.getIntAttribute("player_id");
        const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
        if (player is null) return; 
        
        float range = 3.0;
        float proceeds = 0.0;
        Vector3 sellPos = stringToVector3(event.getStringAttribute("position"));
        array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, 0);
		dictionary sellableBuildings = {
            {"pillbox.vehicle", 10},
            {"prism_tower.vehicle", 30},
            {"grand_cannon.vehicle", 40},
            {"sentry_gun.vehicle", 10},
            {"battle_bunker.vehicle", 10},
            {"tesla_coil.vehicle", 30},
            {"gattling_cannon.vehicle", 20},
            {"psychic_tower.vehicle", 30},
            {"barracks_a.vehicle", 100},
            {"barracks_s.vehicle", 100},
            {"barracks_y.vehicle", 100},
            {"warfactory_a.vehicle", 400},
            {"warfactory_s.vehicle", 400},
            {"warfactory_y.vehicle", 400}
		};

        // get all vehicles
        for (uint i = 0; i < vehicles.length(); ++i) {

            Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));
            if (!checkRange(sellPos, vehiclePos, range)) continue;

            // get vehicle info
            int vehicleId = vehicles[i].getIntAttribute("id");
            const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
            if (vehicleInfo is null) continue;

            // check health
            float vehicleHealth = vehicleInfo.getFloatAttribute("health");
            if (vehicleHealth <= 0.0) continue;

            // check type and set proceeds
            string targetKey = vehicleInfo.getStringAttribute("key");
            if (sellableBuildings.exists(targetKey)) {
                proceeds = float(sellableBuildings[targetKey]);
            } else continue;

            string command1 = "<command class='remove_vehicle' id='" + vehicleId + "' />";
            string command2 = "<command class='rp_reward' character_id='" + characterId + "' reward='" + proceeds + "' />";
            string command3 = "<command class='play_sound' filename='uselbuil.wav' position='" + event.getStringAttribute("position") + "' />";
            
            m_metagame.getComms().send(command1);
            m_metagame.getComms().send(command2);
            m_metagame.getComms().send(command3);
        }
    }
}
