#===============================================================================
# Load menu and language selection - Enter/Space confirm support
#===============================================================================
module LanguageSelectionConfirmKeys
  ENTER_KEY = 0x0D
  SPACE_KEY = 0x20

  class << self
    attr_accessor :active

    def raw_key_pressed?(code)
      return false if !defined?(Win32API)
      @get_async_key_state ||= Win32API.new("user32", "GetAsyncKeyState", ["L"], "L")
      (@get_async_key_state.call(code.to_i).to_i & 0x8000) != 0
    rescue
      false
    end

    def raw_key_trigger?(code)
      @raw_key_states ||= {}
      current = raw_key_pressed?(code)
      previous = @raw_key_states[code.to_i] ? true : false
      @raw_key_states[code.to_i] = current ? true : false
      current && !previous
    rescue
      false
    end

    def confirm_key_triggered?
      return true if Input.respond_to?(:triggerex?) && Input.triggerex?(ENTER_KEY)
      return true if Input.respond_to?(:triggerex?) && Input.triggerex?(SPACE_KEY)
      return true if raw_key_trigger?(ENTER_KEY)
      return true if raw_key_trigger?(SPACE_KEY)
      false
    rescue
      false
    end

    def with_active_confirm_keys
      previous = @active
      unless previous
        # Do not carry a held title-screen key into the load menu.
        @raw_key_states = { ENTER_KEY => raw_key_pressed?(ENTER_KEY), SPACE_KEY => raw_key_pressed?(SPACE_KEY) }
      end
      @active = true
      yield
    ensure
      @active = previous
    end
  end
end

class << Input
  alias trigger_without_language_selection_confirm_keys trigger? unless method_defined?(:trigger_without_language_selection_confirm_keys)
  def trigger?(key)
    return true if LanguageSelectionConfirmKeys.active && Input.const_defined?(:C) && key == Input::C && LanguageSelectionConfirmKeys.confirm_key_triggered?
    trigger_without_language_selection_confirm_keys(key)
  end
end

if defined?(pbChooseLanguage) && !defined?(pbChooseLanguage_without_enter_space_confirm)
  alias pbChooseLanguage_without_enter_space_confirm pbChooseLanguage
  def pbChooseLanguage(*args)
    LanguageSelectionConfirmKeys.with_active_confirm_keys do
      pbChooseLanguage_without_enter_space_confirm(*args)
    end
  end
end
