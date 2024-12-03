# frozen_string_literal: true

# app/presenters/stages_presenter.rb
class StagesPresenter
  attr_reader :client, :client_custom_fields, :contact_tags, :stage, :stage_parent, :user

  def initialize(args = {})
    if args.dig(:stage_parent)
      self.stage_parent = args.dig(:stage_parent)
      self.stage        = args.dig(:stage)
      self.client       = args.dig(:client)
    elsif args.dig(:stage)
      self.stage        = args.dig(:stage)
      self.stage_parent = args.dig(:stage_parent)
      self.client       = args.dig(:client)
    else
      self.client       = args.dig(:client)
      self.stage_parent = args.dig(:stage_parent)
      self.stage        = args.dig(:stage)
    end

    @client_custom_fields = nil
    @contacts             = nil
    @contact_tags         = nil
    @default_stage_parent = nil
    @stages               = nil
    @stage_parents        = nil
    @user                 = nil
    @user_settings        = nil
  end

  def client=(client)
    @client = case client
              when Client
                client
              when Integer
                Client.find_by(id: client)
              else
                if self.stage_parent.is_a?(StageParent)
                  self.stage_parent.client
                elsif self.stage.is_a?(Stage)
                  self.stage.stage_parent.client
                else
                  Client.new
                end
              end
  end

  def contacts(search_string = '', session = {})
    @contacts = self.stage.contacts.select('contacts.*, contact_phones.phone as phone').left_outer_joins(:contact_phones).where(contact_phones: { primary: true }).or(self.stage.contacts.select('contacts.*, contact_phones.phone as phone').where.missing(:contact_phones)).includes(:user)

    @contacts = @contacts.where('contacts.firstname ILIKE ? OR contacts.lastname ILIKE ?', "%#{search_string}%", "%#{search_string}%") if search_string.present?

    if self.user.access_controller?('stages', 'all_contacts', session)
      @contacts = @contacts.where(user_id: self.user_settings.data[:user_ids]) if self.user_settings.data.dig(:user_ids).present?
    else
      @contacts = @contacts.where(user_id: self.user.id)
    end

    @contacts = @contacts.order(:lastname, :firstname).limit(100)

    if @contacts.present?
      @contact_tags         = Contacttag.joins(:tag).where(contact_id: @contacts.pluck(:id)).where("(tags.color = '') IS FALSE").includes(:tag)
      @client_custom_fields = ClientCustomField.where(client_id: @client.id)
                                               .where(id: self.stage.show_custom_fields)
                                               .select('contact_custom_fields.contact_id AS contact_id, client_custom_fields.id AS id, client_custom_fields.var_name AS var_name, client_custom_fields.var_type AS var_type, client_custom_fields.var_options AS var_options, contact_custom_fields.var_value AS var_value')
                                               .joins(:contact_custom_fields)
                                               .where(contact_custom_fields: { contact_id: @contacts.pluck(:id) })
                                               .order(:var_name)
    end

    @contacts
  end

  def default_stage_parent
    @default_stage_parent || self.user.default_stage_parent_id.positive? ? StageParent.for_user(self.user.id).find { |x| x.id == self.user.default_stage_parent_id } : nil
  end

  def show_client_custom_field(contact, client_custom_field)
    if client_custom_field.var_value.present?

      case client_custom_field.var_type
      when 'string'

        if client_custom_field.var_options.is_a?(Hash) && client_custom_field.var_options.dig(:string_options).present?
          var_options = client_custom_field.string_options_for_select.to_h { |x| [x[1], x[0]] }

          if var_options.key?(client_custom_field.var_value)
            "<div class=\"text-muted ml-1\" id=\"client_custom_field_#{client_custom_field.id}_#{contact.id}\" style=\"#{self.stage.show_custom_fields&.include?(client_custom_field.id) ? 'display:block' : 'display:none'};\">#{client_custom_field.var_name}: #{var_options[client_custom_field.var_value]}</div>"
          else
            "<div class=\"text-muted ml-1\" id=\"client_custom_field_#{client_custom_field.id}_#{contact.id}\" style=\"#{self.stage.show_custom_fields&.include?(client_custom_field.id) ? 'display:block' : 'display:none'};\">#{client_custom_field.var_name}: #{client_custom_field.var_value}</div>"
          end
        else
          "<div class=\"text-muted ml-1\" id=\"client_custom_field_#{client_custom_field.id}_#{contact.id}\" style=\"#{self.stage.show_custom_fields&.include?(client_custom_field.id) ? 'display:block' : 'display:none'};\">#{client_custom_field.var_name}: #{client_custom_field.var_value}</div>"
        end
      when 'numeric', 'stars', 'currency'
        "<div class=\"text-muted ml-1\" id=\"client_custom_field_#{client_custom_field.id}_#{contact.id}\" style=\"#{self.stage.show_custom_fields&.include?(client_custom_field.id) ? 'display:block' : 'display:none'};\">#{client_custom_field.var_name}: #{client_custom_field.var_value}</div>"
      when 'date'
        "<div class=\"text-muted ml-1\" id=\"client_custom_field_#{client_custom_field.id}_#{contact.id}\" style=\"#{self.stage.show_custom_fields&.include?(client_custom_field.id) ? 'display:block' : 'display:none'};\">#{client_custom_field.var_name}: #{Time.use_zone(contact.client.time_zone) { Chronic.parse(client_custom_field.var_value) }.strftime('%m/%d/%Y %I:%M %p')}</div>"
      else
        ''
      end
    else
      ''
    end
  end

  def stage=(stage)
    @stage = case stage
             when Stage
               stage
             when Integer
               Stage.find_by(id: stage)
             else
               if self.stage_parent.is_a?(StageParent)
                 self.stage_parent.stages.new
               else
                 Stage.new
               end
             end
  end

  def stage_parent=(stage_parent)
    @stage_parent = case stage_parent
                    when StageParent
                      stage_parent
                    when Integer
                      StageParent.find_by(id: stage_parent)
                    else
                      if self.stage.is_a?(Stage)
                        self.stage.stage_parent
                      elsif self.client.is_a?(Client)
                        self.client.stage_parents.new
                      else
                        StageParent.new
                      end
                    end
  end

  def stage_parents
    @stage_parents || StageParent.for_user(self.user.id).sort_by(&:name)
  end

  def stages
    @stages || self.stage_parent.stages.order(:sort_order)
  end

  def user=(user)
    @user = case user
            when User
              user
            when Integer
              if @user && @user.id == user.id
                @user
              else
                User.find_by(id: user)
              end
            else
              self.client.users.new
            end
  end

  def user_settings
    @user_settings ||= self.user.user_settings.find_or_create_by(controller_action: 'stages_index', current: 1)
  end

  def users
    self.client.users.order(:lastname, :firstname)
  end
end
