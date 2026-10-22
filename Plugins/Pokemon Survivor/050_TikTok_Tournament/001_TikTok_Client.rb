#===============================================================================
# Pokemon Survivor - TikTok Live TCP Network Client (Pure Ruby, No Gems)
# Connects to Node.js backend (127.0.0.1:8081)
#===============================================================================
require 'socket'

module PokemonSurvivor
  # Lightweight, pure-Ruby JSON parser & serializer for embedded Ruby (MKXP-Z)
  module MiniJSON
    def self.parse(str)
      return nil if str.nil? || str.empty?
      str = str.strip
      pos = 0
      tokens = str.scan(/"(?:\\.|[^"\\])*"|true|false|null|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|[{}\[\],:]/)
      return nil if tokens.empty?

      parse_val = lambda do
        return nil if pos >= tokens.length
        tok = tokens[pos]
        pos += 1
        if tok == '{'
          hash = {}
          while pos < tokens.length && tokens[pos] != '}'
            key_tok = tokens[pos]
            pos += 1
            key = key_tok =~ /^"(.*)"$/ ? $1.gsub('\\"', '"').gsub('\\\\', '\\') : key_tok
            pos += 1 if tokens[pos] == ':' # skip ':'
            hash[key] = parse_val.call
            pos += 1 if tokens[pos] == ',' # skip ','
          end
          pos += 1 # skip '}'
          hash
        elsif tok == '['
          arr = []
          while pos < tokens.length && tokens[pos] != ']'
            arr << parse_val.call
            pos += 1 if tokens[pos] == ','
          end
          pos += 1 # skip ']'
          arr
        elsif tok == 'true'
          true
        elsif tok == 'false'
          false
        elsif tok == 'null'
          nil
        elsif tok =~ /^"(.*)"$/
          $1.gsub('\\"', '"').gsub('\\\\', '\\')
        elsif tok =~ /^-?\d+\.\d+/
          tok.to_f
        elsif tok =~ /^-?\d+/
          tok.to_i
        else
          tok
        end
      end

      parse_val.call
    end

    def self.generate(obj)
      case obj
      when Hash
        "{" + obj.map { |k, v| "\"#{k}\":#{generate(v)}" }.join(",") + "}"
      when Array
        "[" + obj.map { |v| generate(v) }.join(",") + "]"
      when String
        "\"#{obj.to_s.gsub('"', '\"')}\""
      when Numeric, true, false
        obj.to_s
      when nil
        "null"
      else
        "\"#{obj.to_s}\""
      end
    end
  end

  @tiktok_socket = nil
  @tiktok_events_queue = []
  @tiktok_queue_mutex = Mutex.new
  @tiktok_thread = nil
  @tiktok_connected = false

  def self.tiktok_connected?
    @tiktok_connected
  end

  def self.start_tiktok_client(host = '127.0.0.1', port = 8081)
    return if @tiktok_thread && @tiktok_thread.alive?

    @tiktok_thread = Thread.new do
      loop do
        begin
          sock = TCPSocket.new(host, port)
          sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) rescue nil
          @tiktok_socket = sock
          @tiktok_connected = true
          echoln "[TikTok TCP] Conectado al backend en #{host}:#{port}" if defined?(echoln)

          while line = sock.gets
            line = line.strip
            next if line.empty?
            begin
              payload = MiniJSON.parse(line)
              if payload && payload.is_a?(Hash)
                @tiktok_queue_mutex.synchronize do
                  @tiktok_events_queue << payload
                end
              end
            rescue => parse_err
              # Ignore json parse errors
            end
          end
        rescue => e
          @tiktok_connected = false
          @tiktok_socket = nil
          sleep 1.5
        ensure
          sock.close rescue nil if sock
          @tiktok_connected = false
        end
      end
    end
  end

  def self.poll_tiktok_events
    events = []
    @tiktok_queue_mutex.synchronize do
      events = @tiktok_events_queue.dup
      @tiktok_events_queue.clear
    end
    events
  end

  def self.send_tiktok_event(payload)
    return unless @tiktok_socket && @tiktok_connected
    begin
      @tiktok_socket.puts(MiniJSON.generate(payload))
    rescue => e
      @tiktok_connected = false
    end
  end
end
