require 'rails_helper'

RSpec.describe AffiliatedResource, type: :model do
  let(:department) { Department.create!(name: "Test Department") }

  describe 'associations' do
    subject { AffiliatedResource.new(name: "Test", url: "http://test.com", department: department) }
    it { should belong_to(:department) }
  end

  describe 'validations' do
    it 'requires name' do
      resource = AffiliatedResource.new(url: "http://example.com", department: department)
      expect(resource).not_to be_valid
      expect(resource.errors[:name]).to be_present
    end

    it 'requires url' do
      resource = AffiliatedResource.new(name: "Test Resource", department: department)
      expect(resource).not_to be_valid
      expect(resource.errors[:url]).to be_present
    end

    it 'is valid with name and url' do
      resource = AffiliatedResource.new(name: "Test Resource", url: "http://example.com", department: department)
      expect(resource).to be_valid
    end
  end

  describe 'scopes' do
    let!(:resource1) { AffiliatedResource.create!(name: "Resource 1", url: "http://example.com/1", department: department, position: 2) }
    let!(:resource2) { AffiliatedResource.create!(name: "Resource 2", url: "http://example.com/2", department: department, position: 1) }
    let!(:resource3) { AffiliatedResource.create!(name: "Resource 3", url: "http://example.com/3", department: department, position: 1) }

    describe '.ordered' do
      it 'orders by position then name' do
        ordered = AffiliatedResource.ordered.to_a
        expect(ordered.first).to eq(resource2) # position 1, name "Resource 2"
        expect(ordered.last).to eq(resource1) # position 2
      end
    end
  end
end
