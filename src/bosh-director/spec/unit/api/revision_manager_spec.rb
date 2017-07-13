require 'spec_helper'

module Bosh::Director
  describe Api::RevisionManager do
    let(:task) { '1' }
    let(:username) { 'FAKE_USER' }

    describe '#revisions' do
      it 'can return a previously created revision' do
        event = subject.create_revision("my-deployment", username, task, Time.now, 'test-key: test-value', nil, [], [], [])

        expect(subject.revisions('my-deployment')).to eq([
          {
            deployment_name:"my-deployment",
            revision_number: 1,
            user: username,
            task: task,
            started_at: event.context['started_at'],
            completed_at: event.timestamp,
            error: nil,
          }
        ])
      end

      it 'can return a previously created revision including manifest if specified' do
        event = subject.create_revision("my-deployment", username, task, Time.now, 'test-key: test-value', nil, [], [], [])

        expect(subject.revisions('my-deployment', should_include_manifest: true)).to eq([
          {
            deployment_name:"my-deployment",
            revision_number: 1,
            user: username,
            task: task,
            started_at: event.context['started_at'],
            completed_at: event.timestamp,
            manifest_content: 'test-key: test-value',
            error: nil,
          }
        ])
      end

      it 'only returns deployment_revision object_types as revision' do
        event = subject.create_revision("my-deployment", username, task, Time.now, 'test-key: test-value', nil, [], [], [])

        Models::Event.create(
          timestamp:   Time.now,
          user:        "user",
          action:      "create",
          object_type: "some-other-object-type",
          deployment:  "my-deployment",
        )

        expect(subject.revisions('my-deployment')).to eq([
          {
            deployment_name:"my-deployment",
            revision_number: 1,
            user: username,
            task: task,
            started_at: event.context['started_at'],
            completed_at: event.timestamp,
            error: nil,
          }
        ])
      end
    end
    
    describe '#create_revision' do
      it 'creates consecutive revision_numbers per deployment in event.object_name' do
        expect(subject.create_revision("deployment-A", username, task, Time.now, 'manifest', nil, [], [], []).object_name).to eq '1'
        expect(subject.create_revision("deployment-B", username, task, Time.now, 'manifest', nil, [], [], []).object_name).to eq '1'
        expect(subject.create_revision("deployment-A", username, task, Time.now, 'manifest', nil, [], [], []).object_name).to eq '2'
        expect(subject.create_revision("deployment-B", username, task, Time.now, 'manifest', nil, [], [], []).object_name).to eq '2'
        expect(subject.create_revision("deployment-B", username, task, Time.now, 'manifest', nil, [], [], []).object_name).to eq '3'
        expect(subject.create_revision("deployment-A", username, task, Time.now, 'manifest', nil, [], [], []).object_name).to eq '3'
      end
    end

    describe '#diff' do
      it 'returns a diff between the manifests' do
        subject.create_revision("deployment-A", username, task, Time.now, 'key: 1', nil, [], [], [])
        subject.create_revision("deployment-A", username, task, Time.now, 'key: 2', nil, [], [], [])

        expect(subject.diff("deployment-A", 1, 2, should_redact: false)).to eq([
          ["key: 1", "removed"],
          ["", nil], 
          ["key: 2", "added"]
        ])
      end
    end
  end
end
