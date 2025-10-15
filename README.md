# EmailSignatureParser

A Ruby gem for parsing email signatures. The gem tries to find the signature based on the name, if available, or email address and try to extract as much information as it can from the 

## Prerequisites

This library uses [ruby_postal](https://github.com/openvenues/ruby_postal), which uses [libpostal](https://github.com/openvenues/libpostal). You need to install the libpostal C library. Make sure you have the following prerequisites

**On Ubuntu/Debian**

```bash
sudo apt-get install curl autoconf automake libtool pkg-config
```

**On CentOS/RHEL**

```bash
sudo yum install curl autoconf automake libtool pkgconfig
```

**On Mac OSX**

```bash
brew install curl autoconf automake libtool pkg-config
```

**Installing libpostal**

```bash
git clone https://github.com/openvenues/libpostal
cd libpostal
./bootstrap.sh
./configure --datadir=[...some dir with a few GB of space...]
make
sudo make install

# On Linux it's probably a good idea to run
sudo ldconfig
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'email_signature_parser'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install email_signature_parser
```

## Usage

To extract information from an email signature, you can extract in from an eml file, from the plain text of an email, or pass it the 

```ruby
require 'email_signature_parser'

result = EmailSignatureParser.from_file('/path/to/email.eml')
result = EmailSignatureParser.from_html('John Doe <jdoe@email.com>', email_body_html)
result = EmailSignatureParser.from_text('John Doe <jdoe@email.com>', email_text)
```

It will return a hash with whatever could be extracted from the signature

```json
{
  "name": "John Doe",
  "email_address": "jdoe@testcompany.com",
  "address": "Alhambra Circle Street, 125, Coral Gables, FL, 33134 USA",
  "phones": [
    {
      "type": "Mobile",
      "phone_number": "+1 5056223073",
      "country": "US/CA"
    },
  ],
  "links": {
    "social_media": {
      "linkedin": "https://www.linkedin.com/company/testcompany/"
    },
    "other": [
    ]
  },
  "job_title": {
    "title": "",
    "acronym": "CEO"
  },
  "text": "Text of the signature",
  "company_name": "TestCompany Ltd"
}
```

## Enron Data

Ive tested this library, among other things using the enron data. You can get the data [data](https://www.cs.cmu.edu/~enron/). Running `rake process_enron_data[input_path,output_path]` will process all emails and generate json files (with a copy of the original email) for all signatures found.
