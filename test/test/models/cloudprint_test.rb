require 'test_helper'

class CloudprintTest < ActiveSupport::TestCase
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    puts "***** outer set up *****"
   
  context "a printer" do
    
    setup do
      puts ">>>>> inner set up >>>>>"
    end

    should 'be true' do
      assert true
    end
    
    should 'be true again' do
      assert true
    end
    
  end   # context post

# _____________________________________________________________________________    

end  # class test
