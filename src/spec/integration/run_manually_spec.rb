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

    cloud_config['compilation']['reuse_compilation_vms'] = false
    upload_cloud_config(cloud_config_hash: cloud_config)

    manifest_hash['jobs'][0]['instances'] = 2
    deploy_simple_manifest(manifest_hash: manifest_hash)

    manifest_hash['jobs'][0]['instances'] = 3
    deploy_simple_manifest(manifest_hash: manifest_hash)

    sleep(3600)
  end
end
