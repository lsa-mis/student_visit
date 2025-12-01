class PageContent < ApplicationRecord
  has_rich_text :content if defined?(ActionText)

  validates :page_path, presence: true
  validates :area_name, presence: true
  validates :area_name, uniqueness: { scope: :page_path }

  # Find or initialize content for a specific page and area
  def self.for_page(page_path, area_name)
    find_or_initialize_by(page_path: page_path, area_name: area_name)
  end

  # Get all content areas for a specific page
  def self.for_page_path(page_path)
    where(page_path: page_path).order(:area_name)
  end
end
