require 'test/unit'

require_relative '../lib/util'

class TestUtil < Test::Unit::TestCase
  class << self

    def startup
      p :_startup
    end


    def shutdown
      p :_shutdown
    end
  end


  def setup
    p :setup
  end


  def cleanup
    p :cleanup
  end


  def test_safe_cmd_ok
    p :test_safe_cmd_ok

    assert_equal("chakku", safe_run_cmd("echo chakku").strip)
  end

  def test_safe_cmd_catch
    p 'test_vimruntime'

    # delete PATH
    path = ENV['PATH']
    ENV['PATH'] = ""


    # run
    assert_raises (Errno::ENOENT) do
      raise safe_run_cmd("locate vim") {|ex|
        puts "#{ex.message}",""
        ex
      }
    end

    # recover
    ENV['PATH'] = path

  end

end
