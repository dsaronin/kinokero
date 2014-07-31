# ****************************************************************************
# *******    common methods for twiga appliance    ********************
# ****************************************************************************
module Twiga
# **************************************************************************

  @@env = nil

# -----------------------------------------------------------------------------
  def self.say_info(msg)
    print "\e[1;34m" + msg + "\e[0m"
  end
# -----------------------------------------------------------------------------
  def self.say_warn(msg)
    print "\e[1;33m" + msg + "\e[0m"
  end
# -----------------------------------------------------------------------------
  def self.say_err(msg)
    print "\e[1;31m" + msg + "\e[0m"
  end
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# env= -- sets the environment for appliance
  # raises ArgumentError exception if invalid
# -----------------------------------------------------------------------------
  def self.env=( new_env )

    if %w(development production test staging).include?( new_env )
      @@env = new_env   # ok to set environment
    else
      raise ArgumentError, "Unrecognized environment: #{new_env}"
    end  # environment validation check

    return @@env

  end

# -----------------------------------------------------------------------------
# set_environment! -- initializes and sets environment variable
  # tries to get from environment variable if missing
  # else defaults to 'development'
# -----------------------------------------------------------------------------
  def self.set_environment!
    env= ( ENV[ 'TWIGA_ENV' ] || 'development' )
  end

  def self.env
    @@env || set_environment!
  end

  def self.env_is_production?
    @@env == 'production'
  end

  def self.env_is_test?
    @@env == 'test'
  end

  def self.env_is_staging?
    @@env == 'staging'
  end

  def self.env_is_development?
    @@env == 'development'
  end



# ****************************************************************************
# ****************************************************************************
# ****************************************************************************
end  # module Twiga
