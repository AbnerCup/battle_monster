#===============================================================================
# Pokemon Survivor - Generic Mega Evolution equipment support
# Extends the CHARIZARDITE Mega system to other compatible final forms.
#===============================================================================

module PokemonSurvivor
  MEGA_EVOLUTION_DATA = [
    { item: :mawilite, item_name: "Mawilite", icon: "MAWILITE", line: [:MAWILE], final: :MAWILE, mega: :MAWILE_1, frames: [4, 13] },
    { item: :eelektrossite, item_name: "Eelektrossite", icon: "EELEKTROSSITE", line: [:TYNAMO, :EELEKTRIK, :EELEKTROSS], final: :EELEKTROSS, mega: :EELEKTROSS_1, frames: [10, 10] },
    { item: :dragalgite, item_name: "Dragalgite", icon: "DRAGALGITE", line: [:SKRELP, :DRAGALGE], final: :DRAGALGE, mega: :DRAGALGE_1, frames: [5, 10] },
    { item: :charizardite,  item_name: "Charizardite",  icon: "CHARIZARDITE",  line: [:CHARMANDER, :CHARMELEON, :CHARIZARD], final: :CHARIZARD,  mega: :CHARIZARD_1,  frames: [4, 4] },
    { item: :excadrite,     item_name: "Excadrite",     icon: "EXCADRITE",     line: [:DRILBUR, :EXCADRILL], final: :EXCADRILL, mega: :EXCADRILL_1, frames: [4, 4] },
    { item: :galladite,     item_name: "Galladite",     icon: "GALLADITE",     line: [:RALTS, :KIRLIA, :GALLADE], final: :GALLADE,   mega: :GALLADE_1,   frames: [4, 5] },
    { item: :gardevoirite,  item_name: "Gardevoirite",  icon: "GARDEVOIRITE",  line: [:RALTS, :KIRLIA, :GARDEVOIR], final: :GARDEVOIR, mega: :GARDEVOIR_1, frames: [4, 4] },
    { item: :gengarite,     item_name: "Gengarite",     icon: "GENGARITE",     line: [:GASTLY, :HAUNTER, :GENGAR], final: :GENGAR,   mega: :GENGAR_1,   frames: [4, 8] },
    { item: :hawluchanite,  item_name: "Hawluchanite",  icon: "HAWLUCHANITE",  line: [:HAWLUCHA], final: :HAWLUCHA, mega: :HAWLUCHA_1, frames: [4, 6] },
    { item: :lucarionite,   item_name: "Lucarionite",   icon: "LUCARIONITE",   line: [:RIOLU, :LUCARIO], final: :LUCARIO,   mega: :LUCARIO_1,   frames: [4, 10] },
    { item: :sablenite,     item_name: "Sablenite",     icon: "SABLENITE",     line: [:SABLEYE], final: :SABLEYE, mega: :SABLEYE_1, frames: [4, 2] },
    { item: :tyranitarite,  item_name: "Tyranitarite",  icon: "TYRANITARITE",  line: [:LARVITAR, :PUPITAR, :TYRANITAR], final: :TYRANITAR, mega: :TYRANITAR_1, frames: [4, 4] },
    { item: :sceptilite,    item_name: "Sceptilite",    icon: "SCEPTILITE",    line: [:TREECKO, :GROVYLE, :SCEPTILE], final: :SCEPTILE, mega: :SCEPTILE_1, frames: [4, 2] },
    { item: :sharpedonite, item_name: "Sharpedonite", icon: "SHARPEDONITE", line: [:CARVANHA, :SHARPEDO], final: :SHARPEDO, mega: :SHARPEDO_1, frames: [8, 4] },
    { item: :skarmorite, item_name: "Skarmorite", icon: "SKARMORITE", line: [:SKARMORY], final: :SKARMORY, mega: :SKARMORY_1, frames: [9, 7] },
    { item: :alakazite, item_name: "Alakazite", icon: "ALAKAZITE", line: [:ABRA, :KADABRA, :ALAKAZAM], final: :ALAKAZAM, mega: :ALAKAZAM_1, frames: [8, 8] },
    { item: :mewtwonitey, item_name: "Mewtwonite Y", icon: "MEWTWONITEY", line: [:MEWTWO], final: :MEWTWO, mega: :MEWTWO_2, frames: [6, 8] }
  ].freeze unless const_defined?(:MEGA_EVOLUTION_DATA)

  module_function

  def mega_evolution_data
    MEGA_EVOLUTION_DATA
  rescue
    []
  end

  def mega_evolution_data_for_item(item_id)
    return nil if item_id.nil?
    key = item_id.respond_to?(:to_sym) ? item_id.to_sym : item_id.to_s.to_sym
    return nil if !key
    mega_evolution_data.find { |data| data[:item] == key }
  rescue
    nil
  end

  def mega_evolution_data_for_final(species)
    return nil if species.nil?
    key = species_key(species)
    mega_evolution_data.find { |data| data[:final] == key || data[:mega] == key }
  rescue
    nil
  end

  def mega_evolution_item_ids
    mega_evolution_data.map { |data| data[:item] }
  rescue
    []
  end

  def mega_item?(item_id)
    return false if item_id.nil?
    !!mega_evolution_data_for_item(item_id)
  rescue
    false
  end

  def mega_item_compatible?(pokemon, item_id)
    return false if item_id.nil?
    data = mega_evolution_data_for_item(item_id)
    return true if !data
    return false if pokemon.nil?
    key = species_key(pokemon)
    data[:line].include?(key) || key == data[:final] || key == data[:mega]
  rescue
    false
  end

  def register_generic_mega_equipment
    return if !const_defined?(:EQUIPMENT_ITEMS)
    items = EQUIPMENT_ITEMS.dup
    mega_evolution_data.each do |data|
      next if items.any? { |item| item[:id] == data[:item] }
      final_name = data[:final].to_s.capitalize
      items << {
        id: data[:item],
        name: data[:item_name],
        desc: "#{final_name} can Mega Evolve after Burst is fully charged.",
        effect: :mega_stone,
        mega_species: data[:mega],
        rarity: :legendary,
        icon: data[:icon]
      }
    end
    redefine_const(:EQUIPMENT_ITEMS, items.freeze) if respond_to?(:redefine_const)
    if const_defined?(:BATTLE_PASS_LOCKED_EQUIPMENT_IDS)
      locked = BATTLE_PASS_LOCKED_EQUIPMENT_IDS.dup
      mega_evolution_data.each { |data| append_unique(locked, data[:item]) if respond_to?(:append_unique) }
      redefine_const(:BATTLE_PASS_LOCKED_EQUIPMENT_IDS, locked.freeze) if respond_to?(:redefine_const)
    end
  rescue
  end

  def register_generic_mega_animation_frames
    if const_defined?(:EIGHT_DIRECTION_HERO_SPRITES)
      mega_evolution_data.each { |data| append_unique(EIGHT_DIRECTION_HERO_SPRITES, data[:mega]) if respond_to?(:append_unique) }
    end
    return if !const_defined?(:EIGHT_DIRECTION_ASSET_FRAMES)
    mega_evolution_data.each do |data|
      walk, idle = data[:frames]
      EIGHT_DIRECTION_ASSET_FRAMES[data[:mega].to_s] = walk.to_i
      EIGHT_DIRECTION_ASSET_FRAMES["#{data[:mega]}_IDLE"] = idle.to_i
    end
  rescue
  end
end

# Keep runtime hooks with the generic Mega system, not the Tome definitions.
module SurvivorMegaRuntime
  def capture_ultimate_action_input
    super
    return if @state != :play || @evolution_anim || @charizard_mega_active
    if charizard_mega_eligible? && select_leaderboard_triggered?
      @charizard_mega_action_buffer = true
      @charizard_mega_action_buffer_timer = 0.2
    end
  end

  def update_ultimate(dt)
    return if @evolution_anim
    if @charizard_mega_active
      @mega_prompt_timer = 0.0
      @ultimate_charge = 0.0
      @ultimate_action_buffer = false
      @charizard_mega_timer = [@charizard_mega_timer.to_f - dt, 0.0].max
      end_charizard_mega if @charizard_mega_timer <= 0.0
      return
    end
    was_ready = ultimate_ready?
    super
    unless charizard_mega_eligible? && ultimate_ready?
      @mega_prompt_timer = 0.0
      @charizard_mega_charge = 0.0
      @charizard_mega_action_buffer = false
      @charizard_mega_action_buffer_timer = 0.0
      return
    end
    mega_was_ready = charizard_mega_ready?
    @charizard_mega_charge = [@charizard_mega_charge.to_f + (was_ready ? dt : 0.0), 10.0].min
    @mega_prompt_timer = if !mega_was_ready && charizard_mega_ready?
                           3.0
                         else
                           [@mega_prompt_timer.to_f - dt, 0.0].max
                         end
    if @charizard_mega_action_buffer && charizard_mega_ready?
      start_charizard_mega
      return
    end
    @charizard_mega_action_buffer_timer = [@charizard_mega_action_buffer_timer.to_f - dt, 0.0].max
    @charizard_mega_action_buffer = false if @charizard_mega_action_buffer_timer <= 0.0
  end

  def update_hero_evolution_animation(dt)
    return super unless @evolution_anim && @evolution_anim[:charizard_mega]
    @evolution_anim[:elapsed] = @evolution_anim[:elapsed].to_f + dt
    repel_nearby_threats(178, 11.5, true)
    # A Mega transition must not grant a regular evolution/boost again.
    @evolution_anim = nil if @evolution_anim[:elapsed] >= 16.0 / 60.0
  end

  def draw_hud(bitmap)
    super
    return unless @charizard_mega_active || charizard_mega_eligible?
    rate = @charizard_mega_active ? @charizard_mega_timer.to_f / 15.0 : @charizard_mega_charge.to_f / 10.0
    draw_special_charge_gauge(bitmap, rate)
  end

  def draw_special_charge_gauge(bitmap, rate)
    width = (174 * [[rate, 0.0].max, 1.0].min).round
    return if width <= 0
    # Overlay only the charged portion, preserving Burst underneath.
    palette = (@mega_gauge_palette ||= [Color.new(255, 90, 100), Color.new(255, 170, 70),
      Color.new(255, 230, 85), Color.new(100, 230, 145), Color.new(80, 180, 255), Color.new(185, 110, 255)])
    phase = (System.uptime * 8).to_i
    8.times do |row|
      color = palette[(row - phase) % palette.length]
      bitmap.fill_rect(20, 33 + row, width, 1, color)
    end
    # fill_rect replaces pixels, so translucent highlights punch holes in the HUD.
    shine = (@mega_gauge_shine ||= Color.new(230, 240, 255, 255))
    bitmap.fill_rect(21, 34, [width - 2, 0].max, 2, shine) if width > 2
    stripe = 0
    stripe.step(width - 1, 12) { |offset| bitmap.fill_rect(20 + offset, 34, 1, 6, shine) }
  end

  def show_ultimate_prompt?
    return @mega_prompt_timer.to_f > 0.0 if charizard_mega_ready?
    super
  end

  def draw_ultimate_prompt(bitmap)
    return super unless charizard_mega_ready?
    draw_special_action_prompt(bitmap, _INTL("Mega"))
  end

  def draw_special_action_prompt(bitmap, label)
    pbSetSystemFont(bitmap)
    icon_w = defined?(ControlHelpText) ? ControlHelpText::ICON_SIZE : 16
    text_w = bitmap.text_size(label).width
    box_w = [[text_w + icon_w + 28, 84].max, 180].min
    x = [[(world_screen_x(hero_visual_x) - box_w / 2).round, 6].max, Graphics.width - box_w - 6].min
    y = [[(world_screen_y(hero_visual_y) + 31).round, 6].max, Graphics.height - 28].min
    draw_soft_badge(bitmap, x, y, box_w, 22, Color.new(0, 0, 0, 130))
    draw_text_box(bitmap, label, x + 8, y + 1, box_w - icon_w - 22, 20, Color.new(255, 224, 92))
    ControlHelpText.draw_icon(bitmap, :ready_menu, x + box_w - icon_w - 8, y + 4) if defined?(ControlHelpText)
  end
end

PokemonSurvivor.register_generic_mega_equipment
PokemonSurvivor.register_generic_mega_animation_frames

module PokemonSurvivor
  class << self
    alias equip_pokemon_item_without_generic_mega_gate equip_pokemon_item unless method_defined?(:equip_pokemon_item_without_generic_mega_gate)
    def equip_pokemon_item(pokemon, item_id)
      return false if mega_item?(item_id) && !mega_item_compatible?(pokemon, item_id)
      equip_pokemon_item_without_generic_mega_gate(pokemon, item_id)
    rescue
      false
    end
  end
end

class Scene_PokemonSurvivor
  alias apply_pokemon_equipment_effects_without_generic_mega apply_pokemon_equipment_effects unless method_defined?(:apply_pokemon_equipment_effects_without_generic_mega)
  def apply_pokemon_equipment_effects(base)
    apply_pokemon_equipment_effects_without_generic_mega(base)
    @mega_stone_equipped = !!(@equipped_item && PokemonSurvivor.mega_item?(@equipped_item[:id]) && PokemonSurvivor.mega_item_compatible?(base, @equipped_item[:id]))
    @charizardite_equipped = @mega_stone_equipped if PokemonSurvivor.species_key(base) == :CHARMANDER
  rescue
  end

  alias open_pokemon_equipment_menu_without_generic_mega open_pokemon_equipment_menu unless method_defined?(:open_pokemon_equipment_menu_without_generic_mega)
  def open_pokemon_equipment_menu(pokemon = nil)
    open_pokemon_equipment_menu_without_generic_mega(pokemon)
    filter_generic_mega_equipment_items
    draw_pokemon_equipment_menu if @state == :equipment_menu
  rescue
    @state = :select
  end

  def filter_generic_mega_equipment_items
    return if !@equipment_items
    @equipment_items = @equipment_items.select do |item|
      next false if !item || !item.respond_to?(:[])
      item_id = item[:id]
      !PokemonSurvivor.mega_item?(item_id) || PokemonSurvivor.mega_item_compatible?(@equipment_pokemon, item_id)
    end
    equipped = PokemonSurvivor.equipped_pokemon_item(@equipment_pokemon)
    @equipment_index = @equipment_items.index { |item| item[:id] == equipped } || 0
  rescue
  end

  def current_mega_evolution_data
    return nil if !@hero || @hero.hp.to_i <= 0
    item_id = @equipped_item && @equipped_item[:id]
    data = PokemonSurvivor.mega_evolution_data_for_item(item_id)
    return nil if !data
    base = PokemonSurvivor.species_key(@hero_base_name || @passive_key)
    current = PokemonSurvivor.species_key(@hero.name || @hero_name)
    return nil if !data[:line].include?(base) && base != data[:final] && base != data[:mega]
    return nil if current != data[:final] && current != data[:mega]
    data
  rescue
    nil
  end

  def charizard_mega_eligible?
    !!current_mega_evolution_data
  rescue
    false
  end

  def charizard_mega_ready?
    charizard_mega_eligible? && !@charizard_mega_active && @charizard_mega_charge.to_f >= 10.0
  rescue
    false
  end

  def start_charizard_mega
    data = current_mega_evolution_data
    return if !data
    @current_mega_evolution_data = data
    @charizard_mega_active = true
    @charizard_mega_timer = 15.0
    @charizard_mega_charge = 10.0
    @charizard_mega_action_buffer = false
    @charizard_mega_action_buffer_timer = 0.0
    @ultimate_charge = 0.0
    @charizard_mega_damage_mult = 4.0
    @charizard_mega_cooldown_mult = 0.5
    extra = @projectile_count_bonus.to_i
    @charizard_mega_count_bonus = [extra, 0].max
    @damage_mult *= @charizard_mega_damage_mult
    @cooldown_mult *= @charizard_mega_cooldown_mult
    @projectile_count_bonus += @charizard_mega_count_bonus
    old_bitmap = @hero.bitmap rescue nil
    set_charizard_mega_sprite(true)
    start_charizard_mega_transform_animation(old_bitmap, @hero.bitmap, true)
    play_survivor_cry(data[:final]) if respond_to?(:play_survivor_cry)
    add_ultimate_effect(hero_effect_x, hero_effect_y, 0.62, { type: (@hero.attack_type || :NORMAL), vfx: "VFX_EVOLUTION", vfx_loop: false, vfx_fps: 16 }, 86, :ring) if respond_to?(:add_ultimate_effect)
    PokemonSurvivor.gamepad_vibrate_event(:burst) if PokemonSurvivor.respond_to?(:gamepad_vibrate_event)
  rescue
  end

  def end_charizard_mega
    return if !@charizard_mega_active
    @charizard_mega_active = false
    @charizard_mega_timer = 0.0
    @charizard_mega_charge = 0.0
    @damage_mult /= @charizard_mega_damage_mult if @charizard_mega_damage_mult.to_f > 0
    @cooldown_mult /= @charizard_mega_cooldown_mult if @charizard_mega_cooldown_mult.to_f > 0
    @projectile_count_bonus = [@projectile_count_bonus.to_i - @charizard_mega_count_bonus.to_i, 0].max
    @charizard_mega_damage_mult = 1.0
    @charizard_mega_cooldown_mult = 1.0
    @charizard_mega_count_bonus = 0
    old_bitmap = @hero.bitmap rescue nil
    set_charizard_mega_sprite(false)
    start_charizard_mega_transform_animation(old_bitmap, @hero.bitmap, false)
    add_ultimate_effect(hero_effect_x, hero_effect_y, 0.50, { type: (@hero.attack_type || :NORMAL), vfx: "VFX_EVOLUTION", vfx_loop: false, vfx_fps: 16 }, 78, :ring) if respond_to?(:add_ultimate_effect)
    @current_mega_evolution_data = nil
  rescue
  end

  def start_charizard_mega_transform_animation(old_bitmap, new_bitmap, active)
    return if !@hero
    data = @current_mega_evolution_data || current_mega_evolution_data || PokemonSurvivor.mega_evolution_data_for_final(@hero.name)
    @evolution_anim = {
      stage: active ? 99 : -99,
      old_name: active ? (data && data[:final]) : (data && data[:mega]),
      old_bitmap: old_bitmap || @hero.bitmap,
      new_name: @hero.name,
      new_bitmap: new_bitmap || @hero.bitmap,
      elapsed: 0.0,
      vfx_name: "VFX_EVOLUTION",
      charizard_mega: true
    }
    @hero.moving = false
    repel_nearby_threats(170, 10.0, true) if respond_to?(:repel_nearby_threats)
    pbSEPlay("Survivor/Battle recall", PokemonSurvivor::SFX_EVOLUTION_VOLUME, 100) rescue pbPlayDecisionSE rescue nil
    play_survivor_se(:mega_evolution_vfx, "Survivor/Shiny sparkle", 0.5, PokemonSurvivor::SFX_EVOLUTION_VFX_VOLUME, 92) if respond_to?(:play_survivor_se)
  rescue
  end

  def charizard_mega_folder(shiny)
    base = shiny ? PokemonSurvivor::HERO_SHINY_DIR : PokemonSurvivor::HERO_DIR
    data = @current_mega_evolution_data || current_mega_evolution_data
    if data && PokemonSurvivor.pokemon_alt_active?(@hero_base_name || data[:line][0])
      alt = shiny ? PokemonSurvivor::HERO_ALT_SHINY_DIR : PokemonSurvivor::HERO_ALT_DIR
      return "#{alt}/Mega" if PokemonSurvivor.resolve("#{alt}/Mega", data[:mega].to_s)
    end
    "#{base}/Mega"
  rescue
    PokemonSurvivor::HERO_DIR
  end

  def set_charizard_mega_sprite(active)
    return if !@hero
    data = @current_mega_evolution_data || current_mega_evolution_data || PokemonSurvivor.mega_evolution_data_for_final(@hero.name)
    return if !data
    name = active ? data[:mega] : data[:final]
    base = @hero_base_name || data[:line][0]
    shiny = PokemonSurvivor.pokemon_shiny_active?(base) rescue false
    folder = active ? charizard_mega_folder(shiny) : PokemonSurvivor.hero_graphics_folder(name, base)
    @hero_name = name
    @hero.name = name.to_s
    walk = cached_bitmap(folder, name.to_s) rescue nil
    idle = cached_bitmap(folder, "#{name}_Idle") rescue nil
    @hero.walk_bitmap = walk if walk && !walk.disposed?
    @hero.idle_bitmap = idle if idle && !idle.disposed?
    PokemonSurvivor.register_eight_direction_bitmap(@hero.walk_bitmap, PokemonSurvivor.eight_direction_asset_frame_count(name.to_s)) if @hero.walk_bitmap
    PokemonSurvivor.register_eight_direction_bitmap(@hero.idle_bitmap, PokemonSurvivor.eight_direction_asset_frame_count("#{name}_IDLE")) if @hero.idle_bitmap
    @hero.bitmap = @hero.walk_bitmap if @hero.walk_bitmap
    @hero.types = PokemonSurvivor.species_types(name) if @hero.respond_to?(:types=)
  rescue
  end
end




Scene_PokemonSurvivor.prepend(SurvivorMegaRuntime) unless Scene_PokemonSurvivor.ancestors.include?(SurvivorMegaRuntime)
