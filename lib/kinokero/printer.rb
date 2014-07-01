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
  def initialize( gcp_info={}, request_info={}, model_info=nil )
    super

    setup_gcp( gcp_info )
    setup_request( request_info )
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
    validate_gcp_options( gcp_info )
    @gcp_printer_control = gcp_info    # persist the hash
  end

# -----------------------------------------------------------------------------

# setup_request info from hash (possibly empty)
#
# * *Args*    :
#   - +request_info+ - hash of info needed for a request
# * *Returns* :
#   - 
# * *Raises* :
#   - ArgumentError upon invalid values or keys for gcp_info
#
  def setup_request( request_info )
    validate_request_options( request_info )
    @gcp_printer_request = request_info    # persist the hash
  end

# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

protected

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# SAMPLE_GCP_OPTIONS are indicative of the data furnished by GCP after
# printer registration; the data here has been sanitized
SAMPLE_GCP_OPTIONS = {
  gcp_xmpp_jid: "123456789cbce123456789abcdef123a@cloudprint.googleusercontent.com" 
  gcp_confirmation_url: "https://www.google.com/cloudprint/regconfirmpage?printername=my_printer_name&email=my_user@gmail.com&dpi=300&pagesize=215900,279400" 
  gcp_owner_email: "my_user@gmail.com" 

  gcp_printer_name: "my_printer_name"
  gcp_printerid: "bd9234a9-abc6-1a34-012def1234ab63f03" 

  gcp_access_token: "ya29.LgDrBsgEaZ7b-ridicuously-long-encrypted-key-u2TA" 
  gcp_refresh_token: "1/nm0_another_encrypted_key_xxxxxxxxxxxxxe730" 
  gcp_token_type: "Bearer" 
  gcp_token_expiry_time: <%= Time.new(2014,6,13,19,31,0) %>
}

# VALID_GCP_OPTIONS is used to determine if user options valid
# if (in future) any default options were to be off-limits,
# then a specific sets of keys will have to be enumerated below 
VALID_GCP_OPTIONS = SAMPLE_GCP_OPTIONS.keys


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

    # options validations: check for invalid keys
    options.assert_valid_keys(VALID_GCP_OPTIONS)

    # options validations: check for invalid values
    VALID_GCP_OPTIONS.each do |key|
       if options[key].nil? || !option[key].kind_of?( SAMPLE_GCP_OPTIONS[key].class )
         raise ArgumentError,"[gcp_control validation] value for key #{key} should be similar to #{SAMPLE_GCP_OPTIONS[key]}"
       end

    end  # do validate each key
    
  end

# -----------------------------------------------------------------------------

  end # Printer
  
# ****************************************************************************

end # Kinokero
