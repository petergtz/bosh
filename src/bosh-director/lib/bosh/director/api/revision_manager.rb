module Bosh::Director
  module Api
    class RevisionManager
      include ApiHelper

      def initialize
        @event_manager = EventManager.new(true)
      end

      def create_revision(deployment_name, manifest_content, user)
        Models::Event.create(
          timestamp:   Time.now,
          user:        user,
          action:      "create",
          object_type: "deployment_revision",
          deployment:  deployment_name,
          context: {
            manifest_text: validate_manifest_yml(manifest_content, nil)
          }
          )
      end
      
      def revisions(deployment_name)
        Models::Event.order_by(Sequel.desc(:id)).
          where(deployment: deployment_name).
          and(object_type: 'deployment_revision').all.map do |event|
            {
              id: event.id, 
              deployment_name: deployment_name,
              timestamp: event.timestamp,
              manifest_content: event.context['manifest_text'],
            }
          end
      end

      def diff(deployment, revision1, revision2)
        event1 = Models::Event.find_by_id(revision1)
        event2 = Models::Event.find_by_id(revision2)
        Manifest.load_from_hash(
          validate_manifest_yml(event1.content['manifest_text'], nil),
          event1.content['cloud_config'],
          event1.content['runtime_config'],
        ).diff(
          Manifest.load_from_hash(
            validate_manifest_yml(event2.content['manifest_text'], nil),
            event2.content['cloud_config'],
            event2.content['runtime_config'],
          ) 
        )
      end
    end
  end
end
