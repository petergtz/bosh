module Bosh::Director
  module Api
    class RevisionManager
      include ApiHelper

      def initialize
        @event_manager = EventManager.new(true)
      end

      def create_revision(deployment_name:, user:, task:, started_at:, manifest_text:, cloud_config_id:, runtime_config_ids:, releases:, stemcells:, error: nil)
        Models::Event.create(
          timestamp:   Time.now,
          user:        user,
          task:        task,
          action:      "create",
          object_type: "deployment_revision",
          object_name: (last_revision_number(deployment_name)+1).to_s,
          deployment:  deployment_name,
          context: {
            manifest_text: manifest_text,
            started_at: started_at,
            cloud_config_id: cloud_config_id,
            runtime_config_ids: runtime_config_ids,
            releases: releases,
            stemcells: stemcells,
          },
          error: error,
          )
      end

      def last_revision_number(deployment_name)
        Models::Event.where(object_type: 'deployment_revision', deployment: deployment_name).select(:object_name).map{|event| event.object_name.to_i}.sort.last.to_i
      end
      
      
      def revisions(deployment_name, include_manifest: false, include_cloud_config: false, include_runtime_configs: false)
        Models::Event.order_by(Sequel.desc(:id)).
          where(deployment: deployment_name).
          and(object_type: 'deployment_revision').all.map do |event|
            {
              deployment_name: deployment_name,
              revision_number: event.object_name.to_i, 
              user: event.user,
              task: event.task,
              started_at: event.context['started_at'],
              completed_at: event.timestamp,
              error: event.error,
            }.tap{ |result| 
              result[:manifest_text] = event.context['manifest_text'] if include_manifest
            }
          end
      end

      def revision(deployment_name, revision_number)
        event = Models::Event.find(object_name: revision_number)
        cloud_config = Bosh::Director::Models::CloudConfig.find(id: event.context['cloud_config_id'])
        runtime_configs = Bosh::Director::Models::RuntimeConfig.find_by_ids(event.context['runtime_config_ids'])
        {
          deployment_name: deployment_name,
          revision_number: event.object_name.to_i, 
          user: event.user,
          task: event.task,
          started_at: event.context['started_at'],
          completed_at: event.timestamp,
          error: event.error,
          manifest_text: event.context['manifest_text'],
          releases: event.context['releases'],
          stemcells: event.context['stemcells'],
          runtime_configs: runtime_configs.map{ |runtime_config| runtime_config.raw_manifest },
        }.tap{ |result| 
          result[:cloud_config] = cloud_config.interpolated_manifest(deployment_name) if cloud_config
        }
      end

      def diff(deployment, revision1, revision2, should_redact: true)
        event1 = Models::Event.find(object_name: revision1)
        event2 = Models::Event.find(object_name: revision2)

        Manifest.load_from_hash(
          validate_manifest_yml(event1.context['manifest_text'], nil),
          Bosh::Director::Models::CloudConfig.find(id: event1.context['cloud_config_id']),
          Bosh::Director::Models::RuntimeConfig.find_by_ids(event1.context['runtime_config_ids']),
          {resolve_interpolation: false}
        ).diff(
          Manifest.load_from_hash(
            validate_manifest_yml(event2.context['manifest_text'], nil),
            Bosh::Director::Models::CloudConfig.find(id: event2.context['cloud_config_id']),
            Bosh::Director::Models::RuntimeConfig.find_by_ids(event2.context['runtime_config_ids']),
            {resolve_interpolation: false}
          ),
          should_redact
        ).map { |l| [l.to_s, l.status] }
      end
    end
  end
end
