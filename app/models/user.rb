class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Alias for compatibility with gems that expect an email method
  def email
    email_address
  end
end
