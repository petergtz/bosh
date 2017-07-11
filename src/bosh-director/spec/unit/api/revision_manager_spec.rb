require 'spec_helper'

module Bosh::Director
  describe Api::RevisionManager do
    let(:task) { double('Task') }
    let(:username) { 'FAKE_USER' }

    describe '#revisions' do
      it 'can create and return a revision' do
        event = subject.create_revision("my-deployment", "bla", 'user')

        expect(subject.revisions('my-deployment')).to eq([
              {
                id: 1,
                deployment_name:"my-deployment",
                timestamp:event.timestamp,
                manifest_content:"bla"
              }
            ])
      end

      it 'only returns deployment_revision object_types as revision' do
        event = subject.create_revision("my-deployment", "bla", 'user')

        Models::Event.create(
          timestamp:   Time.now,
          user:        "user",
          action:      "create",
          object_type: "some-other-object-type",
          deployment:  "my-deployment",
          )

        expect(subject.revisions('my-deployment')).to eq([
              {
                id: 1,
                deployment_name: "my-deployment",
                timestamp: event.timestamp,
                manifest_content: "bla"
              }
            ])
      end

    end
  end
end
