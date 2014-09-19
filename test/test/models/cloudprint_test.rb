require 'test_helper'
require 'test_kinokero'

class CloudprintTest < ActiveSupport::TestCase
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  setup :setup_jig
  teardown :teardown_jig

  context "cloudprint" do
    
    should 'get printer list' do
      list_result = @proxy.my_devices['test'].cloudprint.gcp_get_printer_list
      assert list_result['success']   # should always return success even if no printers

      if @proxy.my_devices['test'].gcp_printer_control[:is_active]  # for an active printer
        assert !list_result["printers"].empty?
        printerid = @proxy.my_devices['test'].gcp_printer_control[:gcp_printerid]
        assert list_result["printers"].any? { |p| p["id"] == printerid }
      else # for inactive printer
        assert list_result["printers"].empty?
      end
    end    # end should test
    
    should 'refresh tokens' do
      if @proxy.my_devices['test'].gcp_printer_control[:is_active]  # for an active printer
        refresh_result =@proxy.my_devices['test'].cloudprint.gcp_refresh_tokens
        assert refresh_result['success']
      end
    end    # end should test

    should 'update device status' do

      if @proxy.my_devices['test'].gcp_printer_control[:is_active]  # for an active printer

        update_result = @proxy.my_devices['test'].cloudprint.gcp_ready_state_changed( 
            true,   # shows ready for jobs
            0,  # waiting for work
            ''      # no reason description needed
        )

        assert !update_result['success']   # should fail cuz printer not connected & ready

      end  # if active

    end    # end should test
    
    should 'register and delete offshoot printer' do

      item = 'wildblue'

        # build an offshoot request list
      new_request = build_gcp_request( item )

      response = Kinokero::Cloudprint.register_anonymous_printer( new_request ) do |gcp_ctl|

          # wrap the newly registered printer in a device object
        # new_device =  Kinokero::Printer.new( gcp_ctl, new_request)

          # create a cloudprint object to manage the protocols
        # cloudprint = 
        #         Kinokero::Cloudprint.new( gcp_ctl, {} )

      end   # handle new printer information

      assert response[:success]

    end    # end should test

    should 'fail to poll an old printer id claim' do

      poll_url = "https://www.google.com/cloudprint/getauthcode?printerid=#{@proxy.my_devices['test'].gcp_printer_control[:printer_id]}&oauth_client_id=" + Kinokero.proxy_client_id
      poll_response = Kinokero::Cloudprint.gcp_poll_request( poll_url )
      assert   !poll_response.body['success']     # should have failed

    end    # end should test


    should 'form a jingle auth token' do

      @proxy.my_devices['test'].gcp_printer_control[:virgin_access] = true  # force logic
      token = @proxy.my_devices['test'].cloudprint.gcp_form_jingle_auth_token()

      assert_kind_of String,token
      assert_not_equal '',token

    end  # end should test


    should 'form an auth token' do

      token = @proxy.my_devices['test'].cloudprint.gcp_form_auth_token()

      assert_kind_of String,token
      assert_not_equal '',token

    end  # end should test

    should 'fail to get oauth2 token using an old token' do

      old_token = "4/efjvnDKE7-fklBzH8G7KZVQ3S1V7.ckxazuujaQMWshQV0ieZDArE9o5tjAI"
      oauth_response = Kinokero::Cloudprint.gcp_get_oauth2_tokens( old_token ).body
      assert   !oauth_response['success']    # should fail on old data

    end    # end should test
    
  end   # context post

# _____________________________________________________________________________    

end  # class test
