require 'test/unit'
require_relative 'gifthubber'
require 'webmock/test_unit'
require 'httparty'

class TestGiftHubber < Test::Unit::TestCase
  def setup
    GiftHubber.set_testing_mode
    Mailgun::Client.deliveries.clear

    @issue_number = '1'
    @repo = 'spinecone/greatstuff'
    token = GiftHubber::GITHUB_ACCESS_TOKEN
    @expected_url = "https://api.github.com/repos/#{@repo}/issues/#{@issue_number}/comments?access_token=#{token}"
  end

  def test_sends_emails
    api_response = [
      { 'user' => { 'login' => 'user1' }, 'body' => 'I want cats' },
      { 'user' => { 'login' => 'user2' }, 'body' => 'I want pants' }
    ]

    stub_request(:get, @expected_url).to_return('body' => api_response.to_json)
    GiftHubber.distribute_gifts(@repo, @issue_number)

    deliveries = Mailgun::Client.deliveries.sort_by { |d| d[:to] }
    assert_equal 2, deliveries.length

    assert_equal GiftHubber::FROM_ADDRESS, deliveries[0][:from]
    assert_equal "user1@#{GiftHubber::EMAIL_DOMAIN}", deliveries[0][:to]
    assert deliveries[0][:text].include?('Your secret gift recipient is user2! Their wishlist is: I want pants.')

    assert_equal GiftHubber::FROM_ADDRESS, deliveries[1][:from]
    assert_equal "user2@#{GiftHubber::EMAIL_DOMAIN}", deliveries[1][:to]
    assert deliveries[1][:text].include?('Your secret gift recipient is user1! Their wishlist is: I want cats.')
    Mailgun::Client.deliveries.clear
  end

  def test_assigns_recipients_and_senders_correctly
    100.times do # bein thorough!!!
      api_response = []
      10.times do |x|
        api_response << { 'user' => { 'login' => "user#{x}" }, 'body' => 'I want stuff' }
      end
      stub_request(:get, @expected_url).to_return('body' => api_response.to_json)
      GiftHubber.distribute_gifts(@repo, @issue_number)

      deliveries = Mailgun::Client.deliveries
      assert_equal 10, deliveries.length
      assert_equal 10, deliveries.map { |d| d[:to] }.uniq.count
      recipients = []
      deliveries.map do |delivery|
        recipient = delivery[:to].match(/(.*?)@#{GiftHubber::EMAIL_DOMAIN}/)[1]
        sender = delivery[:text].match(/Your secret gift recipient is (.*?)!/)[1]
        assert sender != recipient
        recipients << recipient
      end
      assert_equal 10, recipients.uniq.count
      Mailgun::Client.deliveries.clear
    end
  end

  def test_requires_an_even_number_of_participants
    api_response = [
      { 'user' => { 'login' => 'user1' }, 'body' => 'I want cats' },
      { 'user' => { 'login' => 'user2' }, 'body' => 'I want pants' },
      { 'user' => { 'login' => 'user3' }, 'body' => "I'm here to ruin christmas" }
    ]
    stub_request(:get, @expected_url).to_return('body' => api_response.to_json)
    assert_raise GiftHubber::HolidayError do
      GiftHubber.distribute_gifts(@repo, @issue_number)
    end
  end
end
