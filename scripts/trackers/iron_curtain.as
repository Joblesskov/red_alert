#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

class IronCurtain : Tracker {
    protected Metagame@ m_metagame;
    protected array<string> m_excludedVehicles;
    // 存储受到铁幕影响的载具ID
    protected array<int> m_appliedVehicles;
    // 存储对应载具的剩余有效时间
    protected array<float> m_timers;
    
    protected float m_timer = 1.0f;
    protected float m_interval = m_timer;
    protected float m_effectTime = 60.0f;
    protected bool m_started = true;
    protected bool m_ended = false;
    protected float m_maxHealth = 10.0f;

    // 构造函数
    IronCurtain(Metagame@ metagame) {
        @m_metagame = @metagame;
        m_excludedVehicles = array<string> = {"cover1.vehicle", "sandbag_cover.vehicle"};
    }

    // --------------------------------------------
    // 处理事件：检测铁幕激活
    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
        string sourceKey = event.getStringAttribute("key");
        if (sourceKey != "iron_curtain") return;

        // 铁幕参数配置
        float range = 10.0f;          // 作用半径
        float y_offset = -1.0f;       // 位置偏移

        // 获取施放者和位置
        int casterId = event.getIntAttribute("character_id");
        Vector3 castPos = stringToVector3(event.getStringAttribute("position"));
        castPos = Vector3(castPos.get_opIndex(0), castPos.get_opIndex(1) + y_offset, castPos.get_opIndex(2));

        // 遍历所有阵营和载具
        for (uint f = 0; f < 4; ++f){
            array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, f);

            for (uint i = 0; i < vehicles.length(); ++i) {
                int vehicleId = vehicles[i].getIntAttribute("id");
                if (vehicleId == -1) continue;

                Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));

                // 检查距离
                if (checkRange(castPos, vehiclePos, range)) {
                    const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
                    if (vehicleInfo !is null) {
                        string targetKey = vehicleInfo.getStringAttribute("key");

                        // 排除特定载具 (如沙袋)
                        if (m_excludedVehicles.find(targetKey) < 0) {
                            // 关键逻辑：检查载具是否已在列表中
                            int index = m_appliedVehicles.find(vehicleId);
                            
                            if (index < 0) {
                                // 新载具：添加到列表末尾，设置初始时间
                                m_appliedVehicles.insertLast(vehicleId);
                                m_timers.insertLast(m_effectTime);
                            } else {
                                m_timers[index] = m_effectTime; 
                            }
                        }
                    }
                }
            }
        }
    }
    
    protected void handleVehicleSpawnEvent(const XmlElement@ event) {
        int vehicleId = event.getIntAttribute("vehicle_id");
        string vehicleKey = event.getStringAttribute("vehicle_key");

        const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
        if (vehicleInfo is null) return;

        float currentHealth = vehicleInfo.getFloatAttribute("health");
        float maxHealth = vehicleInfo.getFloatAttribute("max_health");

        if (currentHealth > maxHealth) {
            string command = "<command class='update_vehicle' id='" + vehicleId + "' health='" + maxHealth + "' />";
            m_metagame.getComms().send(command);
        }
    }

    // --------------------------------------------
    // 触发函数：更新铁幕效果
    // --------------------------------------------
    void trigger(float time) {
        for (int i = m_appliedVehicles.length() - 1; i >= 0; i--) {
            int vehicleId = m_appliedVehicles[i];

            // 获取载具信息
            const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
            if (vehicleInfo is null) {
                m_appliedVehicles.removeAt(i);
                m_timers.removeAt(i);
                continue;
            }

            float vehicleMaxHealth = vehicleInfo.getFloatAttribute("max_health");
            float currentHealth = vehicleInfo.getFloatAttribute("health");

            if (currentHealth <= 0.0f) {
                m_appliedVehicles.removeAt(i);
                m_timers.removeAt(i);
                continue;
            }

            // 更新时间
            m_timers[i] -= time;

            // 检查时间是否结束
            if (m_timers[i] <= 0.0f) {
                string command = "<command class='update_vehicle' id='" + vehicleId + "' health='" + vehicleMaxHealth + "' />";
                m_metagame.getComms().send(command);
                m_appliedVehicles.removeAt(i);
                m_timers.removeAt(i);
                continue;
            }

            // 维持无敌效果
            float protectedHealth = vehicleMaxHealth * m_maxHealth;
            float factor = m_timers[i] / m_effectTime;
            protectedHealth = factor * protectedHealth + (1.0f - factor) * vehicleMaxHealth;
            string command = "<command class='update_vehicle' id='" + vehicleId + "' health='" + protectedHealth + "' />";
            m_metagame.getComms().send(command);
        }
    }
    
    // --------------------------------------------
    // 更新函数：控制触发频率
    // --------------------------------------------
    void update(float time) {
        if (m_ended) return; // 如果已结束，不再更新
        
        m_timer -= time;
        if (m_timer < 0.0f) {
            m_timer += m_interval;
            trigger(m_timer);
        }
    }

    // 状态查询
    bool hasEnded() const {
        return m_ended;
    }

    bool hasStarted() const {
        return m_started;
    }
};