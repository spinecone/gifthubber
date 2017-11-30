require 'test/unit'
require_relative 'gifthubber'
require 'webmock/test_unit'
require 'httparty'

class TestGiftHubber < Test::Unit::TestCase
  def setup
    Mail.defaults do
      delivery_method :test
    end
    Mail::TestMailer.deliveries.clear
    @access_token = '123abc'
    @issue_number = '1'
    @repo = 'spinecone/greatstuff'
    @expected_url = "https://api.github.com/repos/#{@repo}/issues/#{@issue_number}/comments?access_token=#{@access_token}"
  end

  def test_sends_emails
    api_response = [
      { 'user' => { 'login' => 'user1' }, 'body' => 'I want cats' },
      { 'user' => { 'login' => 'user2' }, 'body' => 'I want pants' }
    ]

    stub_request(:get, @expected_url).to_return('body' => api_response.to_json)
    GiftHubber.distribute_gifts(@repo, @issue_number, @access_token)

    deliveries = Mail::TestMailer.deliveries.sort_by(&:to)
    assert_equal 2, deliveries.length

    assert_equal [GiftHubber::FROM_ADDRESS], deliveries[0].from
    assert_equal ["user1@#{GiftHubber::EMAIL_DOMAIN}"], deliveries[0].to
    assert deliveries[0].body.raw_source.include?('Your secret gift recipient is user2! Their wishlist is: I want pants.')

    assert_equal [GiftHubber::FROM_ADDRESS], deliveries[1].from
    assert_equal ["user2@#{GiftHubber::EMAIL_DOMAIN}"], deliveries[1].to
    assert deliveries[1].body.raw_source.include?('Your secret gift recipient is user1! Their wishlist is: I want cats.')
    Mail::TestMailer.deliveries.clear
  end

  def test_assigns_recipients_and_senders_correctly
    100.times do # bein thorough!!!
      api_response = []
      10.times do |x|
        api_response << { 'user' => { 'login' => "user#{x}" }, 'body' => 'I want stuff' }
      end
      stub_request(:get, @expected_url).to_return('body' => api_response.to_json)
      GiftHubber.distribute_gifts(@repo, @issue_number, @access_token)

      deliveries = Mail::TestMailer.deliveries
      assert_equal 10, deliveries.length
      assert_equal 10, deliveries.map(&:to).uniq.count
      recipients = []
      deliveries.map do |delivery|
        recipient = delivery.to[0].match(/(.*?)@#{GiftHubber::EMAIL_DOMAIN}/)[1]
        sender = delivery.body.raw_source.match(/Your secret gift recipient is (.*?)!/)[1]
        assert sender != recipient
        recipients << recipient
      end
      assert_equal 10, recipients.uniq.count
      Mail::TestMailer.deliveries.clear
    end
  end
end
