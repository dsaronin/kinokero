# ****************************************************************************
# *****  app configured, initialized, and ruby-prepped here   ****************
# ****************************************************************************
# make it so that our lib is at the head of the load/require path array
#   $:.unshift( File.expand_path('../lib', __FILE__) )
#   load File.expand_path('../config/application_configuration.rb', __FILE__)
  
# ****************************************************************************

  require 'yaml'
  require 'erb'
  require 'active_support/core_ext/hash'
  require 'cups'
  require 'thread'
  
# ****************************************************************************
# get temporary managed printer data for testing interfaces
# ****************************************************************************

GCP_SEED_FILE = "../fixtures/gcp_seed.yml"

# #########################################################################
# ##########  working with seed data  #####################################
# #########################################################################

# -----------------------------------------------------------------------------

  def load_gcp_seed()
    if @seed_data.nil?
      @seed_data =  YAML.load( 
          ERB.new(
            File.read(
              File.expand_path(GCP_SEED_FILE , __FILE__ ) 
            )
          ).result 
      )

      #  puts "seed_data: #{@seed_data.object_id}"

    end
  end

# -----------------------------------------------------------------------------

  def write_gcp_seed()
    unless @seed_data.nil?

      File.open(
        File.expand_path(GCP_SEED_FILE , __FILE__ ), 
        'w'
      ) { |f| 
        YAML.dump(@seed_data, f) 
      }

    end   # unless no seed data yet
  end

# -----------------------------------------------------------------------------

  def update_gcp_seed(gcp_control, item, &block )

    @seed_data[item] ||= {}  # if first time
    
    @seed_data[item]['gcp_xmpp_jid'] = gcp_control[:gcp_xmpp_jid]
    @seed_data[item]['gcp_confirmation_url'] = gcp_control[:gcp_confirmation_url]
    @seed_data[item]['gcp_owner_email'] = gcp_control[:gcp_owner_email]

    @seed_data[item]['gcp_printer_name'] = gcp_control[:gcp_printer_name]
    @seed_data[item]['gcp_printerid'] = gcp_control[:gcp_printerid]

    @seed_data[item]['gcp_access_token'] = gcp_control[:gcp_access_token]
    @seed_data[item]['gcp_refresh_token'] = gcp_control[:gcp_refresh_token]
    @seed_data[item]['gcp_token_type'] = gcp_control[:gcp_token_type]
    @seed_data[item]['gcp_token_expiry_time'] = gcp_control[:gcp_token_expiry_time]

    @seed_data[item]['is_active'] = gcp_control[:is_active]
    @seed_data[item]['virgin_access'] = gcp_control[:virgin_access]

    yield( @seed_data[item] ) if block_given?

    write_gcp_seed()

  end

# -----------------------------------------------------------------------------


  def add_gcp_seed_request( seed, new_request )

      # add in some addtional initializing seed info from the request block
    seed['printer_id']    = new_request[:printer_id]
    seed['item']          = new_request[:item]
    seed['cups_alias']    = new_request[:cups_alias]
    seed['capability_ppd']   = new_request[:capability_ppd]
    seed['capability_cdd']   = new_request[:capability_cdd]
    seed['gcp_printer_name'] = new_request[:gcp_printer_name]

    seed['gcp_uuid']     = new_request[:gcp_uuid]
    seed['gcp_manufacturer']     = new_request[:gcp_manufacturer]
    seed['gcp_model']     = new_request[:gcp_model]
    seed['gcp_setup_url']     = new_request[:gcp_setup_url]
    seed['gcp_support_url']     = new_request[:gcp_support_url]
    seed['gcp_update_url']     = new_request[:gcp_update_url]
    seed['gcp_firmware']     = new_request[:gcp_firmware]

    return seed
  end

# -----------------------------------------------------------------------------

  def update_gcp_seed_tokens( item )

    @seed_data[item] ||= {}  # if first time
    
    gcp = @proxy.my_devices[item].gcp_printer_control

    @seed_data[item]['gcp_access_token'] = gcp[:gcp_access_token]
    @seed_data[item]['gcp_token_expiry_time'] = gcp[:gcp_token_expiry_time]
    @seed_data[item]['virgin_access'] = gcp[:virgin_access]

    write_gcp_seed()
  end

# -----------------------------------------------------------------------------

  def build_device_list()

    load_gcp_seed()    # load the seed data

      # prep to build up a hash of gcp_control hashes
    gcp_control_hash = {}

    @seed_data.each_key do |item|
      gcp_control_hash[ item ] = @seed_data[ item ].symbolize_keys  # strip item into hash with keys
    end   # convert each seed to a device object

    return gcp_control_hash
    
  end   # convert each seed to a device object

# -----------------------------------------------------------------------------

# if item hasn't yet been defined in seed data, create one out of
# thin air by using test as a template
  def build_gcp_request( item )

    use_item = validate_item( item )

    return {
      item:  item,
      printer_id:   0,  # will be cue to create new record
      gcp_printer_name: "gcp_#{item}_printer",
      capability_ppd: @seed_data[use_item]['capability_ppd'],
      capability_cdd: @seed_data[use_item]['capability_cdd'],
      cups_alias: @seed_data[use_item]['cups_alias'],
      gcp_uuid:         @seed_data[use_item]['gcp_uuid'],
      gcp_manufacturer: @seed_data[use_item]['gcp_manufacturer'],
      gcp_model:        @seed_data[use_item]['gcp_model'],
      gcp_setup_url:    @seed_data[use_item]['gcp_setup_url'],
      gcp_support_url:  @seed_data[use_item]['gcp_support_url'],
      gcp_update_url:   @seed_data[use_item]['gcp_update_url'],
      gcp_firmware:     @seed_data[use_item]['gcp_firmware'],
    }
  end

# -----------------------------------------------------------------------------

  def find_or_fail( filename )
    user_file = Dir.glob(filename).first
    if user_file.blank? 
       raise  IOError, "file: '#{filename}' not found"
    end
    return user_file
  end

# -----------------------------------------------------------------------------
 
  def validate_item( item )
    return ( @seed_data.has_key?(item) ? item : 'test' )
  end

# -----------------------------------------------------------------------------

# **************************************************************************** 
# *****  test jig initialization here    *************************************
# ****************************************************************************

  def validate_pre_conditions()
    unless  ENV["GCP_PROXY_CLIENT_ID"]  &&  ENV["GCP_PROXY_CLIENT_SECRET"]

      raise ArgumentError, "Missing environment variables for GCP_PROXY_CLIENT_ID, GCP_PROXY_CLIENT_SECRET"

    end   # unless environment variables defined

    find_or_fail( '/etc/cups/ppd/laserjet_1102w.ppd' )
    find_or_fail( '/etc/cups/cdd/laserjet_1102w.cdd' )
    find_or_fail( File.expand_path(GCP_SEED_FILE , __FILE__ ) )

  end

  def setup_jig()
    if @proxy.nil?  # start up the GCP proxy
      validate_pre_conditions()   # validate prerequisite assumptions
       
        # read seed file, set up proxy for testing
      @proxy = Kinokero::Proxy.new( build_device_list(), {} )
    end  # initial @proxy setup
  end

  def teardown_jig()
  end

# -----------------------------------------------------------------------------
