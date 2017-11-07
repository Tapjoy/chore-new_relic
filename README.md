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

Note that using [Chore](https://github.com/Tapjoy/chore)'s `ForkedWorkerStrategy` is incompatible with the vanilla version of [rpm](https://github.com/newrelic/rpm). There are issues with how the child processes report data back up to their parents and this can sometimes cause the child workers to die.

Here's Tapjoy's fork of the `rpm` that fixes the issues but is currently unmaintained (since Tapjoy no longer uses the forked worker strategy) - https://github.com/Tapjoy/rpm. The relevant PRs commits are in https://github.com/Tapjoy/rpm/pull/3 & https://github.com/Tapjoy/rpm/pull/7.