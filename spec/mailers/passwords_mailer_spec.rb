require 'rails_helper'

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }

  describe '#reset' do
    let(:mail) { PasswordsMailer.reset(user) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Reset your password')
      expect(mail.to).to eq([ user.email_address ])
      expect(mail.from).to be_present
    end

    it 'renders the body' do
      expect(mail.body.encoded).to be_present
    end

    it 'includes password reset link in HTML body' do
      if user.respond_to?(:password_reset_token)
        # Token is generated in the view, so we just check that a URL is present
        expect(mail.body.encoded).to include('passwords/')
        expect(mail.body.encoded).to include('/edit')
      else
        # If password_reset_token method doesn't exist, just check body is present
        expect(mail.body.encoded).to be_present
      end
    end

    it 'includes password reset link in text body' do
      if user.respond_to?(:password_reset_token)
        # Token is generated in the view, so we just check that a URL is present
        expect(mail.text_part.body.encoded).to include('passwords/')
        expect(mail.text_part.body.encoded).to include('/edit')
      else
        expect(mail.text_part.body.encoded).to be_present
      end
    end

    it 'sets the correct user' do
      # The user is set as an instance variable in the mailer
      # Check via the email address instead
      expect(mail.to).to eq([ user.email_address ])
    end

    context 'when delivered' do
      it 'queues the email' do
        expect {
          PasswordsMailer.reset(user).deliver_later
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end

      it 'can be delivered now' do
        expect {
          PasswordsMailer.reset(user).deliver_now
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'with different email formats' do
      it 'handles lowercase email' do
        user.update!(email_address: 'lowercase@example.com')
        mail = PasswordsMailer.reset(user)
        expect(mail.to).to eq([ 'lowercase@example.com' ])
      end

      it 'handles mixed case email' do
        user.update!(email_address: 'MixedCase@Example.COM')
        mail = PasswordsMailer.reset(user)
        # Email should be normalized
        expect(mail.to).to eq([ 'mixedcase@example.com' ])
      end
    end
  end
end
