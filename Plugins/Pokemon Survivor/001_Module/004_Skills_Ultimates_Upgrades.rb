#===============================================================================
# Pokemon Survivor - skills, bursts and run upgrades
#===============================================================================
module PokemonSurvivor
  SKILLS = {
    :psychic_well => {
      name: "Psy Vortex", desc: "Homing Psychic shots leave small fields that pull enemies in and deal repeated damage.",
      kind: :projectile, type: :PSYCHIC, cooldown: 1.8, damage: 26,
      speed: 5.0, count: 1, max_count: 5, pierce: 1, homing: true,
      psychic_well: true, well_damage: 12, well_radius: 30, well_duration: 2.0,
      vfx: "VFX_PSYCHIC5", vfx_frames: 6, vfx_loop: true
    },
    :headache => {
      name: "Headache", desc: "An unpredictable Psychic charge that briefly stops you and can blast up to 12 enemies. Golduck skips the charge; other Pokemon must reach their full potential.",
      kind: :psychic_headache, type: :PSYCHIC, cooldown: 2.5, damage: 90,
      radius: 58, count: 1, max_count: 6, vfx: "VFX_PSYCHIC6",
      vfx_frames: 8, vfx_fps: 12.0, vfx_loop: false, vfx_radius: 40.0
    },
    :night_raid => {
      name: "Night Raid", desc: "Dark sweeps strike nearby enemies and push them back once.",
      kind: :survivor_swing, type: :DARK, cooldown: 0.90, damage: 18, radius: 34,
      count: 1, max_count: 6, knockback: 38, knock_limit: 1, duration: 0.70,
      arc: Math::PI * 2.0, spin_speed: 0.0, full_swing: false, radial_hit: true,
      vfx: "VFX_DARK7", vfx_frames: 21, vfx_fps: 30, vfx_loop: false,
      single_row_vfx: true, visual_offset_mult: 1.28, hit_radius_mult: 1.0,
      visual_scale: 1.35, visual_radius_base: 48, target_nearest: true
    },
    :psi_trail => {
      name: "Psi Trail", desc: "Dash leaves homing Psychic shots that bounce between enemies. Only Kadabra and Alakazam also fire automatically.",
      kind: :psychic_dash, type: :PSYCHIC, cooldown: 2.0, speed: 5.5, damage: 28,
      count: 1, max_count: 6, pierce: 1, bounce: 2, homing: true,
      vfx: "VFX_PSYCHIC5", vfx_frames: 6, vfx_loop: true
    },
    :night_fang => {
      name: "Night Fang",
      desc: "Dark fangs strike nearby enemies and briefly paralyze them.",
      kind: :survivor_swing, type: :DARK, cooldown: 0.82, damage: 19, radius: 34,
      count: 1, max_count: 6, freeze: 0.65, duration: 0.60,
      arc: Math::PI * 2.0, spin_speed: 0.0, full_swing: false, radial_hit: true,
      vfx: "VFX_DARK5", vfx_fps: 30, vfx_loop: false, visual_offset_mult: 1.28,
      hit_radius_mult: 0.50, visual_scale: 1.35, visual_radius_base: 48, target_nearest: true
    },
    :disciplined_strikes => {
      name: "Disciplined Strikes",
      desc: "Unleashes a flurry of nine light Fighting hits against nearby enemies.",
      kind: :survivor_swing, type: :FIGHTING, cooldown: 1.20, damage: 3, radius: 34,
      count: 1, max_count: 6, duration: 0.60, arc: Math::PI * 2.0,
      spin_speed: 0.0, radial_hit: true, target_nearest: true,
      visual_offset_mult: 1.28, hit_radius_mult: 1.0, visual_scale: 1.35, visual_radius_base: 48,
      vfx: "VFX_FIGHTING6", vfx_frames: 9, vfx_fps: 15, vfx_loop: false,
      single_row_vfx: true, tick_per_frame: true
    },
    :toxic_spark => {
      name: "Toxic Spark", desc: "Electric shots burst for Poison damage and poison nearby enemies.",
      kind: :projectile, type: :ELECTRIC, cooldown: 0.70, speed: 6.7, damage: 13,
      pierce: 1, count: 1, max_count: 5, parallel_shots: true,
      vfx: "VFX_ELECTRIC3", vfx_loop: true, impact_blast: true,
      impact_radius: 32, impact_damage: 10, impact_type: :POISON, impact_dot: 3.0,
      impact_vfx: "VFX_POISON3", impact_vfx_radius: 28.0, impact_frames: 18
    },
    :mischief_sweep => {
      name: "Mischief Sweep", desc: "Sweeps all around you with Dark energy and pushes enemies back.",
      kind: :survivor_swing, type: :DARK, cooldown: 0.64, damage: 16, radius: 34,
      count: 1, max_count: 1, knockback: 34, knock_limit: 2, duration: 0.28,
      arc: 6.283185307179586, spin_speed: 10.0, full_swing: true, ignore_projectile_count: true,
      centered_visual: true, visual_scale: 1.35, visual_radius_base: 48,
      vfx: "VFX_DARK4", vfx_fps: 30, vfx_loop: false
    },
    :fae_bloom => {
      name: "Fae Bloom", desc: "Sends a powerful, growing Fairy wave through enemies before fading away.",
      kind: :fae_bloom, type: :FAIRY, cooldown: 1.30, speed: 3.4, damage: 40,
      radius: 40, pierce: 1, count: 1, max_count: 4, infinite_pierce: true, hit_interval: 9999.0,
      vfx: "VFX_FAIRY3", vfx_frames: 13, vfx_fps: 12.0, vfx_loop: false,
      damage_until_frame: 11, keep_until_expiry: true
    },
    :phantom_warhead => {
      name: "Phantom Warhead", desc: "Fires a powerful Ghost shot that erupts in a Dragon blast. Gains a second shot as your Pokemon develops.",
      kind: :projectile, type: :GHOST, cooldown: 1.10, speed: 6.7, damage: 36,
      pierce: 1, count: 1, max_count: 2, strict_max_count: true, ignore_projectile_count: true,
      evolution_pair: true, vfx: "VFX_GHOST3", vfx_loop: true,
      impact_blast: true, impact_radius: 36, impact_damage: 32,
      impact_type: :DRAGON, impact_vfx: "VFX_DRAGON5", impact_vfx_radius: 27.0
    },
    :iron_gale => {
      name: "Numbing Gale", desc: "Launches drifting Flying tornadoes that repeatedly hit and paralyze each enemy once.",
      kind: :rook_tornado, type: :FLYING, cooldown: 1.40, speed: 1.5, damage: 10,
      radius: 24, pierce: 1, count: 1, max_count: 4, freeze: 0.75,
      freeze_status: :rook_tornado, infinite_pierce: true, hit_interval: 0.45,
      vfx: "VFX_FLYING2", vfx_frames: 52, vfx_fps: 12.0, vfx_loop: false
    },
    :steel_gale => {
      name: "Steel Gale", desc: "Launches drifting Steel tornadoes that repeatedly hit and paralyze each enemy once.",
      kind: :rook_tornado, type: :STEEL, cooldown: 1.40, speed: 1.5, damage: 10,
      radius: 24, pierce: 1, count: 1, max_count: 4, freeze: 0.75,
      freeze_status: :rook_tornado, infinite_pierce: true, hit_interval: 0.45,
      vfx: "VFX_STEEL5", vfx_frames: 52, vfx_fps: 12.0, vfx_loop: false
    },
    :ember_strike => {
      name: "Ember Strike", desc: "Fast fire shots burst on impact, dealing extra area damage and burning enemies.",
      kind: :projectile, type: :FIRE, cooldown: 0.50, speed: 6.7, damage: 8,
      pierce: 1, count: 1, max_count: 4, strict_max_count: true, four_direction_shots: true,
      vfx: "VFX_FIRE5", vfx_loop: true,
      impact_blast: true, impact_radius: 32, impact_damage: 5, burn_time: 3.0
    },
    :apple_aegis => {
      name: "Apple Aegis", desc: "Apples circle you, blocking enemy shots before flying at separate targets. They briefly paralyze enemies on contact.",
      kind: :apple_orbit, type: :GRASS, cooldown: 6.0, orbit_speed: 2.1,
      speed: 6.5, damage: 24, radius: 54, count: 1, max_count: 4, pierce: 1, freeze: 0.65,
      vfx: "VFX_GRASS_ORBIT2", vfx_loop: true
    },
    :prism_sweep => {
      name: "Prism Sweep", desc: "Eevee sweeps at nearby enemies, pushing them back. This exclusive skill changes with its evolution.",
      kind: :eevee_sweep, type: :NORMAL, cooldown: 0.95, damage: 20, radius: 46,
      count: 1, max_count: 4, duration: 0.55, knockback: 36, knockback_limit: 1,
      vfx: "VFX_NORMAL4", vfx_frames: 7, vfx_fps: 24.0, vfx_loop: true, single_row_vfx: true
    },
    :normal_shot => {
      name: "Swift Star",
      desc: "Fires steady normal shots at a reliable pace.",
      kind: :projectile, type: :NORMAL, cooldown: 0.58, speed: 5.4, damage: 12, pierce: 2, count: 1
    },
    :normal_sweep => {
      name: "Rival Sweep",
      desc: "Spins one normal sweep around the Pokemon and cuts nearby enemies.",
      kind: :survivor_swing, type: :NORMAL, cooldown: 0.64, damage: 16, radius: 34,
      count: 1, max_count: 1, knockback: 34, knock_limit: 2, duration: 0.28,
      arc: 6.283185307179586, spin_speed: 10.0, full_swing: true, ignore_projectile_count: true, centered_visual: true, visual_scale: 1.35, visual_radius_base: 48,
      vfx: "VFX_NORMAL3", vfx_fps: 30, vfx_loop: false
    },
    :leaf => {
      name: "Leaf Boomerang",
      desc: "Throws leaves that fly out and return through enemies.",
      kind: :boomerang, type: :GRASS, cooldown: 0.78, speed: 5.0, damage: 11, pierce: 5, count: 1
    },
    :fire => {
      name: "Ember Burst",
      desc: "Throws hot embers that burn through several enemies.",
      kind: :projectile, type: :FIRE, cooldown: 0.52, speed: 5.8, damage: 13, pierce: 4, count: 1
    },
    :flying_gust => {
      name: "Gust Shot",
      desc: "Fires light flying gusts more often than fire attacks.",
      kind: :projectile, type: :FLYING, cooldown: 0.38, speed: 6.2, damage: 6, pierce: 4, count: 1
    },
    :fire2_combo => {
      name: "Flame Combo",
      desc: "Throws quick flames in short volleys.",
      kind: :projectile, type: :FIRE, cooldown: 0.44, speed: 6.1, damage: 12, pierce: 3, count: 1, vfx: "VFX_FIRE2"
    },
    :cinder_swarm => {
      name: "Cinder Swarm",
      desc: "Sends burning wisps that seek enemies and split on impact.",
      kind: :projectile, type: :FIRE, cooldown: 0.84, speed: 4.6, damage: 14, pierce: 2, count: 1, homing: true, split: 3, dot: 2.4, vfx: "VFX_FIRE2"
    },
    :foxfire_seek => {
      name: "Foxfire Arc",
      desc: "Side flames curve into enemies and leave a short burn.",
      kind: :side_seek, type: :FIRE, cooldown: 0.88, speed: 5.7, damage: 13, pierce: 2, count: 2, dot: 2.2, vfx: "VFX_FIRE2"
    },
    :flying_spread => {
      name: "Wing Volley",
      desc: "Fires flying shots around the Pokemon.",
      kind: :nova, type: :FLYING, cooldown: 0.68, speed: 5.8, damage: 7, pierce: 3, count: 6, max_count: 10
    },
    :bug_thread => {
      name: "Silk Sting",
      desc: "Fires sticky bug shots that freeze enemies briefly.",
      kind: :projectile, type: :BUG, cooldown: 0.72, speed: 5.0, damage: 9, pierce: 2, count: 1, freeze: 1.0
    },
    :toxic_thread => {
      name: "Toxic Thread",
      desc: "Fires poisonous bug shots that push enemies back.",
      kind: :projectile, type: :BUG, cooldown: 0.74, speed: 5.1, damage: 9, pierce: 2, count: 1, dot: 3.0, knockback: 36, knock_limit: 1, vfx: "VFX_BUG2"
    },
    :charge_spark => {
      name: "Charge Spark",
      desc: "Charges a large electric orb in front of you, then launches it at a target.",
      kind: :charge_shot, type: :ELECTRIC, cooldown: 3.0, charge_time: 3.0, speed: 7.4, damage: 58, pierce: 1, count: 1, max_count: 4, radius: 11
    },
    :shinx_charge => {
      name: "Spark Break",
      desc: "Charges like Charge Spark, then bursts into homing electric impact shots on contact.",
      kind: :charge_shot, type: :ELECTRIC, cooldown: 3.0, charge_time: 3.0, speed: 7.2, damage: 66, pierce: 1, count: 1, max_count: 4, radius: 11, vfx: "VFX_ELECTRIC2", shot_vfx: "VFX_ELECTRIC2_SHOT", impact_homing: 4, impact_type: :ELECTRIC, impact_vfx: "VFX_ELECTRIC2_SHOT", impact_speed: 6.3
    },
    :rock_pierce => {
      name: "Stone Spear",
      desc: "Throws a heavy stone that pierces and knocks enemies once.",
      kind: :projectile, type: :ROCK, cooldown: 0.92, speed: 5.2, damage: 15, pierce: 5, count: 1, knockback: 58, knock_limit: 1
    },
    :dragon_pierce => {
      name: "Dragon Fang",
      desc: "Fires heavy dragon fangs that pierce and push once.",
      kind: :projectile, type: :DRAGON, cooldown: 1.08, speed: 5.4, damage: 19, pierce: 5, count: 1, knockback: 58, knock_limit: 1, vfx: "VFX_DRAGON3"
    },
    :dragon_pulse => {
      name: "Draco Lance",
      desc: "Fires special dragon lances that pierce through enemies.",
      kind: :projectile, type: :DARK, cooldown: 0.96, speed: 5.8, damage: 16, pierce: 4, count: 1, vfx: "VFX_DRAGON4"
    },
    :slime_wave => {
      name: "Dragon Trail",
      desc: "Leaves sticky dragon trails behind you, slowing enemies inside them.",
      kind: :trail, type: :DRAGON, cooldown: 0.34, damage: 6, radius: 34, duration: 3.2, slow: 2.4, slow_mult: 0.28, vfx: "VFX_DRAGON_TRAIL"
    },
    :sonic_wave => {
      name: "Gale Ring",
      desc: "Circling gusts push enemies and fire bouncing shots.",
      kind: :orbit_shot, type: :FLYING, cooldown: 0.50, shot_cooldown: 0.88, speed: 5.9, orbit_speed: 1.30, damage: 7, radius: 58, count: 1, max_count: 5, pierce: 1, bounce: 2, knockback: 46, knock_limit: 2, orbit_vfx: "VFX_FLYING_ORBIT", vfx: "VFX_FLYING"
    },
    :fossil_jaw => {
      name: "Rock Claw",
      desc: "Slashes nearby enemies with rocky claws and briefly paralyzes them.",
      kind: :survivor_swing, type: :ROCK, cooldown: 0.82, damage: 19, radius: 34,
      count: 1, max_count: 6, freeze: 0.65, duration: 0.60,
      arc: Math::PI * 2.0, spin_speed: 0.0, full_swing: false, radial_hit: true,
      vfx: "VFX_ROCK3", vfx_fps: 30, vfx_loop: false, visual_offset_mult: 1.28,
      hit_radius_mult: 0.50, visual_scale: 1.35, visual_radius_base: 48, target_nearest: true
    },
    :vine_gust => {
      name: "Vine Gust",
      desc: "Fires light grass shots at a fast pace.",
      kind: :projectile, type: :GRASS, cooldown: 0.40, speed: 6.0, damage: 7, pierce: 4, count: 1, vfx: "VFX_GRASS2"
    },
    :water => {
      name: "Water Pulse",
      desc: "Creates water shots that bounce between enemies.",
      kind: :projectile, type: :WATER, cooldown: 0.76, speed: 4.8, damage: 12, pierce: 1, count: 1, bounce: 2
    },
    :splash => {
      name: "Splash",
      desc: "Flops harmlessly. It creates no projectile and deals no damage.",
      kind: :splash, type: :WATER, cooldown: 1.15, damage: 0, radius: 18, count: 0, vfx: "VFX_WATER"
    },
    :fairy_splash => {
      name: "Fairy Splash",
      desc: "Harmless at first, but becomes Fairy Surge when your Pokemon is fully developed. Feebas unlocks its power upon evolving.",
      kind: :splash, type: :WATER, cooldown: 1.15, damage: 0, radius: 18, count: 0, vfx: "VFX_WATER"
    },
:hydro_pump => {
  name: "Hydro Pump",
  desc: "Drops a crushing water blast on enemy groups, knocking targets back for heavy damage.",
  kind: :zone, type: :WATER, cooldown: 1.20, damage: 44, radius: 100, range: 190, knockback: 120, knock_limit: 2, count: 1, max_count: 3, duration: 0.72, vfx: "VFX_WATER_ZONE", vfx_loop: true, vfx_fps: 18
},
:fairy_pump => {
  name: "Fairy Surge",
  desc: "Drops a radiant fairy surge that knocks groups back.",
  kind: :zone, type: :FAIRY, cooldown: 1.20, damage: 44, radius: 100, range: 190, knockback: 120, knock_limit: 2, count: 1, max_count: 3, duration: 0.72, vfx: "VFX_FAIRY_ZONE", vfx_loop: true, vfx_fps: 18
},
    :water_shuriken => {
      name: "Aqua Shuriken",
      desc: "Throws quick water blades through enemy lines.",
      kind: :projectile, type: :WATER, cooldown: 0.50, speed: 6.7, damage: 4, pierce: 4, count: 1, max_count: 5, vfx: "VFX_WATER3"
    },
    :leaf_orbit => {
      name: "Leaf Ring",
      desc: "Circling leaves fire bouncing shots on contact.",
      kind: :orbit, type: :GRASS, cooldown: 0.42, speed: 2.4, orbit_speed: 1.35, damage: 8, radius: 56, count: 1, max_count: 8, pierce: 1, bounce: 2, contact_shot: true, contact_shot_count: 1, contact_shot_damage_mult: 0.80, contact_shot_cooldown: 0.34, contact_shot_vfx: "VFX_GRASS", orbit_vfx: "VFX_GRASS_ORBIT"
    },
    :battery_shuriken => {
      name: "Spark Shuriken",
      desc: "Throws electric blades that pierce and briefly paralyze.",
      kind: :projectile, type: :ELECTRIC, cooldown: 0.52, speed: 6.7, damage: 5, pierce: 4, count: 1, max_count: 5, freeze: 0.50, vfx: "VFX_ELECTRIC3_SHOT"
    },
    :toxic_scuttle => {
      name: "Toxic Burst",
      desc: "A bug shot bursts into poisonous homing fragments.",
      kind: :projectile, type: :BUG, cooldown: 0.86, speed: 5.2, damage: 13, pierce: 1, count: 1, max_count: 4, vfx: "VFX_BUG3", impact_homing: 4, impact_type: :POISON, impact_vfx: "VFX_POISON", impact_speed: 6.0, impact_dot: 3.0, impact_damage_mult: 0.42
    },
    :scale_lance => {
      name: "Scale Spear",
      desc: "Fires fighting scales that pierce enemy lines.",
      kind: :projectile, type: :FIGHTING, cooldown: 0.82, speed: 6.3, damage: 14, pierce: 99, count: 1, max_count: 5, knockback: 30, vfx: "VFX_FIGHTING3"
    },
    :rock_run => {
      name: "Rock Rush",
      desc: "Fires fast rocks that pierce and push through crowds.",
      kind: :projectile, type: :ROCK, cooldown: 0.68, speed: 6.0, damage: 11, pierce: 6, count: 1, max_count: 6, knockback: 54, knock_limit: 99, vfx: "VFX_ROCK2"
    },
    :water_orbit => {
      name: "Bubble Ring",
      desc: "Circling bubbles fire slower bouncing water shots.",
      kind: :orbit_shot, type: :WATER, cooldown: 0.54, shot_cooldown: 0.92, speed: 4.9, orbit_speed: 1.12, damage: 7, radius: 58, count: 1, max_count: 5, pierce: 1, bounce: 1, knockback: 38, knock_limit: 2, orbit_vfx: "VFX_WATER2", vfx: "VFX_WATER"
    },
    :psychic => {
      name: "Psy Wave",
      desc: "Launches psychic waves in rotating directions.",
      kind: :projectile, type: :PSYCHIC, cooldown: 0.42, speed: 5.5, damage: 10, pierce: 2, count: 2
    },
    :psychic_sweep => {
      name: "Psy Ring",
      desc: "Orbs fire psychic shots. Contact defeats regular enemies, pushes bosses, then briefly hides the orb.",
      kind: :orbit_shot, type: :PSYCHIC, cooldown: 0.46, shot_cooldown: 0.72, speed: 5.6, orbit_speed: 1.25, damage: 10, radius: 62, count: 1, max_count: 8, pierce: 1, knockback: 44, knock_limit: 1, orbit_vfx: "VFX_PSYCHIC_ORBIT", vfx: "VFX_PSYCHIC3", vfx_loop: true, orbit_respawn_time: 3.0
    },
    :poison_aura => {
      name: "Toxic Trail",
      desc: "Leaves small poison zones behind you while moving.",
      kind: :trail, type: :POISON, cooldown: 0.34, damage: 5, radius: 32, duration: 3.2, slow: 2.2, dot: 3.0
    },
    :thunder_ring => {
      name: "Thunder Ring",
      desc: "Circling sparks fire small electric bolts.",
      kind: :orbit_shot, type: :ELECTRIC, cooldown: 0.46, shot_cooldown: 0.42, speed: 7.2, orbit_speed: 1.65, damage: 7, radius: 58, count: 1, max_count: 4, pierce: 1, orbit_freeze: 1.0
    },
    :rock_burst => {
      name: "Rock Burst",
      desc: "Throws stones in every direction.",
      kind: :nova, type: :ROCK, cooldown: 2.8, speed: 4.4, damage: 16, pierce: 1, count: 8, max_count: 14, knockback: 72, knock_limit: 2
    },
    :ice_zone => {
      name: "Frost Field",
      desc: "Drops a cold field that slows enemies inside.",
      kind: :zone, type: :ICE, cooldown: 1.55, damage: 13, radius: 44, range: 150, freeze: 3.0, dot: 3.0
    },
    :ice_shatter => {
      name: "Ice Shatter",
      desc: "Fires an ice shard that bursts into three homing ice fragments on impact.",
      kind: :projectile, type: :ICE, cooldown: 0.92, speed: 5.2, damage: 12, pierce: 1, count: 1, freeze: 0.55, vfx: "VFX_ICE2", impact_homing: 3, impact_type: :ICE, impact_vfx: "VFX_ICE3"
    },
    :fairy_guard => {
      name: "Fairy Bloom",
      desc: "Drops bright fairy strikes that push enemies away.",
      kind: :zone, type: :FAIRY, cooldown: 1.35, damage: 14, radius: 42, range: 135, knockback: 46, count: 1, max_count: 5
    },
    :drill_spikes => {
      name: "Steel Spines",
      desc: "Raises short steel lances around the Pokemon.",
      kind: :drill_spikes, type: :STEEL, cooldown: 0.72, damage: 20, radius: 38, count: 1, max_count: 8,
      duration: 0.34, arc: 0.48, visual_offset_mult: 1.02, hit_radius_mult: 0.42, visual_scale: 1.45, visual_radius_base: 46, vfx: "VFX_STEEL4", vfx_fps: 28, vfx_loop: false
    },
    :steel_orbit => {
      name: "Iron Orbit",
      desc: "Keeps small steel shots circling around you and knocks enemies back.",
      kind: :orbit, type: :STEEL, cooldown: 0.36, damage: 7, radius: 54, count: 1, max_count: 12, speed: 2.4, orbit_speed: 1.45, knockback: 28
    },
    :steel_volley => {
      name: "Iron Shards",
      desc: "Throws steel blades that return through enemies and push them once.",
      kind: :boomerang, type: :STEEL, cooldown: 1.12, speed: 5.0, damage: 18, pierce: 6, count: 1, max_count: 4, knockback: 52, knock_limit: 1, vfx: "VFX_STEEL"
    },
    :living_blade => {
      name: "Spirit Blade",
      desc: "Sends steel blades outward, around you in a half-circle, then back.",
      kind: :returning_swing, type: :STEEL, cooldown: 1.12, damage: 18, radius: 34,
      count: 1, max_count: 4, knockback: 52, knock_limit: 1, duration: 1.35, travel_radius: 120,
      arc: Math::PI * 2.0, centered_visual: true, radial_hit: true, spin_speed: 0.0,
      vfx: "VFX_STEEL3", vfx_loop: false, visual_scale: 1.35, visual_radius_base: 48
    },
    :ground_spike => {
      name: "Earth Spike",
      desc: "Raises ground spikes under enemy groups.",
      kind: :zone, type: :GROUND, cooldown: 1.7, damage: 17, radius: 36, range: 170, slow: 2.8, slow_mult: 0.25
    },
    :sandile_ground_zone => {
      name: "Sand Pit",
      desc: "Opens slowing ground zones under enemy groups.",
      kind: :zone, type: :GROUND, cooldown: 1.7, damage: 17, radius: 36, range: 170, slow: 2.8, slow_mult: 0.25, vfx: "VFX_GROUND_ZONE"
    },
    :fighting_dash => {
      name: "Focus Wave",
      desc: "Creates two side shots that seek nearby enemies.",
      kind: :side_seek, type: :FIGHTING, cooldown: 1.05, speed: 6.2, damage: 15, pierce: 1, count: 2, knockback: 44
    },
    :sky_press => {
      name: "Sky Press",
      desc: "Launches a fast guided fighting strike that hits hard and knocks one target away.",
      kind: :projectile, type: :FIGHTING, cooldown: 0.92, speed: 7.2, damage: 18, pierce: 1, count: 1, max_count: 4, homing: true, knockback: 72, knock_limit: 1, vfx: "VFX_FIGHTING2"
    },
    :dark_wave => {
      name: "Dark Wave",
      desc: "Sends a wide dark wave through crowds.",
      kind: :nova, type: :DARK, cooldown: 2.4, speed: 3.9, damage: 13, pierce: 3, count: 6, max_count: 17, dot: 3.4
    },
    :night_bolt => {
      name: "Night Bolt",
      desc: "Fires slower dark shots with stronger base damage.",
      kind: :projectile, type: :DARK, cooldown: 0.56, speed: 5.2, damage: 13, pierce: 4, count: 1, vfx: "VFX_DARK2"
    },
    :dragon_arc => {
      name: "Dragon Arc",
      desc: "Summons rotating dragon lines around the Pokemon.",
      kind: :vortex, type: :DRAGON, cooldown: 15.0, speed: 1.15, damage: 24, pierce: 1, count: 1, max_count: 8, radius: 30, vfx: "VFX_DRAGON"
    },
    :fairy_arc => {
      name: "Fairy Arc",
      desc: "Summons rotating fairy blades around the Pokemon.",
      kind: :vortex, type: :FAIRY, cooldown: 15.0, speed: 1.15, damage: 24, pierce: 1, count: 1, max_count: 8, radius: 30, vfx: "VFX_FAIRY2"
    },
    :dragon_shot => {
      name: "Dragon Needle",
      desc: "Fires piercing dragon bolts that cut through enemy lines.",
      kind: :projectile, type: :DRAGON, cooldown: 0.60, speed: 6.0, damage: 12, pierce: 5, count: 1, vfx: "VFX_DRAGON2"
    },
    :echo_charge => {
      name: "Echo Cannon",
      desc: "Charges a heavy sound orb that bursts on impact.",
      kind: :charge_shot, type: :NORMAL, cooldown: 5.1, charge_time: 5.1, speed: 7.0, damage: 76, pierce: 1, count: 1, max_count: 3, radius: 12, knockback: 76, knock_limit: 1, vfx: "VFX_NORMAL2", shot_vfx: "VFX_NORMAL2_SHOT", impact_radial: 4
    },
    :aura_charge => {
      name: "Aura Bolt",
      desc: "Launches a guided fighting bolt that hits hard.",
      kind: :projectile, type: :FIGHTING, cooldown: 3.0, speed: 7.4, damage: 82, pierce: 1, count: 1, radius: 12, knockback: 86, knock_limit: 1, homing: true, vfx: "VFX_FIGHTING2"
    },
    :toxic_bounce => {
      name: "Toxic Ricochet",
      desc: "Fires bouncing poison shots that deal poison over time.",
      kind: :projectile, type: :POISON, cooldown: 0.82, speed: 4.9, damage: 10, pierce: 1, count: 1, bounce: 2, dot: 3.2, vfx: "VFX_POISON"
    },
    :ghost_wisp => {
      name: "Ghost Wisp",
      desc: "Sends drifting wisps that seek enemies from a distance.",
      kind: :projectile, type: :GHOST, cooldown: 0.82, speed: 4.4, damage: 15, pierce: 2, count: 1, homing: true, split: 3
    },
    :litwick_ghost_bounce => {
      name: "Spectral Bounce",
      desc: "Fires ghost shots that bounce between enemies.",
      kind: :projectile, type: :GHOST, cooldown: 0.82, speed: 4.8, damage: 14, pierce: 1, count: 1, bounce: 2, vfx: "VFX_GHOST"
    },
    :twin_mirage => {
      name: "Twin Mirage",
      desc: "Twin orbs circle you: ghost slows, normal pushes.",
      kind: :dual_orbit_shot, type: :GHOST, cooldown: 0.62, shot_cooldown: 0.82, speed: 5.0, orbit_speed: 1.22, damage: 8, radius: 60, count: 1, max_count: 3, pierce: 1, bounce: 1, slow: 1.5, slow_mult: 0.42, knockback: 38, knock_limit: 1,
      ghost_orbit_vfx: "VFX_GHOST_ORBIT", ghost_shot_vfx: "VFX_GHOST", normal_orbit_vfx: "VFX_NORMAL_ORBIT", normal_shot_vfx: "VFX_NORMAL2_SHOT"
    }
  }

  EEVEE_ORBIT_SKILLS = {
    ember_sphere: [:FIRE, "Ember Sphere", "VFX_FIRE8", "VFX_FIRE6", 12, { dot: 3.0 }],
    volt_sphere: [:ELECTRIC, "Volt Sphere", "VFX_ELECTRIC2_SHOT", "VFX_ELECTRIC4", 13, { freeze: 0.65 }],
    tidal_sphere: [:WATER, "Tidal Sphere", "VFX_WATER", "VFX_WATER4", 8, { knockback: 38 }],
    psy_sphere: [:PSYCHIC, "Psy Sphere", "VFX_PSYCHIC", "VFX_PSYCHIC4", 11, { slow: 2.0 }],
    dusk_sphere: [:DARK, "Dusk Sphere", "VFX_DARK", "VFX_DARK6", 18, { slow: 2.0 }],
    leaf_sphere: [:GRASS, "Leaf Sphere", "VFX_GRASS_ORBIT", "VFX_GRASS5", 3, { freeze: 0.65 }],
    frost_sphere: [:ICE, "Frost Sphere", "VFX_ICE", "VFX_ICE4", 6, { knockback: 38 }],
    charm_sphere: [:FAIRY, "Charm Sphere", "VFX_FAIRY5", "VFX_FAIRY6", 10, {}]
  }.freeze
  EEVEE_ORBIT_SKILLS.each do |id, (type, name, vfx, impact, frames, status)|
    description = case type
                  when :FIRE then "Orbits once, then launches and bursts. Hits burn enemies."
                  when :ELECTRIC, :GRASS then "Orbits once, then launches and bursts. Hits paralyze enemies."
                  when :WATER, :ICE then "Orbits once, then launches and bursts. Hits push enemies back."
                  when :PSYCHIC, :DARK then "Orbits once, then launches and bursts. Hits slow enemies."
                  else "Orbits once, then launches and bursts, dealing heavy Fairy damage."
                  end
    SKILLS[id] = {
      name: name, desc: description,
      kind: :apple_orbit, type: type, cooldown: 6.0, orbit_speed: 2.1,
      speed: 6.5, damage: type == :FAIRY ? 38 : 24, radius: 54, count: 1, max_count: 4,
      pierce: 1, vfx: vfx, vfx_loop: true, eevee_orbit: true,
      impact_blast: true, impact_radius: 32, impact_damage: type == :FAIRY ? 30 : 12,
      impact_type: type, impact_vfx: impact, impact_frames: frames, impact_dot: status[:dot]
    }.merge(status)
  end

  SKILLS[:bloom_trick] = {
    name: "Bloom Trick", desc: "Seeking leaves hit hard, then surround the target with a flurry of Grass cuts.",
    kind: :projectile, type: :GRASS, cooldown: 1.1, damage: 28, speed: 6.5,
    count: 1, max_count: 5, pierce: 1, homing: true,
    vfx: "VFX_GRASS8", vfx_frames: 9, vfx_loop: true,
    vfx_fixed_orientation: true, vfx_speed_mult: 3.0,
    impact_flurry: true, impact_damage: 2, impact_radius: 30,
    impact_type: :GRASS, impact_vfx: "VFX_GRASS3", impact_frames: 9, impact_8dir: true
  }
  SKILLS[:cinder_song] = SKILLS[:ember_strike].merge(
    name: "Cinder Song", desc: "Fire shots raise burning tornadoes where they hit.",
    damage: 7, vfx: "VFX_FIRE8", impact_blast: false, impact_twister: true)
  SKILLS[:volt_pummel] = SKILLS[:disciplined_strikes].merge(
    name: "Volt Pummel", desc: "Fighting blows release seeking sparks at other enemies, paralyzing them.",
    vfx: "VFX_FIGHTING7", spark_chain: true)
  SKILLS[:ember_armor] = SKILLS[:fire].merge(
    name: "Ember Armor", desc: "Fire shots burst on impact and burn nearby enemies.",
    damage: 16, impact_blast: true, impact_damage: 8, impact_radius: 32, burn_time: 3.0)
  SKILLS[:armor_cannon] = SKILLS[:ember_armor].merge(
    name: "Armor Cannon", desc: "Heavy flames pierce every enemy, burning and pushing them back.",
    cooldown: 1.1, damage: 42, speed: 6.5, vfx: "VFX_FIRE7", vfx_frames: 3,
    impact_blast: false, infinite_pierce: true, hit_interval: 9999.0, knockback: 42, dot: 3.0)
  SKILLS[:spectral_blade] = SKILLS[:living_blade].merge(
    name: "Spectral Blade", desc: "Ghost blades sweep outward and circle back through enemies.",
    type: :GHOST, vfx: "VFX_GHOST4", vfx_frames: 9)
  SKILLS[:frost_fang] = {
    name: "Frost Fang", desc: "Fast seeking ice fangs burst on impact and slow nearby enemies.",
    kind: :projectile, type: :ICE, cooldown: 0.9, damage: 24, speed: 8.0,
    count: 1, max_count: 5, pierce: 1, homing: true,
    vfx: "VFX_ICE6", vfx_frames: 1, vfx_loop: true, impact_blast: true,
    impact_radius: 34, impact_damage: 16, impact_type: :ICE,
    impact_vfx: "VFX_ICE4", impact_frames: 6, slow: 2.0, slow_mult: 0.5
  }
  SKILLS[:fairy_hammer] = SKILLS[:normal_sweep].merge(
    name: "Fairy Hammer", desc: "A heavy Steel sweep unleashes a flurry of Fairy hits on each target.",
    type: :STEEL, damage: 22, cooldown: 1.25, vfx: "VFX_STEEL3",
    impact_flurry: true, impact_damage: 2, impact_radius: 28,
    impact_type: :FAIRY, impact_vfx: "VFX_FAIRY7", impact_frames: 20, impact_8dir: false)
  SKILLS[:gold_rush] = SKILLS[:frost_fang].merge(
    name: "Gold Rush", desc: "Seeking coins explode on impact and briefly freeze nearby enemies.",
    type: :STEEL, vfx: "VFX_STEEL6", impact_type: :STEEL,
    impact_vfx: "VFX_STEEL7", impact_frames: 10, slow: nil, freeze: 0.7)
  GEN9_SKILL_IDS = [:bloom_trick, :cinder_song, :volt_pummel, :ember_armor,
    :armor_cannon, :spectral_blade, :frost_fang, :fairy_hammer, :gold_rush].freeze

  ULTIMATES = {
    :SQUIRTLE => { name: "Hydro Barrage", desc: "Eight powerful water blasts orbit you for 8 seconds, repeatedly pushing enemies back on contact.",
      kind: :survivor_orbit_burst, type: :WATER, cooldown: 52.0, damage: 60,
      knockback: 60, unlimited_knockback: true,
      burst_time: 8.0, count: 8, radius: 95, vfx: "VFX_WATER_ZONE", vfx_radial_orientation: true },
    :CUBONE => { name: "Bonequake", desc: "Repeated shockwaves push enemies back for 8 seconds.",
      kind: :repeating_shockwave, type: :GROUND, cooldown: 54.0, damage: 42,
      radius: 164, count: 1, burst_time: 8.0, interval: 0.75, knockback: 60,
      vfx: "VFX_GROUND2", vfx_fps: 18 },
    :MAWILE => { name: "Captivating Jaws", desc: "Four Fairy fields circle you and trap enemies for 9 seconds.",
      kind: :fairy_prison, type: :FAIRY, cooldown: 60.0, damage: 6, burst_time: 9.0,
      radius: 38, sphere_count: 4, orbit_radius: 105.0, follow_player: true,
      frame_ticks: true, vfx: "VFX_FAIRY4", speed: 0.0, pierce: 1 },
    :TYNAMO => { name: "Charged Eclipse", desc: "Dark gems rain down. Doubles attack damage for 4 seconds.",
      kind: :gem_rain, type: :DARK, cooldown: 58.0, damage: 38, radius: 48,
      count: 10, dot: 3.0, magnet_time: 4.0, power_time: 4.0, power_mult: 2.0 },
    :SKRELP => { name: "Dragon Reef", desc: "Dragon waves circle you for 6 seconds.",
      kind: :survivor_orbit_burst, type: :DRAGON, cooldown: 52.0, damage: 24,
      burst_time: 6.0, count: 8, radius: 95, vfx: "VFX_DRAGON3" },
    :ENTEI => { name: "Volcanic Overdrive", desc: "Greatly increases attack speed for 6 seconds.",
      kind: :projectile_overdrive, type: :FIRE, cooldown: 51.0, damage: 0,
      radius: 120, haste_time: 6.0, haste_mult: 0.2 },
    :RAIKOU => { name: "Storm Collector", desc: "Becomes invulnerable and attracts XP and dropped items for 6 seconds.",
      kind: :storm_collector, type: :ELECTRIC, cooldown: 58.0, damage: 0,
      burst_time: 6.0, shield: 6.0, magnet_time: 6.0 },
    :SUICUNE => { name: "Aurora Current", desc: "Your water orbits fire twice as fast for 8 seconds.",
      kind: :aurora_current, type: :WATER, cooldown: 48.0, damage: 0, burst_time: 8.0 },
    :SPRIGATITO => {
      name: "Night Masquerade", desc: "Sends repeated waves of returning Dark blades around you.",
      kind: :returning_blade_burst, type: :DARK, cooldown: 50.0, damage: 32,
      radius: 34, count: 4, burst_time: 6.0, interval: 0.55, vfx: "VFX_DARK4", vfx_fps: 30
    },
    :FUECOCO => {
      name: "Cinder Chorus", desc: "Orbiting flames seek nearby enemies and explode on contact.",
      kind: :gen9_burst, type: :FIRE, cooldown: 52.0, damage: 28, burst_time: 6.0,
      vfx: "VFX_FIRE10"
    },
    :PAWMI => {
      name: "Revival Current", desc: "Fires a rotating Electric barrage. Its hits restore HP where healing is allowed.",
      kind: :treecko_barrage, type: :ELECTRIC, cooldown: 55.0, damage: 24,
      speed: 8.2, pierce: 2, burst_time: 5.0, barrage_time: 5.0, shot_interval: 0.14,
      barrage_directions: 4, vfx: "VFX_ELECTRIC_SHOT", life_steal: 0.0625
    },
    :CHARCADET => {
      name: "Flame Formation", desc: "Fires a rotating barrage of flames.",
      kind: :treecko_barrage, type: :FIRE, cooldown: 52.0, damage: 26,
      speed: 8.2, pierce: 2, burst_time: 5.0, barrage_time: 5.0,
      shot_interval: 0.14, barrage_directions: 4, vfx: "VFX_FIRE8"
    },
    :FRIGIBAX => {
      name: "Glacial Rampage", desc: "Fires much faster and becomes invulnerable for 5 seconds.",
      kind: :projectile_overdrive, type: :ICE, cooldown: 55.0, damage: 0,
      haste_time: 5.0, haste_mult: 0.2, burst_time: 5.0, shield: 5.0, vfx: "VFX_ICE4"
    },
    :TINKATINK => {
      name: "Fairy Forge", desc: "Four circling Fairy fields trap enemies, then finish with a repelling shockwave.",
      kind: :gen9_burst, type: :FAIRY, cooldown: 60.0, damage: 6, burst_time: 6.0,
      vfx: "VFX_FAIRY4"
    },
    :GIMMIGHOUL => {
      name: "Golden Deluge", desc: "Unleashes huge waves of powerful Steel coins for 8 seconds.",
      kind: :treecko_barrage, type: :STEEL, cooldown: 58.0, damage: 32,
      speed: 8.0, pierce: 3, burst_time: 8.0, barrage_time: 8.0, shot_interval: 0.12,
      barrage_directions: 8, vfx: "VFX_STEEL6"
    },
    :CELEBI => {
      name: "Forest Dance", desc: "Five grass sweeps strike around you for 8 seconds.",
      kind: :forest_dance, type: :GRASS, cooldown: 52.0, damage: 30,
      burst_time: 8.0, radius: 34, vfx: "VFX_GRASS3"
    },
    :VICTINI => {
      name: "Victory Barrage", desc: "Fires a rotating Psychic barrage for 8 seconds.",
      kind: :treecko_barrage, type: :PSYCHIC, cooldown: 52.0, damage: 26,
      speed: 8.2, pierce: 3, burst_time: 8.0, barrage_time: 8.0,
      shot_interval: 0.12, vfx: "VFX_PSYCHIC3"
    },
    :MEWTWO => {
      name: "Psychic Dominion", desc: "Fires a rotating eight-way Psychic barrage for 5 seconds. All damage to bosses is multiplied by 1.5 during the Burst.",
      kind: :treecko_barrage, type: :PSYCHIC, cooldown: 50.0,
      damage: 30, speed: 8.2, pierce: 2, burst_time: 5.0, barrage_time: 5.0,
      shot_interval: 0.14, barrage_directions: 8, radius: 70, vfx: "VFX_PSYCHIC5", vfx_scale: 2.0
    },
    :PSYDUCK => {
      name: "Total Confusion", desc: "Reverses your movement controls for 30 seconds.",
      kind: :psyduck_confusion, type: :PSYCHIC, cooldown: 35.0,
      damage: 0, radius: 0, burst_time: 30.0, vfx: "VFX_PSYCHIC_WAIT2"
    },
    :ZIGZAGOON_1 => {
      name: "Riot Rush", desc: "For 5 seconds, attacks fire faster and Night Raid pulls enemies in. Linoone attracts XP; Obstagoon also doubles damage.",
      kind: :galar_rush, type: :DARK, cooldown: 55.0, damage: 0, radius: 120,
      burst_time: 5.0, haste_time: 5.0, haste_mult: 0.2, vfx: "VFX_DARK"
    },
    :ABRA => {
      name: "Psychic Echoes", desc: "Fires a homing Psychic volley every second for 6 seconds.",
      kind: :psi_echoes, type: :PSYCHIC, cooldown: 48.0, damage: 28, radius: 100,
      burst_time: 6.0, vfx: "VFX_PSYCHIC5"
    },
    :SKARMORY => {
      name: "Steel Tempest", desc: "Launches a giant Steel tornado forward for 12 seconds. It pulls enemies in, then pushes them away.",
      kind: :steel_tempest, type: :STEEL, cooldown: 70.0, damage: 24,
      radius: 100, speed: 1.5, count: 1, pierce: 1, burst_time: 12.0,
      vfx: "VFX_STEEL5", vfx_loop: true
    },
    :EEVEE => {
      name: "Prismatic Rush", desc: "Become invincible and unleash skills five times faster for 6 seconds.",
      kind: :eevee_rush, type: :NORMAL, cooldown: 65.0, damage: 0, radius: 100,
      burst_time: 6.0, haste_time: 6.0, haste_mult: 0.2
    },
    :CARVANHA => {
      id: :ultimate_carvanha, name: "Aqua Pursuit",
      desc: "Eight Water shots hunt separate targets for 10 seconds and orbit you when no target is available.",
      kind: :psychic_pursuit, type: :WATER, cooldown: 65.0, damage: 24,
      speed: 5.5, count: 8, pierce: 1, burst_time: 10.0, vfx: "VFX_WATER5"
    },
    :KUBFU => {
      id: :ultimate_kubfu, name: "Focused Training",
      desc: "Disciplined Strikes attacks twice as often and grows 50% larger for 5 seconds.",
      kind: :kubfu_focus, type: :FIGHTING, cooldown: 46.0, damage: 0, burst_time: 5.0
    },
    :TOXEL => {
      id: :ultimate_toxel, name: "Venom Outburst",
      desc: "Blasts up to six random nearby targets with heavy Poison damage and poisons enemies in each blast.",
      kind: :toxic_bombardment, type: :POISON, cooldown: 55.0, damage: 68,
      radius: 48, count: 6, speed: 0.0, pierce: 1, dot: 4.0,
      burst_time: 26.0 / 18.0, vfx: "VFX_POISON4"
    },
    :IMPIDIMP => {
      id: :ultimate_impidimp, name: "Fairy Captivity",
      desc: "Creates eight circling Fairy spheres that trap and damage enemies for 6 seconds. They stay in the area where they appeared.",
      kind: :fairy_prison, type: :FAIRY, cooldown: 65.0, damage: 30,
      radius: 48, count: 8, speed: 0.0, pierce: 1, burst_time: 6.0, vfx: "VFX_FAIRY4"
    },
    :HATENNA => {
      id: :ultimate_hatenna, name: "Psychic Pursuit",
      desc: "Eight Psychic shots hunt separate targets for 10 seconds and orbit you when no target is available.",
      kind: :psychic_pursuit, type: :PSYCHIC, cooldown: 65.0, damage: 24,
      speed: 5.5, count: 8, pierce: 1, burst_time: 10.0, vfx: "VFX_PSYCHIC3"
    },
    :DREEPY => {
      id: :ultimate_dreepy, name: "Phantom Overdrive",
      desc: "For 5 seconds, projectile attacks fire 5 times faster and all your projectiles grow by 50%.",
      kind: :projectile_overdrive, type: :GHOST, cooldown: 58.0, damage: 0,
      radius: 120, haste_time: 5.0, haste_mult: 0.2, vfx: "VFX_GHOST"
    },
    :ROOKIDEE => {
      name: "Tempest Guard", desc: "Eight tornadoes circle you, then scatter outward. They deal Flying damage, or Steel damage as Corviknight.",
      kind: :rook_tornado_burst, type: :FLYING, cooldown: 60.0, damage: 18,
      radius: 28, count: 8, pierce: 1, freeze: 0.75,
      burst_time: 52.0 / 12.0, vfx: "VFX_FLYING2"
    },
    :SCORBUNNY => {
      name: "Blazing Striker", desc: "Launches a huge fireball for up to 10 seconds. Once away from you, it pulls enemies into its path.",
      kind: :blazing_striker, type: :FIRE, cooldown: 60.0, damage: 28,
      speed: 1.8, radius: 56, pierce: 1, count: 1, burst_time: 10.0, vfx: "VFX_FIRE7"
    },
    :APPLIN => {
      id: :ultimate_applin, name: "Orchard Downpour",
      desc: "Rains heavy apples directly onto enemies for 4 seconds.",
      kind: :poison_rain, type: :GRASS, cooldown: 45.0, damage: 52,
      radius: 0, rain_time: 4.0, interval: 0.65, rain_direct: true,
      vfx: "VFX_GRASS4", vfx_loop: true, vfx_fps: 18
    },
    :BULBASAUR => {
      id: :ultimate_bulbasaur, name: "Toxic Downpour",
      desc: "Rains poisonous seeds on random enemies for a short time, leaving light poison bursts on impact.",
      kind: :poison_rain, type: :POISON, cooldown: 40.0, damage: 32, radius: 46, rain_time: 6.0, interval: 0.13, impact_damage_mult: 0.45, dot: 2.8, vfx: "VFX_POISON2", vfx_fps: 24
    },    :CYNDAQUIL => {
      id: :ultimate_cyndaquil, name: "Inferno Spiral",
      desc: "Launches piercing embers in every direction with a light push.",
      kind: :radial, type: :FIRE, cooldown: 39.0, damage: 42, speed: 7.2, count: 20, pierce: 5, knockback: 28, dot: 2.6
    },
    :MUDKIP => {
      id: :ultimate_mudkip, name: "Mudslide Pulse",
      desc: "Drops expanding ground waves on nearby enemies, damaging and slowing groups.",
      kind: :tyrunt_shockwave, type: :GROUND, cooldown: 52.0, damage: 42, count: 4, radius: 132, slow: 2.8, slow_mult: 0.28, targeted: true, target_range: 520, repeat: 3, repeat_delay: 0.82, vfx: "VFX_GROUND3", vfx_fps: 18
    },
    :MAREEP => {
      id: :ultimate_mareep, name: "Thunder Halo",
      desc: "Creates an electric ring that shocks enemies, then bursts into bolts.",
      kind: :thunder_ring_burst, type: :ELECTRIC, cooldown: 43.0, damage: 34, speed: 7.6, count: 16, pierce: 2, radius: 118, freeze: 0.9, knockback: 20
    },
    :RALTS => {
      id: :ultimate_ralts, name: "Fairy Wish",
      desc: "Drops fairy blossoms on several enemies and restores HP.",
      kind: :fairy_rain, type: :FAIRY, cooldown: 46.0, damage: 34, radius: 54, count: 7, knockback: 54, heal: 0.14
    },
    :GASTLY => {
      id: :ultimate_gastly, name: "Phantom Rift",
      desc: "Opens a ghost rift that slows enemies and releases seeking wisps.",
      kind: :ghost_rift, type: :GHOST, cooldown: 42.0, damage: 42, speed: 4.8, count: 6, pierce: 2, radius: 155, dot: 3.4, slow: 2.0
    },
    :ARON => {
      id: :ultimate_aron, name: "Iron Overdrive",
      desc: "Greatly increases this Pokemon's attack speed for a brief burst.",
      kind: :projectile_overdrive, type: :STEEL, cooldown: 51.0, damage: 0, radius: 120, haste_time: 6.0, haste_mult: 0.2
    },
    :NIDORANm => {
      id: :ultimate_nidoran, name: "Venom Crown",
      desc: "Poison zones bloom around the Pokemon and weaken crowds.",
      kind: :poison_crown, type: :POISON, cooldown: 41.0, damage: 32, radius: 44, zone_time: 6.0, dot: 4.2, slow: 2.4
    },
    :BAGON => {
      id: :ultimate_bagon, name: "Dragon Breath",
      desc: "Breathes a wide cone of dragon force before splitting into arcs.",
      kind: :dragon_breath, type: :DRAGON, cooldown: 50.0, damage: 58, speed: 6.2, count: 9, pierce: 5, radius: 170, knockback: 38
    },
    :BELDUM => {
      id: :ultimate_beldum, name: "Magnet Crash",
      desc: "A magnetic crash pulls enemies into several impact points.",
      kind: :magnet_crash, type: :STEEL, cooldown: 54.0, damage: 68, radius: 176, knockback: 120
    },
    :ZANGOOSE => {
      id: :ultimate_zangoose, name: "Rival Rush",
      desc: "Enlarges the normal sweep, spins it faster, and greatly raises its damage for 5 seconds.",
      kind: :zangoose_surge, type: :NORMAL, cooldown: 39.0, damage: 0, radius: 118,
      surge_time: 5.0, radius_mult: 1.5, spin_mult: 2.0, power_mult: 4.0, vfx: "VFX_NORMAL3"
    },
    :SABLEYE => {
      id: :ultimate_sableye, name: "Gem Eclipse",
      desc: "Dark gems rain down and pull experience closer.",
      kind: :gem_rain, type: :DARK, cooldown: 62.0, damage: 38, radius: 48, count: 10, dot: 3.0, magnet_time: 5.0
    },
    :MACHOP => {
      id: :ultimate_machop, name: "Atlas Breaker",
      desc: "Launches heavy fighting shockwaves in the faced direction.",
      kind: :fighting_wave, type: :FIGHTING, cooldown: 44.0, damage: 50, speed: 5.6, count: 5, pierce: 10, radius: 136, knockback: 116
    },
    :TRAPINCH => {
      id: :ultimate_trapinch, name: "Sand Pit",
      desc: "Opens a collapsing sand pit that pulls enemies in and leaves trapping ground zones.",
      kind: :sand_pit, type: :GROUND, cooldown: 43.0, damage: 42, radius: 164, count: 6, slow: 3.2, slow_mult: 0.12, dot: 2.8, knockback: 18
    },
    :ZUBAT => {
      id: :ultimate_zubat, name: "Sonic Swarm",
      desc: "Fires a rapid frontal swarm of flying projectiles for 6 seconds, with a few side shots.",
      kind: :sonic_swarm, type: :FLYING, cooldown: 41.0, damage: 24, speed: 7.8, count: 3, pierce: 4, radius: 130, burst_time: 6.0, knockback: 48, knock_limit: 2
    },
    :SPHEAL => {
      id: :ultimate_spheal, name: "Aurora Floe",
      desc: "Freezes the area in layered ice and grants a brief protective chill.",
      kind: :aurora_floe, type: :ICE, cooldown: 49.0, damage: 38, radius: 150, count: 6, freeze: 3.8, dot: 3.8, shield: 1.6, heal: 0.06
    },
    :SPINARAK => {
      id: :ultimate_spinarak, name: "Spider Nest",
      desc: "Pins several enemies with sticky bug threads and leaves freezing web traps.",
      kind: :spider_nest, type: :BUG, cooldown: 40.0, damage: 30, speed: 5.8, count: 10, pierce: 2, radius: 46, freeze: 2.2, slow: 3.0, slow_mult: 0.18
    },
    :PICHU => {
      id: :ultimate_pichu, name: "Volt Barrage",
      desc: "Launches a dense electric ring with many strong shots that stop on impact.",
      kind: :radial, type: :ELECTRIC, cooldown: 46.0, damage: 42, speed: 8.0, count: 60, pierce: 1, radius: 110, vfx: "VFX_ELECTRIC_SHOT"
    },
    :LARVITAR => {
      id: :ultimate_larvitar, name: "Tyrant Barrage",
      desc: "Fires a rapid frontal barrage of piercing rock projectiles for 5.5 seconds.",
      kind: :sonic_swarm, type: :ROCK, cooldown: 53.0, damage: 48, speed: 6.6, count: 3, pierce: 4, radius: 130, burst_time: 5.5, knockback: 58, knock_limit: 1, vfx: "VFX_ROCK"
    },
    :BELLSPROUT => {
      id: :ultimate_bellsprout, name: "Root Devour",
      desc: "A huge grass bloom strikes, pushes enemies away, and heals for half total damage dealt.",
      kind: :root_devour, type: :GRASS, cooldown: 48.0, damage: 46, radius: 150, knockback: 92, heal_from_damage: 0.5, vfx: "VFX_GRASS"
    },
    :AZURILL => {
      id: :ultimate_azurill, name: "Bubble Tide",
      desc: "A compact tide pushes nearby enemies away and releases bouncing water shots.",
      kind: :bubble_tide, type: :WATER, cooldown: 45.0, damage: 30, speed: 5.4, count: 12, pierce: 1, bounce: 2, radius: 126, knockback: 82, vfx: "VFX_WATER"
    },
    :WHISMUR => {
      id: :ultimate_whismur, name: "Echo Chamber",
      desc: "A resonant blast hits a forward cone, then fires short sound bursts sideways.",
      kind: :echo_chamber, type: :NORMAL, cooldown: 44.0, damage: 40, speed: 6.6, count: 8, pierce: 2, radius: 138, knockback: 88, vfx: "VFX_NORMAL2_SHOT"
    },
    :DRATINI => {
      id: :ultimate_dratini, name: "Dragon Current",
      desc: "Dragon currents spiral outward as piercing shots and briefly clear pressure.",
      kind: :dragon_current, type: :DRAGON, cooldown: 47.0, damage: 36, speed: 6.8, count: 10, pierce: 6, radius: 138, knockback: 42, vfx: "VFX_DRAGON2"
    },
    :CHIMCHAR => {
      id: :ultimate_chimchar, name: "Blazing Barrage",
      desc: "Unleashes rapid fire strikes in front of the Pokemon.",
      kind: :sonic_swarm, type: :FIRE, cooldown: 40.0, damage: 27, speed: 8.2, count: 4, pierce: 3, radius: 124, burst_time: 5.0, dot: 2.0, knockback: 20, vfx: "VFX_FIRE2"
    },
    :STARLY => {
      id: :ultimate_starly, name: "Sky Scatter",
      desc: "Fires a wide burst of flying shots around the Pokemon.",
      kind: :radial, type: :FLYING, cooldown: 39.0, damage: 25, speed: 7.0, count: 28, pierce: 3, radius: 116
    },
    :SHINX => {
      id: :ultimate_shinx, name: "Static Breaker",
      desc: "Shocks nearby enemies, then releases a sharp electric ring.",
      kind: :thunder_ring_burst, type: :ELECTRIC, cooldown: 43.0, damage: 34, speed: 7.4, count: 18, pierce: 2, radius: 124, freeze: 0.8, knockback: 24, vfx: "VFX_ELECTRIC2_SHOT"
    },
    :GIBLE => {
      id: :ultimate_gible, name: "Dragon Overdrive",
      desc: "Greatly increases this Pokemon's attack speed for a brief burst.",
      kind: :projectile_overdrive, type: :DRAGON, cooldown: 53.0, damage: 0, radius: 124, haste_time: 5.0, haste_mult: 0.2, vfx: "VFX_DRAGON3"
    },
    :RIOLU => {
      id: :ultimate_riolu, name: "Aura Rings",
      desc: "Creates chained fighting rings around the Pokemon.",
      kind: :aura_ring_chain, type: :FIGHTING, cooldown: 45.0, damage: 36, speed: 6.8, count: 8, pierce: 2, radius: 118, knockback: 70, vfx: "VFX_FIGHTING2"
    },
    :CROAGUNK => {
      id: :ultimate_croagunk, name: "Poison Pit",
      desc: "Pulls enemies into poison trails and leaves toxic zones nearby.",
      kind: :sand_pit, type: :POISON, cooldown: 44.0, damage: 36, radius: 152, count: 6, slow: 3.0, slow_mult: 0.18, dot: 3.6, knockback: 14, vfx: "VFX_POISON_TRAIL"
    },
    :LITWICK => {
      id: :ultimate_litwick, name: "Soul Furnace",
      desc: "Releases a dark ghost pulse that pierces enemies and slows the nearest wave.",
      kind: :radial, type: :GHOST, cooldown: 45.0, damage: 32, speed: 6.2, count: 18, pierce: 4, radius: 136, slow: 1.6, vfx: "VFX_GHOST"
    },
    :SANDILE => {
      id: :ultimate_sandile, name: "Quaking Maw",
      desc: "Pulls enemies through a ground trap and leaves damaging sand zones.",
      kind: :sand_pit, type: :GROUND, cooldown: 48.0, damage: 38, radius: 150, count: 5, slow: 2.5, slow_mult: 0.20, dot: 3.0, knockback: 16, vfx: "VFX_GROUND_ZONE"
    },
    :PAWNIARD => {
      id: :ultimate_pawniard, name: "Iron Edict",
      desc: "Accelerates steel blade shots and grants brief protection.",
      kind: :projectile_overdrive, type: :STEEL, cooldown: 52.0, damage: 0, radius: 120, haste_time: 5.0, haste_mult: 0.24, shield: 1.6, vfx: "VFX_STEEL_ORBIT"
    },
    :DRILBUR => {
      id: :ultimate_drilbur, name: "Drill Overdrive",
      desc: "Fires repeated rings of steel spines and briefly shields the Pokemon.",
      kind: :drilbur_spike_burst, type: :STEEL, cooldown: 46.0, damage: 18, speed: 7.6, pierce: 4, count: 8, radius: 126, burst_time: 5.0, interval: 0.32, shield: 1.4, vfx: "VFX_STEEL4"
    },
    :VENIPEDE => {
      id: :ultimate_venipede, name: "Toxic Stampede",
      desc: "Scatters fast bug shots around the Pokemon and briefly freezes enemies.",
      kind: :radial, type: :BUG, cooldown: 42.0, damage: 26, speed: 7.2, count: 24, pierce: 3, radius: 116, freeze: 0.7, vfx: "VFX_BUG"
    },
    :VANILLITE => {
      id: :ultimate_vanillite, name: "Whiteout Crown",
      desc: "Creates a wide ice field that damages and freezes nearby enemies.",
      kind: :zone, type: :ICE, cooldown: 47.0, damage: 38, radius: 158, freeze: 1.4, dot: 2.6, vfx: "VFX_ICE"
    },
    :DEINO => {
      id: :ultimate_deino, name: "Dark Dragon Rush",
      desc: "Fires piercing dragon projectiles in a focused barrage.",
      kind: :sonic_swarm, type: :DRAGON, cooldown: 50.0, damage: 48, speed: 7.2, count: 4, pierce: 5, radius: 132, burst_time: 4.5, knockback: 36, vfx: "VFX_DRAGON4"
    },
    :LARVESTA => {
      id: :ultimate_larvesta, name: "Sun Moth Spiral",
      desc: "Sends hot fire arcs around the Pokemon and burns nearby enemies.",
      kind: :radial, type: :FIRE, cooldown: 44.0, damage: 30, speed: 7.4, count: 30, pierce: 3, radius: 122, dot: 2.4, vfx: "VFX_FIRE2"
    },
    :ZORUA => {
      id: :ultimate_zorua, name: "Night Mirage",
      desc: "Unleashes a mirage of dark bolts that slows enemies and grants a short safeguard.",
      kind: :radial, type: :DARK, cooldown: 46.0, damage: 34, speed: 6.8, count: 20, pierce: 3, radius: 130, slow: 1.8, shield: 1.2, vfx: "VFX_DARK2"
    },
    :ZORUA_1 => {
      id: :ultimate_zorua_hisui, name: "Twin Eclipse",
      desc: "Releases alternating ghost and normal rings, slowing one wave and pushing the next away.",
      kind: :twin_eclipse, type: :GHOST, cooldown: 47.0, damage: 34, speed: 6.8, count: 18, pierce: 3, radius: 134, slow: 2.0, knockback: 70, shield: 1.0, vfx: "VFX_GHOST"
    },
    :FENNEKIN => {
      id: :ultimate_fennekin, name: "Mystic Foxfire",
      desc: "Calls crossing foxfire waves that seek targets and burn through groups.",
      kind: :radial, type: :FIRE, cooldown: 42.0, damage: 31, speed: 7.1, count: 24, pierce: 3, radius: 128, dot: 3.0, slow: 1.0, vfx: "VFX_FIRE2"
    },
    :FROAKIE => {
      id: :ultimate_froakie, name: "Shuriken Rain",
      desc: "Throws a rapid storm of bouncing water blades around the Pokemon.",
      kind: :radial, type: :WATER, cooldown: 40.0, damage: 25, speed: 7.5, count: 30, pierce: 1, bounce: 2, radius: 118, knockback: 28, vfx: "VFX_WATER"
    },
    :HONEDGE => {
      id: :ultimate_honedge, name: "Royal Guard",
      desc: "Summons a steel blade storm and grants a brief defensive guard.",
      kind: :steel_rain, type: :STEEL, cooldown: 50.0, damage: 42, radius: 54, count: 12, pierce: 4, shield: 2.2, knockback: 46, vfx: "VFX_STEEL"
    },
    :GOOMY => {
      id: :ultimate_goomy, name: "Mucus Monsoon",
      desc: "Covers the area in sticky dragon zones that slow crowds and soften pressure.",
      kind: :sand_pit, type: :DRAGON, cooldown: 48.0, damage: 34, radius: 158, count: 6, slow: 3.4, slow_mult: 0.16, dot: 3.4, knockback: 8, shield: 1.4, vfx: "VFX_DRAGON4"
    },
    :NOIBAT => {
      id: :ultimate_noibat, name: "Echo Cyclone",
      desc: "Releases layered sound waves that sweep the screen and briefly slow enemies.",
      kind: :sonic_swarm, type: :FLYING, cooldown: 43.0, damage: 24, speed: 8.0, count: 5, pierce: 5, radius: 140, burst_time: 4.0, slow: 1.2, knockback: 24, vfx: "VFX_FLYING"
    },
    :TYRUNT => {
      id: :ultimate_tyrunt, name: "Ancient Quake",
      desc: "Releases expanding ground shockwaves that smash enemies around the Pokemon.",
      kind: :tyrunt_shockwave, type: :GROUND, cooldown: 55.0, damage: 54, count: 3, radius: 178, vfx: "VFX_GROUND2", vfx_fps: 24
    },
    :HAWLUCHA => {
      id: :ultimate_hawlucha, name: "Flying Press Rush",
      desc: "Chains fast fighting waves in the faced direction and briefly empowers movement.",
      kind: :fighting_wave, type: :FIGHTING, cooldown: 41.0, damage: 40, speed: 7.2, count: 7, pierce: 6, radius: 142, knockback: 86, power_time: 3.5, vfx: "VFX_FIGHTING2"
    },
    :MAGIKARP => {
      id: :ultimate_magikarp, name: "Tiny Splash",
      desc: "Creates a small harmless splash with only a light push around Magikarp.",
      kind: :radial, type: :WATER, cooldown: 5.0, damage: 4, speed: 4.4, count: 8, pierce: 1, radius: 54, knockback: 14, instant_ko_normal: true, vfx: "VFX_WATER"
    },
    :GYARADOS => {
      id: :ultimate_gyarados, name: "Raging Tempest",
      desc: "For 5 seconds, attacks hit far harder and fire much faster.",
      kind: :projectile_overdrive, type: :WATER, cooldown: 15.0, damage: 0, radius: 150, haste_time: 5.0, haste_mult: 0.2, power_time: 5.0, power_mult: 5.0, clear_shots: true, vfx: "VFX_WATER"
    },
    :FEEBAS => {
      id: :ultimate_feebas, name: "Prism Tide",
      desc: "Fires eight water shots that instantly defeat regular enemies, but not bosses or mini-bosses.",
      kind: :radial, type: :WATER, cooldown: 5.0, damage: 4, speed: 4.4, count: 8, pierce: 1, radius: 54, knockback: 14, instant_ko_normal: true, vfx: "VFX_WATER"
    },
    :MILOTIC => {
      id: :ultimate_milotic, name: "Prism Tempest",
      desc: "For 5 seconds, fairy attacks hit far harder and fire much faster.",
      kind: :projectile_overdrive, type: :FAIRY, cooldown: 15.0, damage: 0, radius: 150, haste_time: 5.0, haste_mult: 0.2, power_time: 5.0, power_mult: 5.0, clear_shots: true, vfx: "VFX_FAIRY_ZONE", vfx_loop: true
    },
    :ROWLET => {
      id: :ultimate_rowlet, name: "Verdant Orbit",
      desc: "Speeds up grass orbits and fills the screen with bouncing leaves.",
      kind: :radial, type: :GRASS, cooldown: 43.0, damage: 30, speed: 7.1, count: 26, pierce: 2, bounce: 2, radius: 124, power_time: 4.0, vfx: "VFX_GRASS"
    },
    :GRUBBIN => {
      id: :ultimate_grubbin, name: "Battery Storm",
      desc: "Throws a fast storm of piercing electric shots that paralyze enemies.",
      kind: :radial, type: :ELECTRIC, cooldown: 43.0, damage: 27, speed: 7.8, count: 28, pierce: 3, radius: 126, freeze: 0.9, knockback: 20, vfx: "VFX_ELECTRIC3_SHOT"
    },
    :WIMPOD => {
      id: :ultimate_wimpod, name: "Toxic Escape",
      desc: "Splits poisonous bug shots through nearby crowds and grants a short shield.",
      kind: :radial, type: :BUG, cooldown: 45.0, damage: 30, speed: 7.0, count: 18, pierce: 1, radius: 132, impact_homing: 3, impact_type: :POISON, impact_vfx: "VFX_POISON", impact_dot: 2.8, shield: 1.4, vfx: "VFX_BUG3"
    },
    :JANGMOO => {
      id: :ultimate_jangmoo, name: "Clanging Lances",
      desc: "Fires dense fighting lances in every direction with strong piercing power.",
      kind: :radial, type: :FIGHTING, cooldown: 48.0, damage: 40, speed: 7.1, count: 24, pierce: 99, radius: 134, knockback: 42, vfx: "VFX_FIGHTING3"
    },
    :MIMIKYU => {
      id: :ultimate_mimikyu, name: "Gem Disguise",
      desc: "Dark gems rain down and pull experience closer.",
      kind: :gem_rain, type: :DARK, cooldown: 62.0, damage: 38, radius: 48, count: 10, dot: 3.0, magnet_time: 5.0
    },
    :ROCKRUFF => {
      id: :ultimate_rockruff, name: "Dusk Rush",
      desc: "Fires fast piercing rocks in a focused barrage and briefly boosts movement.",
      kind: :sonic_swarm, type: :ROCK, cooldown: 44.0, damage: 35, speed: 7.0, count: 4, pierce: 7, radius: 128, burst_time: 4.0, knockback: 68, knock_limit: 99, power_time: 3.0, vfx: "VFX_ROCK2"
    },
    :MEW => {
      id: :ultimate_mew, name: "Ancient Pulse",
      desc: "Unleashes a random ancient type burst with a small safeguard.",
      kind: :mew_random, type: :PSYCHIC, cooldown: 56.0, damage: 48, speed: 6.0, pierce: 4, radius: 165, count: 10, slow: 2.0, shield: 1.2, heal: 0.10
    },
    :DEOXYS => {
      id: :ultimate_deoxys, name: "Psycho Break",
      desc: "Sweeps dense psychic blades outward from the Pokemon.",
      kind: :radial, type: :PSYCHIC, cooldown: 50.0, damage: 42, speed: 8.2, count: 24, pierce: 6, knockback: 42
    }
  }

  SKILLS[:shell_rain] = { name: "Shell Shower", desc: "Rain falls on nearby enemies and bursts into waves of damage.",
    kind: :impact_rain, type: :WATER, cooldown: 1.8, count: 2, max_count: 6,
    damage: 12, radius: 12, vfx: "VFX_WATER", impact_type: :WATER,
    impact_vfx: "VFX_WATER4", impact_frames: 8, impact_damage: 3, impact_radius: 30 }
  SKILLS[:bone_return] = { name: "Bone Return", desc: "Returning bones cause repeated ground impacts that paralyze enemies.",
    kind: :boomerang, type: :GROUND, cooldown: 1.4, speed: 5.5, damage: 18,
    count: 1, max_count: 5, pierce: 99, vfx: "VFX_GROUND5", vfx_loop: true,
    infinite_pierce: true, keep_until_expiry: true, hit_interval: 0.4,
    impact_flurry: true, impact_type: :GROUND, impact_vfx: "VFX_GROUND6",
    impact_frames: 6, impact_damage: 3, impact_radius: 30, impact_freeze: 0.6 }
  SKILLS[:ancestral_flames] = { name: "Ancestral Flames", desc: "Up to four flames pursue enemies, circling you when no targets remain.",
    kind: :pursuit_guard, type: :FIRE, cooldown: 4.0, speed: 5.5, damage: 18,
    count: 1, max_count: 4, pierce: 1, vfx: "VFX_FIRE10", vfx_loop: true }
  SKILLS[:iron_jaw] = SKILLS[:fossil_jaw].merge(name: "Iron Jaw",
    desc: "Steel jaws strike nearby enemies and paralyze them.", type: :STEEL,
    vfx: "VFX_STEEL8", vfx_frames: 12)
  SKILLS[:volt_orbit] = SKILLS[:water_orbit].merge(name: "Volt Ring",
    desc: "Circling sparks fire bouncing Electric shots.", type: :ELECTRIC,
    orbit_vfx: "VFX_ELECTRIC2", vfx: "VFX_ELECTRIC2_SHOT")
  SKILLS[:toxic_drag] = { name: "Venom Undertow", desc: "Poison shots pull nearby enemies into repeated venom impacts.",
    kind: :projectile, type: :POISON, cooldown: 1.25, damage: 14, speed: 4.8,
    count: 1, max_count: 5, pierce: 1, vfx: "VFX_POISON",
    impact_flurry: true, impact_type: :POISON, impact_vfx: "VFX_POISON5",
    impact_frames: 15, impact_damage: 2, impact_radius: 36, impact_pull_radius: 110.0 }
  SKILLS[:volcanic_guard] = { name: "Volcanic Guard", desc: "Summons burning tornadoes around you.",
    kind: :guard_twister, type: :FIRE, cooldown: 2.4, damage: 9, radius: 32,
    duration: 2.0, count: 2, max_count: 6, dot: 2.0, vfx: "VFX_FIRE3" }
  SKILLS[:thunder_relay] = { name: "Thunder Relay", desc: "Electric bolts paralyze enemies and release a spark that seeks three other targets.",
    kind: :projectile, type: :ELECTRIC, cooldown: 1.1, damage: 20, speed: 6.0,
    count: 1, max_count: 5, pierce: 1, freeze: 0.6, vfx: "VFX_ELECTRIC3", relay_spark: true }
  SKILLS[:aurora_orbit] = SKILLS[:psychic_sweep].merge(name: "Aurora Ring",
    desc: "Water orbs fire shots that burst into waves of damage. Contact defeats regular enemies before the orb briefly disappears.",
    type: :WATER, orbit_vfx: "VFX_WATER", vfx: "VFX_WATER5",
    impact_flurry: true, impact_type: :WATER, impact_vfx: "VFX_WATER6",
    impact_frames: 6, impact_damage: 3, impact_radius: 32)

  SKILLS[:forest_echo] = {
    name: "Forest Echo", desc: "Psychic shots release homing leaves that burst against other enemies.",
    kind: :projectile, type: :PSYCHIC, cooldown: 1.35, damage: 26,
    speed: 5.5, count: 1, max_count: 5, pierce: 1,
    vfx: "VFX_PSYCHIC8", vfx_frames: 12, vfx_loop: true, vfx_fps: 24,
    forest_relay: true, relay_count: 1
  }
  SKILLS[:victory_flurry] = SKILLS[:disciplined_strikes].merge(
    name: "Victory Flurry", desc: "Light Fire strikes ignite powerful explosions that burn and push enemies away.",
    type: :FIRE, damage: 2, cooldown: 1.35, vfx: "VFX_FIRE11",
    impact_flurry: true, impact_once: true, impact_type: :FIRE,
    impact_vfx: "VFX_FIRE6", impact_frames: 12, impact_damage: 5,
    impact_radius: 32, impact_dot: 2.5, impact_knockback: 35
  )

  UPGRADE_POOL = [
    { id: :learn_forest_echo, name: "Learn Forest Echo", desc: "Adds Psychic shots that release explosive homing leaves.", max: 1, skill: :forest_echo, rarity: :epic },
    { id: :learn_victory_flurry, name: "Learn Victory Flurry", desc: "Adds Fire strikes with burning explosions.", max: 1, skill: :victory_flurry, rarity: :epic },
    { id: :learn_bloom_trick, name: "Learn Bloom Trick", desc: "Adds seeking leaves that release a flurry of Grass cuts.", max: 1, skill: :bloom_trick, rarity: :epic },
    { id: :learn_cinder_song, name: "Learn Cinder Song", desc: "Adds fire shots that raise burning tornadoes.", max: 1, skill: :cinder_song, rarity: :epic },
    { id: :learn_volt_pummel, name: "Learn Volt Pummel", desc: "Adds Fighting blows that send sparks at other enemies.", max: 1, skill: :volt_pummel, rarity: :epic },
    { id: :learn_ember_armor, name: "Learn Ember Armor", desc: "Adds flames that burst and burn on impact.", max: 1, skill: :ember_armor, rarity: :rare },
    { id: :learn_frost_fang, name: "Learn Frost Fang", desc: "Adds seeking ice fangs with slowing explosions.", max: 1, skill: :frost_fang, rarity: :epic },
    { id: :learn_fairy_hammer, name: "Learn Fairy Hammer", desc: "Adds a Steel sweep followed by repeated Fairy hits.", max: 1, skill: :fairy_hammer, rarity: :epic },
    { id: :learn_gold_rush, name: "Learn Gold Rush", desc: "Adds seeking coins that explode and freeze enemies.", max: 1, skill: :gold_rush, rarity: :epic },
    { id: :learn_headache, name: "Learn Headache", desc: "Adds an unreliable but powerful Psychic charge. Fires without charging once your Pokemon is fully developed.", max: 1, skill: :headache, rarity: :epic },
    { id: :learn_night_raid, name: "Learn Night Raid", desc: "Adds Dark sweeps aimed at nearby enemies.", max: 1, skill: :night_raid, rarity: :epic },
    { id: :learn_psi_trail, name: "Learn Psi Trail", desc: "Dash leaves bouncing homing Psychic shots. No automatic shots on other Pokemon.", max: 1, skill: :psi_trail, rarity: :rare },
    { id: :learn_ember_sphere, name: "Learn Ember Sphere", desc: "Adds orbiting Fire spheres that burn and burst on impact.", max: 1, skill: :ember_sphere, rarity: :epic },
    { id: :learn_volt_sphere, name: "Learn Volt Sphere", desc: "Adds orbiting Electric spheres that paralyze and burst on impact.", max: 1, skill: :volt_sphere, rarity: :epic },
    { id: :learn_tidal_sphere, name: "Learn Tidal Sphere", desc: "Adds orbiting Water spheres that push and burst on impact.", max: 1, skill: :tidal_sphere, rarity: :epic },
    { id: :learn_psy_sphere, name: "Learn Psy Sphere", desc: "Adds orbiting Psychic spheres that slow and burst on impact.", max: 1, skill: :psy_sphere, rarity: :epic },
    { id: :learn_dusk_sphere, name: "Learn Dusk Sphere", desc: "Adds orbiting Dark spheres that slow and burst on impact.", max: 1, skill: :dusk_sphere, rarity: :epic },
    { id: :learn_leaf_sphere, name: "Learn Leaf Sphere", desc: "Adds orbiting Grass spheres that paralyze and burst on impact.", max: 1, skill: :leaf_sphere, rarity: :epic },
    { id: :learn_frost_sphere, name: "Learn Frost Sphere", desc: "Adds orbiting Ice spheres that push and burst on impact.", max: 1, skill: :frost_sphere, rarity: :epic },
    { id: :learn_charm_sphere, name: "Learn Charm Sphere", desc: "Adds powerful orbiting Fairy spheres that burst on impact.", max: 1, skill: :charm_sphere, rarity: :legendary },
    { id: :learn_night_fang, name: "Learn Night Fang", desc: "Adds Dark fangs that briefly paralyze nearby enemies.", max: 1, skill: :night_fang, rarity: :legendary },
    { id: :learn_disciplined_strikes, name: "Learn Disciplined Strikes", desc: "Adds a flurry of nine close-range Fighting hits.", max: 1, skill: :disciplined_strikes, rarity: :epic },
    { id: :learn_toxic_spark, name: "Learn Toxic Spark", desc: "Adds Electric shots with poisonous impact blasts.", max: 1, skill: :toxic_spark, rarity: :super_rare },
    { id: :learn_mischief_sweep, name: "Learn Mischief Sweep", desc: "Adds a close-range Dark sweep around you.", max: 1, skill: :mischief_sweep, rarity: :epic },
    { id: :learn_fae_bloom, name: "Learn Fae Bloom", desc: "Adds powerful Fairy waves that grow as they travel.", max: 1, skill: :fae_bloom, rarity: :epic },
    { id: :learn_phantom_warhead, name: "Learn Phantom Warhead", desc: "Adds a Ghost shot with a powerful Dragon explosion. Gains a second shot as your Pokemon develops.", max: 1, skill: :phantom_warhead, rarity: :epic },
    { id: :learn_iron_gale, name: "Learn Numbing Gale", desc: "Adds drifting Flying tornadoes that briefly paralyze.", max: 1, skill: :iron_gale, rarity: :epic },
    { id: :learn_steel_gale, name: "Learn Steel Gale", desc: "Adds drifting Steel tornadoes that briefly paralyze.", max: 1, skill: :steel_gale, rarity: :epic },
    { id: :learn_ember_strike, name: "Learn Ember Strike", desc: "Adds fire shots that explode and burn nearby enemies.", max: 1, skill: :ember_strike, rarity: :epic },
    { id: :learn_splash, name: "Learn Splash", desc: "Deals no damage at first. Unlocks the powerful Hydro Pump once your Pokemon is fully developed.", max: 1, skill: :splash, rarity: :epic },
    { id: :learn_normal_sweep, name: "Learn Rival Sweep", desc: "Adds a close-range sweep around you.", max: 1, skill: :normal_sweep, rarity: :epic },
    { id: :learn_leaf_blade_sweep, name: "Learn Leaf Blade Sweep", desc: "Adds grass sweeps aimed at nearby enemies.", max: 1, skill: :leaf_blade_sweep, rarity: :epic },
    { id: :learn_apple_aegis, name: "Learn Apple Aegis", desc: "Adds shot-blocking apples that briefly paralyze on hit.", max: 1, skill: :apple_aegis, rarity: :epic },
    { id: :damage,       name: "Power Up",          desc: "Attack damage +8%.",                    max: 12, rarity: :common },
    { id: :damage_plus,  name: "Heavy Power",        desc: "Attack damage +15%.",                   max: 6,  rarity: :rare },
    { id: :speed,        name: "Fast Attacks",        desc: "All skill recharge times -4%.",                  max: 10, rarity: :common },
    { id: :speed_plus,   name: "Rapid Attacks",       desc: "All skill recharge times -10%.",                 max: 4,  rarity: :super_rare },
    { id: :count,        name: "Extra Strike",      desc: "Launch one extra attack.",              max: 3,  rarity: :epic },
    { id: :move,         name: "Swift Steps",       desc: "Movement speed +5%.",                   max: 8,  rarity: :common },
    { id: :move_plus,    name: "Fleet Instinct",    desc: "Movement speed +12%.",                  max: 3,  rarity: :rare },
    { id: :dash_training, name: "Dash Training",     desc: "Dash cooldown -1.5s, down to a minimum of 3s.", max: 6, rarity: :rare },
    { id: :max_hp_small, name: "Vital Spark",       desc: "Max HP +8 and recover 8 HP.",           max: 10, rarity: :common },
    { id: :max_hp,       name: "Endurance",         desc: "Max HP +20 and recover 20 HP.",         max: 6,  rarity: :rare },
    { id: :magnet_small, name: "Gather Sense",      desc: "XP pickup range +12%.",                 max: 8,  rarity: :common },
    { id: :magnet,       name: "Wide Sense",        desc: "XP pickup range +25%.",                 max: 4,  rarity: :rare },
    { id: :expgain_small,name: "Battle Notes",      desc: "Experience gained +5%.",                max: 8,  rarity: :common },
    { id: :expgain,      name: "Battle Study",      desc: "Experience gained +15%.",               max: 4,  rarity: :super_rare },
    { id: :shield_small, name: "Guard Step",        desc: "Enemy contact damage -4%.",             max: 8,  rarity: :common },
    { id: :shield,       name: "Guard Stance",      desc: "Enemy contact damage -8%.",             max: 5,  rarity: :rare },
    { id: :projectile_guard, name: "Warding Veil",  desc: "Enemy projectile damage -12%.",         max: 4,  rarity: :rare },
    { id: :lifesteal, name: "Vampiric Pulse",       desc: "Damaging hits can restore 0.1% to 0.5% HP, improving from 1-in-200 to 1-in-150.", max: 5, rarity: :super_rare },
    { id: :burst_charge, name: "Burst Flow",        desc: "Burst gauge charges +8% faster.",       max: 5,  rarity: :rare },
    { id: :burst_charge_plus, name: "Overcharge",   desc: "Burst gauge charges +15% faster.",      max: 3,  rarity: :epic },
    { id: :boss_damage,  name: "Boss Hunter",       desc: "Damage to Boss Pokemon +12%.",          max: 4,  rarity: :super_rare },
    { id: :chestxp,      name: "Mini Boss Training", desc: "Mini Bosses give more EXP.",            max: 4,  rarity: :rare },
    { id: :legend_pulse, name: "Legend Pulse",      desc: "Damage +15%, Burst charge +15%, and one extra attack.", max: 1, rarity: :legendary },
    { id: :second_wind,  name: "Second Wind",       desc: "Once per run, survive a fatal hit and recover 25% HP.",  max: 1, rarity: :legendary },
    { id: :wide_cast,    name: "Wide Range",         desc: "Skill range and hit area +6.",             max: 4, rarity: :rare },
    { id: :quick_recovery, name: "Quick Recharge",  desc: "Main skill recharge time -8%.",                  max: 3, rarity: :rare },
    { id: :element_focus, name: "Elemental Power",    desc: "Attacks matching your Pokemon type deal +7% damage.",                     max: 4, rarity: :super_rare },
    { id: :status_mastery, name: "Status Mastery",  desc: "Freeze, slow, and damage-over-time durations +12%.", max: 3, rarity: :rare },
    { id: :rare_draft,   name: "Rare Draft",        desc: "Rare choices appear more often this run.",   max: 3, rarity: :epic },
    { id: :floor_momentum, name: "Floor Momentum",  desc: "Clearing Tower floors slowly increases your damage.", max: 3, rarity: :rare },
    { id: :boss_preparation, name: "Boss Preparation", desc: "Recover HP before Tower boss floors.",    max: 3, rarity: :rare },
    { id: :overlevel_instinct, name: "Limit Break", desc: "Levels past 100 give better overlevel bonuses.", max: 3, rarity: :super_rare },
    { id: :clean_focus,  name: "Clean Charge",       desc: "Burst charges faster while you avoid damage.", max: 5, rarity: :rare },
    { id: :guarded_heart, name: "Guarded Heart",    desc: "All damage taken -3%.",                     max: 5, rarity: :common },
    { id: :learn_psychic_well, name: "Learn Psy Vortex", desc: "Adds homing Psychic shots that create pulling damage fields.", max: 1, skill: :psychic_well, rarity: :epic },
    { id: :learn_normal_shot, name: "Learn Swift Star", desc: "Adds steady normal shots.", max: 1, skill: :normal_shot, rarity: :common },
    { id: :learn_leaf,    name: "Learn Leaf Shot",   desc: "Adds piercing leaf attacks.",   max: 1, skill: :leaf, rarity: :uncommon },
    { id: :learn_fire,    name: "Learn Ember Burst", desc: "Adds fast ember attacks.",      max: 1, skill: :fire, rarity: :rare },
    { id: :learn_flying_gust, name: "Learn Gust Shot", desc: "Adds fast flying gust attacks.", max: 1, skill: :flying_gust, rarity: :uncommon },
    { id: :learn_bug_thread, name: "Learn Silk Sting", desc: "Adds bug shots that briefly freeze enemies.", max: 1, skill: :bug_thread, rarity: :rare },
    { id: :learn_toxic_thread, name: "Learn Toxic Thread", desc: "Adds poisonous bug shots that push enemies back.", max: 1, skill: :toxic_thread, rarity: :super_rare },
    { id: :learn_charge_spark, name: "Learn Charge Spark", desc: "Adds a charged electric shot.", max: 1, skill: :charge_spark, rarity: :super_rare },
    { id: :learn_rock_pierce, name: "Learn Stone Spear", desc: "Adds piercing stones with a short push.", max: 1, skill: :rock_pierce, rarity: :super_rare },
    { id: :learn_vine_gust, name: "Learn Vine Gust", desc: "Adds quick grass gust attacks.", max: 1, skill: :vine_gust, rarity: :uncommon },
    { id: :learn_water_orbit, name: "Learn Bubble Ring", desc: "Adds orbiting bubbles that fire water shots.", max: 1, skill: :water_orbit, rarity: :epic },
    { id: :learn_echo_charge, name: "Learn Echo Charge", desc: "Adds a charged sound orb that splits on impact.", max: 1, skill: :echo_charge, rarity: :epic },
    { id: :learn_dragon_shot, name: "Learn Dragon Needle", desc: "Adds piercing dragon bolts.", max: 1, skill: :dragon_shot, rarity: :rare },
    { id: :learn_water,   name: "Learn Water Pulse", desc: "Adds wide water attacks.",      max: 1, skill: :water, rarity: :rare },
    { id: :learn_psychic, name: "Learn Psy Wave",    desc: "Adds rotating psychic attacks.", max: 1, skill: :psychic, rarity: :super_rare },
    { id: :learn_psychic_sweep, name: "Learn Psy Orbit", desc: "Adds psychic orbs that fire slower shots.", max: 1, skill: :psychic_sweep, rarity: :epic },
    { id: :learn_poison_aura,  name: "Learn Toxic Aura",   desc: "Adds a close poison aura.",          max: 1, skill: :poison_aura, rarity: :rare },
    { id: :learn_thunder_ring, name: "Learn Thunder Ring", desc: "Adds a wide lightning ring.",        max: 1, skill: :thunder_ring, rarity: :epic },
    { id: :learn_rock_burst,   name: "Learn Rock Burst",   desc: "Adds attacks in every direction.",   max: 1, skill: :rock_burst, rarity: :epic },
    { id: :learn_ice_zone,     name: "Learn Frost Zone",   desc: "Adds strikes on enemy groups.",      max: 1, skill: :ice_zone, rarity: :rare },
    { id: :learn_ice_shatter,  name: "Learn Ice Shatter", desc: "Adds ice shards that split into homing fragments.", max: 1, skill: :ice_shatter, rarity: :epic },
    { id: :learn_fairy_guard,  name: "Learn Fairy Guard",  desc: "Adds damage against close enemies.", max: 1, skill: :fairy_guard, rarity: :rare },
    { id: :learn_steel_orbit,  name: "Learn Iron Orbit",   desc: "Adds circling steel shots.",          max: 1, skill: :steel_orbit, rarity: :super_rare },
    { id: :learn_drill_spikes, name: "Learn Steel Spines", desc: "Adds short steel lances around the Pokemon.", max: 1, skill: :drill_spikes, rarity: :epic },
    { id: :learn_steel_volley, name: "Learn Iron Shards", desc: "Adds returning steel blades that push enemies once.", max: 1, skill: :steel_volley, rarity: :epic },
    { id: :learn_ground_spike, name: "Learn Ground Spike", desc: "Adds ground strikes near enemy groups.", max: 1, skill: :ground_spike, rarity: :rare },
    { id: :learn_sandile_ground_zone, name: "Learn Sand Pit", desc: "Adds slowing ground zones under enemy groups.", max: 1, skill: :sandile_ground_zone, rarity: :super_rare },
    { id: :learn_fighting_dash, name: "Learn Focus Wave", desc: "Adds a strong focused strike.", max: 1, skill: :fighting_dash, rarity: :super_rare },
    { id: :learn_dark_wave, name: "Learn Umbral Wave", desc: "Adds wide dark waves.", max: 1, skill: :dark_wave, rarity: :rare },
    { id: :learn_dragon_arc, name: "Learn Dragon Arc", desc: "Adds rotating dragon lines.", max: 1, skill: :dragon_arc, rarity: :epic },
    { id: :learn_ghost_wisp, name: "Learn Ghost Wisp", desc: "Adds seeking ghost wisps.", max: 1, skill: :ghost_wisp, rarity: :rare },
    { id: :learn_litwick_ghost_bounce, name: "Learn Spectral Bounce", desc: "Adds ghost shots that bounce between enemies.", max: 1, skill: :litwick_ghost_bounce, rarity: :super_rare },
    { id: :learn_fire2_combo, name: "Learn Flame Combo", desc: "Adds quick flame volleys.", max: 1, skill: :fire2_combo, rarity: :epic },
    { id: :learn_cinder_swarm, name: "Learn Cinder Swarm", desc: "Adds seeking fire wisps that split on impact.", max: 1, skill: :cinder_swarm, rarity: :epic },
    { id: :learn_flying_spread, name: "Learn Wing Scatter", desc: "Adds multidirectional flying shots.", max: 1, skill: :flying_spread, rarity: :epic },
    { id: :learn_shinx_charge, name: "Learn Spark Break", desc: "Adds charged electric shots that seek targets after impact.", max: 1, skill: :shinx_charge, rarity: :epic },
    { id: :learn_dragon_pierce, name: "Learn Dragon Fang", desc: "Adds heavy piercing dragon shots.", max: 1, skill: :dragon_pierce, rarity: :legendary },
    { id: :learn_dragon_pulse, name: "Learn Draco Lance", desc: "Adds special piercing dragon lances.", max: 1, skill: :dragon_pulse, rarity: :super_rare },
    { id: :learn_night_bolt, name: "Learn Night Bolt", desc: "Adds slower but stronger dark shots.", max: 1, skill: :night_bolt, rarity: :super_rare },
    { id: :learn_twin_mirage, name: "Learn Twin Mirage", desc: "Adds paired ghost and normal orbs.", max: 1, skill: :twin_mirage, rarity: :legendary },
    { id: :learn_aura_charge, name: "Learn Aura Seeker", desc: "Adds a strong guided fighting shot.", max: 1, skill: :aura_charge, rarity: :epic },
    { id: :learn_toxic_bounce, name: "Learn Toxic Ricochet", desc: "Adds bouncing poison shots.", max: 1, skill: :toxic_bounce, rarity: :super_rare },
    { id: :learn_foxfire_seek, name: "Learn Foxfire Flank", desc: "Adds side flames that seek targets and burn them.", max: 1, skill: :foxfire_seek, rarity: :super_rare },
    { id: :learn_water_shuriken, name: "Learn Aqua Shuriken", desc: "Adds fast ricocheting water blades.", max: 1, skill: :water_shuriken, rarity: :rare },
    { id: :learn_living_blade, name: "Learn Spirit Blade", desc: "Adds steel blades that circle halfway around you and return.", max: 1, skill: :living_blade, rarity: :epic },
    { id: :learn_slime_wave, name: "Learn Dragon Trail", desc: "Adds sticky dragon trails that slow and damage enemies.", max: 1, skill: :slime_wave, rarity: :super_rare },
    { id: :learn_sonic_wave, name: "Learn Gale Ring", desc: "Adds flying orbs that push and fire bouncing gusts.", max: 1, skill: :sonic_wave, rarity: :epic },
    { id: :learn_fossil_jaw, name: "Learn Rock Claw", desc: "Adds rocky claws that paralyze nearby targets.", max: 1, skill: :fossil_jaw, rarity: :legendary },
    { id: :learn_sky_press, name: "Learn Sky Press", desc: "Adds guided fighting strikes with strong push.", max: 1, skill: :sky_press, rarity: :epic },
    { id: :learn_fairy_pump, name: "Learn Fairy Splash", desc: "Deals no damage at first. Unlocks the powerful Fairy Surge once your Pokemon is fully developed.", max: 1, skill: :fairy_splash, rarity: :epic },
    { id: :learn_leaf_orbit, name: "Learn Leaf Ring", desc: "Adds grass orbs that counter on contact.", max: 1, skill: :leaf_orbit, rarity: :epic },
    { id: :learn_battery_shuriken, name: "Learn Spark Shuriken", desc: "Adds piercing electric blades that paralyze enemies.", max: 1, skill: :battery_shuriken, rarity: :rare },
    { id: :learn_toxic_scuttle, name: "Learn Toxic Scuttle", desc: "Adds bug shots that split into poisonous homing fragments.", max: 1, skill: :toxic_scuttle, rarity: :epic },
    { id: :learn_scale_lance, name: "Learn Scale Lance", desc: "Adds piercing fighting scales.", max: 1, skill: :scale_lance, rarity: :rare },
    { id: :learn_fairy_arc, name: "Learn Fairy Arc", desc: "Adds rotating fairy blades.", max: 1, skill: :fairy_arc, rarity: :epic },
    { id: :learn_rock_run, name: "Learn Rock Rush", desc: "Adds piercing rocks that push every target.", max: 1, skill: :rock_run, rarity: :super_rare },
  ]
end



























