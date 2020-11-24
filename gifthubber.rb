require 'httparty'
require 'mailgun-ruby'

EMAIL_DOMAIN = 'example.com'.freeze
MAILGUN_API_KEY = 'abc123'.freeze
GITHUB_ACCESS_TOKEN = 'xyz999'.freeze
MAILGUN_DOMAIN = 'mail.example.com'.freeze
FROM_ADDRESS = 'sender@example.com'.freeze

class GiftHubber
  def self.distribute_gifts(repo, issue_number)
    issue_url = "https://api.github.com/repos/#{repo}/issues/#{issue_number}/comments?per_page=1000"
    comments_response = HTTParty.get(
      issue_url,
      headers: {
        "Authorization" => "token #{GITHUB_ACCESS_TOKEN}",
        "User-Agent" => "GiftHubber"
      }
    )
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
      message = <<-MESSAGE
      Your secret gift recipient is #{recipient_name}! Their wishlist is: #{recipient_request}. Please send them something that costs about $20. You can find their shipping address on Team <3

      - from spinecone, secret gift facilitator
      MESSAGE
      p "#{sender} was asked to send a gift to #{recipient_name}"
      send_email(sender, message)
      recipients.delete(recipient_name)
    end
  end

  def self.send_email(sender, message)
    mail_params = {
      from: FROM_ADDRESS,
      to: "#{sender}@#{EMAIL_DOMAIN}",
      subject: 'Your githubber secret gift recipient',
      text: message
    }

    mg_client.send_message(MAILGUN_DOMAIN, mail_params)
  end

  def self.mg_client
    @mg_client ||= Mailgun::Client.new(MAILGUN_API_KEY)
  end

  def self.set_testing_mode
    mg_client.enable_test_mode!
  end

  class HolidayError < StandardError
  end
end
