// gamemode specific
#include "faction_config.as"
#include "stage_configurator.as"
#include "stage_invasion.as"
#include "phase_controller_map12.as"
#include "pausing_koth_timer.as"
#include "spawn_at_node.as"
#include "comms_capacity_handler.as"
#include "attack_defense_handler_map16.as"
#include "attack_defense_handler_map1_2.as"
#include "run_at_start.as"

// ------------------------------------------------------------------------------------------------
class StageConfiguratorInvasion : StageConfigurator {
	protected GameModeInvasion@ m_metagame;
	protected MapRotatorInvasion@ m_mapRotator;
	protected int m_stagesAdded;

	// ------------------------------------------------------------------------------------------------
	StageConfiguratorInvasion(GameModeInvasion@ metagame, MapRotatorInvasion@ mapRotator) {
		@m_metagame = @metagame;
		@m_mapRotator = mapRotator;
		mapRotator.setConfigurator(this);
		m_stagesAdded = 0;
	}

	// ------------------------------------------------------------------------------------------------
	void setup() {
		setupFactionConfigs();

		setupWorld();

		setupNormalStages();
	}

	// ------------------------------------------------------------------------------------------------
	const array<FactionConfig@>@ getAvailableFactionConfigs() const {
		array<FactionConfig@> availableFactionConfigs;

		availableFactionConfigs.push_back(FactionConfig(-1, "green.xml", "Greenbelts", "0.1 0.5 0", "green_boss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "grey.xml", "Graycollars", "0.5 0.5 0.5", "grey_boss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "brown.xml", "Brownpants", "0.5 0.25 0", "brown_boss.xml"));

		return availableFactionConfigs;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupFactionConfigs() {
		array<FactionConfig@> availableFactionConfigs = getAvailableFactionConfigs(); // copy for mutability

		const UserSettings@ settings = m_metagame.getUserSettings();
		// - the faction the player picks in lobby campaign menu needs to be inserted first in the faction configs list
		{
			_log("faction choice: " + settings.m_factionChoice, 1);
			FactionConfig@ userChosenFaction = availableFactionConfigs[settings.m_factionChoice];
			_log("player faction: " + userChosenFaction.m_file, 1);

			int index = int(getFactionConfigs().size()); // is 0
			userChosenFaction.m_index = index;
			m_mapRotator.addFactionConfig(userChosenFaction);

			availableFactionConfigs.erase(settings.m_factionChoice);
		}

		// - next add the rest of them, in random order
		while (availableFactionConfigs.size() > 0) {
			int index = int(getFactionConfigs().size());

			int availableIndex = rand(0, availableFactionConfigs.size() - 1);
			FactionConfig@ faction = availableFactionConfigs[availableIndex];

			_log("setting " + faction.m_name + " as index " + index, 1);

			faction.m_index = index;
			m_mapRotator.addFactionConfig(faction);

			availableFactionConfigs.erase(availableIndex);
		}

		// - finally add neutral
		{
			int index = getFactionConfigs().size();
			m_mapRotator.addFactionConfig(FactionConfig(index, "neutral.xml", "Neutral", "0 0 0"));
		}

		_log("total faction configs " + getFactionConfigs().size(), 1);
	}

	// ------------------------------------------------------------------------------------------------
	protected void addRandomSpecialCrates(Stage@ stage, int minCount, int maxCount) {
		array<ScoredResource@> resources = {
			ScoredResource("special_crate1.vehicle", "vehicle", 100.0f),	// m4
			ScoredResource("special_crate2.vehicle", "vehicle", 80.0f),		// p90
			ScoredResource("special_crate3.vehicle", "vehicle", 80.0f),		// aks
			ScoredResource("special_crate4.vehicle", "vehicle", 80.0f),		// Stoner
			ScoredResource("special_crate5.vehicle", "vehicle", 80.0f),		// neo
			ScoredResource("special_crate6.vehicle", "vehicle", 70.0f),		// aa12
			ScoredResource("special_crate7.vehicle", "vehicle", 40.0f),		// chain
			ScoredResource("special_crate8.vehicle", "vehicle", 40.0f),		// m107
			ScoredResource("special_crate9.vehicle", "vehicle", 50.0f),		// apr
			ScoredResource("special_crate10.vehicle", "vehicle", 30.0f),	// ares
			ScoredResource("special_crate11.vehicle", "vehicle", 30.0f),	// kriss
			ScoredResource("special_crate12.vehicle", "vehicle", 40.0f),	// m712
			ScoredResource("special_crate13.vehicle", "vehicle", 40.0f),	// jack
			ScoredResource("special_crate14.vehicle", "vehicle", 10.0f),	// m60
			ScoredResource("special_crate15.vehicle", "vehicle", 30.0f),	// paw
			ScoredResource("special_crate16.vehicle", "vehicle", 5.0f),		// honey
			ScoredResource("special_crate17.vehicle", "vehicle", 10.0f),	// flame
			ScoredResource("special_crate18.vehicle", "vehicle", 1.0f),		// milk
			ScoredResource("special_crate19.vehicle", "vehicle", 1.0f),		// l39
			ScoredResource("special_crate20.vehicle", "vehicle", 1.0f),		// mg42
			ScoredResource("special_crate31.vehicle", "vehicle", 3.0f),		// cb2
			ScoredResource("special_crate32.vehicle", "vehicle", 5.0f),		// stoner62
			ScoredResource("special_crate33.vehicle", "vehicle", 40.0f),	// camo_vest
			ScoredResource("special_crate34.vehicle", "vehicle", 30.0f),	// deagle
			ScoredResource("special_crate35.vehicle", "vehicle", 100.0f),	// banana peel
			ScoredResource("special_crate36.vehicle", "vehicle", 15.0f),	// mp7
			ScoredResource("special_crate37.vehicle", "vehicle", 60.0f),	// goldbar
			ScoredResource("special_crate38.vehicle", "vehicle", 50.0f),	// medikit
			ScoredResource("special_crate39.vehicle", "vehicle", 100.0f),	// resmini
			ScoredResource("special_crate41.vehicle", "vehicle", 5.0f),		// cb3 
			ScoredResource("special_crate42.vehicle", "vehicle", 4.0f)		// cb4 
		};
		int count = rand(minCount, maxCount);
		stage.addTracker(SpawnAtNode(m_metagame, resources, "random_crate", 0, count));
	}
	
	// ------------------------------------------------------------------------------------------------
	protected void addFixedSpecialCrates(Stage@ stage) {
		array<ScoredResource@> resources = {
			ScoredResource("special_crate21.vehicle", "vehicle", 50.0f),		// xm25
			ScoredResource("special_crate22.vehicle", "vehicle", 50.0f),		// musket
			ScoredResource("special_crate23.vehicle", "vehicle", 40.0f),		// aafrag
			ScoredResource("special_crate24.vehicle", "vehicle", 30.0f),		// Deagle
			ScoredResource("special_crate25.vehicle", "vehicle", 100.0f),		// gb1
			ScoredResource("special_crate26.vehicle", "vehicle", 30.0f),		// gb2
			ScoredResource("special_crate27.vehicle", "vehicle", 10.0f),		// gb3
			ScoredResource("special_crate28.vehicle", "vehicle", 5.0f),			// cb1
			ScoredResource("special_crate29.vehicle", "vehicle", 100.0f),		// resmini
			ScoredResource("special_crate30.vehicle", "vehicle", 100.0f),		// resgl
			ScoredResource("special_crate35.vehicle", "vehicle", 100.0f),		// banana peel
			ScoredResource("special_crate19.vehicle", "vehicle", 5.0f),			// l39
			ScoredResource("special_crate32.vehicle", "vehicle", 5.0f)			// stoner62
		};
		stage.addTracker(SpawnAtNode(m_metagame, resources, "fixed_crate", 0, 1000));
	}
	
	// ------------------------------------------------------------------------------------------------
	protected void addLotteryVehicle(Stage@ stage) {
		array<ScoredResource@> resources = {
			// for testing: 0 score no spawn -> 100% chance for icecream
			//ScoredResource("", "", 0.0f),          
			ScoredResource("", "", 85.0f),
			ScoredResource("icecream.vehicle", "vehicle", 15.0f)
		};
		stage.addTracker(SpawnAtNode(m_metagame, resources, "icecream", 1, 1));
	}
	
	// ------------------------------------------------------------------------------------------------
	protected void addDarkcatVehicle(Stage@ stage) {
		array<ScoredResource@> resources = {
			// for testing: 0 score no spawn -> 100% chance for icecream
			//ScoredResource("", "", 0.0f),          
			ScoredResource("", "", 90.0f),
			ScoredResource("darkcat.vehicle", "vehicle", 10.0f)
		};
		stage.addTracker(SpawnAtNode(m_metagame, resources, "darkcat", 1, 1, true));
	}	
	
	// ------------------------------------------------------------------------------------------------
    protected void addArenaJammer(Stage@ stage) {
		array<ScoredResource@> resources = {
			// for testing: 0 score no spawn -> 100% chance for icecream
			//ScoredResource("", "", 0.0f),          
			ScoredResource("", "", 0.0f),
			ScoredResource("radio_jammer2.vehicle", "vehicle", 100.0f)
		};
		stage.addTracker(SpawnAtNode(m_metagame, resources, "arena_jammer", 1, 1));
	}

	// ------------------------------------------------------------------------------------------------
	protected void addStage(Stage@ stage) {
		addFixedSpecialCrates(stage);
		addRandomSpecialCrates(stage, stage.m_minRandomCrates, stage.m_maxRandomCrates);
		addLotteryVehicle(stage);
		addDarkcatVehicle(stage);
		addArenaJammer(stage);
		
		if (stage.isCapture()) {
			stage.setIntelManager(IntelManager(m_metagame));
		}

		m_mapRotator.addStage(stage);
		m_stagesAdded++;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setupNormalStages() {
	addStage(setupStage7());		// map6 #0
	addStage(setupStage1());		// map2 #1
	addStage(setupStage9());		// map9 #2
	addStage(setupStage16());		// map8_2 #3
	addStage(setupStage4());		// map7 #4
	addStage(setupStage15());		// map1_2 #5
	addStage(setupStage12());		// map14 #6
	addStage(setupStage21());		// map20 #7
	addStage(setupStage10());		// map10 #8
	addStage(setupStage17());		// map17  #9  
	addStage(setupStage18());		// map13_2 #10
	addStage(setupStage3());		// map3 #11
	addStage(setupStage13());		// map16  #12  
	addStage(setupFinalStage1());	// map11 #13
	addStage(setupStage8());		// map8 #14
	addStage(setupStage14());		// map6_2 #15
	addStage(setupStage2());		// map4 #16
	addStage(setupStage20());		// map19 #17	
	addStage(setupStage5());		// map1 #18
	addStage(setupStage6());		// map5 #19
	addStage(setupFinalStage2());	// map12 #20
	addStage(setupStage19());		// map18 #21
	addStage(setupStage11());		// map13 #22
	addStage(setupStage22());		// map21 #23
	}

	// --------------------------------------------
	protected Stage@ createStage() const {
		Stage@ stage = Stage(m_metagame.getUserSettings());
		return stage;
	}

	// --------------------------------------------
	protected PhasedStage@ createPhasedStage() const {
		return PhasedStage(m_metagame.getUserSettings());
	}

	// --------------------------------------------
	const array<FactionConfig@>@ getFactionConfigs() const {
		return m_mapRotator.getFactionConfigs();
	}

	// ------------------------------------------------------------------------------------------------
	Stage@ setupCompletedStage(Stage@ inputStage) {
		// currently not in use in invasion
		return null;
	}

	// ------------------------------------------------------------------------------------------------
	protected void setDefaultAttackBreakTimes(Stage@ stage) {
		for (uint i = 0; i < stage.m_factions.size(); ++i) {
			XmlElement command("command");
			command.setStringAttribute("class", "commander_ai");
			command.setIntAttribute("faction", i);
			command.setFloatAttribute("start_attack_break_time", 50.0f);
			command.setFloatAttribute("attack_break_time", 60.0f);
			// initially clear final attack boost
			command.setFloatAttribute("reduce_defense_for_final_attack", 0.0f); 
			stage.m_extraCommands.insertLast(command);
		}
	}

	// ------------------------------------------------------------------------------------------------
	protected void setReduceDefenseForFinalAttack(Stage@ stage, float value) {
		XmlElement command("command");
		command.setStringAttribute("class", "commander_ai");
		command.setIntAttribute("faction", 0);
		command.setFloatAttribute("reduce_defense_for_final_attack", value);
		stage.m_extraCommands.insertLast(command);
	}
	
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage1() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Keepsake Bay";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map2";
		stage.m_mapInfo.m_id = "map2";
		
		stage.m_includeLayers.insertLast("layer1.invasion"); 


		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 12 * 8;

		stage.m_soldierCapacityVariance = 0.3;
		stage.m_playerAiCompensation = 4.5;
		stage.m_playerAiReduction = 2.5;

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 4;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.55, 0.1));                                                  
			f.m_capacityOffset = 0; 
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));
			f.m_overCapacity = 40;
			f.m_capacityOffset = 8;
			stage.m_factions.insertLast(f);
		}
		
		{
			XmlElement c1("command");
			c1.setStringAttribute("class", "faction_resources");
			c1.setIntAttribute("faction_id", 1);
			addFactionResourceElements(c1, "vehicle", array<string> = {"barracks_a.vehicle", "barracks_s.vehicle", "barracks_y.vehicle"}, false);

			stage.m_extraCommands.insertLast(c1);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		// setReduceDefenseForFinalAttack(stage, 0.1); // use this for final attack boost if needed for friendlies
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage2() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Fridge Valley";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map4";
		stage.m_mapInfo.m_id = "map4";
		
		stage.m_includeLayers.insertLast("layer1.invasion");		

		stage.m_fogOffset = 20.0;    
		stage.m_fogRange = 50.0;     

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 17 * 6;
		stage.m_playerAiCompensation = 4.5;
		stage.m_playerAiReduction = 3;

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.55, 0.1));
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));
			f.m_overCapacity = 40;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f); 
		}
		
		{
			XmlElement c1("command");
			c1.setStringAttribute("class", "faction_resources");
			c1.setIntAttribute("faction_id", 1);
			addFactionResourceElements(c1, "vehicle", array<string> = {"barracks_a.vehicle", "barracks_s.vehicle", "barracks_y.vehicle"}, false);

			stage.m_extraCommands.insertLast(c1);
		}
		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage3() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Old Fort Creek";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map3";
		stage.m_mapInfo.m_id = "map3";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 14 * 8;
		stage.m_playerAiCompensation = 5;
		stage.m_playerAiReduction = 2.0;

		stage.m_soldierCapacityVariance = 0.4;

		stage.m_minRandomCrates = 2;
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0));
			f.m_capacityOffset = 0; 
			f.m_overCapacity = 0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(1));
			f.m_overCapacity = 40;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f); 
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"flamer_tank.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage4() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Power Junction";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map7";
		stage.m_mapInfo.m_id = "map7";

		stage.m_includeLayers.insertLast("layer1.invasion");        

		stage.addTracker(Overtime(m_metagame, 0));
		stage.m_maxSoldiers = 30 * 3;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2;
		stage.m_soldierCapacityModel = "constant";

		stage.m_minRandomCrates = 0; 
		stage.m_maxRandomCrates = 0;

		stage.m_defenseWinTime = 600;
		stage.m_defenseWinTimeMode = "custom";
		stage.addTracker(PausingKothTimer(m_metagame, stage.m_defenseWinTime));
	
		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.35, 0.1));
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2, 0.38, 0.1));
			f.m_overCapacity = 20;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.38, 0.1));
			f.m_overCapacity = 20;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}
		{
			// neutral
			Faction f(getFactionConfigs()[3], createCommanderAiCommand(3));
			f.m_capacityMultiplier = 0.0;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "Power Plant";

		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage5() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Moorland Trenches";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map1";
		stage.m_mapInfo.m_id = "map1";
		
		stage.m_includeLayers.insertLast("layer1.invasion"); 

		stage.m_maxSoldiers = 18 * 14;
		stage.m_playerAiCompensation = 3;
		stage.m_playerAiReduction = 1.5;

		stage.m_soldierCapacityVariance = 0.4;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 3; 
		stage.m_maxRandomCrates = 5;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0));
			f.m_overCapacity = 6;
			f.m_bases = 1;
			f.m_capacityMultiplier = 0.79;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));
			// f.m_overCapacity = 60;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2));
			// f.m_overCapacity = 60;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage6() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Bootleg Islands";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map5";
		stage.m_mapInfo.m_id = "map5";

		stage.m_maxSoldiers = 11 * 10;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2.5;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 4;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0));
			f.m_overCapacity = 0;
			f.m_bases = 1;

			f.m_capacityMultiplier = 1.0;
			f.m_capacityOffset = 0;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2));
			f.m_overCapacity = 30;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1));
			f.m_overCapacity = 30;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage7() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Rattlesnake Crescent";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map6";
		stage.m_mapInfo.m_id = "map6";

		stage.m_maxSoldiers = 15 * 9;
		stage.m_playerAiCompensation = 5;
		stage.m_playerAiReduction = 2;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.4, 0.15));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 0; 
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(1, 0.45, 0.2));
			// f.m_overCapacity = 80;
			f.m_capacityOffset = 15;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage8() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Vigil Island";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map8";
		stage.m_mapInfo.m_id = "map8";

		stage.m_includeLayers.insertLast("layer1.invasion"); 

		stage.addTracker(Overtime(m_metagame, 0));

		stage.m_maxSoldiers = 21 * 5;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2;
		stage.m_soldierCapacityModel = "constant";

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 2;

		stage.m_defenseWinTime = 720.0;
		stage.m_defenseWinTimeMode = "custom";
		stage.addTracker(PausingKothTimer(m_metagame, stage.m_defenseWinTime));

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.3, 0.1));
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.25, 0.05));
			f.m_overCapacity = 60;
			f.m_capacityMultiplier = 0.0001;
			f.m_capacityOffset = 60;
			stage.m_factions.insertLast(f);
		}
		{
			// neutral
			Faction f(getFactionConfigs()[3], createCommanderAiCommand(2));
			f.m_capacityMultiplier = 0.0;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "cover1.vehicle", "deployable_minig.vehicle", "hornet.vehicle", "apc.vehicle", "apc_1.vehicle", "apc_2.vehicle", "tank_denied_player.vehicle", "tank_1_denied_player.vehicle", "tank_2_denied_player.vehicle", "noxe.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "Airfield";
		stage.m_radioObjectivePresent = false;

		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage9() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Black Gold Estuary";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map9";
		stage.m_mapInfo.m_id = "map9";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 17 * 13;
		stage.m_soldierCapacityVariance = 0.55;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 4;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.4, 0.3));
			f.m_overCapacity = 0;
			f.m_capacityMultiplier = 1.0;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(1, 0.5, 0.2));
			f.m_overCapacity = 80;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = true;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"sev90.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage10() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Railroad Gap";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map10";
		stage.m_mapInfo.m_id = "map10";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 13 * 12;

		stage.m_soldierCapacityVariance = 0.45;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.4, 0.2));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 8;
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(1, 0.5, 0.2));
			f.m_overCapacity = 70;
			f.m_capacityOffset = 20; 
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement c1("command");
			c1.setStringAttribute("class", "faction_resources");
			c1.setIntAttribute("faction_id", 1);
			addFactionResourceElements(c1, "vehicle", array<string> = {"barracks_a.vehicle", "barracks_s.vehicle", "barracks_y.vehicle"}, false);

			stage.m_extraCommands.insertLast(c1);
		}
		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage11() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Iron Enclave";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map13";
		stage.m_mapInfo.m_id = "map13";
		
		stage.m_includeLayers.insertLast("layer1.invasion"); 

		stage.m_maxSoldiers = 15 * 15;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2.0; 

		stage.m_soldierCapacityVariance = 0.4; 

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 2;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.5, 0.2));
			f.m_overCapacity = 0;
			f.m_bases = 1;
			f.m_capacityMultiplier = 1.0; 
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.5, 0.2));
			f.m_overCapacity = 40;
			f.m_capacityOffset = 20;
			f.m_capacityMultiplier = 1.0; 
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2, 0.5, 0.2));
			f.m_overCapacity = 40;
			f.m_capacityOffset = 20;
			f.m_capacityMultiplier = 1.0; 
			stage.m_factions.insertLast(f);
		}
		{
			// neutral
			Faction f(getFactionConfigs()[3], createCommanderAiCommand(3, 0.8, 0.2));
			f.m_capacityMultiplier = 0.0;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	}
  
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage12() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Misty Heights";
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map14";
		stage.m_mapInfo.m_id = "map14";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_fogOffset = 20.0;    
		stage.m_fogRange = 50.0; 

		stage.m_maxSoldiers = 11 * 13;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2.0;

		stage.m_soldierCapacityVariance = 0.45;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));    
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;  

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.2, 0.1));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 10;
			f.m_capacityMultiplier = 1;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.6, 0.25));
			f.m_overCapacity = 70;
			f.m_capacityOffset = 15; 
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	}  

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage13() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Green Coast";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map16";
		stage.m_mapInfo.m_id = "map16";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 18 * 13;
		stage.m_playerAiCompensation = 3;
		stage.m_playerAiReduction = 2;

		stage.m_soldierCapacityVariance = 0.45;

		stage.addTracker(AttackDefenseHandlerMap16(m_metagame, 0));		// we use this instead of peacefullastbase for map16
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 5;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.53, 0.3));
			f.m_overCapacity = 5;
			f.m_bases = 1;
			f.m_capacityMultiplier = 1.0;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.6, 0.28));
			f.m_overCapacity = 80;
			f.m_capacityOffset = 10;         
			f.m_capacityMultiplier = 1.0; 
			stage.m_factions.insertLast(f);
		}
		{
		// attack score is taken from the map16 attack handler script, if bases => 5    
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2, 0.65, 0.1));
			f.m_overCapacity = 40;
			f.m_capacityOffset = 5;
			f.m_capacityMultiplier = 1.0; 
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"vulcan_tank.vehicle", "radar_tank2.vehicle", "radio_jammer2.vehicle", "apc.vehicle", "apc_1.vehicle", "apc_2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage14() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Rattlesnake Crescent (alt)";
		stage.m_mapInfo.m_path = "media/packages/vanilla.desert/maps/map6";
		stage.m_mapInfo.m_id = "map6_2";

		// we want to exclude some layers here, as the default ones are already used for the other map6
		int index = stage.m_includeLayers.find("layer1.default");
		if (index >= 0) {
		stage.m_includeLayers.removeAt(index);
		}
		index = stage.m_includeLayers.find("bases.default");
		if (index >= 0) {
		stage.m_includeLayers.removeAt(index);
		}

		stage.m_includeLayers.insertLast("layer1.invasion");
		stage.m_includeLayers.insertLast("layer1_2.default"); 
		stage.m_includeLayers.insertLast("bases_2.default"); 

		stage.m_maxSoldiers = 15 * 9;
		stage.m_playerAiCompensation = 5;
		stage.m_playerAiReduction = 2;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.5, 0.15));   
			f.m_overCapacity = 0;
			f.m_capacityOffset = 5;
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(1, 0.48, 0.15));
			f.m_overCapacity = 70;
			f.m_capacityOffset = 15;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radar_tank2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
    
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage15() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Moorland Apocalypse";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map1_2";
		stage.m_mapInfo.m_id = "map1_2";

		stage.m_includeLayers.insertLast("layer1.invasion");        

		stage.m_fogOffset = 15.0;
		stage.m_fogRange = 70.0;

		// we want to exclude some layers here
		int index = stage.m_includeLayers.find("layer1.default");
		if (index >= 0) {
		stage.m_includeLayers.removeAt(index);
		}
		index = stage.m_includeLayers.find("bases.default");
		if (index >= 0) {
		stage.m_includeLayers.removeAt(index);
		}


		stage.m_includeLayers.insertLast("layer1_2.default"); 
		stage.m_includeLayers.insertLast("bases_2.default"); 

		stage.m_maxSoldiers = 20 * 9;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 1;

		stage.m_soldierCapacityVariance = 0.45;
		
		stage.addTracker(AttackDefenseHandlerMap1_2(m_metagame, 0));	// we use this instead of peacefullastbase for map1_2
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 2; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.5, 0.15));   
			f.m_overCapacity = 0;
			f.m_capacityOffset = 0; 
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.58, 0.15));        
			f.m_overCapacity = 40;
			f.m_capacityOffset = 0;
			stage.m_factions.insertLast(f);
		}
		{
		// attack score is taken from the map1_2 attack handler script, if bases => 11
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2, 0.70, 0.1));
			f.m_overCapacity = 50;
			f.m_capacityOffset = 30;
			f.m_capacityMultiplier = 1.0; 
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"vulcan_tank.vehicle", "radar_tank2.vehicle", "radio_jammer2.vehicle", "apc.vehicle", "apc_1.vehicle", "apc_2.vehicle", "guntruck.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage16() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Tropical Blizzard";
		stage.m_mapInfo.m_path = "media/packages/vanilla.winter/maps/map8_2";
		stage.m_mapInfo.m_id = "map8_2";

		stage.m_fogOffset = 15.0;
		stage.m_fogRange = 42.0;

		stage.m_maxSoldiers = 12 * 11;
		stage.m_soldierCapacityVariance = 0.6;

		stage.m_playerAiCompensation = 3;
		stage.m_playerAiReduction = 1.5;
		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.5, 0.1));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 0; 
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.65, 0.1));
			f.m_overCapacity = 50;
			f.m_capacityOffset = 0;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radar_tank2.vehicle", "wiesel_tow.vehicle", "cargo_helicopter_broken.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage17() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Gotcha Island";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map17";
		stage.m_mapInfo.m_id = "map17";
		
		stage.m_includeLayers.insertLast("layer1.invasion"); 

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		stage.m_maxSoldiers = 11 * 12;

		stage.m_soldierCapacityVariance = 0.55;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2.0;

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.6, 0.14));
			f.m_capacityOffset = 0; 
			f.m_capacityMultiplier = 1.0;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.60, 0.14));
			f.m_overCapacity = 60;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"m113_tank_acav.vehicle", "radio_jammer.vehicle", "radar_tower.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "capture";

		setDefaultAttackBreakTimes(stage);
		// setReduceDefenseForFinalAttack(stage, 0.1); // use this for final attack boost if needed for friendlies
		return stage;
	}
	
	// ------------------------------------------------------------------------------------------------
	protected Stage@ setupStage18() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Dry Enclave";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map13_2";
		stage.m_mapInfo.m_id = "map13_2";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.addTracker(Overtime(m_metagame, 0));

		stage.m_maxSoldiers = 10 * 20;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2;
		stage.m_soldierCapacityModel = "constant";

		stage.m_minRandomCrates = 0; 
		stage.m_maxRandomCrates = 1;

		stage.m_defenseWinTime = 800; 
		stage.m_defenseWinTimeMode = "custom";
		stage.addTracker(PausingKothTimer(m_metagame, stage.m_defenseWinTime));
		
		{
		XmlElement command("command");
		command.setStringAttribute("class", "change_game_settings");
		for (uint i = 0; i < m_metagame.getFactionCount(); ++i) {
			XmlElement faction("faction");
			if (int(i) == 3) {
				faction.setFloatAttribute("capacity_multiplier", 0.00001);
				faction.setBoolAttribute("lose_without_bases", false);
			}
			command.appendChild(faction);
			}
		m_metagame.getComms().send(command);
		stage.addTracker(RunAtStart(m_metagame, command));
		}
		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.35, 0.1));     
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(2, 0.32, 0.05));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.32, 0.05));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 5;
			stage.m_factions.insertLast(f);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle", "legion.vehicle", "noxe.vehicle", "m528.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		} 
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}        
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 2);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}  
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 3);
			addFactionResourceElements(command, "vehicle", array<string> = {"technical.vehicle", "radio_jammer2.vehicle", "radar_tank2.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}		
		{
			// neutral
			Faction f(getFactionConfigs()[3], createCommanderAiCommand(3));
		//	f.m_overCapacity = 60;
			f.m_capacityMultiplier = 0;
			stage.m_factions.insertLast(f);
		}


		// metadata
		stage.m_primaryObjective = "koth";
		stage.m_kothTargetBase = "Dry Enclave";

		return stage;
	} 	

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage19() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Warsalt Legacy";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map18";
		stage.m_mapInfo.m_id = "map18";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 16 * 15;
		stage.m_playerAiCompensation = 4;
        stage.m_playerAiReduction = 2.0;
  
		stage.m_soldierCapacityVariance = 0.5;		// was 0.3 (1.91), 0.4 (1.96)

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));
		//stage.addTracker(RunAtStart(m_metagame, command));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;
		
		// make neutral instantly not alive to avoid any possibility to gain capacity, like via not losing all bases first 
		// and then gaining bases which have vehicles that give capacity offset..
		{
			XmlElement command("command");
			command.setStringAttribute("class", "create_instance");
			command.setIntAttribute("faction_id", 1);
			command.setStringAttribute("position", "772 10 949");
			command.setStringAttribute("instance_class", "vehicle");
			command.setStringAttribute("instance_key", "m528.vehicle");
			m_metagame.getComms().send(command);
			// can't use m_extraCommands, they happen before match start, using trackers instead then
			stage.addTracker(RunAtStart(m_metagame, command));
		}
		{				
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.4, 0.1));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 20;
			f.m_capacityMultiplier = 1;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.64, 0.2));		// was 0.55 0.2 (1.95)
			f.m_overCapacity = 120;
			f.m_capacityOffset = 30;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle", "m528.vehicle", "apc.vehicle", "apc_1.vehicles", "apc_2.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	}

	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage20() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Swan River";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map19";
		stage.m_mapInfo.m_id = "map19";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_fogOffset = 24.0;
		stage.m_fogRange = 50.0;

		stage.m_maxSoldiers = 19 * 15;
		stage.m_playerAiCompensation = 4;
        stage.m_playerAiReduction = 2.5;		// was 2.0 (1.97)
  
		stage.m_soldierCapacityVariance = 0.6;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));    
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 4;  

		{ 				
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.46, 0.1));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 20;		// was 15 (1.95)
			f.m_capacityMultiplier = 1;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.66, 0.15));		// was 0.62 0.15  (1.95)
			f.m_overCapacity = 120;
			f.m_capacityOffset = 10;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle", "legion.vehicle", "apc.vehicle", "apc_1.vehicles", "apc_2.vehicle", "flamer_tank.vehicle", "missile_launcher.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
	
	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage21() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Elk Island";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map20";
		stage.m_mapInfo.m_id = "map20";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 12 * 17;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2.5;		// was 2.0 (1.97)

		stage.m_soldierCapacityVariance = 0.6;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;  

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.5, 0.1));
			f.m_overCapacity = 5;
			f.m_capacityOffset = 0;
			f.m_capacityMultiplier = 1;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.66, 0.15));		// was 0.54 0.15 (1.97)
			f.m_overCapacity = 80;
			f.m_capacityOffset = 0;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radio_jammer2.vehicle", "radar_tower.vehicle", "legion.vehicle", "lai-109.vehicle", "wiesel_tow.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	} 
	
	// ------------------------------------------------------------------------------------------------

	protected Stage@ setupStage22() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Road 666";
		stage.m_mapInfo.m_path = "media/packages/vanilla/maps/map21";
		stage.m_mapInfo.m_id = "map21";
		stage.m_mapInfo.m_size = 1536.0;

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_fogOffset = 24.0;    
		stage.m_fogRange = 50.0; 

		stage.m_maxSoldiers = 17 * 15;
		stage.m_playerAiCompensation = 4;
		stage.m_playerAiReduction = 2.0;

		stage.m_soldierCapacityVariance = 0.6;

		stage.addTracker(PeacefulLastBase(m_metagame, 0));
		stage.addTracker(CommsCapacityHandler(m_metagame));

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 4;  

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.40, 0.1));
			f.m_overCapacity = 0;
			f.m_capacityOffset = 15;
			f.m_capacityMultiplier = 1;
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 0.65, 0.15));
			f.m_overCapacity = 120;
			f.m_capacityOffset = 10;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "capture";
		stage.m_radioObjectivePresent = false;

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);
			addFactionResourceElements(command, "vehicle", array<string> = {"lailv-002.vehicle", "mmls-528.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer2.vehicle", "radar_tower.vehicle", "legion.vehicle", "tank_denied_player.vehicle", "tank_1_denied_player.vehicle", "tank_2_denied_player.vehicle", "flamer_tank.vehicle", "missile_launcher.vehicle"}, false);

			stage.m_extraCommands.insertLast(command);
		}

		setDefaultAttackBreakTimes(stage);
		return stage;
	}


	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	// FINAL STAGES
	// ------------------------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------------------------
	// --------------------------------------------
	protected Stage@ setupFinalStage1() {
		Stage@ stage = createStage();
		stage.m_mapInfo.m_name = "Final mission I"; // warning, default.character has reference to this name, careful if it needs to be changed
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map11";
		stage.m_mapInfo.m_id = "map11";

		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_maxSoldiers = 110;

		stage.m_playerAiCompensation = 5;
		stage.m_playerAiReduction = 0;

		stage.m_minRandomCrates = 1; 
		stage.m_maxRandomCrates = 3;

		stage.m_finalBattle = true;
		stage.m_hidden = true;
		
		stage.addTracker(DestroyVehicleToCaptureBase(m_metagame, "radio_jammer.vehicle", 2));
		stage.addTracker(DestroyVehicleToCaptureBase(m_metagame, "radar_tower.vehicle", 2));

		// make neutral instantly not alive to avoid any possibility to gain capacity, like via not losing all bases first 
		// and then gaining bases which have vehicles that give capacity offset..
		{
			XmlElement command("command");
			command.setStringAttribute("class", "set_match_status");
			command.setIntAttribute("faction_id", 2);
			command.setBoolAttribute("lose", true);
			// can't use m_extraCommands, they happen before match start, using trackers instead then
			stage.addTracker(RunAtStart(m_metagame, command));
		}

		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 0.0, 0.0, false));
			f.m_overCapacity = 2;
			f.m_capacityMultiplier = 0.0001;		// have at least a little capacity, otherwise is marked as neutral
			f.m_bases = 1;
			stage.m_factions.insertLast(f);
		}
		{
			// in adventure mode, this faction config will be replaced with the correct one when final battle 1 opponent is decided 
			Faction f(getFactionConfigs()[1], createCommanderAiCommand(1, 1.0, 0.0, false));
			stage.m_factions.insertLast(f); 
		}
		{
			// neutral
			Faction f(getFactionConfigs()[3], createCommanderAiCommand(3));
			f.m_capacityMultiplier = 0.0;
			stage.m_factions.insertLast(f);
		}

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"mobile_armory.vehicle"}, true);

			stage.m_extraCommands.insertLast(command);
		}
		
		// no calls for friendly faction in the last map
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			command.setBoolAttribute("clear_calls", true);
			stage.m_extraCommands.insertLast(command);
		}

		// metadata
		stage.m_primaryObjective = "final1";

		return stage;
	}

	// --------------------------------------------
	protected Stage@ setupFinalStage2() {
		PhasedStage@ stage = createPhasedStage();
		stage.setPhaseController(PhaseControllerMap12(m_metagame));
		stage.m_mapInfo.m_name = "Final mission II";	// warning, default.character has reference to this name, careful if it needs to be changed
		stage.m_mapInfo.m_path = "media/packages/red_alert/maps/map12";
		stage.m_mapInfo.m_id = "map12";
		
		stage.m_includeLayers.insertLast("layer1.invasion");

		stage.m_fogOffset = 20.0;    
		stage.m_fogRange = 50.0; 

		stage.m_maxSoldiers = 70;
		stage.m_playerAiCompensation = 3;
		stage.m_playerAiReduction = 2.5;

		stage.m_minRandomCrates = 0; 
		stage.m_maxRandomCrates = 1;

		stage.m_finalBattle = true;
		stage.m_hidden = true;

		// set all defend initially, the phases will control it once things start moving
		{
			Faction f(getFactionConfigs()[0], createFellowCommanderAiCommand(0, 1.0, 0.0));
			f.m_capacityMultiplier = 0.4;
			stage.m_factions.insertLast(f);
		}
		{
			// in adventure mode, this faction config will be replaced with the correct one when final battle 1 opponent is decided 
			Faction f(getFactionConfigs()[2], createCommanderAiCommand(1, 1.0, 0.0));
			f.m_loseWithoutBases = false;
			stage.m_factions.insertLast(f); 
		}
		{
			// neutral
			Faction f(getFactionConfigs()[3], createCommanderAiCommand(3));
			f.m_capacityMultiplier = 0.0;
			stage.m_factions.insertLast(f);
		}

		// metadata
		stage.m_primaryObjective = "final2";

		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 0);
			addFactionResourceElements(command, "vehicle", array<string> = {"radio_jammer.vehicle", "radar_tower.vehicle"}, false);
			stage.m_extraCommands.insertLast(command);
		}
		{
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setIntAttribute("faction_id", 1);
			addFactionResourceElements(command, "vehicle", array<string> = {"aa_emplacement.vehicle"}, true);
			stage.m_extraCommands.insertLast(command);
		}

		stage.m_allowChangeCapacityOnTheFly = false;

		return stage;
	}

	// --------------------------------------------
	protected void setupWorld() {
		// World disabled in Invasion for now, map10 elements are missing
		//$this->world = new World($this->metagame);
	}

	// --------------------------------------------
	array<XmlElement@>@ getFactionResourceConfigChangeCommands(float completionPercentage, Stage@ stage) {
		array<XmlElement@>@ commands = getFactionResourceChangeCommands(stage.m_factions.size());

		_log("completion percentage: " + completionPercentage);

		const UserSettings@ settings = m_metagame.getUserSettings();
		_log(" variance enabled: " + settings.m_completionVarianceEnabled);
		if (settings.m_completionVarianceEnabled) {
			array<XmlElement@>@ varianceCommands = getCompletionVarianceCommands(stage, completionPercentage);
			// append with command already gathered
			merge(commands, varianceCommands);
		}

		merge(commands, stage.m_extraCommands);

		return commands;
	}

	// --------------------------------------------
	protected array<XmlElement@>@ getFactionResourceChangeCommands(int factionCount) const {
		array<XmlElement@> commands;

		// invasion faction resources are nowadays based on resources declared for factions in the faction files 
		// + some minor changes for common and friendly
		for (int i = 0; i < factionCount; ++i) {
			commands.insertLast(getFactionResourceChangeCommand(i, getCommonFactionResourceChanges()));
		}

		// apply initial friendly faction resource modifications
		commands.insertLast(getFactionResourceChangeCommand(0, getFriendlyFactionResourceChanges()));

		return commands;
	}

	// --------------------------------------------
	protected array<ResourceChange@>@ getCommonFactionResourceChanges() const {
		array<ResourceChange@> list;
	
		list.push_back(ResourceChange(Resource("armored_truck.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("mobile_armory.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("a10_gun_run.call", "call"), true));
		list.push_back(ResourceChange(Resource("gunship_run.call", "call"), true));        

		// disable certain weapons here; mainly because Dominance uses the same .resources files but we have further changes for Invasion here
		list.push_back(ResourceChange(Resource("l85a2.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("famasg1.weapon", "weapon"), false));
		list.push_back(ResourceChange(Resource("sg552.weapon", "weapon"), false));
		// list.push_back(ResourceChange(Resource("minig_resource.weapon", "weapon"), false));
		// list.push_back(ResourceChange(Resource("tow_resource.weapon", "weapon"), false));
		// list.push_back(ResourceChange(Resource("gl_resource.weapon", "weapon"), false));
		// list.push_back(ResourceChange(Resource("hornet_resource.weapon", "weapon"), false));
		
		return list;
	}

	// --------------------------------------------
	protected array<ResourceChange@> getFriendlyFactionResourceChanges() const {
		array<ResourceChange@> list;

		// enable mobile spawn and armory trucks for player faction
		list.push_back(ResourceChange(Resource("armored_truck.vehicle", "vehicle"), true));
		list.push_back(ResourceChange(Resource("mobile_armory.vehicle", "vehicle"), true));
//		list.push_back(ResourceChange(Resource("a10_gun_run.call", "call"), true));
//		list.push_back(ResourceChange(Resource("gunship_run.call", "call"), true));        

		// no m79 for friendlies
		list.push_back(ResourceChange(Resource("m79.weapon", "weapon"), false));

		// no suitcases/laptops carried by friendlies
		list.push_back(ResourceChange(Resource("suitcase.carry_item", "carry_item"), false));
		list.push_back(ResourceChange(Resource("laptop.carry_item", "carry_item"), false));

		// no cargo, prisons or aa
		list.push_back(ResourceChange(Resource("cargo_truck.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("prison_door.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("prison_bus.vehicle", "vehicle"), false));
		list.push_back(ResourceChange(Resource("prison_hatch.vehicle", "vehicle"), false));    
		list.push_back(ResourceChange(Resource("aa_emplacement.vehicle", "vehicle"), false));

		return list;
	}

	// --------------------------------------------
	protected array<XmlElement@>@ getCompletionVarianceCommands(Stage@ stage, float completionPercentage) {
		// we want to have a sense of progression 
		// with the starting map vs other maps played before extra final maps

		array<XmlElement@> commands;

		if (stage.isFinalBattle()) {
			// don't use for final battles
			return commands;
		}

		if (completionPercentage < 0.08) {
			_log("below 10%");
			for (uint i = 0; i < stage.m_factions.size(); ++i) {
				// disable comms truck, cargo and radio tower on all factions, same for prisons
				array<string> keys = {
					"radar_truck.vehicle", 
					"cargo_truck.vehicle", 
					"radar_tower.vehicle", 
					"prison_bus.vehicle", 
					"prison_door.vehicle", 
					"aa_emplacement.vehicle",
					"m113_tank_mortar.vehicle" };

				if (i == 0) {
					// let friendlies have the tank, need it to make a successful tank call
				} else {
					// disable tanks for enemy factions
					keys.insertLast("tank.vehicle");
					keys.insertLast("tank_1.vehicle");
					keys.insertLast("tank_2.vehicle");
				}

				if (keys.size() > 0) {
					XmlElement command("command"); 
					command.setStringAttribute("class", "faction_resources"); 
					command.setIntAttribute("faction_id", i);
					addFactionResourceElements(command, "vehicle", keys, false);

					commands.insertLast(command);
				}
			}
			// a bit odd that we change stage members here in a getter function, but just do it for now, it's just metadata
			stage.m_radioObjectivePresent = false;

		} else if (completionPercentage < 0.20) {
			_log("below 25%, above 10%");
			for (uint i = 0; i < stage.m_factions.size(); ++i) {
				array<string> keys;

				if (i == 0) {
					// disable comms truck and radio tower on friendly faction only
					keys.insertLast("radar_truck.vehicle");
					keys.insertLast("radar_tower.vehicle");

					// cargo & prisons are disabled anyway for friendly faction
				} else {
				}

				if (keys.size() > 0) {
					XmlElement command("command"); 
					command.setStringAttribute("class", "faction_resources"); 
					command.setIntAttribute("faction_id", i);
					addFactionResourceElements(command, "vehicle", keys, false);

					commands.insertLast(command);
				}
			}
		}

		return commands;
	}

}
