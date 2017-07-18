require 'spec_helper'

describe 'deploy job update', type: :integration do
  with_reset_sandbox_before_each

  it 'WAITING FOR YOUR STUFF' do
    manifest_hash = Bosh::Spec::Deployments.simple_manifest
    manifest_hash['jobs'][0]['persistent_disk_pool'] = 'disk_a'
    manifest_hash['jobs'][0]['instances'] = 1
    cloud_config = Bosh::Spec::Deployments.simple_cloud_config
    disk_pool = Bosh::Spec::Deployments.disk_pool
    cloud_config['disk_pools'] = [disk_pool]
    cloud_config['compilation']['reuse_compilation_vms'] = true
    deploy_from_scratch(manifest_hash: manifest_hash, cloud_config_hash: cloud_config, runtime_config_hash: {
        'releases' => [{'name' => 'bosh-release', 'version' => '0.1-dev'}]
    })

    sleep(3600)
    # manifest_hash = Bosh::Spec::Deployments.simple_manifest
    # manifest_hash['update']['canaries'] = 0
    # manifest_hash['update']['max_in_flight'] = 2
    # manifest_hash['properties'] = { 'test_property' => 2 }
    # deploy_from_scratch(manifest_hash: manifest_hash)

    # updating_job_events = events('last').select { |e| e['stage'] == 'Updating instance' }
    # expect(updating_job_events[0]['state']).to eq('started')
    # expect(updating_job_events[1]['state']).to eq('started')
    # expect(updating_job_events[2]['state']).to eq('finished')
  end

  # def start_and_finish_times_for_job_updates(task_id)
  #   jobs = {}
  #   events(task_id).select do |e|
  #     e['stage'] == 'Updating instance' && %w(started finished).include?(e['state'])
  #   end.each do |e|
  #     jobs[e['task']] ||= {}
  #     jobs[e['task']][e['state']] = e['time']
  #   end
  #   jobs
  # end

  # def events(task_id)
  #   result = bosh_runner.run("task #{task_id} --raw")
  #   event_list = []
  #   result.each_line do |line|
  #     begin
  #       event = Yajl::Parser.new.parse(line)
  #       event_list << event if event
  #     rescue Yajl::ParseError
  #     end
  #   end
  #   event_list
  # end
end
