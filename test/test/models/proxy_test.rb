require 'test_helper'
require 'test_kinokero'

class ProxyTest < ActiveSupport::TestCase
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  setup    :setup_jig
  teardown :teardown_jig

  context "proxy" do   # test suite for printer.rb

    should 'print gcp reg info'  do
      reg_response = {
        :success => true,
        :cups_alias => CUPS_NULL_PRINTER,
        :gcp_printer_reg_token =>  'wild_blue_1' ,
        :gcp_claim_token_url =>    'wild_blue_2',
        :gcp_easy_reg_url =>       'wild_blue_3',
        :swalapala_printer_id =>   'wild_blue_4',
        :gcp_printer_name =>       'wild_blue_5',
        :gcp_printer_id   =>       'wild_blue_6'
      }

      assert  @proxy.print_gcp_registration_info(
        reg_response
      )

    end   # should do


    should 'get printer list' do
      list_result = @proxy.do_list( 'test' )
      assert list_result['success']   # should always return success even if no printers
    end   # should do


    should 'do refresh tokens' do
      list_result = @proxy.do_refresh( 'test' )
      assert list_result['success']   # should always return success even if no printers
    end   # should do


    should 'do fetch jobs' do
      list_result = @proxy.do_fetch_jobs( 'test' )
      assert !list_result['success']   # should fail since not on-line
    end   # should do


    should 'do print jobs' do
      list_result = @proxy.do_print_jobs(  
        @proxy.my_devices['test'].gcp_printer_control[:gcp_printerid]
      )
      # TODO: what to assert?
    end   # should do


    should 'not delete printer' do
      @proxy.do_delete( 'lime' )
      assert_nil @proxy.my_devices['lime']   
    end   # should do


    should 'do ready state' do
      list_result = @proxy.do_ready_state( 'test' )
      assert !list_result['success']   # should fail since not on-line
    end   # should do


    should 'not register a printer'  do
      
      item = 'wildblue'

        # build an offshoot request list
      new_request = build_gcp_request( item )

      list_result = @proxy.do_register( new_request ) do  |gcp_ctl|
      end  # do register

      assert !list_result['success']  

    end   # should do


    should 'return item given a printerid' do
      result = @proxy.item_from_printerid(
        @proxy.my_devices['test'].gcp_printer_control[:gcp_printerid]
      )
      assert_equal  'test',result

    end   # should do


  end  # context proxy

# _____________________________________________________________________________    

end  # class test
