module Bosh::Director
  module Api
    class RevisionManager
      include ApiHelper

      def initialize
        @event_manager = EventManager.new(true)
      end

      def create_revision(deployment_name, user, started_at, manifest_content, cloud_config_id, runtime_config_ids, error = nil)
        revision_number = Models::Event.where(object_type: 'deployment_revision', deployment: deployment_name).select(:object_name).map{|event| event.object_name.to_i}.sort.last.to_i+1
        Models::Event.create(
          timestamp:   Time.now,
          user:        user,
          action:      "create",
          object_type: "deployment_revision",
          object_name: revision_number.to_s,
          deployment:  deployment_name,
          context: {
            manifest_text: manifest_content,
            started_at: started_at,
            cloud_config_id: cloud_config_id,
            runtime_config_ids: runtime_config_ids,
          },
          error: error,
          )
      end
      
      def revisions(deployment_name)
        Models::Event.order_by(Sequel.desc(:id)).
          where(deployment: deployment_name).
          and(object_type: 'deployment_revision').all.map do |event|
            {
              deployment_name: deployment_name,
              revision_number: event.object_name.to_i, 
              user: event.user,
              started_at: event.context['started_at'],
              completed_at: event.timestamp,
              manifest_content: event.context['manifest_text'],
              error: event.error,
            }
          end
      end

      def diff(deployment, revision1, revision2, should_redact)
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
