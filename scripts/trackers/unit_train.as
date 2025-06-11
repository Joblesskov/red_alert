#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

const float TRAIN_TIME_INTERVAL = 1.0f;
const float INFANTRY_TIME_FACTOR = 0.5f;
const float VEHICLE_TIME_FACTOR = 1.3f;

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
	protected float m_interval = TRAIN_TIME_INTERVAL;

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
		unit("gi", 10, 1.0f),
		unit("ggi", 15, 0.3f),
		unit("dog", 15, 0.1f),
		unit("engineer", 20, 0.05f),
		unit("seal", 30, 0.18f),
		unit("sniper", 35, 0.15f),
		unit("rocketeer", 45, 0.12f),
		unit("chrono", 50, 0.05f),
		unit("spy", 50, 0.05f),
		unit("tanya", 60, 0.03f)
	};

	protected array<unit@> infantryS = {
		unit("conscript", 10, 1.0f),
		unit("flak", 15, 0.3f),
		unit("dog", 15, 0.1f),
		unit("engineer", 20, 0.05f),
		unit("ivan", 20, 0.15f),
		unit("tesla", 40, 0.25f),
		unit("desolator", 45, 0.15f),
		unit("boris", 60, 0.03f)
	};

	protected array<unit@> infantryY = {
		unit("initiate", 10, 1.0f),
		unit("brute", 15, 0.3f),
		unit("engineer", 20, 0.05f),
		unit("virus", 40, 0.15f),
		unit("psicorp", 50, 0.10f),
		unit("yuri", 60, 0.02f)
	};

	protected array<unit@> vehicleA = {
		unit("grizzly_tank.vehicle", 84, 1.0f),
		unit("ifv.vehicle", 48, 1.0f),
		unit("mirage_tank.vehicle", 80, 0.33f),
		unit("tank_destroyer.vehicle", 72, 0.33f),
		unit("prism_tank.vehicle", 96, 0.33f)
	};

	protected array<unit@> vehicleS = {
		unit("rhino_tank.vehicle", 90, 1.0f),
		unit("flak_track.vehicle", 40, 1.0f),
		unit("v3.vehicle", 48, 0.4f),
		unit("tesla_tank.vehicle", 96, 0.4f),
		unit("apocalypse_tank.vehicle", 140, 0.2f)
	};

	protected array<unit@> vehicleY = {
		unit("lasher_tank.vehicle", 84, 1.0f),
		unit("gattling_tank.vehicle", 48, 1.0f),
		unit("mastermind.vehicle", 140, 0.5f),
		unit("magnetron.vehicle", 80, 0.5f)
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
			_log("CHECKTHIS: FATAL ERROR");
		}

		unit selectedUnit = selectScoredUnit(units);
		TrainingUnits[vehicleIndex] = selectedUnit.name;
		TrainingTimer[vehicleIndex] = selectedUnit.time;
		if (getTrainType(vehicleName) == "character") {
			TrainingTimer[vehicleIndex] = uint(float(TrainingTimer[vehicleIndex]) * INFANTRY_TIME_FACTOR);
		} else {
			TrainingTimer[vehicleIndex] = uint(float(TrainingTimer[vehicleIndex]) * VEHICLE_TIME_FACTOR);
		}
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
		
		float offset = (spawnClass == "vehicle") ? 12.0f : 5.0f;
		forwardVec = forwardVec.scale(offset);
		positionVec = positionVec.add(forwardVec);
		positionVec = positionVec.add(Vector3(0.0f, 1.0f, 0.0f));
		position = positionVec.toString();

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
			m_interval = TRAIN_TIME_INTERVAL;
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