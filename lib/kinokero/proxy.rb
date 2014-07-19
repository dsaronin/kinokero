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

# #########################################################################

# -----------------------------------------------------------------------------
  def initialize( device_hash, options = { verbose: true, auto_connect: true } )

     @proxy_id   = Kinokero.my_proxy_id
     @options    = options
     @my_devices = device_hash

     Kinokero::Log.verbose_debug( options.inspect, options[:verbose] )

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
      # establish a jingle connection
    @my_devices[item].cloudprint.gtalk_start_connection do |printerid|

        # NOTE: this execution takes place asynchronously 
        # upon callback from jingle notification
      do_print_jobs( printerid )

    end  # block

    # execution continues here BEFORE above block executes

    my_printerid = @my_devices[item].gcp_printer_control[:gcp_printerid]
      # upon first connect, fetch & print any pending jobs in queue
    print_fetch_queue(
      item,    # find corresponding device item
      my_printerid,
      @my_devices[item].cloudprint.gcp_get_printer_fetch( my_printerid )
    )

  end

# -----------------------------------------------------------------------------

  def do_fetch_jobs( item )
    
    @my_devices[item].cloudprint.gcp_get_printer_fetch(
      @my_devices[item].gcp_printer_control[:gcp_printerid]
    )

  end

# -----------------------------------------------------------------------------
# do_delete -- 
# -----------------------------------------------------------------------------
  def do_delete(item)
    @my_devices[item].cloudprint.gcp_delete_printer
    @my_devices[item].cloudprint = nil    # release the reference to our object
    @my_devices.delete( item )   # remove device struct from our list
  end


# -----------------------------------------------------------------------------
# do_register -- registers our default printer, prints claim info
# -----------------------------------------------------------------------------
  def do_register( gcp_request, &block )

    response = Kinokero::Cloudprint.register_anonymous_printer( gcp_request ) do |gcp_ctl|  

         # this block is called only if/when asynch polling completes
         # in a separate process
      puts Kinokero::Log.say_info("\n***** Printer successfully registered to GCP *****")
      puts Kinokero::Log.say_warn "register gcp_control: #{@gcp_ctl.object_id}"
      puts gcp_ctl.inspect

        # wrap the newly registered printer in a device object
      new_device =  Kinokero::Printer.new( gcp_ctl, gcp_request)

        # add it to our list of managed devices
      @my_devices[ gcp_ctl[:item] ] = new_device

        # create a cloudprint object to manage the protocols
      new_device.cloudprint = 
               Kinokero::Cloudprint.new( gcp_ctl, @options )

      Kinokero::Log.verbose_debug  "my_devices has #{ @my_devices.size } devices [#{ @my_devices.object_id }]"

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

# do_print_jobs blends across the perfect protocol boundaries I'm trying to 
# maintain with Cloudprint, mainly because there's a higher level process
# handling which it has to handle, thus involving multiple cloudprint
# interactions and Printer class interaction.
# -----------------------------------------------------------------------------
  def do_print_jobs( printerid )

    item = item_from_printerid( printerid )
    print_fetch_queue(
      item,    # find corresponding device item
      printerid,
      @my_devices[item].cloudprint.gcp_get_printer_fetch( printerid )
    )

  end

# -----------------------------------------------------------------------------

# DRY work of printing a fetch queue of jobs
  def print_fetch_queue(item, printerid, fetch_result)
    if fetch_result['success']
      Kinokero::Log.verbose_debug  "#{ printerid } queue has #{ fetch_result['jobs'].size } jobs"

      my_cloudprint = @my_devices[item].cloudprint  # DRY access

        # deal with each job fetched
      fetch_result['jobs'].each do |job|

        unless printerid == job['printerid']  # ? hmmm, different printer ref'd

          item = item_from_printerid( printerid )  # find corresponding device item
          printerid = job['printerid']
          my_cloudprint = @my_devices[item].cloudprint  # DRY access
          print "\e[1;31m\n***** WARNING ***** differ printerid in fetch queue #{printerid}\n\e[0m" 
        end

          # able to download the job file for printing?
        if ( job_file = my_cloudprint.gcp_get_job_file( job["fileUrl"] ) )

            # update printer status to IN PROGRESS
          my_cloudprint.gcp_job_status(
            job["id"], 
            ::Kinokero::Cloudprint::GCP_JOBSTATE_IN_PROGRESS, 
            0
          )

            # write the file locally
          File.open( job["id"], 'wb') { |fp| fp.write(job_file) }
         
          status = @my_devices[item].print_file( #{job['id']} )

          # TODO: do something intelligent with the status
          # like report back to GCP

            # poll printer job status & report back to GCP
          my_cloudprint.gcp_job_status( 
            job["id"], 
            ::Kinokero::Cloudprint::GCP_JOBSTATE_DONE, 
            job["numberOfPages"] 
          )

            # delete the file
          File.delete( job["id"] )

        else  # failure to get file; tell GCP about the status
          my_cloudprint.gcp_job_status_abort( 
              job["id"], 
              ::Kinokero::Cloudprint::GCP_USER_ACTION_OTHER,
              0
          )
            
        end   # if..then..else get job file

      end   # do each job
    end  # pending job queue from fetch

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

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

end # class Proxy

end # module
