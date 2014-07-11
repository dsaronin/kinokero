# #########################################################################
# #########################################################################

module Kinokero

# #########################################################################

class Proxy

  extend Forwardable
#   require 'singleton'
#   include Singleton

# #########################################################################

  attr_reader :my_devices, :options

    # note to self: for some reason, the '@' in :@logger is necessary
    # in the following statement
  def_delegators :@logger, :debug, :info, :warn, :error, :fatal

# #########################################################################

# -----------------------------------------------------------------------------
  def initialize( device_hash, options = { verbose: true } )

     @proxy_id   = Kinokero.my_proxy_id
     @options    = options
     @logger     = ::Logger.new(STDOUT)  # in case we need error logging
     @my_devices = device_hash

     device_hash.each_key do |item|

       device_hash[item].cloudprint = Kinokero::Cloudprint.new( 
             device_hash[item].gcp_printer_control, 
             options 
       )

     end  # setting up each device

  end

# -----------------------------------------------------------------------------
# do_connect -- 
# -----------------------------------------------------------------------------
  def do_connect(item)
    @my_devices[item].cloudprint.gtalk_start_connection do |printerid|
      do_print_jobs( printerid )
    end  # block
  end

# -----------------------------------------------------------------------------
# do_delete -- 
# -----------------------------------------------------------------------------
  def do_delete(item)
    @my_devices[item].cloudprint.gcp_delete_printer
    # TODO: remove from printers, if last, sever connection
  end


# -----------------------------------------------------------------------------
# do_register -- registers our default printer, prints claim info
# -----------------------------------------------------------------------------
  def do_register( gcp_request, &block )

    response = Kinokero::Cloudprint.register_anonymous_printer( gcp_request ) do |gcp_ctl|  

         # this block is called only if/when asynch polling completes
         # in a separate process
      log_debug("\n***** Printer successfully registered to GCP *****\n")
      puts "register gcp_control: #{@gcp_ctl.object_id}"
      puts gcp_ctl.inspect

        # this is the place to save anything we need to about the printers
        # under swalapala control; info is in gcp_ctl
      yield( gcp_ctl )  # persistence

    end  # block for register

    # execution continues here AFTER registering but BEFORE polling completes
    # this is our opportunity to tell the user to claim the printer via
    # registration token at Google Cloud Print server

    print_gcp_registration_info( response )  # output registration instructions

  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_refresh(item)
    @my_devices[item].cloudprint.gcp_refresh_tokens
    # new token should be set up in the gcp_control area
  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_list(item)
    @my_devices[item].cloudprint.gcp_get_printer_list
  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

  def item_from_printerid( printerid )

    found = @my_devices.detect do |item, device|
      break item if device.gcp_printer_control[:gcp_printerid] == printerid
      false
    end  # each item

    raise PrinteridNotFound, printerid if found.nil?  # oops, not found!

    return found

  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

# do_print_jobs blends across the perfect protocol boundaries I'm trying to 
# maintain with Cloudprint, mainly because there's a higher level process
# handling which it has to handle, thus involving multiple cloudprint
# interactions and Printer class interaction.
# -----------------------------------------------------------------------------
  def do_print_jobs( printerid )
    item = item_from_printerid( printerid )  # find corresponding device item
    my_cloudprint = @my_devices[item].cloudprint  # DRY access

    result = my_cloudprint.gcp_get_printer_fetch( printerid )

    log_debug  "#{ printerid } queue has #{ result['jobs'].size } jobs"

      # deal with each job fetched
    result['jobs'].each do |job|

      unless printerid == job['printerid']  # ? hmmm, different printer ref'd

        item = item_from_printerid( printerid )  # find corresponding device item
        printerid = job['printerid']
        my_cloudprint = @my_devices[item].cloudprint  # DRY access
        print "\e[1;31m\n***** WARNING ***** differ printerid in fetch queue #{printerid}\n\e[0m" 
      end

      if ( job_file = my_cloudprint.gcp_get_job_file( job["fileUrl"] ) )

        my_cloudprint.gcp_job_status(
          job["id"], 
          ::Kinokero::Cloudprint::GCP_JOBSTATE_IN_PROGRESS, 
          0
        )

        File.open( job["id"], 'wb') { |fp| fp.write(job_file) }
       
        printer_command = "lp -d #{my_cloudprint.gcp_control[:cups_alias]} #{job['id']}"
        log_debug  "#{job['printerName']}: " + printer_command + "\n"

        status = system( "#{printer_command}" )

        # TODO: poll printer job status & report back to GCP
        my_cloudprint.gcp_job_status( 
          job["id"], 
          ::Kinokero::Cloudprint::GCP_JOBSTATE_DONE, 
          job["numberOfPages"] 
        )

        # TODO: delete the file
        File.delete( job["id"] )

      else  # failure to get file
        my_cloudprint.gcp_job_status_abort( 
            job["id"], 
            ::Kinokero::Cloudprint::GCP_USER_ACTION_OTHER,
            0
        )
          
      end   # if..then..else get job file

    end   # do each job

  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def print_gcp_registration_info( response )
    if response[:success]
      Kinokero::Printer.print_gcp_registration_info( 
        response[:cups_alias],   # actual printer to use
        snippet_registration_info( response )  # crafted message to print
      )
    end
  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def snippet_registration_info( response )
<<RUBY10

  ******************************************************************
  *** Important instructions to complete CloudPrint registration ***
  ******************************************************************
  *** Go to the following url and claim printer with the given   ***
  *** registration token, or click the easy-claim url below. You ***
  *** must do this within the next fifteen (15) minutes. Thanks! ***
  ******************************************************************
   
  Registration token: #{response[:gcp_printer_reg_token]}
  Claim printer URL:  #{response[:gcp_claim_token_url]}
  Easy-claim URL:     #{response[:gcp_easy_reg_url]}
  Record id:          #{response[:swalapala_printer_id]}
  Printer name:       #{response[:gcp_printer_name]}
  GCP printer id:     #{response[:gcp_printer_id]}
  
RUBY10
  end

protected


#
# log_debug -- will log the message if verbose setting
#
# * *Args*    :
#   - +msg+ - string to identify position in protocol sequence
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def log_debug( msg )
    if @options[:verbose]
      debug( msg ) { '' }
    end  # if verbose
  end


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

end # class Proxy

end # module
