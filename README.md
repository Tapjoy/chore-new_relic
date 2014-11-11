# Chore::NewRelic

NewRelic integration for [Chore](https://github.com/Tapjoy/chore).

## Installation

Add this line to your application's Gemfile:

    gem 'chore-new_relic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chore-new_relic

## Usage

Configure NewRelic [according to their documentation](https://github.com/newrelic/rpm).

If you're using Rails, you're done! If not, there's one additional step.

Add the following require statements to your application (order is important due to the way NewRelic handles plugin registration).

    require 'chore/new_relic'
    require 'newrelic_rpm'

The plugin uses your application's NewRelic configuration, and will begin sending custom events for your Chore jobs. You should begin seeing data show up under "Non-Web Transactions" once this is setup.
