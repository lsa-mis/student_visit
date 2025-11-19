require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }

    it 'requires a user' do
      session = Session.new(user_agent: 'Mozilla/5.0', ip_address: '127.0.0.1')
      expect(session).not_to be_valid
      expect(session.errors[:user]).to be_present
    end

    it 'is valid with a user' do
      session = user.sessions.build(user_agent: 'Mozilla/5.0', ip_address: '127.0.0.1')
      expect(session).to be_valid
    end
  end

  describe 'creation' do
    let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }

    it 'can be created with user_agent and ip_address' do
      session = user.sessions.create!(
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        ip_address: '192.168.1.100'
      )

      expect(session).to be_persisted
      expect(session.user_agent).to eq('Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
      expect(session.ip_address).to eq('192.168.1.100')
      expect(session.user).to eq(user)
    end

    it 'can be created without user_agent and ip_address' do
      session = user.sessions.create!
      expect(session).to be_persisted
      expect(session.user).to eq(user)
    end
  end

  describe 'belongs to user' do
    let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }
    let(:session) { user.sessions.create!(user_agent: 'Mozilla/5.0', ip_address: '127.0.0.1') }

    it 'has access to the user' do
      expect(session.user).to eq(user)
    end

    it 'can access user email through session' do
      expect(session.user.email_address).to eq('test@example.com')
    end
  end
end
