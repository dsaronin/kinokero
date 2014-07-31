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
    $ bundle
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
use these primitives to do their work.

Jingle - is the interface for the gtalk jingle (XMPP) protocol
required for asynchronously receiving notification of pending
print jobs (uses a callback mechanism).

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

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
