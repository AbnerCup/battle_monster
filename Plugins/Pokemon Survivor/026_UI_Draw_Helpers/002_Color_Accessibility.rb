#===============================================================================
# Refresh generated surfaces and adapted artwork when changing the palette.
#===============================================================================
class Scene_PokemonSurvivor
  def invalidate_color_accessibility_surfaces
    [:@scroll_text_cache, :@leaderboard_rainbow_text_cache, :@ui_single_line_text_cache,
     :@ui_wrapped_text_cache, :@select_hero_slot_cache, :@shop_text_cache,
     :@shop_scrolling_text_cache, :@shop_description_cache, :@shop_upgrade_cost_cache,
     :@battle_pass_scroll_cache, :@achievement_text_cache, :@joker_title_cache,
     :@event_sleep_wake_zone_cache, :@event_egg_activation_circle_cache,
     :@tower_objective_zone_cache, :@focus_step_cooldown_cache,
     :@shop_background_surface_cache].each do |name|
      cache = instance_variable_get(name)
      next unless cache.is_a?(Hash)
      cache.each_value { |bmp| bmp.dispose if bmp.is_a?(Bitmap) && !bmp.disposed? }
      cache.clear
    end
    [:@shop_static_tree_cache, :@run_bonus_panel_surface, :@achievement_backdrop].each do |name|
      bitmap = instance_variable_get(name)
      bitmap.dispose if bitmap.is_a?(Bitmap) && !bitmap.disposed?
      instance_variable_set(name, nil)
    end
    @shop_static_tree_cache_key = nil
    # Reload adapted artwork from disk; never dispose or recolor Pokemon sprites.
    if @bitmaps
      prefix = "#{PokemonSurvivor::VFX_DIR}/"
      backgrounds = "#{PokemonSurvivor::BACKGROUND_DIR}/"
      shop_backgrounds = ["Background", "Background_Endless", "Background_Training"].map { |name| "#{PokemonSurvivor::SHOP_DIR}/#{name}" }
      @bitmaps.keys.each do |key|
        next unless key.to_s.start_with?(prefix, backgrounds, "enemy_hp_bar:", "achievement_slot_solid:", "achievement_case_solid:") ||
                    key == "menu_hud_background_options" || shop_backgrounds.include?(key)
        bitmap = @bitmaps.delete(key)
        bitmap.dispose if bitmap.is_a?(Bitmap) && !bitmap.disposed?
      end
    end
  end
end
