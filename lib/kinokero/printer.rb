module Kinokero
  
# ****************************************************************************

# all printer-specific information & handling
# mixes in Device for any superset device common stuff 
# 
# == data structure
# relates together:
#   higher-level linkages (such as to a persistance/recall mechanism)
#   GCP-specific info (such as printer_id, access_tokens, etc)
#   GCP-requesting info for device
# 
  class Printer

    include Device
    require 'cups'

    attr_reader :model, :gcp_printer_control, :was_state
    attr_accessor  :cloudprint, :poll_thread   # cloudprint object for this device

# -----------------------------------------------------------------------------

# new object constructor; any/all args can be missing
#
# * *Args*    :
#   - +gcp_info+ - hash of on-going gcp required information
#   - +request_info+ - hash of info needed for a request
#   - +model_info+ - nil or higher-level object itself
# * *Returns* :
#   - Printer object
# * *Raises* :
#   - 
#
  def initialize( gcp_info={}, model_info=nil )
    # TODO: uncomment when Device mix-in is fleshed out
    # super

    @model = nil
    @poll_thread = nil   # will be the polling thread object
    @cloudprint = nil   # Proxy fills this in later
    @was_state  = false   # previous state, printer not ready
    @gcp_printer_control = nil   # default if empty

    setup_model( model_info )
    setup_gcp( gcp_info )


  end

# -----------------------------------------------------------------------------

# setup_model info 
#
# * *Args*    :
#   - +model_info+ - some type of model object meaningful to calling appliance
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def setup_model( model_info )
    @model = model_info
  end


# -----------------------------------------------------------------------------

# setup_gcp info from hash (possibly empty)
#
# * *Args*    :
#   - +gcp_info+ - hash of on-going gcp required information
# * *Returns* :
#   - 
# * *Raises* :
#   - ArgumentError upon invalid values or keys for gcp_info
#
  def setup_gcp( gcp_info )
    unless gcp_info.empty?
      validate_gcp_options( gcp_info )
      @gcp_printer_control = gcp_info    # persist the hash
    end
  end

# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------

  def start_poll_thread()

    if @poll_thread.nil? && @gcp_printer_control[:is_active]

      @poll_thread = Thread.new  do

        while true    # LOOP indefinitely

            # get current device cups state
          state_hash = Cups.options_for( @gcp_printer_control[:cups_alias] ) 

            # if different from before
          if @was_state ^ state_hash['printer-is-accepting-jobs']
               # remember the changed state
            @was_state = state_hash['printer-is-accepting-jobs']
               # then tell GCP about the change
            @cloudprint.gcp_ready_state_changed( 
                @was_state,
                cups_state_to_sym( state_hash['printer-state'] ),
                cups_reason( state_hash['printer-state-reasons'] )
            )
          end

            # go back to sleep again
          sleep Kinokero.printer_poll_cycle   #  <<<< SLEEPING HERE <<<<<
        end

      end  # polling thread; only ends when killed

        # force abort of everything if exception in thread
      @poll_thread.abort_on_exception = true

    end  # if no existing poll_thread and this is an active printer

  end

  def stop_poll_thread()
    @poll_thread.kill  unless @poll_thread.nil?
    @poll_thread = nil
  end

# -----------------------------------------------------------------------------

  
  def cups_state_to_sym( state )
    case ( state )
      when '3' then :idle
      when '4' then :busy
      when '5' then :stopped
      else
        state.to_sym
    end # case
  end

  def cups_reason( reason )
    return ( reason == 'none' ?  ''  :  reason )
  end

  
# ****************************************************************************
# PRINTER CONTROL  
# ****************************************************************************

  def print_file( file )
    printer_command = "lp -d #{@gcp_printer_control[:cups_alias]} #{file} "
    Kinokero::Log.verbose_debug  "#{@gcp_printer_control[:gcp_printer_name]}: " + 
                                 printer_command + "\n"

    status = system( "#{printer_command}" )

    # TODO: figure out what the status means? or get printer status
    # so we know when the job has successfully printed

    return status
  end

# -----------------------------------------------------------------------------

  def is_printer_ready?()
    state_hash = Cups.options_for( @gcp_printer_control[:cups_alias] )
    return state_hash['printer-is-accepting-jobs']
  end


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

protected

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# SAMPLE_GCP_OPTIONS are indicative of the data furnished by GCP after
# printer registration; the data here has been sanitized
SAMPLE_GCP_OPTIONS = {
  gcp_xmpp_jid: "123456789cbce123456789abcdef123a@cloudprint.googleusercontent.com" ,
  gcp_confirmation_url: "https://www.google.com/cloudprint/regconfirmpage?printername=my_printer_name&email=my_user@gmail.com&dpi=300&pagesize=215900,279400" ,
  gcp_owner_email: "my_user@gmail.com" ,

  gcp_printer_name: "my_printer_name",
  gcp_printerid: "bd9234a9-abc6-1a34-012def1234ab63f03" ,

  gcp_access_token: "ya29.LgDrBsgEaZ7b-ridicuously-long-encrypted-key-u2TA" ,
  gcp_refresh_token: "1/nm0_another_encrypted_key_xxxxxxxxxxxxxe730" ,
  gcp_token_type: "Bearer" ,
  gcp_token_expiry_time: Time.new(2014,6,13,19,31,0),

  printer_id: 1,
  item: 'test',
  cups_alias: 'cups_printer_name',
  virgin_access: false,   # true for initial oauth2 token
  is_active: false,   # set to true after successful registration

  capability_ppd: '/etc/cups/ppd/my_printer.ppd',
  capability_cdd: '/etc/cups/cdd/laserjet_1102w.cdd',

  gcp_uuid: 'VND3R11877',
  gcp_manufacturer: 'Hewlett-Packard',
  gcp_model: 'LaserJet P1102w',
  gcp_setup_url: 'http://www8.hp.com/us/en/campaigns/wireless-printing-center/printer-setup-help.html',
  gcp_support_url: 'http://h10025.www1.hp.com/ewfrf/wc/product?product=4110396&lc=en&cc=us&dlc=en&lang=en&cc=us',
  gcp_update_url: 'http://h10025.www1.hp.com/ewfrf/wc/product?product=4110396&lc=en&cc=us&dlc=en&lang=en&cc=us',
  gcp_firmware: '20130703',
}

# VALID_GCP_OPTIONS is used to determine if user options valid
# if (in future) any default options were to be off-limits,
# then a specific sets of keys will have to be enumerated below 
VALID_GCP_OPTIONS = SAMPLE_GCP_OPTIONS.keys

# -----------------------------------------------------------------------------

# validates gcp options
#
# * *Args*    :
#   - +options+ - gcp_control as a hash
# * *Returns* :
#   - 
# * *Raises* :
#   - ArgumentError if invalid option present 
#
  def validate_gcp_options(options)

    validate_hash(
      'VALIDATE gcp_control', 
      VALID_GCP_OPTIONS, 
      SAMPLE_GCP_OPTIONS, 
      options
    )
 
  end

# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------

# validates any hash options against a standard
#
# * *Args*    :
#   - +msg+ - string to display if exception occurs
#   - +valid_keys+ - list of expected hash keys (to look for invalid keys)
#   - +sample+ - hash of sample values for all those keys, used to validate options hash values
#   - +options+ - hash of values to be used
# * *Returns* :
#   - 
# * *Raises* :
#   - ArgumentError if invalid option present 
#

  def validate_hash(msg, valid_keys, sample, options)

    # options validations: check for invalid keys
    options.assert_valid_keys(valid_keys)

    # options validations: check for invalid values
    valid_keys.each do |key|

       if options[key].nil? || !similar_values?(options[key], sample[key]) 
         err_msg = "[#{msg}] value for key #{key} should be similar to <#{sample[key]}>, a #{sample[key].class}; " +
                   "instead it was <#{options[key]}>"
         raise ArgumentError, err_msg
       end

    end  # do validate each key
    
  end

# -----------------------------------------------------------------------------

  def similar_values?(ref, x)
    return true  if ref.kind_of?( x.class ) || ( (x == true) ^ (x == false) )
    return false
  end

# ****************************************************************************

# -----------------------------------------------------------------------------
  def self.print_gcp_registration_info( cups_printer, msg )

      # display in log or the SYSOUT
    Kinokero::Log.debug  ("\n------------------------------------------------------------------\n")
    Kinokero::Log.info( msg )
    Kinokero::Log.debug  ("\n------------------------------------------------------------------\n")

      # print out on the new printer
    command = ( system("which enscript") ? 'enscript -f Helvetica12' : 'lp' )

    system("echo '#{msg}' | #{command} -d #{cups_printer}")
  end




# ****************************************************************************

  end # Printer
  
# ****************************************************************************

end # Kinokero
