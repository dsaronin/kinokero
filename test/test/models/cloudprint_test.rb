require 'test_helper'
require 'test_kinokero'

class CloudprintTest < ActiveSupport::TestCase
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  setup :setup_jig
  teardown :teardown_jig

  context "a printer" do
    
    should 'be true' do
      assert true
    end
    
    should 'be true again' do
      assert true
    end
    
  end   # context post

# _____________________________________________________________________________    

end  # class test
