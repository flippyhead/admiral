module Admiral
  module Base
    def self.extended(thor)
      thor.class_eval do

        class_option :environment,
          desc: 'The environment (e.g. staging or production). Can also be specified with ADMIRAL_ENV.',
          default: ENV['ADMIRAL_ENV'] || 'production',
          aliases: '--env'

      end
    end
  end
end