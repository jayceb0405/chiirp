# frozen_string_literal: true

# app/presenters/tags_presenter.rb
class TagsPresenter
  attr_reader :client, :contact, :contacttag

  def initialize(args = {})
    self.contact  = args.dig(:contact)
    self.client   = args.dig(:client)

    @contacttag  = nil
    @contacttags = nil
  end

  def client=(client)
    @client = if client.is_a?(Client)
                client
              elsif client.is_a?(Integer)
                Client.find_by(id: client)
              elsif self.contact.is_a?(Contact)
                self.contact.client
              else
                Client.new
              end
  end

  def contact=(contact)
    @contact = if contact.is_a?(Contact)
                 contact
               elsif contact.is_a?(Integer)
                 Contact.find_by(id: contact)
               elsif self.client.is_a?(Client)
                 self.client.contacts.new
               else
                 Contact.new
               end
  end

  def contacttag=(contacttag)
    @contacttag = if contacttag.is_a?(Contacttag)
                    contacttag
                  elsif contacttag.is_a?(Integer)
                    Contacttag.find_by(id: contacttag)
                  else
                    self.contact.contacttags.new
                  end
  end

  def contacttags
    @contacttags ||= self.contact.contacttags.order('created_at DESC')
  end

  def contacttags?
    self.contacttags.any?
  end
end
