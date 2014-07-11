module Kinokero
 
# #########################################################################

  class Log

# #########################################################################

    # logger must be accessible as class-method level for register
  @@logger = ::Logger.new(STDOUT)  # in case we need error logging

  # def_delegators :@@logger, :debug, :info, :warn, :error, :fatal
# #########################################################################

# ------------------------------------------------------------------------------

  def self.debug(msg, &block)
    @@logger.debug( say_debug(msg), &block )
  end

# ------------------------------------------------------------------------------

  def self.verbose_debug(msg, verbose=nil )
    if verbose || ( verbose.nil? && Kinokero.verbose )
      @@logger.debug( say_debug(msg) )
    end
  end

# ------------------------------------------------------------------------------

  def self.info(msg, &block)
    @@logger.info( say_info(msg), &block )
  end

# ------------------------------------------------------------------------------

  def self.verbose_info(msg, verbose=nil )
    if verbose || ( verbose.nil? && Kinokero.verbose )
      @@logger.info( say_info(msg) )
    end
  end

# ------------------------------------------------------------------------------

  def self.warn(msg, &block)
    @@logger.warn( say_warn(msg), &block )
  end

# ------------------------------------------------------------------------------

  def self.error(msg, &block)
    @@logger.error( say_error(msg), &block )
  end

# ------------------------------------------------------------------------------

  def self.fatal(msg, &block)
    @@logger.fatal( say_fatal(msg), &block )
  end

# ------------------------------------------------------------------------------



# #########################################################################

# ------------------------------------------------------------------------------

#
# log_request -- will log the farady request params if verbose setting
#
# * *Args*    :
#   - +msg+ - string to identify position in protocol sequence
#   - +req+ - gcp request hash
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def self.log_request( msg, req, verbose = nil )
    if verbose || ( verbose.nil? && Kinokero.verbose )
      body = ( req.body.nil?  ?  req  :  req.body )
      puts "\n---------- REQUEST ------------ #{body.class.name} --------------"
      @@logger.debug( msg ) { body.inspect }
      puts "----------" * 4
    end  # if verbose
  end

# ------------------------------------------------------------------------------

# log the GCP response
# 
# * *Args*    :
#   - +msg+ - string to identify position in protocol sequence
#   - +response+ - gcp response hash
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def self.log_response( msg, response, verbose = nil )
    if verbose || ( verbose.nil? && Kinokero.verbose )
      body = ( response.body.nil?  ?  response  :  response.body )
      puts "\n---------- RESPONSE ------------ #{body.class.name} --------------"
      @@logger.debug( msg ) { body.inspect[0, ::Kinokero.truncate_log] } 
      puts "----------" * 4
    end  # if verbose
  end

# #########################################################################
   
private

# #########################################################################

# -----------------------------------------------------------------------------

# wraps a message in color coding for terminals
#
  def self.say_debug(msg)
    return msg    # white
  end

# -----------------------------------------------------------------------------

  def self.say_info(msg)
    return "\e[1;34m" + msg + "\e[0m"   # blue
  end

# -----------------------------------------------------------------------------

  def self.say_warn(msg)
    return "\e[1;33m" + msg + "\e[0m"   # orange
  end

# -----------------------------------------------------------------------------

  def self.say_error(msg)
    return "\e[1;31m" + msg + "\e[0m"   # red
  end

# -----------------------------------------------------------------------------

  def self.say_fatal(msg)
    return "\e[1;31m" + msg + "\e[0m"   # red
  end



# #########################################################################

  end  # Log
 
# #########################################################################


end # Kinokero
