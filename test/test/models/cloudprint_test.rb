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
    
  end   # context post

# _____________________________________________________________________________    

end  # class test
