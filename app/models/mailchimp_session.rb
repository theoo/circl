class MailchimpSession

  attr_accessor :session

  def initialize
    @session = Mailchimp::API.new(ApplicationSetting.value("mailchimp_api_key"))
  end

  def list_names
    @session.lists.list["data"].each_with_object({}){|l,o| o[l['id']] = l['name']}
  end

end