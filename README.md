For facilitating randomized gift exchange between hubbers (or whatever group of folks) using issue comments

Setup:
- Make sure `EMAIL_DOMAIN` and `FROM_ADDRESS` in `gifthubber.rb` get changed to something relevant
- Figure out how you want to associate github usernames with email addresses; ideally this would be an API call to find the user and using the public email associated with them, but githubbers don't tend to set that field so I'm doing a hackier thing.

To use:
- Make sure everyone's shipping address is accessible to the group somewhere (for githubbers, plz set a public address on Team). This ensures that I'm not storing private info anywhere that it isn't already available.
- Create an issue where participants can post a comment with their wishlist
- When there are enough people (make sure there are an even number of participants!!!) run `GiftHubber.distribute_gifts(repo, issue_number, access_token)` where the `repo` and `issue_number` correspond to the issue where everyone posted their wishlist, and the `access_token` is a github oauth token.
- Emails pairing gift senders/recipients get sent!
