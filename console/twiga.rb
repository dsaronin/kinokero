#!/usr/bin/env ruby

# ****************************************************************************
# *****  app configured, initialized, and ruby-prepped here   ****************
# ****************************************************************************

puts "\nTwiga configuration; running ruby #{ RUBY_VERSION }"

    # make it so that our lib is at the head of the load/require path array
  $:.unshift( File.expand_path('../lib', __FILE__) )
    # kick off module configurations
  load File.expand_path('../config/application_configuration.rb', __FILE__)
  
# ****************************************************************************

  require 'yaml'
  require 'erb'
  require 'active_support/core_ext/hash'
  require 'cups'
  require 'thread'
  
# ****************************************************************************
# get temporary managed printer data for testing interfaces
# ****************************************************************************

GCP_SEED_FILE = "../config/gcp_seed.yml"

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

      puts "seed_data: #{@seed_data.object_id}"

    end
  end

# -----------------------------------------------------------------------------

  def write_gcp_seed()
    unless @seed_data.nil?

      ::Twiga.say_warn "updating seed data\n"

      File.open(
        File.expand_path(GCP_SEED_FILE , __FILE__ ), 
        'w'
      ) { |f| 
        YAML.dump(@seed_data, f) 
      }

    end   # unless no seed data yet
  end

# -----------------------------------------------------------------------------

  def get_gcp_control( item )
    load_gcp_seed()

    @seed_data[ item ].symbolize_keys
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

  def validate_item( item )
    return ( @seed_data.has_key?(item) ? item : 'test' )
  end

# -----------------------------------------------------------------------------

# #########################################################################
# ##########  one-offs for do_work commands  ##############################
# #########################################################################

# -----------------------------------------------------------------------------

  def do_ready_state( item )
    @proxy.do_ready_state( validate_item( item ) )
  end


# -----------------------------------------------------------------------------

  def do_list( item )
    @proxy.do_list( validate_item( item ) )
  end

# -----------------------------------------------------------------------------

  def do_fetch( item )
    jobs = @proxy.do_fetch_jobs( validate_item( item ) )
    if jobs['success']
      ::Twiga.say_warn "#{jobs['request']['params']['printerid'].first }: #{jobs['jobs'].size } print jobs"
    else  # had error
      ::Twiga.say_err "#{jobs['request']['params']['printerid'].first }: #{jobs['message']}" 
    end
  end


# -----------------------------------------------------------------------------

  def do_register( item )
    new_request = build_gcp_request( item )

    response = @proxy.do_register( new_request ) do |gcp_control|

      update_gcp_seed(gcp_control, gcp_control[:item] ) do |seed|
        add_gcp_seed_request( seed, new_request )
      end  # seed additions

    end   # do persist new printer information

    unless response[:success]
      ::Twiga.say_err "printer registration failed: #{response[:message]}"
    end

  end

# -----------------------------------------------------------------------------

  def do_delete( item )
    item = validate_item( item )
    @proxy.do_delete( item )
    @seed_data[item]['is_active'] = false
    write_gcp_seed()
  end

# -----------------------------------------------------------------------------

  def do_refresh( item )
    item = validate_item( item )
    @proxy.do_refresh( item )
    update_gcp_seed_tokens( item )
  end

# -----------------------------------------------------------------------------

  def do_connect( item )
    item = validate_item( item )
    ::Twiga.say_info  "Starting jingle connection to device: #{item}...\n"
    @proxy.do_connect( item )
    update_gcp_seed_tokens( item )
  end

# -----------------------------------------------------------------------------

  def show_seed()
    ::Twiga.say_warn "seed_data: #{@seed_data.object_id}"
    puts @seed_data.inspect
  end

# -----------------------------------------------------------------------------

  def show_gcp( item )
    gcp = @proxy.my_devices[validate_item( item )].gcp_printer_control
    ::Twiga.say_warn "cloudprint gcp: #{gcp.object_id}\n"
    puts gcp.inspect

  end

# -----------------------------------------------------------------------------

  def show_devices()
    ::Twiga.say_warn "device obj: #{@proxy.my_devices.object_id}\n"
    puts @proxy.my_devices.inspect
  end

# -----------------------------------------------------------------------------

  def show_time( item )
    item = validate_item( item )
    extime = @proxy.my_devices[item].gcp_printer_control[:gcp_token_expiry_time]
    ::Twiga.say_warn "expiry for #{item}: #{extime.class.name}\t#{extime.to_s(:db)}\n"

  end

# -----------------------------------------------------------------------------

HELP_LIST = %w(list fetch register ready refresh delete devices connect save seed time exit quit gcp help)

  def show_help()
    ::Twiga.say_info "Twiga commands: " + HELP_LIST.join(', ')
  end

# -----------------------------------------------------------------------------
# do_work --  mini command interpretor to assist debugging & development
# -----------------------------------------------------------------------------
  def do_work()

    show_help()
   ::Twiga.say_info "\ntwiga> "

   while (cmd = gets) do
     cmd.strip!
     tokens = cmd.split(/ /)
     unless tokens.empty?

       item = tokens[1]  ||  'test'
     
       case tokens.first.downcase

         when 'quit','exit' then break

         when 'register' then do_register( item )
         when 'refresh'  then do_refresh( item )
         when 'list'     then do_list( item )
         when 'fetch'    then do_fetch( item )
         when 'delete'   then do_delete( item )

         when 'save'     then update_gcp_seed_tokens( item )
         when 'seed'     then show_seed()
         when 'ready'    then do_ready_state( item )
         when 'time'     then show_time( item )
         when 'devices'  then show_devices()

         when 'connect'  then do_connect( item )

         when 'help' then show_help() 
         when 'cups' then do_cups_work() 
         when 'gcp'  then show_gcp( item )

       else
         ::Twiga.say_err "? unknown command: #{cmd}"
       end # case
     
     end # unless no command

     ::Twiga.say_info "\ntwiga> "
   end

  end

# -----------------------------------------------------------------------------

# #########################################################################
# ##########  one-offs for do_cups commands  ##############################
# #########################################################################

# -----------------------------------------------------------------------------

  def show_printers()
    list = Cups.show_destinations
    puts list.inspect
  end

  def show_default()
    printer = Cups.default_printer
    puts printer.inspect
  end

  def show_jobs()
    hash = Cups.all_jobs( Cups.default_printer )
    last_job = hash.keys.sort.last
    puts "#{last_job}: " + hash[last_job].inspect
  end

  def show_brief_options()
    ::Twiga.say_warn snippet_brief_options(
      Cups.options_for( Cups.default_printer )
    )
  end

  def show_options()
    show_brief_options()
    puts snippet_full_options Cups.options_for( Cups.default_printer )
  end
  
  def state_to_s( state )
    case ( state )
      when '3' then 'idle'
      when '4' then 'busy'
      when '5' then 'stopped'
      else
        state
    end # case
  end

  def snippet_full_options( state_hash )
<<RUBY20
  name:    #{ state_hash['printer-info'] }
  make:    #{ state_hash['printer-make-and-model'] }
  ready:   #{ state_hash['printer-is-accepting-jobs'] }
  state:   #{ state_to_s( state_hash['printer-state'] ) }
  why:     #{ state_hash['printer-state-reasons'] }
RUBY20
  end

  def snippet_brief_options( state_hash )

    state_hash['printer-info'] + ': ' +
    ( state_hash['printer-is-accepting-jobs']  ?  ''  :  'not ') +
    'ready - ' +
    state_to_s( state_hash['printer-state'] ) + 
    ( state_hash['printer-state-reasons'] == 'none'  ?  
     ''  : 
     ': ' + state_hash['printer-state-reasons']    ) + "\n"

  end

  def print_testpage( printer=nil )
   pj = setup_testpage( printer )
   puts "pj initial state is: #{pj.state}"
   pj.print
   return pj
  end

  def setup_testpage( printer=nil )
    return Cups::PrintJob.new( Kinokero.cups_testpage_file, printer) 
  end

  def scan_state( printer=nil )
    state = :queued
    pj = print_testpage( printer )
    while ( state == :processing || state == :held || state == :queued )
      unless pj.state == state
        state = pj.state
        puts "state changed to: #{state}; #{pj.error_code} / #{pj.error_reason}"
      end   # state changed
      sleep 0.200   # sleep for 200 ms
    end  # while
    
    puts "final state:   #{pj.state}"
    puts "scan state finished: #{pj.completed?} / #{pj.failed?}"
    puts "error info: #{pj.error_code} / #{pj.error_reason}"
  end

  def start_poll_thread()

    poll_thread = Thread.new  do

      while true 
        show_brief_options()
        sleep 2
      end

    end  # polling thread

      # force abort of everything if exception in thread
    poll_thread.abort_on_exception = true

    return poll_thread

  end


# -----------------------------------------------------------------------------

CUPS_HELP_LIST = %w(printers default jobs options print scan exit quit help)

  def show_cups_help()
    ::Twiga.say_info "Twiga cups commands: " + CUPS_HELP_LIST.join(', ')
  end


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

  def do_cups_work()

    # start_poll_thread()

    show_help()
   ::Twiga.say_info "\ncups>> "

   while (cmd = gets) do
     cmd.strip!
     tokens = cmd.split(/ /)
     unless tokens.empty?

       item = tokens[1]  ||  'test'
     
       case tokens.first.downcase

         when 'quit','exit' then break

         when 'printers' then show_printers() 
         when 'default' then show_default() 
         when 'jobs' then show_jobs() 
         when 'options' then show_options() 

         when 'print' then print_testpage() 
         when 'scan' then scan_state() 

         when 'help' then show_cups_help() 

       else
         ::Twiga.say_err "? unknown command: #{cmd}"
       end # case
     
     end # unless no command

     ::Twiga.say_info "\ncups>> "
   end


  end

# -----------------------------------------------------------------------------

# #########################################################################
# ##########  command line options handling  ##############################
# #########################################################################

# -----------------------------------------------------------------------------

  def parse_options()

    options = {}

    ARGV.each_index do |index|
      case $*[index]
        when '-m' then options[:auto_connect] = false
        when '-v' then options[:verbose] = true
        when '-q' then options[:verbose] = false
        when '-t' then options[:log_truncate] = true
        when '-r' then options[:log_response] = false
      else
        ::Twiga.say_warn "unknown option: #{arg}"
      end    # case

      $*.delete_at(index)   # remove from command line

    end   # do each cmd line arg
      
    return Kinokero::Cloudprint::DEFAULT_OPTIONS.merge(options)

  end

# -----------------------------------------------------------------------------

# **************************************************************************** # *****  appliance initialization here   *************************************
# ********   MAIN STARTING POINT HERE   **************************************
# ****************************************************************************

  ::Twiga.say_info "\nTwiga starting...\n"
  
     # start up the GCP proxy
  @proxy = Kinokero::Proxy.new( build_device_list(), parse_options )
  @my_devices = @proxy.my_devices

  unless $0 =~ /irb/   # are we in console mode? 
    #  no, start appliance

  # ****************************************************************************
  # ***  appliance primary work goes here   ************************************
  # ****************************************************************************

    do_work()   # primary twiga control area

  # ****************************************************************************
  # *********   app ends here   ************************************************
  # ****************************************************************************

  ::Twiga.say_info "...ending\n\n"

    exit 0

# -----------------------------------------------------------------------------
  end   # end unless console mode
# fall through to IRB
