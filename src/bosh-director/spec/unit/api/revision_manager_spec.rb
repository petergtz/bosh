require 'spec_helper'

module Bosh::Director
  describe Api::RevisionManager do
    let(:task) { double('Task') }
    let(:username) { 'FAKE_USER' }

    describe '#revisions' do
      it 'can return a previously created revision' do
        event = subject.create_revision("my-deployment", username, Time.now, 'test-key: test-value', 1, [1])

        expect(subject.revisions('my-deployment')).to eq([
          {
            deployment_name:"my-deployment",
            revision_number: 1,
            user: username,
            started_at: event.context['started_at'],
            completed_at: event.timestamp,
            manifest_content: 'test-key: test-value' ,
            error: nil,
          }
        ])
      end

      it 'only returns deployment_revision object_types as revision' do
        event = subject.create_revision("my-deployment", username, Time.now, 'test-key: test-value', 1, [1])

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
            started_at: event.context['started_at'],
            completed_at: event.timestamp,
            manifest_content: 'test-key: test-value' ,
            error: nil,
          }
        ])
      end
    end
    
    describe '#create_revision' do
      it 'creates consecutive revision per deployment in event.object_name' do
        expect(subject.create_revision("deployment-A", username, Time.now, 'manifest', 1, [1]).object_name).to eq '1'
        expect(subject.create_revision("deployment-B", username, Time.now, 'manifest', 1, [1]).object_name).to eq '1'
        expect(subject.create_revision("deployment-A", username, Time.now, 'manifest', 1, [1]).object_name).to eq '2'
        expect(subject.create_revision("deployment-B", username, Time.now, 'manifest', 1, [1]).object_name).to eq '2'
        expect(subject.create_revision("deployment-B", username, Time.now, 'manifest', 1, [1]).object_name).to eq '3'
        expect(subject.create_revision("deployment-A", username, Time.now, 'manifest', 1, [1]).object_name).to eq '3'
      end
    end

    describe '#diff' do
      it 'returns a diff between the manifests' do
        subject.create_revision("deployment-A", username, Time.now, 'key: 1', nil, [])
        subject.create_revision("deployment-A", username, Time.now, 'key: 2', nil, [])

        expect(subject.diff("deployment-A", 1, 2, false).map { |l| [l.to_s, l.status] }).to eq([
          ["key: 1", "removed"],
          ["", nil], 
          ["key: 2", "added"]
        ])
      end
    end
  end
end
