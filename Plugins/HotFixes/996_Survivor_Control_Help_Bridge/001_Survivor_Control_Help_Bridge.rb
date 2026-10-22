#===============================================================================
# Pokemon Survivor - remapped helper icons bridge
#===============================================================================
# This patch lives beside the native helper renderer so footer helper bands always
# resolve Pokemon Survivor actions through the Survivor remap before drawing icons.

if defined?(ControlHelpText)
  module ControlHelpText
    class << self
      alias survivor_remap_original_keys_for keys_for unless method_defined?(:survivor_remap_original_keys_for)
      alias survivor_remap_original_key key unless method_defined?(:survivor_remap_original_key)
      alias survivor_remap_original_icon_path icon_path unless method_defined?(:survivor_remap_original_icon_path)
      alias survivor_remap_original_segment_width segment_width unless method_defined?(:survivor_remap_original_segment_width)
      alias survivor_remap_original_draw_icon draw_icon unless method_defined?(:survivor_remap_original_draw_icon)
      alias survivor_remap_original_draw_segments_raw draw_segments_raw unless method_defined?(:survivor_remap_original_draw_segments_raw)

      def survivor_remap_action(action)
        if defined?(PokemonSurvivor) && PokemonSurvivor.respond_to?(:control_help_action)
          mapped = PokemonSurvivor.control_help_action(action) rescue nil
          return mapped if mapped
        end
        action = action.to_sym if action.respond_to?(:to_sym)
        case action
        when :confirm then :confirm
        when :cancel then :cancel
        when :action then :action
        when :ready_menu, :special, :menu then :menu
        else nil
        end
      rescue
        nil
      end

      def survivor_remap_input_kind
        return :gamepad if respond_to?(:last_input_type) && last_input_type == :gamepad
        :keyboard
      rescue
        :keyboard
      end

      def survivor_remap_key(action)
        mapped = survivor_remap_action(action)
        return nil if !mapped
        return nil if !defined?(PokemonSurvivor) || !PokemonSurvivor.respond_to?(:control_key_name)
        key_name = PokemonSurvivor.control_key_name(mapped, survivor_remap_input_kind) rescue nil
        key_name && !key_name.to_s.empty? ? key_name.to_s : nil
      rescue
        nil
      end

      def keys_for(action)
        key_name = survivor_remap_key(action)
        return [key_name] if key_name
        survivor_remap_original_keys_for(action)
      end

      def key(action)
        keys = keys_for(action)
        preferred = preferred_key(keys)
        preferred || action.to_s
      rescue
        survivor_remap_original_key(action) rescue action.to_s
      end

      def icon_path(action)
        key_name = survivor_remap_key(action)
        return icon_path_for_key(key_name) if key_name
        survivor_remap_original_icon_path(action)
      rescue
        nil
      end

      def segment_width(bitmap, action, label = nil)
        label = label.to_s
        key_name = survivor_remap_key(action)
        return survivor_remap_original_segment_width(bitmap, action, label) if !key_name
        text_w = label.empty? ? 0 : (bitmap.text_size(label).width rescue 0)
        icon_w = ICON_SIZE
        if icon_path_for_key(key_name).nil?
          display_key = gamepad_key?(key_name) ? key_name : keyboard_display_key(key_name)
          icon_w = bitmap.text_size(display_key).width rescue ICON_SIZE
        end
        icon_w + (label.empty? ? 0 : ICON_TEXT_GAP + text_w)
      rescue
        survivor_remap_original_segment_width(bitmap, action, label) rescue ICON_SIZE
      end

      def draw_icon(bitmap, action, x, y)
        key_name = survivor_remap_key(action)
        return survivor_remap_original_draw_icon(bitmap, action, x, y) if !key_name
        path = icon_path_for_key(key_name)
        if path
          icon = cached_icon_bitmap(path)
          if icon && !icon.disposed?
            src_w = [icon.width, ICON_SIZE].min
            src_h = [icon.height, ICON_SIZE].min
            bitmap.blt(x, y, icon, Rect.new(0, 0, src_w, src_h))
            return ICON_SIZE
          end
        end
        display_key = gamepad_key?(key_name) ? key_name : keyboard_display_key(key_name)
        pbDrawTextPositions(bitmap, [[display_key, x, y - 2, 0, Color.white, Color.new(0, 0, 0)]])
        bitmap.text_size(display_key).width rescue ICON_SIZE
      rescue
        survivor_remap_original_draw_icon(bitmap, action, x, y) rescue ICON_SIZE
      end

      def draw_segments_raw(bitmap, segments, draw_x, y, base, shadow)
        segments.each_with_index do |segment, i|
          action = segment[0]
          label = segment[1].to_s
          icon_w = draw_icon(bitmap, action, draw_x, y + 1)
          draw_x += [icon_w.to_i, ICON_SIZE].max
          if !label.empty?
            draw_x += ICON_TEXT_GAP
            pbDrawTextPositions(bitmap, [[label, draw_x, y, 0, base, shadow]])
            draw_x += bitmap.text_size(label).width rescue 0
          end
          draw_x += (label.empty? ? 3 : SEGMENT_GAP) if i < segments.length - 1
        end
      rescue
        survivor_remap_original_draw_segments_raw(bitmap, segments, draw_x, y, base, shadow) rescue nil
      end
    end
  end
end
#===============================================================================
# Native Input bridge
#===============================================================================
# Native Essentials menus read Input::C/Input::B/Input::ACTION directly. Bridge
# those semantic actions to the Survivor remap so save/options/load-style menus
# react to the new bindings too. Direction keys stay native-only.

module Input
  class << self
    alias survivor_remap_native_original_trigger trigger? unless method_defined?(:survivor_remap_native_original_trigger)
    alias survivor_remap_native_original_press press? unless method_defined?(:survivor_remap_native_original_press)
    alias survivor_remap_native_original_repeat repeat? unless method_defined?(:survivor_remap_native_original_repeat)

    def survivor_remap_native_action_for_code(code)
      return nil if !defined?(PokemonSurvivor) || !PokemonSurvivor.respond_to?(:control_trigger?)
      return :confirm if Input.const_defined?(:C) && code == Input::C
      return :confirm if Input.const_defined?(:USE) && code == Input::USE
      return :cancel if Input.const_defined?(:B) && code == Input::B
      return :cancel if Input.const_defined?(:BACK) && code == Input::BACK
      return :action if Input.const_defined?(:ACTION) && code == Input::ACTION
      return :menu if Input.const_defined?(:SPECIAL) && code == Input::SPECIAL
      return :menu if Input.const_defined?(:MENU) && code == Input::MENU
      nil
    rescue
      nil
    end

    def trigger?(code)
      action = survivor_remap_native_action_for_code(code)
      return PokemonSurvivor.control_trigger?(action) if action
      survivor_remap_native_original_trigger(code)
    rescue
      survivor_remap_native_original_trigger(code) rescue false
    end

    def press?(code)
      action = survivor_remap_native_action_for_code(code)
      return PokemonSurvivor.control_press?(action) if action
      survivor_remap_native_original_press(code)
    rescue
      survivor_remap_native_original_press(code) rescue false
    end

    def repeat?(code)
      action = survivor_remap_native_action_for_code(code)
      return PokemonSurvivor.control_press?(action) if action
      survivor_remap_native_original_repeat(code)
    rescue
      survivor_remap_native_original_repeat(code) rescue false
    end
  end
end