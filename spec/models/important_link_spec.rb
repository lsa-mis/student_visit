require 'rails_helper'

RSpec.describe ImportantLink, type: :model do
  let(:department) { create(:department) }
  let(:program) { create(:program, department: department) }

  describe 'associations' do
    subject { ImportantLink.new(name: "Test Link", url: "https://example.com", program: program) }
    it { should belong_to(:program) }
  end

  describe 'validations' do
    it 'requires name' do
      link = ImportantLink.new(url: "https://example.com", program: program)
      expect(link).not_to be_valid
      expect(link.errors[:name]).to be_present
    end

    it 'requires url' do
      link = ImportantLink.new(name: "Test Link", program: program)
      expect(link).not_to be_valid
      expect(link.errors[:url]).to be_present
    end

    it 'is valid with name and url' do
      link = ImportantLink.new(name: "Test Link", url: "https://example.com", program: program)
      expect(link).to be_valid
    end
  end

  describe 'scopes' do
    describe '.ordered' do
      let!(:link1) { create(:important_link, program: program, name: "B Link", ranking: 2) }
      let!(:link2) { create(:important_link, program: program, name: "A Link", ranking: 1) }
      let!(:link3) { create(:important_link, program: program, name: "C Link", ranking: 1) }

      it 'orders by ranking first, then by name' do
        ordered = ImportantLink.ordered
        expect(ordered.to_a).to eq([ link2, link3, link1 ])
      end
    end
  end
end
