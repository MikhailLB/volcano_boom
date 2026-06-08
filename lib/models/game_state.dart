import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements.dart';
import '../data/upgrades.dart';
import '../data/volcanoes.dart';

/// Data passed to the UI whenever an eruption happens, so it can play effects.
class EruptEvent {
  final double reward;
  final bool crit;
  EruptEvent(this.reward, this.crit);
}

/// The single source of truth for the entire game. Extends [ChangeNotifier]
/// so widgets can rebuild via [ListenableBuilder].
class GameState extends ChangeNotifier {
  GameState._();
  static final GameState instance = GameState._();

  static const String _saveKey = 'volcano_boom_save_v1';
  static const double prestigeThreshold = 1000000; // 1M lava earned this run
  static const int offlineCapSeconds = 8 * 3600;

  final Random _rng = Random();
  SharedPreferences? _prefs;

  // ---- Currency & progress ----
  double lava = 0;
  double totalLavaEarned = 0;
  double lavaEarnedThisRun = 0;
  int magmaCores = 0;

  // ---- Upgrade levels ----
  final Map<UpgradeId, int> levels = {
    UpgradeId.tapPower: 0,
    UpgradeId.pressureCap: 0,
    UpgradeId.autoErupt: 0,
    UpgradeId.combo: 0,
    UpgradeId.crit: 0,
  };

  // ---- Volcanoes ----
  Set<int> unlocked = {0};
  int selectedVolcano = 0;

  // ---- Live gameplay ----
  double pressure = 0;
  double comboValue = 1.0;
  double _comboTimer = 0;

  // ---- Stats ----
  int totalTaps = 0;
  int totalEruptions = 0;
  int prestigeCount = 0;
  double bestCombo = 1.0;
  int sessionStart = DateTime.now().millisecondsSinceEpoch;

  // ---- Achievements & daily ----
  Set<String> claimedAchievements = {};
  int lastDailyClaimMs = 0;
  int dailyStreak = 0;

  // ---- Settings ----
  bool soundOn = true;
  bool hapticsOn = true;
  bool firstRunDone = false;

  // ---- Transient (not saved) ----
  double pendingOfflineEarnings = 0;
  final List<EruptEvent> pendingErupts = [];
  final List<String> pendingAchievementToasts = [];
  int lastSeenMs = 0;

  // =================== Derived values ===================

  VolcanoDef get currentVolcano => kVolcanoes[selectedVolcano];

  double get tapPower => 5 + levels[UpgradeId.tapPower]! * 4;

  double get pressureCap => 50 + levels[UpgradeId.pressureCap]! * 30;

  double get volcanoMultiplier => currentVolcano.multiplier;

  double get prestigeMultiplier => 1 + magmaCores * 0.08;

  double get globalMultiplier => volcanoMultiplier * prestigeMultiplier;

  double get maxCombo => 2.0 + levels[UpgradeId.combo]! * 0.5;

  double get comboDuration => 1.2 + levels[UpgradeId.combo]! * 0.12;

  double get critChance => min(0.6, levels[UpgradeId.crit]! * 0.03);

  double get critMultiplier => 5 + levels[UpgradeId.crit]! * 0.5;

  double get autoPerSec {
    final int lvl = levels[UpgradeId.autoErupt]!;
    if (lvl <= 0) return 0;
    return lvl * 0.08 * pressureCap * globalMultiplier;
  }

  /// Average lava produced per eruption (without crit), for previews.
  double get eruptionBaseReward => pressureCap * globalMultiplier;

  double get pressureFraction => (pressure / pressureCap).clamp(0.0, 1.0);

  bool get canPrestige => lavaEarnedThisRun >= prestigeThreshold;

  int get pendingCores {
    if (lavaEarnedThisRun < prestigeThreshold) return 0;
    final int total = sqrt(lavaEarnedThisRun / prestigeThreshold).floor();
    return max(0, total - 0); // cores granted on this run
  }

  double upgradeCost(UpgradeId id) => kUpgrades[id]!.costForLevel(levels[id]!);

  bool canAfford(double cost) => lava >= cost;

  // =================== Persistence ===================

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final String? raw = _prefs!.getString(_saveKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
        lava = (j['lava'] as num?)?.toDouble() ?? 0;
        totalLavaEarned = (j['totalLavaEarned'] as num?)?.toDouble() ?? 0;
        lavaEarnedThisRun = (j['lavaEarnedThisRun'] as num?)?.toDouble() ?? 0;
        magmaCores = (j['magmaCores'] as num?)?.toInt() ?? 0;
        final Map<String, dynamic> lv = (j['levels'] as Map?)?.cast<String, dynamic>() ?? {};
        for (final id in UpgradeId.values) {
          levels[id] = (lv[id.name] as num?)?.toInt() ?? 0;
        }
        unlocked = ((j['unlocked'] as List?)?.map((e) => (e as num).toInt()).toSet()) ?? {0};
        unlocked.add(0);
        selectedVolcano = (j['selectedVolcano'] as num?)?.toInt() ?? 0;
        if (!unlocked.contains(selectedVolcano)) selectedVolcano = 0;
        totalTaps = (j['totalTaps'] as num?)?.toInt() ?? 0;
        totalEruptions = (j['totalEruptions'] as num?)?.toInt() ?? 0;
        prestigeCount = (j['prestigeCount'] as num?)?.toInt() ?? 0;
        bestCombo = (j['bestCombo'] as num?)?.toDouble() ?? 1.0;
        claimedAchievements = ((j['achievements'] as List?)?.map((e) => e.toString()).toSet()) ?? {};
        lastDailyClaimMs = (j['lastDailyClaimMs'] as num?)?.toInt() ?? 0;
        dailyStreak = (j['dailyStreak'] as num?)?.toInt() ?? 0;
        soundOn = j['soundOn'] as bool? ?? true;
        hapticsOn = j['hapticsOn'] as bool? ?? true;
        firstRunDone = j['firstRunDone'] as bool? ?? false;
        lastSeenMs = (j['lastSeenMs'] as num?)?.toInt() ?? 0;

        // Offline earnings.
        if (lastSeenMs > 0 && autoPerSec > 0) {
          final int now = DateTime.now().millisecondsSinceEpoch;
          final int elapsed = ((now - lastSeenMs) / 1000).floor();
          final int capped = elapsed.clamp(0, offlineCapSeconds);
          if (capped > 30) {
            pendingOfflineEarnings = autoPerSec * capped;
          }
        }
      } catch (_) {
        // Corrupt save: start fresh but keep going.
      }
    }
    sessionStart = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
        'lava': lava,
        'totalLavaEarned': totalLavaEarned,
        'lavaEarnedThisRun': lavaEarnedThisRun,
        'magmaCores': magmaCores,
        'levels': {for (final e in levels.entries) e.key.name: e.value},
        'unlocked': unlocked.toList(),
        'selectedVolcano': selectedVolcano,
        'totalTaps': totalTaps,
        'totalEruptions': totalEruptions,
        'prestigeCount': prestigeCount,
        'bestCombo': bestCombo,
        'achievements': claimedAchievements.toList(),
        'lastDailyClaimMs': lastDailyClaimMs,
        'dailyStreak': dailyStreak,
        'soundOn': soundOn,
        'hapticsOn': hapticsOn,
        'firstRunDone': firstRunDone,
        'lastSeenMs': DateTime.now().millisecondsSinceEpoch,
      };

  Future<void> save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_saveKey, jsonEncode(_toJson()));
  }

  void claimOfflineEarnings() {
    if (pendingOfflineEarnings <= 0) return;
    _addLava(pendingOfflineEarnings);
    pendingOfflineEarnings = 0;
    _checkAchievements();
    notifyListeners();
    save();
  }

  // =================== Core gameplay ===================

  void _addLava(double amount) {
    lava += amount;
    totalLavaEarned += amount;
    lavaEarnedThisRun += amount;
  }

  /// A single tap on the volcano. Returns the number of eruptions triggered.
  int tap() {
    totalTaps++;
    // Build combo.
    final double step = (maxCombo - 1) / 14.0;
    comboValue = min(maxCombo, comboValue + step);
    _comboTimer = comboDuration;
    if (comboValue > bestCombo) bestCombo = comboValue;

    pressure += tapPower;
    int erupts = 0;
    while (pressure >= pressureCap) {
      pressure -= pressureCap;
      _erupt();
      erupts++;
      if (erupts > 50) break; // safety
    }
    _checkAchievements();
    notifyListeners();
    return erupts;
  }

  void _erupt() {
    final bool crit = _rng.nextDouble() < critChance;
    double reward = pressureCap * globalMultiplier * comboValue;
    if (crit) reward *= critMultiplier;
    _addLava(reward);
    totalEruptions++;
    pendingErupts.add(EruptEvent(reward, crit));
  }

  /// Advances passive systems. [dt] in seconds.
  void tick(double dt) {
    bool changed = false;
    // Auto income.
    final double auto = autoPerSec;
    if (auto > 0) {
      _addLava(auto * dt);
      changed = true;
    }
    // Combo decay.
    if (comboValue > 1.0) {
      if (_comboTimer > 0) {
        _comboTimer -= dt;
      } else {
        comboValue = max(1.0, comboValue - dt * 1.8);
      }
      changed = true;
    }
    if (changed) {
      _maybeCheckAchievements();
      notifyListeners();
    }
  }

  int _achTickCounter = 0;
  void _maybeCheckAchievements() {
    // Throttle achievement checks during ticks for performance.
    if (++_achTickCounter % 30 == 0) _checkAchievements();
  }

  // =================== Shop / volcanoes ===================

  bool buyUpgrade(UpgradeId id) {
    final def = kUpgrades[id]!;
    if (def.isMaxed(levels[id]!)) return false;
    final double cost = upgradeCost(id);
    if (lava < cost) return false;
    lava -= cost;
    levels[id] = levels[id]! + 1;
    _checkAchievements();
    notifyListeners();
    save();
    return true;
  }

  bool unlockVolcano(int index) {
    if (unlocked.contains(index)) return false;
    final def = kVolcanoes[index];
    if (lava < def.unlockCost) return false;
    lava -= def.unlockCost;
    unlocked.add(index);
    selectedVolcano = index;
    _checkAchievements();
    notifyListeners();
    save();
    return true;
  }

  void selectVolcano(int index) {
    if (!unlocked.contains(index)) return;
    selectedVolcano = index;
    notifyListeners();
    save();
  }

  // =================== Prestige ===================

  bool prestige() {
    if (!canPrestige) return false;
    final int gained = pendingCores;
    if (gained <= 0) return false;
    magmaCores += gained;
    prestigeCount++;
    // Reset run progress but keep collection, cores, stats and achievements.
    lava = 0;
    lavaEarnedThisRun = 0;
    pressure = 0;
    comboValue = 1.0;
    for (final id in UpgradeId.values) {
      levels[id] = 0;
    }
    selectedVolcano = 0;
    _checkAchievements();
    notifyListeners();
    save();
    return true;
  }

  // =================== Daily reward ===================

  bool get dailyAvailable {
    if (lastDailyClaimMs == 0) return true;
    final int now = DateTime.now().millisecondsSinceEpoch;
    return now - lastDailyClaimMs >= 20 * 3600 * 1000;
  }

  Duration get dailyCooldown {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int next = lastDailyClaimMs + 20 * 3600 * 1000;
    return Duration(milliseconds: max(0, next - now));
  }

  /// Reward grows with streak. Scales with current eruption power so it stays
  /// relevant in the late game.
  double dailyReward(int streak) {
    final double base = max(1000, eruptionBaseReward * 12);
    return base * (1 + streak * 0.5);
  }

  double claimDaily() {
    if (!dailyAvailable) return 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    // Streak continues if claimed within 44h, otherwise resets.
    if (lastDailyClaimMs != 0 && now - lastDailyClaimMs <= 44 * 3600 * 1000) {
      dailyStreak = (dailyStreak % 7) + 1;
    } else {
      dailyStreak = 1;
    }
    final double reward = dailyReward(dailyStreak);
    _addLava(reward);
    lastDailyClaimMs = now;
    _checkAchievements();
    notifyListeners();
    save();
    return reward;
  }

  // =================== Achievements ===================

  double _metric(AchMetric m) {
    switch (m) {
      case AchMetric.taps:
        return totalTaps.toDouble();
      case AchMetric.eruptions:
        return totalEruptions.toDouble();
      case AchMetric.lavaEarned:
        return totalLavaEarned;
      case AchMetric.volcanoes:
        return unlocked.length.toDouble();
      case AchMetric.prestige:
        return prestigeCount.toDouble();
      case AchMetric.bestCombo:
        return bestCombo;
      case AchMetric.autoLevel:
        return levels[UpgradeId.autoErupt]!.toDouble();
    }
  }

  double achievementProgress(AchievementDef a) => (_metric(a.metric) / a.target).clamp(0.0, 1.0);

  bool isAchievementClaimed(String id) => claimedAchievements.contains(id);

  bool isAchievementComplete(AchievementDef a) => _metric(a.metric) >= a.target;

  void _checkAchievements() {
    for (final a in kAchievements) {
      if (!claimedAchievements.contains(a.id) && _metric(a.metric) >= a.target) {
        claimedAchievements.add(a.id);
        lava += a.reward;
        totalLavaEarned += a.reward;
        lavaEarnedThisRun += a.reward;
        pendingAchievementToasts.add(a.name);
      }
    }
  }

  // =================== Settings ===================

  void setSound(bool v) {
    soundOn = v;
    notifyListeners();
    save();
  }

  void setHaptics(bool v) {
    hapticsOn = v;
    notifyListeners();
    save();
  }

  void markFirstRunDone() {
    firstRunDone = true;
    save();
  }

  /// Wipes all progress (used by settings "reset").
  Future<void> hardReset() async {
    lava = 0;
    totalLavaEarned = 0;
    lavaEarnedThisRun = 0;
    magmaCores = 0;
    for (final id in UpgradeId.values) {
      levels[id] = 0;
    }
    unlocked = {0};
    selectedVolcano = 0;
    pressure = 0;
    comboValue = 1.0;
    totalTaps = 0;
    totalEruptions = 0;
    prestigeCount = 0;
    bestCombo = 1.0;
    claimedAchievements = {};
    lastDailyClaimMs = 0;
    dailyStreak = 0;
    firstRunDone = false;
    notifyListeners();
    await save();
  }
}
