require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'contacts_export_notification' do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.with(user_id: user.id).contacts_export_notification }

    it 'renders the headers' do
      expect(mail.subject).to eq('Contacts export')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['support@chiirp.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match(user.firstname.to_s)
    end
  end
end
