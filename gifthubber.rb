require 'httparty'
require 'mail'

EMAIL_DOMAIN = 'example.com'.freeze
FROM_ADDRESS = 'sender@example.com'.freeze

class GiftHubber
  def self.distribute_gifts(repo, issue_number, access_token)
    issue_url = "https://api.github.com/repos/#{repo}/issues/#{issue_number}/comments"
    comments_response = HTTParty.get(issue_url + "?access_token=#{access_token}")
    parsed_json = JSON.parse(comments_response.body)
    recipients = {}

    parsed_json.each { |comment| recipients[comment['user']['login']] = comment['body'] }
    senders = recipients.keys
    unless senders.count.even?
      raise HolidayError, "THERE ARE AN ODD NUMBER OF PARTICIPANTS, THIS IS TERRIBLE!!!!"
    end

    senders.each do |sender|
      recipient_name = (recipients.keys - [sender]).sample
      recipient_request = recipients[recipient_name]
      message = "Your secret gift recipient is #{recipient_name}! Their wishlist is: #{recipient_request}. Please send them something that costs about $20. You can find their shipping address on Team <3"
      send_email(sender, message)
      recipients.delete(recipient_name)
    end
  end

  def self.send_email(sender, message)
    mail = Mail.new do
      from FROM_ADDRESS
      to "#{sender}@#{EMAIL_DOMAIN}"
      subject 'Your githubber secret gift recipient'
      body message
    end
    mail.deliver!
  end

  class HolidayError < StandardError
  end
end
