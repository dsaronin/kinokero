require 'test_helper'
require 'test_kinokero'

class JingleTest < ActiveSupport::TestCase
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  setup    :setup_jig
  teardown :teardown_jig

  context "jingle" do   # test suite for printer.rb

    should 'have active jingle connection' do
      assert  @proxy.my_devices['test'].cloudprint.jingle
    end   # should test do


    should 'start then close connection' do
      jingle = @proxy.my_devices['test'].cloudprint.jingle

      #  Kinokero::Jingle.set_verbose

      jingle.gtalk_start_connection do |printerid|
        
      end   # do

      assert jingle.is_connection

      jingle.gtalk_close_connection

      assert !jingle.is_connection

    end   # should test do


# TODO: add dynamic queue print job and test the asynch notification




  end  # context jingle

# _____________________________________________________________________________    

end  # class test
