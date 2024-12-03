class AddPageTokenToContactFbPages < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding page_token to Contacts::FbPage model...' do
      add_column :contact_fb_pages, :page_token, :string, null: false, default: ''

      Contacts::FbPage.all.each do |contact_fb_page|

        if (user_api_integration = UserApiIntegration.where(target: 'facebook', name: '').find_by('data @> ?', { pages: [id: contact_fb_page.page_id] }.to_json)) &&
          (page = user_api_integration.pages.find { |p| p['id'] == contact_fb_page.page_id })

          contact_fb_page.update(page_token: page.dig('token'))
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
