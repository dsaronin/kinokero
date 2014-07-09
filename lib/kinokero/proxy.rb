# #########################################################################
# #########################################################################

module Kinokero

# #########################################################################

class Proxy

  extend Forwardable
#   require 'singleton'
#   include Singleton

# #########################################################################

  attr_reader :cloudprint, :options

    # note to self: for some reason, the '@' in :@logger is necessary
    # in the following statement
  def_delegators :@logger, :debug, :info, :warn, :error, :fatal

# #########################################################################

# -----------------------------------------------------------------------------
  def initialize( gcp_control, options = { verbose: true } )
     @cloudprint = Kinokero::Cloudprint.new( gcp_control, options )
     @proxy_id   = Kinokero.my_proxy_id
     @options    = options
     @logger     = ::Logger.new(STDOUT)  # in case we need error logging
  end

# -----------------------------------------------------------------------------
# do_connect -- 
# -----------------------------------------------------------------------------
  def do_connect()
    @cloudprint.gtalk_start_connection do |printerid|
      do_print_jobs( printerid )
    end  # block
  end

# -----------------------------------------------------------------------------
# do_delete -- 
# -----------------------------------------------------------------------------
  def do_delete()
    @cloudprint.gcp_delete_printer
    # TODO: remove from printers, if last, sever connection
  end


# -----------------------------------------------------------------------------
# do_register -- registers our default printer, prints claim info
# -----------------------------------------------------------------------------
  def do_register( gcp_request, &block )

    response = @cloudprint.register_anonymous_printer( gcp_request ) { |gcp_ctl|  

         # this block is called only if/when asynch polling completes
         # in a separate process
      log_debug("\n***** Printer successfully registered to GCP *****\n")
      puts "register gcp_control: #{@gcp_ctl.object_id}"
      puts gcp_ctl.inspect

        # this is the place to save anything we need to about the printers
        # under swalapala control; info is in gcp_ctl
      yield( gcp_ctl )  # persistence

    }

    # execution continues here AFTER registering but BEFORE polling completes
    # this is our opportunity to tell the user to claim the printer via
    # registration token at Google Cloud Print server

    print_gcp_registration_info( response )  # output registration instructions

  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_refresh()
    @cloudprint.gcp_refresh_tokens
    # new token should be set up in the gcp_control area
  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_list()
    result = @cloudprint.gcp_get_printer_list
  end


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_job_status(job,status,pages)
    @cloudprint.gcp_job_status( job["id"], status, pages )
  end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def do_print_jobs( printerid )
    result = @cloudprint.gcp_get_printer_fetch( printerid )
    log_debug  "#{printerid} queue has #{result['jobs'].size} jobs"

    result['jobs'].each do |job|
      # TODO: lookup our printer and relevant gcp_control stuff
      # cups_printer = find_printer_by_gcp_id( job["printerid"] )

      if ( job_file = @cloudprint.gcp_get_job_file( job["fileUrl"] ) )

        do_job_status(job, ::Kinokero::Cloudprint::GCP_JOBSTATE_IN_PROGRESS, 0)

        File.open( job["id"], 'wb') { |fp| fp.write(job_file) }
       
        printer_command = "lp -d #{@cloudprint.gcp_control[:cups_alias]} #{job['id']}"
        log_debug  "#{job['printerName']}: " + printer_command + "\n"

        status = system( "#{printer_command}" )

        # TODO: poll printer job status & report back to GCP
        do_job_status( job, ::Kinokero::Cloudprint::GCP_JOBSTATE_DONE, job["numberOfPages"] )

        # TODO: delete the file
        File.delete( job["id"] )

      else  # failure to get file
        @cloudprint.gcp_job_status_abort( 
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
      msg = snippet_registration_info( response )

        # display in log or the SYSOUT

      log_debug  ("\n------------------------------------------------------------------\n")
      info( msg )
      log_debug  ("\n------------------------------------------------------------------\n")

        # print out on the new printer
      command = ( system("which enscript") ? 'enscript -f Helvetica12' : 'lp' )

      system("echo '#{msg}' | #{command} -d #{response[:cups_alias]}")
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
