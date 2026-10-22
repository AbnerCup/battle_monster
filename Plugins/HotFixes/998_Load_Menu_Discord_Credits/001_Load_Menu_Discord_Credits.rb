# Adds Discord and Credits commands to the load/title command menu.
# Source text stays English and translatable through _INTL.
class PokemonLoadScreen
  DISCORD_INVITE_URL = "https://discord.com/invite/TBWbpbF4aG"
  DEBUG_MENU_PASSWORD = "feFNWVAyMwhDbRbg7elMmhz7cYBOrzXr"
  DEBUG_PASSWORD_MAX_LENGTH = 32

  def pbStartLoadScreen
    commands = []
    cmd_continue     = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_language     = -1
    cmd_discord      = -1
    cmd_credits      = -1
    cmd_mystery_gift = -1
    cmd_debug        = -1
    cmd_quit         = -1
    show_continue = !@save_data.empty?
    if show_continue
      commands[cmd_continue = commands.length] = _INTL("Continue")
      if @save_data[:player].mystery_gift_unlocked
        commands[cmd_mystery_gift = commands.length] = _INTL("Mystery Gift")
      end
    end
    commands[cmd_new_game = commands.length] = _INTL("New Game")
    commands[cmd_language = commands.length] = _INTL("Language") if Settings::LANGUAGES.length >= 2
    commands[cmd_discord = commands.length]  = _INTL("Discord")
    commands[cmd_credits = commands.length]  = _INTL("Credits")
    commands[cmd_debug = commands.length]    = _INTL("Debug") if $DEBUG
    commands[cmd_quit = commands.length]     = _INTL("Quit Game")
    map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
    @scene.pbSetParty(@save_data[:player]) if show_continue
    @scene.pbStartScene2
    loop do
      command = if defined?(LanguageSelectionConfirmKeys)
        LanguageSelectionConfirmKeys.with_active_confirm_keys { @scene.pbChoose(commands) }
      else
        @scene.pbChoose(commands)
      end
      pbPlayDecisionSE if command != cmd_quit
      case command
      when cmd_continue
        @scene.pbEndScene
        Game.load(@save_data)
        return
      when cmd_new_game
        @scene.pbEndScene
        Game.start_new
        return
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }

      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = if defined?(LanguageSelectionConfirmKeys)
          LanguageSelectionConfirmKeys.with_active_confirm_keys { pbChooseLanguage }
        else
          pbChooseLanguage
        end
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
      when cmd_discord
        open_discord_invite
      when cmd_credits
        pbFadeOutIn { open_load_menu_credits }
      when cmd_debug
        pbFadeOutIn { open_protected_debug_menu }
      when cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      else
        pbPlayBuzzerSE
      end
    end
  end

  def open_protected_debug_menu
    if debug_password_accepted?
      pbDebugMenu(false)
    else
      pbPlayBuzzerSE rescue nil
      pbMessage(_INTL("Access denied.")) rescue nil
    end
  rescue
    pbMessage(_INTL("Unable to open the debug menu.")) rescue nil
  end

  def debug_password_accepted?
    password = DEBUG_MENU_PASSWORD.to_s
    return true if password.empty?
    entered = debug_password_input
    entered.to_s == password
  rescue
    false
  end

  def debug_password_input
    message = _INTL("Enter debug password.")
    if defined?(pbMessageFreeText)
      begin
        return pbMessageFreeText(message, "", false, DEBUG_PASSWORD_MAX_LENGTH).to_s
      rescue
        begin
          return pbMessageFreeText(message, "", DEBUG_PASSWORD_MAX_LENGTH).to_s
        rescue
        end
      end
    end
    if defined?(pbEnterText)
      begin
        return pbEnterText(message, 0, DEBUG_PASSWORD_MAX_LENGTH, "").to_s
      rescue
        begin
          return pbEnterText(message, 1, DEBUG_PASSWORD_MAX_LENGTH, "").to_s
        rescue
        end
      end
    end
    ""
  rescue
    ""
  end

  def open_load_menu_credits
    previous_bgm = ($game_system.getPlayingBGM rescue nil)
    previous_position = ($game_system.bgm_position rescue 0)
    $PokemonGlobal = PokemonGlobalMetadata.new if !$PokemonGlobal
    $PokemonGlobal.creditsPlayed = true if $PokemonGlobal.respond_to?(:creditsPlayed=)
    Scene_Credits.new.main
    if previous_bgm
      $game_system.bgm_position = previous_position rescue nil
      pbBGMPlay(previous_bgm)
    else
      pbBGMStop(0.0) rescue pbBGMStop rescue nil
    end
  rescue
    if previous_bgm
      pbBGMPlay(previous_bgm) rescue nil
    else
      pbBGMStop(0.0) rescue pbBGMStop rescue nil
    end
    pbMessage(_INTL("Unable to open the credits.")) rescue nil
  end
  def open_discord_invite
    url = DISCORD_INVITE_URL
    platform = (System.platform rescue "")
    if platform[/Windows/i]
      system("cmd /c start \"\" \"#{url}\"")
    elsif platform[/Mac/i]
      system("open", url)
    else
      system("xdg-open", url)
    end
  rescue
    pbMessage(_INTL("Unable to open the Discord page.")) rescue nil
  end
end






