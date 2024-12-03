# frozen_string_literal: true

# app/models/concerns/message_central.rb
# included in User model
module MessageCentral
  extend ActiveSupport::Concern

  # user.active_contacts_list()
  #   (req) active_contacts_list_args: (Hash)
  #   (opt) page:                      (Integer / default: 1)
  #   (opt) per_page:                  (Integer / default: 10)
  def active_contacts_list(args = {})
    Kaminari.paginate_array(Contact.active_contacts_list(args.dig(:active_contacts_list_args))).page([args.dig(:page).to_i, 1].max).per([args.dig(:per_page).to_i, 10].max)
  end

  def users_for_active_contacts(args = {})
    if args.dig(:all_users).to_bool && args.dig(:agent).to_bool
      User.select('users.id, users.firstname, users.lastname, clients.name AS client_name, clients.id AS client_id')
          .where('clients.data @> ?', { my_agencies: [self.client_id] }.to_json)
          .joins(:client)
          .or(User.select('users.id, users.firstname, users.lastname, clients.name AS client_name, clients.id AS client_id')
          .where(client_id: self.client_id)
          .joins(:client))
          .order(:client_name, :lastname, :firstname)
          .group_by(&:client_name)
          .map { |k, v| [k, v.map { |u| [Friendly.new.fullname(u.firstname, u.lastname), u.client_id, u.id] }] }
          .map { |c| [c[0], c[1].insert(0, ["All #{c[0]} Users", "all_#{c[1][0][1]}"])] }
    elsif args.dig(:all_users).to_bool
      User.where(client_id: self.client_id).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |u| [Friendly.new.fullname(u[1], u[2]), u[0]] }
    else
      User.where(id: self.id).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |u| [Friendly.new.fullname(u[1], u[2]), u[0]] }
    end
  end
end
