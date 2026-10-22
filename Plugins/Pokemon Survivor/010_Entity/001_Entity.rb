#===============================================================================
# Pokemon Survivor - Entity model
#===============================================================================

class PokemonSurvivorEntity
  attr_accessor :x, :y, :vx, :vy, :hp, :max_hp, :kind, :name, :damage, :speed
  attr_accessor :cooldown, :age, :pierce, :value, :radius, :bitmap, :color, :ttl
  attr_accessor :direction, :moving, :walk_bitmap, :idle_bitmap, :charset_directions
  attr_accessor :types, :attack_type, :archetype
  attr_accessor :owner, :shooter
  attr_accessor :bounces, :boomerang, :homing, :slow_timer, :slow_mult, :freeze_timer
  attr_accessor :dot_timer, :dot_tick_timer, :dot_damage, :dot_type, :dot_source
  attr_accessor :orbit_target, :orbit_angle, :orbit_radius, :orbit_growth, :split_done
  attr_accessor :vfx_name, :source_skill, :homing_target, :homing_refresh
  attr_accessor :status_locks, :knockback_count, :hit_cooldowns, :defeated
  attr_accessor :orbit_remaining, :vfx_scale, :apple_launch_targets
  attr_accessor :tornado_motion

  def initialize(kind, name, x, y)
    @kind = kind
    @name = name
    @x = x.to_f
    @y = y.to_f
    @vx = 0.0
    @vy = 0.0
    @hp = 1
    @max_hp = 1
    @damage = 1
    @speed = 1.0
    @cooldown = 0.0
    @age = 0.0
    @pierce = 1
    @value = 1
    @radius = 12
    @bitmap = nil
    @color = Color.new(255, 255, 255)
    @ttl = 6.0
    @direction = PokemonSurvivor::DIR_DOWN
    @moving = false
    @walk_bitmap = nil
    @idle_bitmap = nil
    @charset_directions = PokemonSurvivor::CHARSET_DIRECTIONS
    @types = [:NORMAL]
    @attack_type = :NORMAL
    @archetype = :normal
    @owner = :neutral
    @shooter = false
    @bounces = 0
    @boomerang = false
    @homing = false
    @slow_timer = 0.0
    @slow_mult = 0.45
    @freeze_timer = 0.0
    @dot_timer = 0.0
    @dot_tick_timer = 0.0
    @dot_damage = 0
    @dot_type = nil
    @dot_source = nil
    @orbit_target = nil
    @orbit_angle = 0.0
    @orbit_radius = 0.0
    @orbit_growth = 0.0
    @split_done = false
    @vfx_name = nil
    @source_skill = nil
    @homing_target = nil
    @homing_refresh = 0.0
    @status_locks = {}
    @knockback_count = 0
    @hit_cooldowns = {}
    @defeated = false
  end
end




