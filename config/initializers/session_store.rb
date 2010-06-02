# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_kotaku-magazine_session',
  :secret      => 'ebca56287e292fffa8e7a971736f29dcd11ca43e708926c402201d7869b889e64aeda9dded538f7b8968ec61dc49fb1932355cf947624e45e2d871f3b1920b8f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
