require 'rails_helper'

RSpec.describe PageContent, type: :model do
  describe 'validations' do
    it 'requires page_path' do
      page_content = PageContent.new(area_name: "test", content: "content")
      expect(page_content).not_to be_valid
      expect(page_content.errors[:page_path]).to be_present
    end

    it 'requires area_name' do
      page_content = PageContent.new(page_path: "/test", content: "content")
      expect(page_content).not_to be_valid
      expect(page_content.errors[:area_name]).to be_present
    end

    it 'requires uniqueness of area_name scoped to page_path' do
      create(:page_content, page_path: "/test", area_name: "main")
      duplicate = PageContent.new(page_path: "/test", area_name: "main")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:area_name]).to be_present
    end

    it 'allows same area_name on different pages' do
      create(:page_content, page_path: "/test1", area_name: "main")
      duplicate = PageContent.new(page_path: "/test2", area_name: "main")
      expect(duplicate).to be_valid
    end
  end

  describe '.for_page' do
    it 'finds existing page content' do
      page_content = create(:page_content, page_path: "/test", area_name: "main")
      found = PageContent.for_page("/test", "main")
      expect(found).to eq(page_content)
      expect(found).to be_persisted
    end

    it 'initializes new page content when not found' do
      found = PageContent.for_page("/test", "main")
      expect(found).to be_a(PageContent)
      expect(found).not_to be_persisted
      expect(found.page_path).to eq("/test")
      expect(found.area_name).to eq("main")
    end
  end

  describe '.for_page_path' do
    it 'returns all content areas for a page' do
      page_content1 = create(:page_content, page_path: "/test", area_name: "main")
      page_content2 = create(:page_content, page_path: "/test", area_name: "sidebar")
      create(:page_content, page_path: "/other", area_name: "main")

      results = PageContent.for_page_path("/test")
      expect(results).to include(page_content1, page_content2)
      expect(results.count).to eq(2)
    end

    it 'orders by area_name' do
      page_content1 = create(:page_content, page_path: "/test", area_name: "zebra")
      page_content2 = create(:page_content, page_path: "/test", area_name: "alpha")
      page_content3 = create(:page_content, page_path: "/test", area_name: "beta")

      results = PageContent.for_page_path("/test")
      expect(results.map(&:area_name)).to eq(["alpha", "beta", "zebra"])
    end

    it 'returns empty relation when no content exists' do
      results = PageContent.for_page_path("/nonexistent")
      expect(results).to be_empty
    end
  end
end
