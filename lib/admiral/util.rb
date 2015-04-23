require 'aws-sdk-v1'
require 'tmpdir'
require 'git'

module Admiral
  module Util

    SUCCESS_STATS = [:create_complete, :update_complete, :update_rollback_complete]
    FAILED_STATS = [:create_failed, :update_failed, :rollback_complete]
    DEFAULT_RECIPES = [].join(",")

    def opsworks
      @opsworks ||= AWS::OpsWorks::Client.new({:region => ENV['AWS_REGION']})
    end

    def cfm
      @cfm ||= AWS::CloudFormation.new
    end

    def wait_for_cf_stack_op_to_finish(stack)
      stats = stack.status.downcase.to_sym
      puts "[Stack: #{stack.name}]: current status: #{stats}"

      while !SUCCESS_STATS.include?(stats)
        sleep 15
        stats = stack.status.downcase.to_sym
        raise "Resource stack update failed!" if FAILED_STATS.include?(stats)
        puts "[Stack: #{stack.name}]: current status: #{stats}"
      end
    end

    def cf_query_output(stack, key)
      output = stack.outputs.find { |o| o.key == key }
      output && output.value
    end

    def instance_online?(instance_id)
      response = opsworks.describe_instances(:instance_ids => [instance_id])
      response[:instances].first[:status] == "online"
    end

    def instance_status(instance_id)
      begin
        response = opsworks.describe_instances(:instance_ids => [instance_id])
      rescue AWS::OpsWorks::Errors::ResourceNotFoundException
        return "nonexistent"
      end
      response[:instances].first[:status].tap do |status|
        raise "Instance #{instance_id} has a failed status #{status}" if status =~ /fail|error/i
      end
    end

    def wait_for_instance(instance_id, status)
      while (ins_status = instance_status(instance_id)) != status
        puts "[Instance #{instance_id}] waiting for instance to become #{status}. Current status: #{ins_status}"
        sleep 10
      end
    end

    def all_availability_zones
      ec2 = AWS::EC2.new
      ec2.availability_zones.map(&:name)
    end

    def get_all_instances(layer_id)
      response = opsworks.describe_instances({:layer_id => layer_id})
      response[:instances]
    end

    def attach_ebs_volumes(instance_id, volume_ids)
      volume_ids.each do |volume_id|
        puts "Attaching EBS volume #{volume_id} to instance #{instance_id}"
        opsworks.assign_volume({:volume_id => volume_id, :instance_id => instance_id})
      end
    end

    def detach_ebs_volumes(instance_id)
      response = opsworks.describe_volumes(:instance_id => instance_id)
      volume_ids = response[:volumes].map { |v| v[:volume_id] }
      volume_ids.each do |volume_id|
        puts "Detaching EBS volume #{volume_id} from instance #{instance_id}"
        opsworks.unassign_volume(:volume_id => volume_id)
      end

      volume_ids
    end

    def create_instance(stack_id, layer_id, az)
      opsworks.create_instance({:stack_id => stack_id,
                                :layer_ids => [layer_id],
                                :instance_type => ENV['INSTANCE_TYPE'] || 't2.small',
                                :install_updates_on_boot => !ENV['SKIP_INSTANCE_PACKAGE_UPDATES'],
                                :availability_zone => az})
    end

    def update_instances(stack_id, layer_id, count)
      azs = all_availability_zones
      existing_instances = get_all_instances(layer_id)
      count_to_create = count - existing_instances.size
      new_instances = (1..count_to_create).map do |i|
        instance = create_instance(stack_id, layer_id, azs[(existing_instances.size + i) % azs.size])
        puts "Created instance, id: #{instance[:instance_id]}, starting the instance now."
        opsworks.start_instance(:instance_id => instance[:instance_id])
        instance
      end

      new_instances.each do |instance|
        wait_for_instance(instance[:instance_id], "online")
      end

      puts "Replacing existing instances.." if existing_instances.size > 0

      existing_instances.each do |instance|
        puts "Stopping instance #{instance[:hostname]}, id: #{instance[:instance_id]}"
        opsworks.stop_instance({:instance_id => instance[:instance_id]})
        wait_for_instance(instance[:instance_id], "stopped")
        ebs_volume_ids = detach_ebs_volumes(instance[:instance_id])

        puts "Creating replacement instance"
        replacement = create_instance(stack_id, layer_id, instance[:availability_zone])
        attach_ebs_volumes(replacement[:instance_id], ebs_volume_ids)

        puts "Starting new instance, id: #{replacement[:instance_id]}"
        opsworks.start_instance(:instance_id => replacement[:instance_id])
        wait_for_instance(replacement[:instance_id], "online")

        puts "Deleting old instance #{instance[:hostname]}, #{instance[:instance_id]}"
        opsworks.delete_instance(:instance_id => instance[:instance_id])
      end
    end

    def get_required(name)
      ENV[name] || raise("You must provide the environment variable #{name}")
    end

    def add_param_if_set(params, param_name, env_var)
      if ENV[env_var]
        "Setting CloudFormation param #{param_name.inspect} => #{ENV[env_var].inspect}"
        params.merge!(param_name => ENV[env_var])
      end
    end

  end
end