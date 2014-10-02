kinokero
========

Complete Google CloudPrint Proxy client. Includes seperate classes to handle
the GCP server protocol (Cloudprint), the GCP Jingle notification protocol 
(Jingle), and a class for interacting with CUPS devices on a linux system 
(Printer). The Cloudprint class uses a faraday-based http client for 
interacting with Google CloudPrint Services. Persistence is expected to 
be handled by whatever is invoking Kinokero. Each of these major classes
can (more or less) function in a stand-alone manner for low-level 
cloudprint primitives.

# Kinokero Status

* The gem is currently pre-Alpha.
* All GCP protocol interactions are working as a GCP2.0 printer
* jingle notifications are working.
* Files can be cloudprinted remotely.
* Verbose mode has extensive logging of everything from a protocol standpoint
* I have a makeshift manual command interpreter ('console')
  which functions as a debug-level persistence calling module for overall 
  testing kinokero. Please see discussion below.
* Kinokero uses Ruby threads when polling is required.
* TBD: documentation
* TBD: unit tests

## Discussion

GCP documentation is bad at best and inaccurate and incomplete at worst.
There is nothing approaching correct and accurate protocol documentation with
complete examples. There are no state diagrams. 

The Chromium Project has a GCP proxy, but the C++ code is the worst code I have
ever seen and was almost useless as a reference. Needless to say, the code has
no documentation. From a Ruby perspective, the code is horrific and frightening.
Is Ruby the only world with packaged interfaces for doing common things like
encryption, http client, xmpp client, etc?

Libjingle was touted as necessary; but again, there is no API documentation and
numerous sources mentioned the impossibility of getting it working on a linux
system.

The GCP documents do have some Python code, but they are old and outdated and don't
match the current protocol. Lately, Google has added numerous disclaimers to the
examples (which are not complete GCP examples!) about the code being outdated
and to use it as reference only.

During development, I had to trial & error hack my way to get the protocol's working.

I used popular working Ruby gems to make this package DRY:

* faraday as the http client (and needed faraday middleware)
* xmpp4r as an excellent XMPP module (made skipping libjingle easy)
* cups as an interface to the linux CUPS system.
* beefcake as the protocol buffer handler & compiler

## Installation

Add this line to your application's Gemfile (pre-alpha versions):

```
    gem 'kinokero', :git => "git://github.com/dsaronin/kinokero.git"  
```

And then execute:

```
    $ bundle install
```

Or install it yourself as:

```
    $ gem install kinokero, :git => "git://github.com/dsaronin/kinokero.git"
```

## Console

During development, I needed a convenient setup and testing structure
to individually trigger GCP primitives and see traces of the request
and result. I'm callling that the "console" and it has no function
inherent to the gem, other than a convenient setup and testing
apparatus. Rather than having it vanish, I have made it part of the
gem superstructure and it can be run indepently, as though it were
an application, for calling and testing the gem.

It is rather crude and no further improvements will be made to it.
Nor will I be particularly receptive to issues published against
it. I will, however, potentially request its usage to isolate
situations for issues made against the core gem itself.

The console has a simple means of persistence (a seed yaml file)
for any printers which are registered. The seed yaml requires,
at the least for initial startup, a section of data for the
(required) test printer.

Some of commands have to be issued in a particular order to be
useful. This is largely related to the GCP protocol itself.

### Invocation

Before invoking, make sure you cd into the console directory
and run bundler to install all the required gems.

```
  $ cd console
  $ bundle install
```

You will need to also set up your Google developers API for
your proxy and have that information in the following 
environmental variables (I do it in .bashrc). The samples
shown below have been sterilized for security.

```
export GCP_PROXY_API_PROJECT_NBR=407407407407
export GCP_PROXY_API_CLIENT_EMAIL="407407407407@developer.gserviceaccount.com"
export GCP_PROXY_CLIENT_ID="407407407407-abcd1abcd2abcd3abcd4abcd5abcd5ef.apps.googleusercontent.com"
export GCP_PROXY_CLIENT_SECRET="someSECRETencryptedHEREo"
```

The console can be invoked in two ways: the normal way runs
the console and then simply exits to the OS when finished.
Or it can be run to exit into irb, still maintaining all
instantiated objects, similar to the Rails console. 

Currently, both of these run the console with the '-m'
switch, which means *manual* connection for each printer.
Without that switch, active printers will be automatically
connected (jingle connection) to the GCP servers.

#### normal invocation

```
  $ ./console
```

#### exit-to-irb invocation

```
  $ ./irb_console
```

### Command syntax

```
  <command> [<printer item>]
```

example: 

```
  register wild
```

will register a printer called "gcp_wild_printer" and persist the data in the "wild" item in the seed yaml file.

A single word command (listed below) is required.
An optional _item keyword_ to identify which printer. If missing,
'test' is assumed as the default printer. Most commands are 
specific to a printer.

### Console commands

#### commands which don't require a printer item

* *help* - the list of commands
* *quit* - exit the console
* *exit* - exit the console
* *save* - writes the internal seed information to the seed file
* *devices* - lists Proxy's my_devices hash for all Kinokero devices (lengthy)
* *cups* - switches to submode for querying CUPS primitives

#### commands which do require a printer item

* *list* - returns GCP response listing GCP parameters for the given printer if registered.
* *fetch* - returns GCP job fetch list for given printer
* *register* - anonymous register the given printer. if the given printer
* *ready* - queries CUPS for the printer and performs a GCP /update command for its status
* *refresh* - refreshes the OAUTH2 token for the given printer
* *delete* - deletes the given printer from GCP registered list
* *connect* - starts a persistent jingle connection for the given printer; tells GCP that printer is now 'on-line' and ready to receive print requests.
   this is only necessary if the console has been started in manual mode.
* *time* - time when OAUTH2 token expires next for given printer
* *gcp* - dump of Cloudprint gcp_control hash for given printer

### CUPS sub-mode commands

The CUPS sub-mode is for querying the local CUPS system and displaying the results.


* *help* - lists sub-mode commands
* *quit* - exit the cups sub-mode
* *exit* - exit the cups sub-mode

* *printers* - displays CUPS printers by name
* *default* - displays the CUPS default printer name
* *jobs* - displays the last CUPS printer job status structure
* *options* - displays the options (attributes) for the default printer
* *print* - prints a test page to the default printer
* *scan* - displays a polled scan of printer status while printer prints a test page

### Seed file

As a minimum, the "test" printer item must be defined. Each printer item can be
mapped to the same, or different, CUPS printers on the local system. The file is:
<i>console/config/gcp_seed.yml</i> 

Variables (you supply the correct information) are indicated enclosed in angular
brackets: <variable name>.

```
test:
  printer_id: 0
  item: test
  cups_alias: <actual CUPS printer name>
  is_active: false
  virgin_access: false
  gcp_printer_name: gcp_test_printer
  capability_ppd: /etc/cups/ppd/<actual CUPS printer name>.ppd
  capability_cdd: /etc/cups/cdd/<actual CUPS printer name>.cdd
  gcp_uuid: <printer serial number>
  gcp_manufacturer: <printer manufacturer name>
  gcp_model: <printer model name>
  gcp_setup_url: <url to a page for setting up the printer>
  gcp_support_url: <url to a page for supporting the printer>
  gcp_update_url: <url to a page for updating the printer>
  gcp_firmware: '<firmware version number>'
```

For legacy purposes, the PPD file name (complete path) is required.
From that, please use the Google CDD converter to convert the 
PPD to CDD (Cloud Device Description) format and save that on your
local system. Provide the complete path to that file. The web
tool for this is at: https://www.google.com/cloudprint/tools/cdd/cdd.html

## Gem Structure

The kinokero overall structure parallels the different levels for the
cloudprint protocol.

Proxy - is the overall, high-level appliance that satisfies the basic
functionality of a cloudprint device. This is the expected entry point
for an application which also maintains persistence of printer information.
The kinokero console (above), for example, functions as a crude
persistent application.

Cloudprint - is the primary interace for issuing commands to 
Google Cloudprint servers via HTTP POST commands. Proxy functions
use these primitives to do their work. The main data structure
used here is based off of an options hash termed
<i>gcp_control</i> (described below).

Jingle - is the interface for the gtalk jingle (XMPP) protocol
required for asynchronously receiving notification of pending
print jobs (uses a callback mechanism). Class Cloudprint 
directly accesses Jingle, so you probably won't have to be 
too concerned about it.

Printer - is the interface to the local OS CUPS system and does any
actual printing. It also does device state polling.

## Threads

The gem uses several threads to handle asynchronous polling tasks:

* polling for user interaction when registering a printer
* polling device status
* jingle connection
* jingle callback

Note: at this point I haven't seen the need for mutex semaphore control
over any of the control structures. It might be required in the future.

## Usage

Note that the primary example for setting up and using this gem is the
console code: <i>console/twiga.rb</i> and all config, setup folders.

Terms: the cloudprint proxy (or connector) orchestrates the overall GCP
interactions to do the higher level tasks such as register or remove a printer,
intercept print notifications and print jobs, etc. So the "user" of kinokero is
whoever is using the proxy to register and control local printers. It is not
the end user trying to print something on a cloud printer.

### Printer Names, ids, and aliases

This can potentially be a point of confusion to first time kinokero users, 
so please pay close attention. Kinokero has been set up so that you can map
several cloudprint (logical) devices to a single CUPS (physical) device. The
reason you might want to do this is because each logical device can be defined
with its own CDD (Cloud Device Description) parameters: such as color vs
monochrome, dual-sided vs single-sided, etc. For economic purposes, an
organization might want to limit access to the color-capabilities of a
laser printer and give out broader access to the monochrome-capability of
that same printer. With kinokero, this is theoretically possible to do.

So let's work backward through the different names and described them and
their purpose. The gcp_control hash (later section) maps these all together.

<b>item:</b> This is the hash key into the @proxy.my_devices hash of all
gcp_control hashes being managed by kinokero.

<b>gcp_cups_alias:</b> This is the printer name as recognized by cups when used
to issue a print command.
```
  lp -d <gcp_cups_alias>
```

<b>gcp_printer_name:</b> This is the name by which a cloudprint user sees the
printer when it shows up in their cloudprint managed printers list. For example:
"Brother MFC-9340CDW".

<b>gcp_printerid:</b> This is a string issued by GCPS for use in GCPS calls.
For example: "d0510370-f36b-356f-1a82-f93c0756a5d9". This also appears in the
"advanced details" section of DETAILS for a cloudprint printer in the Manage
Printers dashboard.

<b>printer_id:</b> This is some type of unique id (string or integer) which
the user's program (the one which invokes kinokero) uses to access a persistence
record for the given logical printer. It could, for example, be a database
record number for the given persistence.

#### Examples

  item: color
  gcp_cups_alias: laserjet_1020w
  gcp_printer_name: color laser printer
  gcp_printerid: d0510370-f36b-356f-1a82-f93c0756a5d9
  printer_id:  509

  item: b&w
  gcp_cups_alias: laserjet_1020w
  gcp_printer_name: monochrome laser printer
  gcp_printerid: cda248c1-e1f5-8066-1e10-3efe078cface
  printer_id:  510

  item: test
  gcp_cups_alias: lp_null
  gcp_printer_name: null_printer
  gcp_printerid: 8231517c-716d-4b0a-f721-83fdbe52a05d
  printer_id:  508

In these examples we see three logical cloudprint printers
defined. The first two map into the same physical CUPS device.
The last one maps into a CUPS device, but has actually been
defined to be file:///dev/null and so no physical device exists.





### setting up and initializing the gem

This section will describe the basic first steps of prepping a call to each of the
major classes of the kinokero gem: Proxy, Printer, and Cloudprint. Proxy.new is the
highest level and in turn invokes Printer.new and Cloudprint.new. So if you're 
choosing to work at the Proxy level (recommended!), you won't need to worry
about the other two.

For references, see the sections below dealing with the primary gcp_control hash,
kinokero global parameters, pre-defined gem constants,
and template file for Rails config/initializers usage.

#### Class Proxy initialization
```ruby

  # build a hash of options for all active & inactive printers
  # from the persistence memory (in this case a YAML file)
  # for details on the gcp_control hash, see later sections in this README
  #
  def build_device_list()

    load_gcp_seed()    # load the YAML seed data

      # prep to build up a hash of gcp_control hashes
    gcp_control_hash = {}

    @seed_data.each_key do |item|
      gcp_control_hash[ item ] = @seed_data[ item ].symbolize_keys  # strip item into hash with keys
    end   # convert each seed to a device object

    return gcp_control_hash
    
  end   # convert each seed to a device object

  gem_options = {
        # true if automatically jingle connect active printers from list
      auto_connect:  true,  
        # true if instance-level verbose log trace of all GCPS and jingle requests
      verbose:       true, 
        # true if truncate long responses
      log_truncate:  true, 
        # true if log trace all responses from GCPS
      log_response:  true 
  }

  @proxy = Kinokero::Proxy.new( build_device_list(), gem_options )
```

#### Class Proxy automatice running

Proxy is the higher level way to do all cloudprint control. If your gem_options
have auto_connect set to true, then everything else is automatic for all
currently registered printers. As job print notifications are received, the
files will be downloaded, printed, deleted, and the job status updated to DONE.

#### Class Proxy register or remove cloudprint printers
```ruby
  new_request = {
      item:  'name for this item',
      printer_id:   0,  # will be cue to create new record
      gcp_printer_name: "gcp_#{item}_printer",
      capability_ppd: 'pathname for the PPD file',  # legacy GCP 1.0
      capability_cdd: 'pathname for the CDD file',  # required GCP 2.0
      cups_alias: 'cups printer name',
      gcp_uuid:        string, # see gcp_control hash below 
      gcp_manufacturer:string, # see gcp_control hash below 
      gcp_model:       string, # see gcp_control hash below 
      gcp_setup_url:   string, # see gcp_control hash below 
      gcp_support_url: string, # see gcp_control hash below 
      gcp_update_url:  string, # see gcp_control hash below 
      gcp_firmware:    string, # see gcp_control hash below 
  }

  response = @proxy.do_register( new_request ) do |gcp_control|

      # item_persistence is user-defined means to persist the
      # GCPS-issued information for a printer
      # which must be supplied again to the proxy whenever
      # rebooting
      # remember to set up a gcp_control[:printer_id] as the
      # database record number for this new item for any
      # future need to update persistence (such as on 
      # refresh token
    item_persistence( gcp_control )

  end   # do persist new printer information

  unless response[:success]
    puts "printer registration failed: #{response[:message]}"
  end
```


### gcp_control hash

This is used throughout the gem, so each attribute will be explained here. Most
attributes require persistence, meaning that they have to be supplied to the proxy
at initialization for any active printers (this occur at a restart/reboot state).

None of the GCPS-issued items are required when first registering a printer; only
the "Items supplied by the proxy user."

The console uses a yml file (in lieu of any other type of persistence mechanism)
for storing and retrieving these values between sessions. The file is at: 
<i>console/config/gcp_seed.yml</i>.

GCPS-issued items which need persistence
* *gcp_xmpp_jid:* GCPS-issued id for accessing jingle servers
* *gcp_confirmation_url:* GCPS-issued url for confirming the printer registration
* *gcp_owner_email:* GCPS-issued owner's email

* *gcp_printerid:* GCPS-issued printer id

* *gcp_refresh_token:* GCPS-issued used to refresh the OAUTH2 token
* *gcp_access_token:*  GCPS-issued OAUTH2 token
* *gcp_token_expiry_time:* UTC datetime for when the OAUTH2 token expires (thus needing to be refreshed)
* *gcp_token_type:* GCPS-issued, used to form the OAUTH2 token

Items supplied by proxy user
* *item:* identifier for this printer item, such as: 'test'
* *printer_id:* local persistence id (such as for a database record)
* *cups_alias:* printer name from the OS' standpoint (such as registered with CUPS)
* *gcp_printer_name:* user-determined name which shows up in cloudprint user's managed printer list

* *capability_ppd:* complete file pathname for the PPD printer description file (legacy)
* *capability_cdd:* complete file pathname for the CCD cloud device description file (gcp v2.0)

* *gcp_uuid:* printer serial number, such as: 'VND3R11877'
* *gcp_manufacturer:* printer manufacturer, such as: 'Hewlett-Packard'
* *gcp_model:* printer model, such as: 'LaserJet P1102w'
* *gcp_setup_url:* a url for how-to set up the printer
* *gcp_support_url:* a url for getting support
* *gcp_update_url:* a url for getting updates
* *gcp_firmware:* printer firmware version number, such as: '20130703'

Kinokero-internal usage (persistence required)
* *is_active:* set to true after successful registration; false if no longer in use
* *virgin_access:* true for initial oauth2 token for a freshly registered printer; false after first refresh

Future API usage
* *message:* last error message saved


### gem configuration

There are several global parameters which can be set at gem configuration.
Default values are provided for each parameter. These are expained below.
Many parameters, however, are fixed by Google Cloud Printer documentation demands
and should not be changed.


#### configuration in Rails application

When using kinokero
in a Rails application, use the template
<i>console/config/kinokero_initializer_template.rb</i>, which
shows how to access and change any of these parameters during
your rails project initialization.
Copy it into your Rails <i>project-name/config/initializers</i>
directory, and rename it to: _kinokero.rb_ .

The template file also contains comments describing each parameter.

#### configuration in non-Rails application

You can change these parameters similar to the example below for 
changing the verbose setting.
```ruby
  Kinokero.verbose = true
```

#### listing of all configuration parameters and defaults

class Proxy required
* *my_proxy_id:*         =  MY_PROXY_ID    # unique name for this running of the GCP connector client
* *proxy_client_id:*     =  ENV["GCP_PROXY_CLIENT_ID"] || 'missing'
* *proxy_client_secret:* =  ENV["GCP_PROXY_CLIENT_SECRET"] || 'missing'
* *proxy_serial_nbr:*    =  ENV["GCP_PROXY_SERIAL_NBR"] || 'missing'
* *verbose:*             =  false  # for any class-level decisions

class Cloudprint required
* *mimetype_oauth:*  = MIMETYPE_OAUTH # how to encoade oauth files
* *mimetype_ppd:*  =   MIMETYPE_PPD   # how to encode PPD files
* *mimetype_cdd:*  =   MIMETYPE_CDD   # how to encode CDD files
* *polling_secs:*  =   POLLING_SECS   # secs to sleep before register polling again
* *truncate_log:*  =   TRUNCATE_LOG   # number of characters to truncate response logs 
* *followup_host:*  =  FOLLOWUP_HOST  #
* *followup_uri:*  =   FOLLOWUP_URI   #
* *gaia_host:*  =      GAIA_HOST      #
* *login_uri:*  =      LOGIN_URI      #
* *login_url:*  =      LOGIN_URL      #
* *gcp_url:*  =        GCP_URL        #
* *gcp_service:*  =    GCP_SERVICE    #
* *ssl_ca_path:*  =    SSL_CERT_PATH  # SSL certificates path for this machine

* *authorization_scope:*  =        AUTHORIZATION_SCOPE         #
* *authorization_redirect_uri:*  = AUTHORIZATION_REDIRECT_URI  #
* *oauth2_token_endpoint:*  =      OAUTH2_TOKEN_ENDPOINT       #

class Jingle required
* *xmpp_server:*  =     XMPP_SERVER     #  
* *ns_google_push:*  =  NS_GOOGLE_PUSH  #  
* *gcp_channel:*  =     GCP_CHANNEL     #  

cups testpage file path
* *cups_testpage_file:* = CUPS_TESTPAGE_FILE

printer device/cups related
* *printer_poll_cycle:* = PRINTER_POLL_CYCLE

#### kinokero global constants used for defaults

Current constant defaults are defined as follows, with the
actual definitions in _lib/kinokero.rb_ . 

```ruby
# mimetype for how to encode CDD files
MIMETYPE_JSON      = 'application/json'
MIMETYPE_PROTOBUF  = 'application/protobuf'
MIMETYPE_GENERAL   = 'application/octet-stream'
MIMETYPE_CDD       =  MIMETYPE_GENERAL

# mimetype for how to encode PPD files
MIMETYPE_PPD     = 'application/vnd.cups.ppd'

# number of secs to sleep before polling again
POLLING_SECS = 30     

# number of characters before truncate response logs
TRUNCATE_LOG = 1000    

# authentication function constants
FOLLOWUP_HOST = 'www.google.com/cloudprint'
FOLLOWUP_URI = 'select%2Fgaiaauth'
GAIA_HOST = 'www.google.com'
LOGIN_URI = '/accounts/ServiceLoginAuth'
LOGIN_URL = 'https://www.google.com/accounts/ClientLogin'

# GCP documentation constants
AUTHORIZATION_SCOPE = "https://www.googleapis.com/auth/cloudprint"
CLIENT_REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob"
AUTHORIZATION_REDIRECT_URI = 'oob'
OAUTH2_TOKEN_ENDPOINT = "https://accounts.google.com/o/oauth2/token"
MIMETYPE_OAUTH =  "application/x-pkcs12"

# The GCP URL path is composed of URL + SERVICE + ACTION
# below three are used when testing locally
#   GCP_URL = 'http://0.0.0.0:3000'
#   GCP_SERVICE = '/'
#   GCP_REGISTER = ''
GCP_URL = 'https://www.google.com/'
GCP_SERVICE = 'cloudprint'

# jingle constants required

XMPP_SERVER     = "talk.google.com" 
NS_GOOGLE_PUSH  = "google:push"
GCP_CHANNEL     = "cloudprint.google.com"

# MY_PROXY_ID is a unique name for this running of the GCP connector client
# formed with gem name + machine-node name (expected to be  unique)
# TODO: make sure machine nodename is unique
MY_PROXY_ID = "kinokero::"+`uname -n`.chop

# SSL certificates path for this machine
SSL_CERT_PATH = "/usr/lib/ssl/certs"

# CUPS system default testpage file
CUPS_TESTPAGE_FILE = "/usr/share/cups/data/default-testpage.pdf"

# printer device status polling cycle (float secs to sleep)
PRINTER_POLL_CYCLE = 15    # wait fifteen seconds before recheck status
```


## Testing

Unit Testing is somewhat problematic because the kinokero gem is also a 
wrapper for interactions with the Google Cloud Print Server (GCPS).
GCPS, unfortunately, are not really set up to handle unit testing. There is
no sandbox; everything is _live._

There are several issues associated with this. 

To use unit testing, you'll 
need to register yourself into the Google API and obtains client id and secret.
You'll then have to set these up in your local environment variables.
The unit testing for Cloudprint will verify whether these exist or not and
fail the unit tests at the outset if not.

```
export GCP_PROXY_CLIENT_ID="407123456789-321ngkabcdefghijklmnooppqrstuvwx.apps.googleusercontent.com"
export GCP_PROXY_CLIENT_SECRET="iAMsecretiAMsecretiAMsec"
```

Next, you'll have to create and register a test printer and claim it
at some Google account. You can use the console to do that. Then copy
and paste the gcp_seed.yml information into the test item area of 
test/test/fixtures/gcp_seed.yml.

The next problem is the manually-intensive nature of registering a
printer. This isn't conducive to automated tests, so the actual
registration of a printer is not currently in the cloudprint_test.rb.

And finally, a number of GCPS commands require an active on-line
printer to fully test. But it is possible to test the _failure_ of
various GCPS commands by issueing them against non-existent
print jobs and files. At the very least, we can test the command 
set up, invocation against GCPS, and an unsuccessful GCPS response. This 
has been done for many of the GCPS actions. These tests are seperated
in the test file and a comment marks the start of the section for 
those tests. That does mean that there will be an OAUTH2 token fetch
fail message printed to the log (below) when running the test. This
is good and should cause no alarm, since it means the code is working
correctly!

```
E, [2014-09-20T12:29:37.479671 #10941] ERROR -- oauth2 token fetch fail: **********************************
```

If you do encounter errors or failures when running the cloudprint tests,
you may want to turn on logging by switching the verbose setting. You can
change this in the <i>test/test/test_kinokero.rb</i> test helper, line 206:
set it to true for a verbose logging; otherwise false for brevity. When 
logging is verbose (enabled) then ALL requests AND responses to/from
GCPS are logged, as well as all Jingle interactions.

```ruby
      full_verbose = false    # ok to change this setting
```

### Available & planned unit tests

The list below has the status of all kinokero unit tests.
All these unit tests are completed and working.

* Cloudprint - <i>test/models/cloudprint_test.rb</i>
  this tests the primary GCPS wrapped interface for all GCPS actions.
* Jingle - <i>test/models/jingle_test.rb</i>
* Printer - <i>test/models/printer_test.rb</i>
* Proxy - <i>test/models/proxy_test.rb</i>

### Running a unit test

There is a mini Rails application for the testing environment.
From the kinokero gem directory:

```
  $cd test   # gets you to the mini Rails app
  $ruby -I test test/models/cloudprint_test.rb
```

or substitute different unit test filenames for <i>cloudprint_test.rb</i>

## references

These references are for Google Cloudprint documentation.
* Google cloudprint overall site: http://www.google.com/cloudprint/learn/
* Google cloudprint developers documentation: https://developers.google.com/cloud-print/docs/overview
* Cloud Device Description protocol: https://developers.google.com/cloud-print/docs/cdd
* Web tool to automatically convert PPD (or XPS) files in CDD format
  (required because kinokero supports Cloudprint 2.0): https://www.google.com/cloudprint/tools/cdd/cdd.html
* Google Protobuf language: https://developers.google.com/protocol-buffers/docs/overview


## future stuff

* use a robot account; A gcp developer claims:
  As long as the same robot account is used for all printers handled by the proxy, you can use just one XMPP connection for notifications for all of the printers. This is mentioned briefly in the documentation at https://developers.google.com/cloud-print/docs/devguide#connectorregistration - just use the robot account from the first registered printer as the 'owner' for all subsequent registrations. In this special case, we make the user who created that robot account the owner of the new printer as well, and use the same robot account credentials for it. This will also resolve the /list issue you mentioned, as calling /list authenticated with the robot account will allow you to see all of the associated printers.
* autotest register printer; same developer claims, but I couldn't figure it out:
  We don't have a special server to test registration against, but you can automate the claim flow for unit tests. It isn't documented externally, but if you use your browser's devtools to look at the requests we make on the claim page, you can see the flow your tests would need to follow to automatically 'claim' a test printer (you can do this with a test Gmail account you register, or with a user's credentials - same for generating the XMPP JID).

## Contributing

GCP interaction is, shall we say, delicate. Any changes to Cloudprint or Jingle
need to be carefully considered and tested under various conditions.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Run the unit tests and make sure nothing is broken. Supply
   new unit tests for any added features.
6. Create new Pull Request
