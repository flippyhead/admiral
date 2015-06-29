# Admiral

Admiral is a command line utility for managing AWS CloudFormation and OpsWorks stacks, and for deploying applications to EC2 instances. Admiral is modular in design -- you include just the modules you need, dependencies are automatically resolved.

Developed in Seattle at [Fetching](http://fetching.io).

## Getting Started

Please see the [step by step setup guide](http://ptb.io/2015/06/22/easy-server-management-for-aws-and-meteor/) to get started.

## Installation

Currently there are four Admiral modules. Simply install what you need to get started.

* [admiral](https://github.com/flippyhead/admiral): the core command line utility and binary.
* [admiral-cloudformation](https://github.com/flippyhead/admiral-cloudformation): tasks for managing AWS CloudFormation templates by environment.
* [admiral-opsworks](https://github.com/flippyhead/admiral-opsworks): tasks for managing AWS OpsWorks stacks and instances.
* [admiral-meteor](https://github.com/flippyhead/admiral-meteor) : tasks for building and deploying Meteor applications.

Please visit the above repositories for details on each module.

## Usage

Install one of the above modules then from your command line:

    $ admiral help

To see a list of available module subcommands and options.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

This project was heavily inspired by [this blog post](http://www.thoughtworks.com/mingle/news/scaling/2015/01/06/How-Mingle-Built-ElasticSearch-Cluster.html) -- thanks ThoughtWorks!