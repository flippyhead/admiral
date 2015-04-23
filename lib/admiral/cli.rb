require 'thor'

module Admiral
  class Cli < Thor

    include Admiral::Tasks::CloudFormation
    # include Admiral::Tasks::OpsWorks
    # include Admiral::Tasks::Deploy::Base
    # include Admiral::Tasks::Deploy::Meteor

  end
end