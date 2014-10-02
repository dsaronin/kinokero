# OPTIONAL: Use this as a template for changing kinokero configuration
# put it in your config/initializers directory and rename to 
# kinokero.rb
# values shown below are the defaults in kinokero
# if for some reason you wish to respecify these defaults, precede the
# default name with "Kinokero::", such as the example for my_proxy_id
#
Kinokero.setup do |config|

# ---------------------------------------------------------------------
#  class Proxy required
# ---------------------------------------------------------------------

# two verbose settings are needed: one for Proxy instances and the 
# other for any class-level decisions; the one below is class-level
   config.verbose             =  false  

# unique name for this running of the GCP connector client
#   config.my_proxy_id         =  Kinokero::MY_PROXY_ID

# picks up your registered Google API client id from environment
#   config.proxy_client_id     =  ENV["GCP_PROXY_CLIENT_ID"]

# picks up your registered Google API client secret from environment
#   config.proxy_client_secret =  ENV["GCP_PROXY_CLIENT_SECRET"]

# picks up a unique serial number for this proxy (future expansion)
#   config.proxy_serial_nbr    =  ENV["GCP_PROXY_SERIAL_NBR"]

# ---------------------------------------------------------------------
#  class Cloudprint required
# ---------------------------------------------------------------------

# how to encoade oauth files
#   config.mimetype_oauth  = MIMETYPE_OAUTH 

# how to encode PPD files
#   config.mimetype_ppd  =   MIMETYPE_PPD   

# how to encode CDD files
#   config.mimetype_cdd  =   MIMETYPE_CDD   

# secs to sleep before register polling again
#   config.polling_secs  =   POLLING_SECS   

# number of characters to truncate response logs 
#   config.truncate_log  =   TRUNCATE_LOG   

# cloudprint registration main URL
#   config.followup_host =   FOLLOWUP_HOST  #

# GCP constant
#   config.followup_uri  =   FOLLOWUP_URI   #

# Google primary URI
#   config.gaia_host  =      GAIA_HOST      #

# user-based OAUTH2 access (future expansion)
#   config.login_uri  =      LOGIN_URI      #

# GCPS primary URL
#   config.gcp_url  =        GCP_URL        #

# GCPS service point
#   config.gcp_service  =    GCP_SERVICE    #

# full pathname of SSL certificates path for this machine
#   config.ssl_ca_path  =    SSL_CERT_PATH


# GCP documentation constants
#   config.authorization_scope  =        AUTHORIZATION_SCOPE         #
#   config.authorization_redirect_uri  = AUTHORIZATION_REDIRECT_URI  #

# Google OAUTH2 token handling endpint URL
#   config.oauth2_token_endpoint  =      OAUTH2_TOKEN_ENDPOINT       #


# ---------------------------------------------------------------------
#  class Jingle required
# ---------------------------------------------------------------------

# Google jingle (XMPP) server domain
#   config.xmpp_server  =     XMPP_SERVER     #  

# Jingle extension for google push stanzas
#   config.ns_google_push  =  NS_GOOGLE_PUSH  #  

# Jingle cloudprint channel domain
#   config.gcp_channel  =     GCP_CHANNEL     #  

# ---------------------------------------------------------------------
#  cups testpage file path
# ---------------------------------------------------------------------

# pathname location of a printable testfile on local machine
#   config.cups_testpage_file = CUPS_TESTPAGE_FILE

# ---------------------------------------------------------------------
#  printer device/cups related
# ---------------------------------------------------------------------

# number of seconds to wait before polling printer status
#   config.printer_poll_cycle = PRINTER_POLL_CYCLE



end  # Kinokero setup
