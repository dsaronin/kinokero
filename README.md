kinokero
========

Complete Google CloudPrint Proxy client. Includes Classes which handle
the GCP server protocol (Cloudprint), the GCP Jingle notification protocol 
(Jingle), and a class for interacting with CUPS devices on a linux system 
(Printer). The Cloudprint class uses a faraday-based http client for 
interacting with Google CloudPrint Services. Persistence is expected to 
be handled by whatever is invoking Kinokero.

# Kinokero Status

* The gem is currently pre-Alpha.
* All GCP protocol interactions are working
  - note I am upgrading /register to meet GCP2.0 spec
  - I have left GCP1.0 spec /register intact
* jingle notifications are working.
* Files can be cloudprinted remotely.
* I'm currently working on improving the CUPS programmatic interface & status reporting.
* Verbose mode has extensive logging of everything from a protocol standpoint
* I have a makeshift manual command interpreter which functions as a debug-level
  persistence calling module for testing kinokero. I will be folding it into the
  gem to have a common reference point for testing and duplicating errors.
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

## Installation

Add this line to your application's Gemfile:

    gem 'kinokero'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kinokero

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
