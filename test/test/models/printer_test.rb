require 'test_helper'
require 'test_kinokero'

class PrinterTest < ActiveSupport::TestCase
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  setup    :setup_jig
  teardown :teardown_jig

  context "printer" do   # test suite for printer.rb

    should 'print gcp registration message' do

      assert   Kinokero::Printer.print_gcp_registration_info(
        CUPS_NULL_PRINTER,
        "lime sublime"
      )

    end  # test


    should "verify printer is ready" do

      assert   @proxy.my_devices['test'].is_printer_ready?

    end  # test


    should "print a file" do

      assert   @proxy.my_devices['test'].print_file( 
                  '/etc/cups/ppd/laserjet_1102w.ppd' 
               )

    end  # test


    should 'change cups state to sym' do

      printer = @proxy.my_devices['test']

      assert_equal  :idle, printer.cups_state_to_sym( '3' )
      assert_equal  :processing, printer.cups_state_to_sym( '4' )
      assert_equal  :stopped, printer.cups_state_to_sym( '5' )
      assert_equal  :lime, printer.cups_state_to_sym( 'lime' )

    end  # test


    should 'change cups reason' do

      printer = @proxy.my_devices['test']

      assert_equal  '', printer.cups_reason( 'none' )
      assert_equal  'wild blue', printer.cups_reason( 'wild blue' )

    end  # test

    should 'stop poll thread' do

      assert_nil @proxy.my_devices['test'].stop_poll_thread()

    end  # test


    should 'start poll thread' do

      assert @proxy.my_devices['test'].start_poll_thread()
      assert @proxy.my_devices['test'].poll_thread

    end  # test


    should 'set up model info' do

      assert @proxy.my_devices['test'].setup_model( {} )

    end  # test


    should 'set up gcp info correctly' do
      assert @proxy.my_devices['test'].setup_gcp( 
        @proxy.my_devices['test'].gcp_printer_control
      )

    end  # test


    should 'set up gcp info incorrectly' do
      assert_raise(ArgumentError)  {  
        @proxy.my_devices['test'].setup_gcp( { cups_alias: 0  } )
      }

    end  # test


  end  # context printer

# _____________________________________________________________________________    

end  # class test
