#===============================================================================
# Deterministic, simulation-time patterns. No graphics, wall clock or network work.
# The scene consumes shot angles at its world-space boss position.
#===============================================================================
module PokemonSurvivor
  module Titan
    PATTERNS = deep_freeze([
      { id: :aimed, duration: 4.0, interval: 0.40, speed: 0.35 },
      { id: :approach, duration: 1.8, interval: nil, speed: 2.8 },
      { id: :ring, duration: 1.2, interval: 1.2, speed: 0.0 },
      { id: :chain, duration: 5.0, interval: 0.14, speed: 0.25 }
    ])
    FINAL_PATTERN = deep_freeze({ id: :spiral, duration: 5.0, interval: 0.16, speed: 0.20 })
    RECOVERY_PATTERN = deep_freeze({ id: :recovery, duration: 1.5, interval: nil, speed: 0.65 })
    SATELLITE_PATTERN = deep_freeze({ id: :satellites, duration: 6.0, interval: 6.0, speed: 0.15 })
    OFFSET_RING_PATTERN = deep_freeze({ id: :offset_rings, duration: 3.6, interval: 1.2, speed: 0.0 })
    PINCER_PATTERN = deep_freeze({ id: :pincers, duration: 4.5, interval: 4.5, speed: 0.0 })
    RUPTURE_PATTERN = deep_freeze({ id: :rupture, duration: 3.0, interval: 3.0, speed: 0.0 })

    class BossPatterns
      ATTACK_DISTANCE = 150.0
      attr_reader :phase, :elapsed, :pattern_index

      def initialize(profile = nil)
        @profile = profile
        @phase = 1
        rebuild
      end

      def evolve!(profile = nil)
        return false if @phase == 2
        @profile = profile if profile
        @phase = 2
        rebuild
        true
      end

      def pattern
        @patterns[@pattern_index]
      end

      def speed_multiplier
        return 2.8 * (@phase == 2 ? 1.15 : 1.0) if @catching_up
        pattern[:speed] * (@phase == 2 ? 1.15 : 1.0)
      end

      def pursuing?
        @catching_up || pattern[:id] == :approach
      end

      def contact_multiplier
        @phase == 2 ? 1.75 : 1.0
      end

      def projectile_multiplier
        @phase == 2 ? 1.60 : 1.0
      end

      # Yield [angle, pattern_id]; the scene handles special attacks and warnings.
      def update(dt, aim_angle, distance = nil, offscreen = false)
        raise ArgumentError unless dt.is_a?(Numeric) && dt.finite? && dt >= 0 && dt <= 1.0
        raise ArgumentError unless aim_angle.is_a?(Numeric) && aim_angle.finite?
        @catching_up = true if offscreen
        if @catching_up
          return if distance.nil? || distance > ATTACK_DISTANCE || offscreen
          @catching_up = false
        end
        remaining = dt.to_f
        while remaining > 0.000000001
          current = pattern
          # A pursuit ends by reaching the player, never just by timing out.
          if current[:id] == :approach && distance
            return if distance > ATTACK_DISTANCE
            @pattern_index = (@pattern_index + 1) % @patterns.length
            @elapsed = @next_shot = 0.0
            @pattern_aim = nil
            next
          end
          slice = [remaining, current[:duration] - @elapsed].min
          ending = @elapsed + slice
          if current[:interval]
            while @next_shot < ending - 0.000000001
              emit(current[:id], aim_angle, @next_shot) { |angle, id| yield angle, id }
              @next_shot += current[:interval]
            end
          end
          @elapsed = ending
          remaining -= slice
          if @elapsed >= current[:duration] - 0.000000001
            @pattern_index = (@pattern_index + 1) % @patterns.length
            @elapsed = @next_shot = 0.0
            @pattern_aim = nil
          end
        end
      end

      private

      def rebuild
        @catching_up = false
        @patterns = PATTERNS.dup
        @patterns.concat([RECOVERY_PATTERN, SATELLITE_PATTERN, RECOVERY_PATTERN, OFFSET_RING_PATTERN])
        @patterns << FINAL_PATTERN if @phase == 2
        @patterns.concat([RECOVERY_PATTERN, PINCER_PATTERN, RECOVERY_PATTERN, RUPTURE_PATTERN]) if @phase == 2
        @patterns << RECOVERY_PATTERN
        if @profile == :lugia
          @patterns = [
            { id: :wind_fan, duration: 4.0, interval: 0.65, speed: 0.3 },
            RECOVERY_PATTERN, SATELLITE_PATTERN, RECOVERY_PATTERN,
            { id: :hunting_tornadoes, duration: 2.0, interval: 2.0, speed: 0.0 },
            OFFSET_RING_PATTERN, PATTERNS[1], RECOVERY_PATTERN
          ]
          if @phase == 2
            @patterns.concat([
              { id: :cross_spiral, duration: 4.0, interval: 0.30, speed: 0.15 },
              RECOVERY_PATTERN,
              { id: :storm_cage, duration: 3.0, interval: 3.0, speed: 0.0 },
              RECOVERY_PATTERN, PINCER_PATTERN, RECOVERY_PATTERN
            ])
          end
        end
        if [:kyurem, :kyurem_fire, :kyurem_electric].include?(@profile)
          @patterns = [PATTERNS[0], RECOVERY_PATTERN, OFFSET_RING_PATTERN,
            RECOVERY_PATTERN, SATELLITE_PATTERN, RECOVERY_PATTERN,
            { id: :frost_fan, duration: 3.0, interval: 0.6, speed: 0.2 },
            PATTERNS[1], RECOVERY_PATTERN,
            { id: :ice_barrage, duration: 3.0, interval: 0.22, speed: 0.1 },
            RECOVERY_PATTERN,
            { id: :glacial_charge, duration: 1.8, interval: 1.8, speed: 0.0 }, RECOVERY_PATTERN]
          if @phase == 2
            special = @profile == :kyurem_fire ? :fusion_flare : :fusion_bolt
            @patterns.concat([PINCER_PATTERN, RECOVERY_PATTERN, RUPTURE_PATTERN,
              RECOVERY_PATTERN,
              { id: :glacial_charge, duration: 1.8, interval: 1.8, speed: 0.0 },
              RECOVERY_PATTERN, FINAL_PATTERN, RECOVERY_PATTERN,
              { id: special, duration: 4.0, interval: 0.5, speed: 0.1 },
              RECOVERY_PATTERN,
              { id: :storm_cage, duration: 3.0, interval: 3.0, speed: 0.0 }, RECOVERY_PATTERN])
          end
        end
        @pattern_index = 0
        @elapsed = @next_shot = 0.0
        @pattern_aim = nil
      end

      def emit(id, aim, time)
        case id
        when :ice_barrage
          [-0.12, 0.0, 0.12].each { |offset| yield aim + offset, id }
        when :fusion_flare
          8.times { |index| yield time * 0.7 + index * Math::PI / 4.0, id }
        when :fusion_bolt
          [-0.24, 0.0, 0.24].each do |offset|
            yield aim + offset, id
            yield aim + Math::PI + offset, id
          end
        when :wind_fan, :frost_fan
          [-0.32, -0.16, 0.0, 0.16, 0.32].each { |offset| yield aim + offset, id }
        when :cross_spiral
          2.times do |index|
            yield time * 1.8 + index * Math::PI, id
            yield -time * 1.8 + index * Math::PI + Math::PI / 2.0, id
          end
        when :storm_cage, :hunting_tornadoes, :glacial_charge
          yield aim, id
        when :aimed, :chain
          yield aim, id
        when :ring
          16.times { |index| yield index * Math::PI * 2.0 / 16, id }
        when :spiral
          4.times { |index| yield time * 2.4 + index * Math::PI / 2.0, id }
        when :offset_rings
          @pattern_aim ||= aim
          gap = @pattern_aim + (time / 1.2).round * Math::PI / 10.0
          # Three missing spokes leave a readable opening in each of the three rings.
          20.times { |index| yield gap + index * Math::PI / 10.0, id unless index <= 1 || index == 19 }
        when :satellites, :pincers, :rupture
          yield aim, id
        end
      end
    end
  end
end
