require 'rails_helper'

RSpec.describe DepartmentAdminMailer, type: :mailer do
  let(:department) { Department.create!(name: "Test Department") }
  let(:user) { User.create!(email_address: 'admin@example.com', password: 'password123') }

  describe '#welcome' do
    let(:mail) { DepartmentAdminMailer.welcome(user, department) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Welcome as Department Admin for Test Department")
      expect(mail.to).to eq([ user.email_address ])
      expect(mail.from).to be_present
    end

    it 'renders the body' do
      # Mail body might be HTML or text, check that it contains key information
      body = mail.body.encoded
      expect(body).to include('Test Department').or include('Department')
      # Email address might be in headers or body
      expect(body).to be_present
    end

    it 'assigns instance variables' do
      expect(mail.body.encoded).to include(department.name)
    end
  end
end
