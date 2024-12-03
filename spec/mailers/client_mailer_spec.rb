require 'rails_helper'

# foreman run rspec spec/mailers/client_mailer_spec.rb
RSpec.describe ClientMailer, type: :mailer do
  describe 'failed_charge_notification' do
    let(:client) { create(:client) }
    let(:mail) { ClientMailer.with(client_id: client.id).failed_charge_notification }

    it 'renders the headers' do
      expect(mail.subject).to eq('Failed charge notification')
      expect(mail.to).to eq([client.def_user.email])
      expect(mail.from).to eq(['support@chiirp.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Hi')
    end
  end
end
