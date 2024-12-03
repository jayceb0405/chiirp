class UpdateTermsAcceptedToDate < ActiveRecord::Migration[5.2]
	def change
		Client.all.each do |c|

			if c.terms_accepted.to_i == 1
				c.update(terms_accepted: c.created_at.strftime("%FT%TZ"))
			else
				c.update(terms_accepted: nil)
			end
		end
	end
end
