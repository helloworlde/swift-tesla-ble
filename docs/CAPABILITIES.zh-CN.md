# swift-tesla-ble 能力清单

本文按**操作对象**整理 `swift-tesla-ble` 当前对外暴露的全部 API：可以下达哪些控制指令、能读到哪些车辆数据、对应的 Swift 入口在哪。所有指令／查询都通过 `TeslaVehicleClient` actor 完成，统一走签名后的 BLE 通道（首次配对的 `addKey` 除外）。

> 命名约定：本文 **指令** 指通过 `client.send(_:)` 下发的写动作（车辆只回 ACK，不返数据）；**查询** 指通过 `client.fetch(_:)` 或 `client.query(_:)` 拿到的结构化数据；**字段** 指 Swift 原生模型中的属性名。
>
> 所有读字段均为 Swift `Optional`（除非另行标注）。`nil` 含义统一为：**车辆没有上报该字段**（对应 protobuf 的 oneof 缺失），不要把 `nil` 解读为 0 / false。

---

## 一、客户端 / 连接

| 入口 | 类型 | 作用 |
|---|---|---|
| `TeslaVehicleClient(vin:keyStore:logger:)` | 构造 | 一个 VIN 对应一个 actor 实例 |
| `client.connect(mode:timeout:)` | 异步操作 | `mode = .normal` 走签名握手；`mode = .pairing` 仅做 BLE 连接（首次配对用） |
| `client.disconnect()` | 异步操作 | 关闭 BLE 会话，回到 `.disconnected` |
| `client.state` | 读 | 当前连接状态（`disconnected / scanning / connecting / handshaking / connected`） |
| `client.stateStream` | `AsyncStream<ConnectionState>` | **唯一的 push 通道** —— 仅推送连接状态变化，**不推送车辆数据** |
| `client.vin` | 读 | 客户端绑定的 VIN |

> 车辆侧 BLE 协议**不主动推送遥测数据**，所有车辆数据都靠拉取。如果需要实时车速／档位，建议在调用方循环 `fetchDrive()`。

---

## 二、控制指令（`client.send(_:)`）

按物理动作 / 安全 / 充电 / 空调 / 媒体 / 信息娱乐 / 钥匙管理 七大类组织。括号里是 Swift 枚举路径。

### 2.1 物理动作 — `Command.actions(_)`

| 指令 | Swift 入口 | 说明 |
|---|---|---|
| 鸣笛 | `.actions(.honk)` | |
| 闪灯 | `.actions(.flashLights)` | |
| 关闭所有车窗 | `.actions(.closeWindows)` | |
| 通风开窗 | `.actions(.ventWindows)` | 所有车窗微开通风 |
| 触发车库门 (Homelink) | `.actions(.triggerHomelink(latitude:, longitude:))` | 按坐标匹配最近的 Homelink 设备 |
| 调整全景天窗 | `.actions(.changeSunroof(level:))` | `0` = 完全关闭，`100` = 完全打开 |

### 2.2 安全与车身 — `Command.security(_)`

#### 锁车 / 唤醒 / 远程驾驶

| 指令 | Swift 入口 | 备注 |
|---|---|---|
| 上锁 | `.security(.lock)` | VCSEC 域 |
| 解锁 | `.security(.unlock)` | VCSEC 域 |
| 唤醒车辆 | `.security(.wakeVehicle)` | |
| 短时远程驾驶授权 | `.security(.remoteDrive)` | 代客泊车场景 |
| 离车自动安全 | `.security(.autoSecure)` | |

#### 后备厢 / 前备厢 / 卷帘

| 指令 | Swift 入口 | 备注 |
|---|---|---|
| 打开后备厢 | `.security(.openTrunk)` | |
| 关闭电动后备厢 | `.security(.closeTrunk)` | 仅电动尾门车型 |
| 打开前备厢 | `.security(.openFrunk)` | |
| 智能开关后备厢 | `.security(.actuateTrunk)` | 关 → 开，开 → 关 |
| 打开卷帘 | `.security(.openTonneau)` | Cybertruck 等 |
| 关闭卷帘 | `.security(.closeTonneau)` | |
| 卷帘原地停止 | `.security(.stopTonneau)` | |

#### 哨兵 / 代客 / 访客模式

| 指令 | Swift 入口 |
|---|---|
| 哨兵模式开关 | `.security(.setSentryMode(Bool))` |
| 代客模式开关（带 PIN） | `.security(.setValetMode(enabled:, password:))` |
| 重置驾驶 PIN | `.security(.resetPin)` |
| 重置代客 PIN | `.security(.resetValetPin)` |
| 访客模式开关 | `.security(.setGuestMode(Bool))` |
| 擦除访客资料 | `.security(.eraseGuestData(reason:))` |

#### PIN-to-Drive

| 指令 | Swift 入口 |
|---|---|
| 启用并设置 PIN-to-Drive | `.security(.setPinToDrive(enabled:, password:))` |
| 取消 PIN-to-Drive | `.security(.clearPinToDrive)` |

#### 限速模式 (Speed Limit Mode)

| 指令 | Swift 入口 |
|---|---|
| 启用限速 | `.security(.activateSpeedLimit(pin:))` |
| 关闭限速 | `.security(.deactivateSpeedLimit(pin:))` |
| 设置限速值（mph） | `.security(.setSpeedLimit(mph:))` |
| 清除限速 PIN | `.security(.clearSpeedLimitPin(pin:))` |
| 管理员强制清除限速 PIN | `.security(.clearSpeedLimitPinAdmin)` |

#### 钥匙白名单管理

| 指令 | Swift 入口 | 路径 |
|---|---|---|
| 首次配对添加钥匙 | `.security(.addKey(publicKey:, role:, formFactor:))` | **未签名** VCSEC 配对路径，需 `connect(mode: .pairing)` |
| 删除钥匙 | `.security(.removeKey(publicKey:))` | |
| 给已有钥匙加角色 | `.security(.addPermissions(publicKey:, role:))` | |
| 收回已有钥匙的角色 | `.security(.removePermissions(publicKey:, role:))` | |
| 替换钥匙（轮换） | `.security(.replaceKey(oldPublicKey:, newPublicKey:, role:, impermanent:))` | |
| 修改钥匙角色 | `.security(.updateKeyPermissions(publicKey:, role:))` | |
| 添加临时钥匙 | `.security(.addImpermanentKey(publicKey:, role:, formFactor:))` | 客人 / 服务场景 |
| 添加临时钥匙并清空已有 | `.security(.addImpermanentKeyAndRemoveExisting(publicKey:, role:, formFactor:))` | |
| 移除全部临时钥匙 | `.security(.removeAllImpermanentKeys)` | |

`KeyRole`：`none / service / owner / driver / fleetManager / vehicleMonitor / chargingManager / guest`
`KeyFormFactor`：`unknown / nfcCard / iosDevice / androidDevice / cloudKey`

### 2.3 充电 — `Command.charge(_)`

| 指令 | Swift 入口 | 备注 |
|---|---|---|
| 开始充电 | `.charge(.start)` | |
| 停止充电 | `.charge(.stop)` | |
| 充至最大续航 | `.charge(.startMaxRange)` | |
| 充至标准续航 | `.charge(.startStandardRange)` | |
| 设置充电上限百分比 | `.charge(.setLimit(percent:))` | |
| 设置交流充电电流 (A) | `.charge(.setAmps(_))` | |
| 打开充电口 | `.charge(.openPort)` | |
| 关闭电动充电口 | `.charge(.closePort)` | |
| 低功耗模式 | `.charge(.setLowPowerMode(Bool))` | |
| 保持电源附件供电 | `.charge(.setKeepAccessoryPowerMode(Bool))` | |
| 添加 / 更新充电计划 | `.charge(.addSchedule(ChargeScheduleInput))` | |
| 删除单条充电计划 | `.charge(.removeSchedule(id:))` | |
| 按位置批量删充电计划 | `.charge(.batchRemoveSchedules(home:, work:, other:))` | |
| 添加 / 更新预热计划 | `.charge(.addPreconditionSchedule(PreconditionScheduleInput))` | |
| 删除单条预热计划 | `.charge(.removePreconditionSchedule(id:))` | |
| 按位置批量删预热计划 | `.charge(.batchRemovePreconditionSchedules(home:, work:, other:))` | |
| 设置一次性出发计划 | `.charge(.scheduleDeparture(ScheduleDepartureInput))` | 含预热 + 错峰策略 |
| 设置每日定时充电 | `.charge(.scheduleCharging(enabled:, timeAfterMidnightMinutes:))` | |
| 清除一次性出发计划 | `.charge(.clearScheduledDeparture)` | |

### 2.4 空调 / 座椅 — `Command.climate(_)`

| 指令 | Swift 入口 | 备注 |
|---|---|---|
| 空调开 | `.climate(.on)` | |
| 空调关 | `.climate(.off)` | |
| 设置驾驶 / 副驾温度（℃） | `.climate(.setTemperature(driver:, passenger:))` | |
| 方向盘加热 | `.climate(.setSteeringWheelHeater(Bool))` | |
| Climate Keeper 模式 | `.climate(.setKeeperMode(.off / .on / .dog / .camp))` | |
| Preconditioning Max | `.climate(.setPreconditioningMax(enabled:, manualOverride:))` | |
| 生化武器防御模式 | `.climate(.setBioweaponDefenseMode(enabled:, manualOverride:))` | |
| 座舱过热保护开关 | `.climate(.setCabinOverheatProtection(enabled:, fanOnly:))` | |
| 座舱过热保护温度阈值 | `.climate(.setCabinOverheatProtectionTemperature(level: .low/.medium/.high))` | |
| 座椅加热档位 | `.climate(.setSeatHeater(level:, seat:))` | level: `off/low/medium/high`，seat：含三排 + 后排靠背 |
| 前排座椅通风档位 | `.climate(.setSeatCooler(level:, seat:))` | seat：仅 `frontLeft / frontRight` |
| 自动座椅气候 | `.climate(.autoSeatAndClimate(enabled:, positions:))` | |

`SeatPosition`：`frontLeft / frontRight / rearLeft / rearLeftBack / rearCenter / rearRight / rearRightBack / thirdRowLeft / thirdRowRight`

### 2.5 媒体 — `Command.media(_)`

| 指令 | Swift 入口 |
|---|---|
| 播放 / 暂停切换 | `.media(.togglePlayback)` |
| 下一曲 | `.media(.nextTrack)` |
| 上一曲 | `.media(.previousTrack)` |
| 设置音量（绝对值） | `.media(.setVolume(Float))` |
| 音量 + | `.media(.volumeUp)` |
| 音量 − | `.media(.volumeDown)` |
| 下一收藏 | `.media(.nextFavorite)` |
| 上一收藏 | `.media(.previousFavorite)` |

### 2.6 信息娱乐 — `Command.infotainment(_)`

| 指令 | Swift 入口 |
|---|---|
| 安排软件更新 | `.infotainment(.scheduleSoftwareUpdate(offsetSeconds:))` |
| 取消软件更新 | `.infotainment(.cancelSoftwareUpdate)` |
| 重命名车辆 | `.infotainment(.setVehicleName(_))` |

---

## 三、车辆状态查询

### 3.1 整车快照 — `client.fetch(_:)`

返回 `TeslaVehicleSnapshot`。可选拉取范围：

```swift
public enum StateQuery {
    case all                           // 12 个类别全部
    case driveOnly                     // 仅 drive（最低延迟）
    case categories(Set<StateCategory>)
}
```

**`fetch(.all)` 内部已自动按类别拆成多次请求**（对真机 BLE 的 `RESPONSE_MTU_EXCEEDED` 的修复，单次合并响应会超 BLE buffer），失败的子类别会被跳过、其余仍正常返回。

`StateCategory` 共 12 项，对应 `TeslaVehicleSnapshot` 的子字段如下。每个表统一为 `字段 | 类型 | 说明`。所有字段均为 `Optional`，`nil` 表示车辆未上报。

#### 3.1.1 充电 (`category: .charge` → `snapshot.charge: ChargeState`)

##### 电池

| 字段 | 类型 | 说明 |
|---|---|---|
| `batteryLevel` | `Int?` | SOC 百分比（0–100） |
| `usableBatteryLevel` | `Int?` | 可用 SOC；BMS 在冷／衰减时会预留 buffer，可能低于 `batteryLevel` |
| `batteryRangeMiles` | `Double?` | 额定剩余续航（英里） |
| `estBatteryRangeMiles` | `Double?` | 基于近期能耗估算的剩余续航（英里） |
| `idealBatteryRangeMiles` | `Double?` | 理想（EPA 等效）剩余续航（英里） |

##### 充电会话

| 字段 | 类型 | 说明 |
|---|---|---|
| `chargingStatus` | `ChargingStatus?` | 高层会话状态：`disconnected / charging / complete / stopped / starting` |
| `chargerVoltage` | `Int?` | 充电桩输出电压（V） |
| `chargerCurrent` | `Int?` | 充电桩实际输出电流（A） |
| `chargerPilotCurrent` | `Int?` | EVSE 通过 pilot 信号广告的电流上限（A） |
| `chargeCurrentRequest` | `Int?` | 用户配置的充电电流请求（A） |
| `chargeCurrentRequestMax` | `Int?` | 允许的最大充电电流请求（A） |
| `chargingAmps` | `Int?` | 车端上报的 charging-amps 设置 |
| `chargerPhases` | `Int?` | 当前使用相数（1 或 3） |
| `chargerPower` | `Int?` | 充电功率（kW） |
| `chargeRateMph` | `Double?` | 每小时新增续航（mph） |
| `minutesToFullCharge` | `Int?` | 剩余充满分钟数 |
| `minutesToChargeLimit` | `Int?` | 距离设定上限的剩余分钟数 |
| `chargeEnergyAddedKWh` | `Double?` | 本次会话已注入能量（kWh） |
| `chargeMilesAddedRated` | `Double?` | 本次会话新增的额定续航（mile） |
| `chargeMilesAddedIdeal` | `Double?` | 本次会话新增的理想续航（mile） |
| `tripCharging` | `Bool?` | 该次充电属于行程规划的一部分（Supercharger trip planner） |
| `superchargerSessionTripPlanner` | `Bool?` | 当前 Supercharger 会话由行程规划托管 |

##### 充电上限

| 字段 | 类型 | 说明 |
|---|---|---|
| `chargeLimitPercent` | `Int?` | 用户配置的充电上限（%） |
| `chargeLimitStandardPercent` | `Int?` | 标准推荐上限（%） |
| `chargeLimitMinPercent` | `Int?` | 允许的最低上限（%） |
| `chargeLimitMaxPercent` | `Int?` | 允许的最高上限（%） |
| `oneTimeChargeLimitPercent` | `Int?` | 一次性高 SOC 上限（如行前充满）（%） |
| `chargeLimitReason` | `ChargeLimitReason?` | 限充原因：`unknown / none / evse / batteryTempLow / highSoc / cabin` |

##### 充电口

| 字段 | 类型 | 说明 |
|---|---|---|
| `chargePortOpen` | `Bool?` | 充电口门物理打开 |
| `chargePortLatch` | `ChargePortLatchState?` | 连接器闩锁状态：`sna / disengaged / engaged / blocking`。已锁等价于 `latch == .engaged` |
| `chargePortColdWeatherMode` | `Bool?` | 冷天模式激活 |
| `chargePortColor` | `ChargePortColor?` | 充电口 LED 颜色枚举 |
| `chargeCableUnlatched` | `Bool?` | 充电线缆已机械解锁 |

##### 接口 / 直流快充

| 字段 | 类型 | 说明 |
|---|---|---|
| `connectedCableType` | `CableType?` | 当前插入的接口类型：`sna / iec / sae / gbAc / gbDc` |
| `fastChargerType` | `FastChargerType?` | 快充类型：`sna / supercharger / chademo / gb / acSingleWireCan / combo / mcSingleWireCan / other / tesla` |
| `fastChargerBrand` | `FastChargerBrand?` | 快充品牌：`tesla / sna` |
| `fastChargerPresent` | `Bool?` | 当前是否连接到 DC 快充 |

##### 定时 / 出发计划

| 字段 | 类型 | 说明 |
|---|---|---|
| `scheduledChargingMode` | `ScheduledChargingMode?` | 定时充电模式：`off / startAt / departBy` |
| `scheduledChargingPending` | `Bool?` | 队列中存在未触发的定时任务 |
| `scheduledChargingStartTimeSecondsSinceEpoch` | `UInt64?` | 计划开始的 Unix 时间戳（秒） |
| `scheduledChargingStartTimeMinutes` | `UInt32?` | 计划开始时间，按本地午夜偏移（分钟） |
| `scheduledChargingStartTimeAppMinutes` | `Int?` | App 提供的计划开始时间，午夜偏移（分钟） |
| `scheduledDepartureTimeMinutes` | `UInt32?` | 计划出发时间，午夜偏移（分钟） |
| `offPeakHoursEndTimeMinutes` | `UInt32?` | 错峰时段结束时间，午夜偏移（分钟） |
| `preconditioningEnabled` | `Bool?` | 出发预热已启用 |

##### 充电使能 / 托管充电

| 字段 | 类型 | 说明 |
|---|---|---|
| `userChargeEnableRequest` | `Bool?` | 用户已请求开始充电 |
| `chargeEnableRequest` | `Bool?` | 车辆已确认放行充电 |
| `managedChargingActive` | `Bool?` | Tesla 托管充电正在调度 |
| `managedChargingUserCanceled` | `Bool?` | 用户已取消本次托管 |
| `managedChargingStartTimeSecondsSinceEpoch` | `UInt64?` | 托管充电开始时间（Unix 秒） |

##### 车辆放电插座（Cybertruck V2H/V2L）

| 字段 | 类型 | 说明 |
|---|---|---|
| `outletState` | `OutletState?` | 110/120V 插座状态：`off / cabinAndBed / cabin` |
| `powerFeedState` | `OutletState?` | 高功率回供 (V2H/V2L) 状态，枚举同上 |
| `outletSocLimitPercent` | `Int?` | 插座自动停止的 SOC 下限（%） |
| `powerFeedSocLimitPercent` | `Int?` | 回供自动停止的 SOC 下限（%） |
| `outletTimeRemainingSeconds` | `Int64?` | 插座自动停止前剩余秒数 |
| `powerFeedTimeRemainingSeconds` | `Int64?` | 回供自动停止前剩余秒数 |
| `outletMaxTimerMinutes` | `Int?` | 插座定时器最大可设值（分钟） |

##### Powershare 子状态 (`powershare: PowershareState?`)

| 字段 | 类型 | 说明 |
|---|---|---|
| `featureAllowed` | `Bool?` | 该 VIN 在硬件 / 软件层允许 Powershare |
| `featureEnabled` | `Bool?` | 用户已启用 Powershare 功能 |
| `requestActive` | `Bool?` | 用户当前已请求 Powershare 启动 |
| `type` | `PowershareType?` | 当前共享对象：`none / load / home` |
| `status` | `PowershareStatus?` | 会话生命周期：`inactive / initializing / active / stopped / handshaking / activeReconnectingSoon` |
| `stopReason` | `PowershareStopReason?` | 上次停止原因：`none / socTooLow / retry / fault / user / reconnecting / authentication` |
| `instantaneousLoadKW` | `Double?` | 瞬时负载（kW） |
| `vehicleEnergyLeftHours` | `Int?` | 按当前负载估算电池剩余可用小时数 |
| `socLimitPercent` | `Int?` | Powershare 自动停止的 SOC 下限（%） |

##### 收藏地点

| 字段 | 类型 | 说明 |
|---|---|---|
| `homeLocation` | `Coordinate?` | 用户保存的"家"坐标 |
| `workLocation` | `Coordinate?` | 用户保存的"公司"坐标 |

#### 3.1.2 空调 (`.climate` → `snapshot.climate: ClimateState`)

##### 温度

| 字段 | 类型 | 说明 |
|---|---|---|
| `insideTempCelsius` | `Double?` | 车内温度（℃） |
| `outsideTempCelsius` | `Double?` | 车外温度（℃） |
| `driverTempSettingCelsius` | `Double?` | 驾驶侧设定温度（℃） |
| `passengerTempSettingCelsius` | `Double?` | 副驾设定温度（℃） |
| `minAvailTempCelsius` | `Double?` | 可设最低温（℃） |
| `maxAvailTempCelsius` | `Double?` | 可设最高温（℃） |

##### HVAC 主开关

| 字段 | 类型 | 说明 |
|---|---|---|
| `fanStatus` | `Int?` | 风扇档位（车端原始值，通常 0–7） |
| `isClimateOn` | `Bool?` | 空调主体是否运行 |
| `isAutoConditioningOn` | `Bool?` | Auto HVAC 是否处于自动控制态 |
| `isPreconditioning` | `Bool?` | 远程或定时预热进行中 |
| `hvacAutoRequest` | `HvacAutoRequest?` | 自动控制是否被手动覆盖：`on / override` |
| `climateKeeperMode` | `ClimateKeeperMode?` | Keeper 模式：`unknown / off / on / dog / party` |
| `isFrontDefrosterOn` | `Bool?` | 前挡除霜开 |
| `isRearDefrosterOn` | `Bool?` | 后窗除霜开 |
| `defrostOn` | `Bool?` | 除霜模式总开关（由 `defrostMode` 推导） |
| `remoteHeaterControlEnabled` | `Bool?` | 远程加热被允许（部分市场会限制） |
| `bioweaponMode` | `Bool?` | 生化武器防御模式激活 |

##### 座椅 / 加热 / 通风

| 字段 | 类型 | 说明 |
|---|---|---|
| `seatHeaterFrontLeft` | `SeatHeaterLevel?` | 前左座椅加热档位（`off=0/low=1/medium=2/high=3`，下同） |
| `seatHeaterFrontRight` | `SeatHeaterLevel?` | 前右座椅加热 |
| `seatHeaterRearLeft` | `SeatHeaterLevel?` | 后左座椅加热 |
| `seatHeaterRearCenter` | `SeatHeaterLevel?` | 后中座椅加热 |
| `seatHeaterRearRight` | `SeatHeaterLevel?` | 后右座椅加热 |
| `seatHeaterRearLeftBack` | `SeatHeaterLevel?` | 后左座椅靠背加热 |
| `seatHeaterRearRightBack` | `SeatHeaterLevel?` | 后右座椅靠背加热 |
| `seatHeaterThirdRowLeft` | `SeatHeaterLevel?` | 第三排左座椅加热 |
| `seatHeaterThirdRowRight` | `SeatHeaterLevel?` | 第三排右座椅加热 |
| `autoSeatClimateLeft` | `Bool?` | 前左座椅自动气候启用 |
| `autoSeatClimateRight` | `Bool?` | 前右座椅自动气候启用 |
| `seatFanFrontLeft` | `Int?` | 前左座椅通风档位 |
| `seatFanFrontRight` | `Int?` | 前右座椅通风档位 |

##### 方向盘 / 雨刷 / 后视镜 / 电池加热

| 字段 | 类型 | 说明 |
|---|---|---|
| `steeringWheelHeater` | `Bool?` | 方向盘加热（旧版布尔） |
| `autoSteeringWheelHeat` | `Bool?` | 自动方向盘加热启用 |
| `steeringWheelHeatLevel` | `SteeringWheelHeatLevel?` | 方向盘加热档位：`unknown / off / low / high` |
| `wiperBladeHeater` | `Bool?` | 雨刷加热（Cybertruck / Refresh） |
| `sideMirrorHeaters` | `Bool?` | 后视镜加热 |
| `isBatteryHeaterOn` | `Bool?` | 高压电池加热运行中 |
| `isBatteryHeaterNoPower` | `Bool?` | 电池加热当前无法取电 |

##### 座舱过热保护 (COP)

| 字段 | 类型 | 说明 |
|---|---|---|
| `allowCabinOverheatProtection` | `Bool?` | 用户在设置中已启用 COP |
| `supportsFanOnlyCabinOverheatProtection` | `Bool?` | 硬件支持仅风扇模式 |
| `cabinOverheatProtection` | `CabinOverheatProtectionMode?` | 当前 COP 模式：`off / on / fanOnly` |
| `cabinOverheatProtectionActivelyCooling` | `Bool?` | 当前正在主动制冷 |
| `copActivationTemperature` | `CopActivationTemperature?` | 触发温度阈值：`unspecified / low / medium / high` |
| `copNotRunningReason` | `CopNotRunningReason?` | 未运行原因：`noReason / userInteraction / energyConsumptionReached / timeout / lowSolarLoad / fault / cabinBelowThreshold` |

#### 3.1.3 行驶 (`.drive` → `snapshot.drive: DriveState`) — 推荐用 `client.fetchDrive()` 单独读

| 字段 | 类型 | 说明 |
|---|---|---|
| `shiftState` | `ShiftState?` | 档位：`park / reverse / neutral / drive` |
| `speedMph` | `Double?` | 当前对地车速（mph） |
| `powerKW` | `Int?` | 瞬时驱动功率（kW，回收为负） |
| `odometerHundredthsMile` | `Int?` | 总里程（**1/100 mile**，除以 100 得到 mile） |
| `activeRouteDestination` | `String?` | 导航目的地名称（若有） |
| `activeRouteMinutesToArrival` | `Double?` | 剩余导航时间（分钟） |
| `activeRouteMilesToArrival` | `Double?` | 剩余导航距离（mile） |
| `activeRouteTrafficMinutesDelay` | `Double?` | 路线上因拥堵增加的分钟数 |
| `activeRouteEnergyAtArrival` | `Double?` | 抵达时预计剩余能量（kWh / 配置单位） |
| `activeRouteCoordinates` | `Coordinate?` | 导航目的地坐标 |
| `lastRouteUpdateSecondsSinceEpoch` | `UInt32?` | 上次路线 ETA / 距离刷新时间（Unix 秒） |
| `lastTrafficUpdateSecondsSinceEpoch` | `Int64?` | 上次流量延迟刷新时间（Unix 秒） |
| `timestampSecondsSinceEpoch` | `Int64?` | 本快照在车端的时间戳（Unix 秒） |

#### 3.1.4 GPS (`.location` → `snapshot.location: LocationState`)

| 字段 | 类型 | 说明 |
|---|---|---|
| `latitude` | `Double?` | 主纬度（十进制度） |
| `longitude` | `Double?` | 主经度（十进制度） |
| `headingDegrees` | `Double?` | 航向角（顺时针自正北 0–359°） |
| `gpsAsOfSecondsSinceEpoch` | `UInt64?` | GPS 定位时间戳（Unix 秒） |
| `correctedLatitude` | `Double?` | 车端修正后纬度（通常 snap-to-road） |
| `correctedLongitude` | `Double?` | 车端修正后经度 |
| `nativeLatitude` | `Double?` | GPS 原始纬度（修正前） |
| `nativeLongitude` | `Double?` | GPS 原始经度（修正前） |
| `homelinkNearby` | `Bool?` | 已配对的 Homelink 设备在附近 |
| `locationName` | `String?` | 当前位置的可读名称（若已知） |
| `geoLatitude` | `Double?` | 地理编码后的纬度（如 map-matched） |
| `geoLongitude` | `Double?` | 地理编码后的经度 |
| `geoHeadingDegrees` | `Double?` | 地理编码后的航向角（°） |
| `geoElevationMeters` | `Double?` | 地理编码后的海拔（米） |
| `geoAccuracyMeters` | `Double?` | 地理位置精度半径（米，越小越好） |
| `estimatedGpsValid` | `Bool?` | 车辆航位推算估计当前是否有效 |

#### 3.1.5 门窗 / 哨兵 / 限速 (`.closures` → `snapshot.closures: ClosuresState`)

##### 车门 / 备厢 / 锁

| 字段 | 类型 | 说明 |
|---|---|---|
| `frontDriverDoor` | `Bool?` | 前左车门打开（`true`=开） |
| `frontPassengerDoor` | `Bool?` | 前右车门打开 |
| `rearDriverDoor` | `Bool?` | 后左车门打开 |
| `rearPassengerDoor` | `Bool?` | 后右车门打开 |
| `frontTrunk` | `Bool?` | 前备厢（frunk）打开 |
| `rearTrunk` | `Bool?` | 后备厢打开 |
| `locked` | `Bool?` | 当前是否上锁 |

##### 车窗

| 字段 | 类型 | 说明 |
|---|---|---|
| `windowDriverFront` | `Bool?` | 前左车窗未完全闭合 |
| `windowPassengerFront` | `Bool?` | 前右车窗未完全闭合 |
| `windowDriverRear` | `Bool?` | 后左车窗未完全闭合 |
| `windowPassengerRear` | `Bool?` | 后右车窗未完全闭合 |

##### 天窗 / 卷帘

| 字段 | 类型 | 说明 |
|---|---|---|
| `sunroofState` | `SunroofState?` | 天窗位置：`closed / open / vent / moving / calibrating / unknown` |
| `sunroofPercentOpen` | `Int?` | 天窗开度（0=完全关，100=完全开） |
| `tonneauState` | `TonneauState?` | 卷帘位置：`closed / open / ajar / unknown / failedUnlatch / opening / closing` |
| `tonneauPercentOpen` | `Int?` | 卷帘开度（0–100） |
| `tonneauInMotion` | `Bool?` | 卷帘正在移动 |

##### 中控 / 哨兵 / 远程启动 / 代客

| 字段 | 类型 | 说明 |
|---|---|---|
| `centerDisplayState` | `DisplayState?` | 中控屏状态：`off / dim / accessory / on / driving / charging / lock / sentry / dog / entertainment` |
| `sentryModeActive` | `Bool?` | 哨兵模式当前已激活 |
| `sentryModeAvailable` | `Bool?` | 车辆硬件 / 固件支持哨兵 |
| `remoteStart` | `Bool?` | 远程启动会话进行中 |
| `valetMode` | `Bool?` | 代客模式启用 |
| `valetPinNeeded` | `Bool?` | 退出代客模式需要 PIN |
| `isUserPresent` | `Bool?` | 检测到乘员在车 |

##### 限速模式 (`speedLimit: SpeedLimitMode?`)

| 字段 | 类型 | 说明 |
|---|---|---|
| `active` | `Bool?` | 限速模式当前已生效 |
| `pinCodeSet` | `Bool?` | 已设置该模式的 PIN |
| `maxLimitMph` | `Double?` | 可设最高限速（mph） |
| `minLimitMph` | `Double?` | 可设最低限速（mph） |
| `currentLimitMph` | `Double?` | 当前限速值（mph） |

#### 3.1.6 充电计划 (`.chargeSchedule` → `snapshot.chargeSchedule: ChargeScheduleState`)

##### 顶层

| 字段 | 类型 | 说明 |
|---|---|---|
| `schedules` | `[ChargeScheduleEntry]` | 当前已保存的全部充电计划 |
| `pendingScheduleWindow` | `ChargeScheduleEntry?` | 用户正在编辑的临时计划 |
| `chargeBufferMinutes` | `Int?` | 计划开始前预留的缓冲分钟数 |
| `maxScheduleCount` | `UInt32?` | 车辆可保存的最大计划条数 |
| `nextScheduleEnabled` | `Bool?` | 下一条计划是否会被执行 |
| `showScheduleCompleteState` | `Bool?` | 是否在车机 UI 显示"计划完成"状态 |
| `timestampSecondsSinceEpoch` | `Int64?` | 该段最后更新时间（Unix 秒） |

##### 单条计划 `ChargeScheduleEntry`（proto3 标量，无 optional 包装；不存在的字段为 0/false）

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `UInt64` | 计划标识，上游为 epoch 时间戳 |
| `name` | `String` | 用户配置的可读名称 |
| `daysOfWeek` | `Int32` | 星期位掩码（语义沿用上游） |
| `startEnabled` | `Bool` | 是否配置了开始时间 |
| `startTimeMinutes` | `Int32` | 开始时间，午夜偏移（分钟） |
| `endEnabled` | `Bool` | 是否配置了结束时间 |
| `endTimeMinutes` | `Int32` | 结束时间，午夜偏移（分钟） |
| `oneTime` | `Bool` | 单次执行后自动失效 |
| `enabled` | `Bool` | 当前是否已启用 |
| `latitude` | `Float` | 围栏纬度，未设为 0 |
| `longitude` | `Float` | 围栏经度，未设为 0 |

#### 3.1.7 预热计划 (`.preconditioningSchedule` → `snapshot.preconditionSchedule: PreconditionScheduleState`)

##### 顶层

| 字段 | 类型 | 说明 |
|---|---|---|
| `schedules` | `[PreconditionScheduleEntry]` | 当前已保存的全部预热计划 |
| `pendingScheduleWindow` | `PreconditionScheduleEntry?` | 用户正在编辑的临时计划 |
| `maxScheduleCount` | `UInt32?` | 车辆可保存的最大计划条数 |
| `nextScheduleEnabled` | `Bool?` | 下一条计划是否会执行 |
| `timestampSecondsSinceEpoch` | `Int64?` | 该段最后更新时间（Unix 秒） |

##### 单条计划 `PreconditionScheduleEntry`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `UInt64` | 计划标识，上游为 epoch 时间戳 |
| `name` | `String` | 用户配置的可读名称 |
| `daysOfWeek` | `Int32` | 星期位掩码 |
| `preconditionTimeMinutes` | `Int32` | 预热完成时间，午夜偏移（分钟） |
| `oneTime` | `Bool` | 单次执行后自动失效 |
| `enabled` | `Bool` | 当前是否启用 |
| `latitude` | `Float` | 围栏纬度，未设为 0 |
| `longitude` | `Float` | 围栏经度，未设为 0 |

#### 3.1.8 胎压 (`.tirePressure` → `snapshot.tirePressure: TirePressureState`)

##### 四轮（每轮 `Tire?`，类型见下表）

| 字段 | 类型 | 说明 |
|---|---|---|
| `frontLeft` | `Tire?` | 前左轮读数 |
| `frontRight` | `Tire?` | 前右轮读数 |
| `rearLeft` | `Tire?` | 后左轮读数 |
| `rearRight` | `Tire?` | 后右轮读数 |
| `recommendedColdFrontBar` | `Double?` | 前轴推荐冷胎压（bar） |
| `recommendedColdRearBar` | `Double?` | 后轴推荐冷胎压（bar） |

##### `Tire` 子结构

| 字段 | 类型 | 说明 |
|---|---|---|
| `pressureBar` | `Double?` | 实测胎压（bar） |
| `hasWarning` | `Bool?` | 该轮存在 TPMS 软告警或硬告警 |

#### 3.1.9 媒体摘要 (`.media` → `snapshot.media: MediaState`)

| 字段 | 类型 | 说明 |
|---|---|---|
| `nowPlayingArtist` | `String?` | 正在播放的艺术家名 |
| `nowPlayingTitle` | `String?` | 正在播放的曲目标题 |
| `audioVolume` | `Double?` | 当前音量（车端原始刻度） |
| `audioVolumeIncrement` | `Double?` | 音量调节最小步进（同一刻度） |
| `audioVolumeMax` | `Double?` | 最大音量值（同一刻度） |
| `remoteControlEnabled` | `Bool?` | 当前是否允许远程媒体控制 |
| `nowPlayingSource` | `MediaSource?` | 媒体源枚举（蓝牙 / Spotify / TuneIn / FM …），未识别枚举值保留为 `.unknown(Int)` |
| `playbackStatus` | `PlaybackStatus?` | 播放状态：`stopped / playing / paused` |

#### 3.1.10 媒体扩展 (`.mediaDetail` → `snapshot.mediaDetail: MediaDetailState`)

| 字段 | 类型 | 说明 |
|---|---|---|
| `nowPlayingDurationSeconds` | `Double?` | 当前曲目总时长（秒） |
| `nowPlayingElapsedSeconds` | `Double?` | 当前曲目已播放时长（秒） |
| `nowPlayingAlbum` | `String?` | 当前曲目专辑名 |
| `nowPlayingStation` | `String?` | 电台名（仅当源为电台时有值） |
| `nowPlayingSourceName` | `String?` | 媒体源可读名（如 Spotify、TuneIn）；枚举形式见 `MediaState.nowPlayingSource` |
| `a2dpSourceName` | `String?` | 已连接 A2DP 蓝牙源广告的设备名 |

#### 3.1.11 软件更新 (`.softwareUpdate` → `snapshot.softwareUpdate: SoftwareUpdateState`)

| 字段 | 类型 | 说明 |
|---|---|---|
| `version` | `String?` | 当前已安装的固件版本号 |
| `status` | `Status?` | OTA 生命周期状态：`unknown / installing / scheduled / available / downloadingWifiWait / downloading` |
| `downloadPercent` | `Int?` | 下载进度（0–100） |
| `installPercent` | `Int?` | 安装进度（0–100） |
| `expectedDurationSeconds` | `Int?` | 预计安装总时长（秒） |
| `scheduledTimeMs` | `UInt64?` | 计划安装时间（Unix 毫秒） |
| `warningTimeRemainingMs` | `UInt64?` | 距离自动开始安装提示的剩余毫秒（"N 分钟后开始"倒计时） |

#### 3.1.12 家长控制 (`.parentalControls` → `snapshot.parentalControls: ParentalControlsState`)

##### 顶层

| 字段 | 类型 | 说明 |
|---|---|---|
| `active` | `Bool?` | 家长控制当前是否激活 |
| `pinSet` | `Bool?` | 已设置家长控制 PIN |
| `settings` | `ParentalControlsSettings?` | 详细设置子状态 |

##### `ParentalControlsSettings`

| 字段 | 类型 | 说明 |
|---|---|---|
| `speedLimitEnabled` | `Bool?` | 限速强制启用 |
| `maxLimitMph` | `Double?` | 可设最大限速（mph） |
| `minLimitMph` | `Double?` | 可设最小限速（mph） |
| `currentLimitMph` | `Double?` | 当前限速值（mph） |
| `chillAccelerationEnabled` | `Bool?` | 节能加速模式启用（限油门响应） |
| `requireSafetySettingsEnabled` | `Bool?` | 强制开启安全相关设置（稳定 / 牵引控制等） |
| `curfewEnabled` | `Bool?` | 宵禁启用 |
| `curfewStartTime` | `Int?` | 宵禁开始时间（编码沿用上游 proto，通常为日内秒或日内分） |
| `curfewEndTime` | `Int?` | 宵禁结束时间（编码同上） |

### 3.2 行驶快路径 — `client.fetchDrive()`

仅拉取 `.drive` 类别，返回 `DriveState`，**典型延迟 200–500ms**，适合循环轮询车速 / 档位 / 路线。字段定义同 [3.1.3](#313-行驶-drive--snapshotdrive-drivestate--推荐用-clientfetchdrive-单独读)。

### 3.3 结构化查询 — `client.query(_:)`

不走 `fetch` 那一套类别合并，每个 case 自己有专属返回类型：

| Query | 返回类型 | 用途 / 备注 |
|---|---|---|
| `.keySummary` | `KeyWhitelistInfo` | 列出 VCSEC 白名单所有钥匙的 SHA-1 摘要 + 槽位掩码 |
| `.keyInfo(slot:)` | `KeyWhitelistEntry` | 查指定槽位的钥匙详情（公钥 / 角色 / 形态） |
| `.keyInfoByPublicKey(publicKey:)` | `KeyWhitelistEntry` | 同上，按 65 字节 SEC1 公钥（`0x04 ‖ X ‖ Y`）查 |
| `.keyInfoByKeyID(publicKeySha1:)` | `KeyWhitelistEntry` | 同上，按 SHA-1 摘要查（一般 4 字节） |
| `.bodyControllerState` | `BodyControllerState` | VCSEC 车身状态（门窗 + 锁 + 用户在场 + 睡眠 + 卷帘开度）；**车机睡眠时仍可查** |
| `.nearbyCharging(includeMetadata:, radiusMiles:, count:)` | `NearbyChargingSites` | 附近超充站列表。**注意 BLE 响应有 MTU 限制**，建议显式传小 `count`（5–10）并把 `includeMetadata` 设为 `false` |
| `.ping(id:)` | `PingResult` | 应用层 ping，可测往返延迟 / 时钟偏差 |

每个返回类型的字段如下。

#### 3.3.1 `KeyWhitelistInfo`

| 字段 | 类型 | 说明 |
|---|---|---|
| `numberOfEntries` | `UInt32` | 已注册的钥匙总数 |
| `entries` | `[KeyIdentifier]` | 每把钥匙一项标识符，按车端报告顺序 |
| `slotMask` | `UInt32` | 占用槽位位掩码：bit `i` 置 1 = 槽位 `i` 已占用 |

##### `KeyIdentifier`

| 字段 | 类型 | 说明 |
|---|---|---|
| `publicKeySha1` | `Data` | 钥匙未压缩 P-256 公钥的 SHA-1 摘要（车端通常用 4 字节截断） |

#### 3.3.2 `KeyWhitelistEntry`

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyIdentifier` | `KeyIdentifier?` | 钥匙公钥的 SHA-1 标识 |
| `publicKey` | `Data?` | 原始公钥字节（65 字节 SEC1 未压缩，`0x04 ‖ X ‖ Y`） |
| `formFactor` | `KeyFormFactor?` | 形态：`unknown / nfcCard / iosDevice / androidDevice / cloudKey / unrecognized(Int)` |
| `slot` | `UInt32` | 占用的白名单槽位号 |
| `role` | `KeyRole` | 角色：`none / service / owner / driver / fleetManager / vehicleMonitor / chargingManager / guest / unrecognized(Int)` |

#### 3.3.3 `BodyControllerState`

| 字段 | 类型 | 说明 |
|---|---|---|
| `closures` | `ClosureStatuses` | 8 个开口部件的位置状态（结构见下） |
| `lockState` | `LockState` | 总体锁状态：`unlocked / locked / internalLocked / selectiveUnlocked / unrecognized(Int)` |
| `sleepStatus` | `SleepStatus` | Infotainment 睡眠状态：`unknown / awake / asleep / unrecognized(Int)`。该状态可能滞后实际 MCU 状态约 30 秒 |
| `userPresence` | `UserPresence` | VCSEC 检测到的用户在场情况：`unknown / notPresent / present / unrecognized(Int)` |
| `tonneauPercentOpen` | `UInt32?` | 卷帘开度（0–100），车辆未上报 `detailedClosureStatus` 时为 nil |

##### `ClosureStatuses`（每项类型为 `ClosureState`）

| 字段 | 类型 | 说明 |
|---|---|---|
| `frontDriverDoor` | `ClosureState` | 前左车门 |
| `frontPassengerDoor` | `ClosureState` | 前右车门 |
| `rearDriverDoor` | `ClosureState` | 后左车门 |
| `rearPassengerDoor` | `ClosureState` | 后右车门 |
| `rearTrunk` | `ClosureState` | 后备厢 |
| `frontTrunk` | `ClosureState` | 前备厢 |
| `chargePort` | `ClosureState` | 充电口 |
| `tonneau` | `ClosureState` | 卷帘 |

`ClosureState`：`closed / open / ajar / unknown / failedUnlatch / opening / closing / unrecognized(Int)`

#### 3.3.4 `NearbyChargingSites`

| 字段 | 类型 | 说明 |
|---|---|---|
| `timestampSecondsSinceEpoch` | `Int64?` | 车端生成快照的时间（Unix 秒） |
| `superchargers` | `[Supercharger]` | 返回的超充站列表 |
| `congestionSyncTimeSecondsSinceEpoch` | `Int64` | 上次车位拥堵同步时间（Unix 秒），未上报为 0 |

##### `Supercharger`（proto3 标量，全部非 Optional；零值表示"未上报或字面 0"）

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `Int64` | Tesla 站点标识 |
| `name` | `String` | 站点显示名称 |
| `location` | `Coordinate?` | 站点地理坐标 |
| `distanceMiles` | `Float` | 与车辆当前位置距离（mile） |
| `availableStalls` | `Int32` | 可用车位数；`-1` 表示"可用性未知" |
| `totalStalls` | `Int32` | 站点车位总数 |
| `outOfOrderStallsNumber` | `Int32` | 故障车位数 |
| `outOfOrderStallsNames` | `String` | 故障车位名称（逗号分隔） |
| `maxPowerKw` | `Int32` | 单桩最大功率（kW），未上报为 0 |
| `siteClosed` | `Bool` | 站点已关闭 |
| `withinRange` | `Bool` | 当前续航可达 |
| `amenities` | `String` | 周边设施（车端 UI 自由文本） |
| `billingInfo` | `String` | 计费信息（自由文本） |
| `billingTime` | `String` | 计费时段（自由文本） |
| `streetAddress` | `String` | 街道地址 |
| `city` | `String` | 城市 |
| `district` | `String` | 行政区 |
| `state` | `String` | 省 / 州 |
| `postalCode` | `String` | 邮编 |
| `country` | `String` | 国家（车端报告的 ISO 名称） |

#### 3.3.5 `PingResult`

| 字段 | 类型 | 说明 |
|---|---|---|
| `pingID` | `Int32` | 车辆原样回显的 ping 标识，用于多路 ping 关联 |
| `localTimestampSecondsSinceEpoch` | `Int64?` | 车端本地时间戳（Unix 秒） |
| `lastRemoteTimestampSecondsSinceEpoch` | `Int64?` | 车辆收到的客户端最近一次时间戳（Unix 秒） |

---

## 四、回调机制

| 通道 | 推送内容 | 备注 |
|---|---|---|
| `client.stateStream: AsyncStream<ConnectionState>` | 连接状态变化 | 唯一内置 push API |
| **车辆数据** | — | **协议层不支持订阅**，必须由调用方轮询 `fetchDrive()` / `fetch(_:)` |

---

## 五、协议 / 工程约束

- **公共 API 不暴露 `Generated/*_pb.swift` 类型**：所有车辆数据都被 `Model/*State.swift` 包成 Swift 原生结构。
- **VIN 与 BLE 设备名匹配**：`VINHelper.bleLocalName(for:) = "S" + lowercase-hex(SHA1(vin)[0..<8]) + "C"`。
- **私钥存储**：`KeychainTeslaKeyStore` 默认使用 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`，不上 iCloud、不跨设备迁移。
- **每个 `TeslaVehicleClient` 绑定一个 VIN**；切换车辆需重建实例。
- **`fetch(.all)` 多类别拆分单次请求**：合并响应在真车上会被拒绝（`RESPONSE_MTU_EXCEEDED`），底层已自动按类别拆分。
- **`query(.nearbyCharging)` 单条响应**：不能拆分；如果取的列表过大会被车辆拒绝，请显式控制 `count`。

---

## 六、当前未提供 / 协议本身不支持

| 项 | 原因 |
|---|---|
| 主动接收车辆遥测 push | Tesla BLE 协议不支持 subscribe/notify 业务数据 |
| 读取 VIN | 协议不返回；VIN 只能作为输入 |
| 读取 GuiSettings / VehicleConfig | 这些字段仅云端 REST API 才有，BLE 不暴露 |
| 一个 client 同时管理多 VIN | actor 设计绑定单 VIN |
| 自动重试 / 自动轮询封装 | 需调用方按需在外层实现 |
