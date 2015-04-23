require 'thor'
require 'json'
require_relative 'util'

module Admiral
  class Cli < Thor
    include Util

    desc "provision ENVIRONMENT", "Provisions ENVIRONMENT"

    option :template, desc: 'A CloudFormation template', default: "CloudFormation.template"
    option :params, desc: 'Parameter definitions for CloudFormation template.'
    option :update_instances, desc: 'Replace and update existing instances', type: :boolean, default: 'false'

    attr_accessor :environment

    def provision(env)
      self.environment = env
      template = File.read options[:template]
      params = JSON.parse File.read(options[:params] || "#{environment}.json")
      cf_stack = cfm.stacks[stack_name]

      if cf_stack.exists?
        begin
          puts "Updating CloudFormation stack #{stack_name}"
          cf_stack.update(:template => template, :parameters => params)
        rescue => e
          raise unless e.message =~ /No updates are to be performed/
          puts "Your CloudFormation stack is already up to date"
        end
      else
        puts "Creating CloudFormation stack #{stack_name}"
        cf_stack = cfm.stacks.create(stack_name, template, :parameters => params)
      end

      wait_for_cf_stack_op_to_finish(cf_stack)

      if options[:update_instances]
        stack_id = cf_query_output(cf_stack, "StackId")
        layer_id = cf_query_output(cf_stack, "LayerId")

        update_instances(stack_id, layer_id, instance_count)
      end
    end

    desc "destroy ENVIRONMENT", "Destroys ENVIRONMENT"
    def destroy(env)
      self.environment = env
      cf_stack = cfm.stacks[stack_name]

      if cf_stack.exists?
        puts "Deleting stack #{stack_name}"
        cf_stack.delete
        wait_for_cf_stack_op_to_finish(cf_stack)
      else
        puts "Environment #{environment} does not exist"
      end
    end

    desc "build", "Build the Meteor app specifically for opsworks"
    def build
      puts "Creating new build"

      Dir.mktmpdir do |tmpdir|
        build_dir = "#{tmpdir}/fetching-build"

        git = Git.clone('/Users/peter/Development/fetching-app', "#{tmpdir}/fetching-checkout")
        branch = git.branches[:master]
        raise "Branch doesn't exist" unless branch
        branch.checkout
        git.chdir do
          `meteor build #{build_dir} --directory --architecture=os.linux.x86_64`
        end

        `cp -a ./deploy #{build_dir}/bundle`
        `mv #{build_dir}/bundle/main.js #{build_dir}/bundle/server.js`
        `tar -C #{build_dir}/bundle/ -zcvf ./fetching.tar.gz .`
      end
    end

    desc "release", "Release the Meteor app"
    def release
      build()

      puts "Pushing build to S3"
      s3 = AWS::S3.new
      build = s3.buckets['fetching-builds'].objects['fetching-app.tar.gz']
      build.write(:file => './fetching.tar.gz')
    end

    desc "deploy", "Deploy the Meteor app"
    def deploy
      release()

      puts "Deploying to opsworks"
      cfm = AWS::CloudFormation.new

      cf_stack = cfm.stacks[stack_name]
      stack_id = cf_query_output(cf_stack, "StackId")
      app_id = '0e997f1e-3c90-4c3c-8176-fd587e0be45a'

      opsworks.create_deployment(
        stack_id: stack_id,
        app_id: app_id,
        command: {
          name: "deploy",
        }
      )
    end

    private

    def stack_name
      "#{@environment}-#{name}"
    end

    def name
      ENV["NAME"] || "test"
    end

  end
end