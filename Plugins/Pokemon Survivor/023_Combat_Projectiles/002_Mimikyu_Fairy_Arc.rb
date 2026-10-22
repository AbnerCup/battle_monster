#===============================================================================
# Pokemon Survivor - Mimikyu Fairy Arc
#===============================================================================

class Scene_PokemonSurvivor
  def vortex_chain_projectile?(projectile, skill_id = nil)
    return false if !projectile || projectile.owner != :player || !projectile.orbit_target
    skill = projectile.source_skill
    return false if !skill || skill[:kind] != :vortex
    return true if !skill_id
    current_id = skill[:id] || (skill_id_for(skill) rescue nil)
    current_id == skill_id
  rescue
    false
  end

  def dragon_chain_projectile?(projectile)
    vortex_chain_projectile?(projectile)
  rescue
    false
  end

  def fire_vortex(skill)
    skill_id = skill_id_for(skill)
    return if @projectiles.any? { |p| vortex_chain_projectile?(p, skill_id) }
    count = skill[:count].to_i + @skill_count_bonus[skill_id]
    count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count] || 8, count)].min
    sides = [[4 + @skill_line_bonus[skill_id].to_i, 4].max, 8].min
    reserve_projectile_slots(count * sides)
    base_radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
    spacing = 14
    phase = (@timer * 0.18) % (Math::PI * 2)
    rotation_speed = skill[:speed].to_f + (@skill_orbit_speed_bonus[skill_id].to_i * 0.18)
    sides.times do |side|
      side_angle = phase + (Math::PI * 2 * side / sides)
      count.times do |i|
        radius = base_radius + (spacing * i)
        spawn_projectile_from(hero_effect_x + Math.cos(side_angle) * radius,
                              hero_effect_y + Math.sin(side_angle) * radius,
                              side_angle, skill) do |p|
          p.orbit_target = @hero
          p.orbit_angle = side_angle
          p.orbit_radius = radius
          p.orbit_growth = 0.0
          p.pierce = 9999
          p.ttl = 5.0
          p.hit_cooldowns = {}
          p.speed = rotation_speed
        end
      end
    end
  rescue
  end

  def refresh_dragon_chains
    return if !@projectiles || !@hero
    grouped = {}
    @projectiles.each do |projectile|
      next if !vortex_chain_projectile?(projectile)
      skill_id = skill_id_for(projectile.source_skill)
      next if !skill_id
      (grouped[skill_id] ||= []) << projectile
    end
    grouped.each_pair do |skill_id, chains|
      skill = PokemonSurvivor::SKILLS[skill_id]
      next if !skill
      base_radius = skill[:radius].to_i + @skill_radius_bonus[skill_id]
      spacing = 14
      count = skill[:count].to_i + @skill_count_bonus[skill_id]
      count = [[count, 1].max, projectile_count_cap(skill, skill[:max_count] || 8, count)].min
      rotation_speed = skill[:speed].to_f + (@skill_orbit_speed_bonus[skill_id].to_i * 0.18)
      chains.each_with_index do |projectile, index|
        ring = index % count
        projectile.orbit_radius = [projectile.orbit_radius.to_f, base_radius + (spacing * ring)].max
        projectile.speed = rotation_speed
        projectile.ttl = [projectile.ttl.to_f, 0.35].max
      end
    end
  rescue
  end
end
