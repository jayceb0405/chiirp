require 'rails_helper'

describe ApplicationCable::Channel do
  let(:user) { create(:user) }

  describe '#full_channel_name' do
    it 'should return user channel name' do
      str = Base64.urlsafe_encode64("gid://funyl/User/#{user.id}", padding: false)
      expect(ApplicationCable::Channel.full_channel_name(user)).to eq("chiirp_test:application_cable::#{str}")
    end

    it 'should return client channel name' do
      str = Base64.urlsafe_encode64("gid://funyl/Client/#{user.client.id}", padding: false)
      expect(ApplicationCable::Channel.full_channel_name(user.client)).to eq("chiirp_test:application_cable::#{str}")
    end
  end
end
