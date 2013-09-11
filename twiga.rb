#!/usr/bin/env ruby

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

me = Twiga.new( :url => "https://secure.majozi.com" )
me.say_info "\nTwiga starting...\n"
system('ruby -v')
me.say_info "...ending\n\n"

exit 0

# -----------------------------------------------------------------------------
#
