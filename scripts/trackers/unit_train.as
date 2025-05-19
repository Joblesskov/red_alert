#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

class unit {
	string name;
	uint time;
	float score;

	unit() {
		name = "";
		time = 0;
		score = 0.0f;
	}
	
	unit(string n, uint t, float s) {
		name = n;
		time = t;
		score = s;
	}
}

class UnitTrain : Tracker {
    protected Metagame@ m_metagame;
    protected bool m_started = true;
    protected bool m_ended = false;
	protected float m_interval = 2.0f;

	protected array<uint> allVehicleKeys = {};
	protected array<string> TrainingUnits = {};
	protected array<uint> TrainingTimer = {};

    protected array<string> validVehicleKeys = {
		"barracks_a.vehicle",
		"barracks_s.vehicle",
		"barracks_y.vehicle",
		"warfactory_a.vehicle",
		"warfactory_s.vehicle",
		"warfactory_y.vehicle"
	};

	protected array<unit@> infantryA = {
		unit("gi", 3, 1.0f),
		unit("ggi", 3, 0.3f),
		unit("dog", 3, 0.1f),
		unit("engineer", 4, 0.05f),
		unit("seal", 5, 0.18f),
		unit("sniper", 5, 0.15f),
		unit("rocketeer", 6, 0.12f),
		unit("chrono", 6, 0.05f),
		unit("spy", 6, 0.05f),
		unit("tanya", 8, 0.03f)
	};

	protected array<unit@> infantryS = {
		unit("conscript", 3, 1.0f),
		unit("flak", 3, 0.3f),
		unit("dog", 3, 0.1f),
		unit("engineer", 4, 0.05f),
		unit("ivan", 4, 0.15f),
		unit("tesla", 5, 0.25f),
		unit("desolator", 6, 0.15f),
		unit("boris", 8, 0.03f)
	};

	protected array<unit@> infantryY = {
		unit("initiate", 3, 1.0f),
		unit("brute", 3, 0.3f),
		unit("engineer", 4, 0.05f),
		unit("virus", 6, 0.15f),
		unit("psicorp", 6, 0.10f),
		unit("yuri", 8, 0.02f)
	};

	protected array<unit@> vehicleA = {
		unit("grizzly_tank.vehicle", 42, 1.0f),
		unit("ifv.vehicle", 24, 1.0f),
		unit("mirage_tank.vehicle", 40, 0.33f),
		unit("tank_destroyer.vehicle", 36, 0.33f),
		unit("prism_tank.vehicle", 48, 0.33f)
	};

	protected array<unit@> vehicleS = {
		unit("rhino_tank.vehicle", 45, 1.0f),
		unit("flak_track.vehicle", 20, 1.0f),
		unit("v3.vehicle", 24, 0.4f),
		unit("tesla_tank.vehicle", 48, 0.4f),
		unit("apocalypse_tank.vehicle", 70, 0.2f)
	};

	protected array<unit@> vehicleY = {
		unit("lasher_tank.vehicle", 42, 1.0f),
		unit("gattling_tank.vehicle", 24, 1.0f),
		unit("mastermind.vehicle", 70, 0.5f),
		unit("magnetron.vehicle", 40, 0.5f)
	};

    UnitTrain(Metagame@ metagame) {
        @m_metagame = @metagame;
    }

	string getTrainType(string vehicleKey) {
		if (startsWith(vehicleKey, "barracks")) {
			return "character";
		} else {
			return "vehicle";
		}
	}

	unit selectScoredUnit(array<unit@> units) {
		float totalScore = 0.0f;
		for (int i = 0; i < units.length(); i++) {
			totalScore += units[i].score;
		}
		float selectedScore = rand(0.0f, totalScore);

		for (int i = 0; i < units.length(); i++) {
			if (selectedScore <= units[i].score) {
				return units[i];
			} else {
				selectedScore -= units[i].score;
			}
		}
		return unit("", 0, 0.0f);
	}

	void decideTrainUnit(uint vehicleIndex) {
		uint vehicleId = allVehicleKeys[vehicleIndex];
		const XmlElement@ vehicle = getVehicleInfo(m_metagame, vehicleId);
		string vehicleName = vehicle.getStringAttribute("key");

		array<unit@> units = {};

		if (vehicleName == "barracks_a.vehicle") {
			units = infantryA;
		} else if (vehicleName == "barracks_s.vehicle") {
			units = infantryS;
		} else if (vehicleName == "barracks_y.vehicle") {
			units = infantryY;
		} else if (vehicleName == "warfactory_a.vehicle") {
			units = vehicleA;
		} else if (vehicleName == "warfactory_s.vehicle") {
			units = vehicleS;
		} else if (vehicleName == "warfactory_y.vehicle") {
			units = vehicleY;
		} else {
			_log("AAAAA: FATAL ERROR");
		}

		unit selectedUnit = selectScoredUnit(units);
		TrainingUnits[vehicleIndex] = selectedUnit.name;
		TrainingTimer[vehicleIndex] = selectedUnit.time;
		return;
	}

	void spawnTrainUnit(uint vehicleIndex) {
		uint vehicleId = allVehicleKeys[vehicleIndex];
		const XmlElement@ vehicle = getVehicleInfo(m_metagame, vehicleId);

		string position = vehicle.getStringAttribute("position");
		string forward = vehicle.getStringAttribute("forward");
		string spawnClass = getTrainType(vehicle.getStringAttribute("key"));
		Vector3 positionVec = stringToVector3(position);	
		Vector3 forwardVec = stringToVector3(forward);
		
		_log("AAAAAA: OLD POSITION " + position);
		float offset = (spawnClass == "vehicle") ? 8.0f : 4.0f;
		forwardVec = forwardVec.scale(offset);
		positionVec = positionVec.add(forwardVec);
		positionVec = positionVec.add(Vector3(0.0f, 1.0f, 0.0f));
		position = positionVec.toString();
		_log("AAAAAA: NEW POSITION " + position);

		XmlElement command("command");
		command.setStringAttribute("class", "create_instance");
		command.setIntAttribute("faction_id", vehicle.getIntAttribute("owner_id"));
		command.setStringAttribute("position", position);
		command.setStringAttribute("instance_class", spawnClass);
		command.setStringAttribute("instance_key", TrainingUnits[vehicleIndex]);
		m_metagame.getComms().send(command);

		return;
	}

	void updateTrain() {
		for (int i = 0; i < allVehicleKeys.length(); i++) {
			TrainingTimer[i] --;
			if (TrainingTimer[i] == 0) {
				spawnTrainUnit(i);
				decideTrainUnit(i);
			}
		}
		return;
	}

	protected void handleVehicleSpawnEvent(const XmlElement@ event) {
		uint vehicleId = event.getIntAttribute("vehicle_id");
		string vehicleKey = event.getStringAttribute("vehicle_key");
		
		// check if vehicle is valid
		if (validVehicleKeys.find(vehicleKey) != -1) {
			allVehicleKeys.insertLast(vehicleId);
			TrainingUnits.insertLast("default");
			TrainingTimer.insertLast(999);
			decideTrainUnit(allVehicleKeys.length() - 1);
			TrainingTimer[allVehicleKeys.length() - 1] = 1;
		} else {
			return;
		}

		return;
	}

	protected void handleVehicleHolderChangeEvent(const XmlElement@ event) {
		return;
	}

	protected void handleVehicleDestroyEvent(const XmlElement@ event) {
		uint vehicleId = event.getIntAttribute("vehicle_id");
		int vehicleIndex = allVehicleKeys.find(vehicleId);

		// remove vehicle from list
		if (vehicleIndex != -1) {
			allVehicleKeys.removeAt(vehicleIndex);
			TrainingUnits.removeAt(vehicleIndex);
			TrainingTimer.removeAt(vehicleIndex);
		}
		return;
	}

	protected void handleVehicleSpotEvent(const XmlElement@ event) {
		return;
	}

	void update(float time) {
		m_interval -= time;
		if (m_interval < 0.0f) {
			updateTrain();
			m_interval = 2.0f;
		}
		return;
	}

	bool hasEnded() const {
		return m_ended;
	}

	bool hasStarted() const {
		return m_started;
	}
}