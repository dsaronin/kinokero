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

end # class Twiga

me = Twiga.new( 
    :url => "https://secure.majozi.com",
    :oauth_token => "wildblue"
)
me.say_info "\nTwiga starting...\n"
system('ruby -v')
me.say_info "...ending\n\n"

exit 0

# -----------------------------------------------------------------------------
#
