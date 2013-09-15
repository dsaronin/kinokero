#!/usr/bin/env ruby
# ****************************************************************************
# ******  mimic the way RAILS sets up required gems  *************************
# ****************************************************************************
require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# ****************************************************************************
require "kinokero"

# ****************************************************************************

class Twiga

# #########################################################################

  attr_reader :cloudprint

# #########################################################################
UBUNTU_PPD_PATH  = '/etc/cups/ppd/'
# TEST_PRINTER_PPD = 'HP-LaserJet-1020.ppd'
# TEST_PRINTER     = 'HP-LaserJet-1020'

TEST_PRINTER_PPD = 'Canon-MP160.ppd'
TEST_PRINTER     = 'Canon-MP160'

# #########################################################################

# -----------------------------------------------------------------------------
  def initialize( options = {} )
     @cloudprint = Kinokero::Cloudprint.new( options )
  end

# -----------------------------------------------------------------------------
  def say_info(msg)
    print "\e[1;34m" + msg + "\e[0m"
  end
# -----------------------------------------------------------------------------
  def say_warn(msg)
    print "\e[1;33m" + msg + "\e[0m"
  end
# -----------------------------------------------------------------------------
  def say_err(msg)
    print "\e[1;31m" + msg + "\e[0m"
  end
# -----------------------------------------------------------------------------
#    action_path = "/_feed/c395af64361f5ad6323a8296381ccfee123145ba/show_events.json" 

    # response = @cloudprint.connection.get "/home/stats"
#    response = @cloudprint.connection.get action_path do |request|
#      request.params['start'] = 1378018800
#      request.params['end']   = 1378105200
#      request.headers['Content-Type'] = 'application/json'
#    end # do

#    puts response.body.first['location']

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_work()

    say_warn("\n----------------------------------------------------------------\n")
    response = @cloudprint.register_anonymous_printer(
      TEST_PRINTER,
      UBUNTU_PPD_PATH + TEST_PRINTER_PPD
    )
    say_warn("\n----------------------------------------------------------------\n")
    puts response.body
    say_warn("\n----------------------------------------------------------------\n")
  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

end # class Twiga

me = Twiga.new( 
    # :url => "https://staging-punda.herokuapp.com"
    #  :oauth_token => "wildblue"
)

me.say_info "\nTwiga starting...\n"
#  system('ruby -v')

me.do_work()   # primary twiga control area

me.say_info "...ending\n\n"

exit 0

# -----------------------------------------------------------------------------
#
