# frozen_string_literal: true

require_relative "helper"

class TestDistributedRemoteServerControlCommands < Minitest::Test
  include Helper::Distributed

  def test_info
    keys = [
      "redis_version",
      "uptime_in_seconds",
      "uptime_in_days",
      "connected_clients",
      "used_memory",
      "total_connections_received",
      "total_commands_processed"
    ]

    infos = r.info

    infos.each do |info|
      keys.each do |k|
        msg = "expected #info to include #{k}"
        assert info.keys.include?(k), msg
      end
    end
  end

  def test_info_commandstats
    target_version "2.5.7" do
      r.nodes.each do |n|
        n.config(:resetstat)
        n.config(:get, :port)
      end

      r.info(:commandstats).each do |info|
        assert_equal '2', info['config']['calls'] # CONFIG RESETSTAT + CONFIG GET = twice
      end
    end
  end

  def test_monitor
    r.monitor
  rescue Exception => ex
  ensure
    assert ex.is_a?(NotImplementedError)
  end

  def test_echo
    assert_equal ["foo bar baz\n"], r.echo("foo bar baz\n")
  end

  def test_time
    target_version "2.5.4" do
      # Test that the difference between the time that Ruby reports and the time
      # that Redis reports is minimal (prevents the test from being racy).
      r.time.each do |rv|
        redis_usec = rv[0] * 1_000_000 + rv[1]
        ruby_usec = Integer(Time.now.to_f * 1_000_000)

        assert((ruby_usec - redis_usec).abs < 500_000)
      end
    end
  end
end
