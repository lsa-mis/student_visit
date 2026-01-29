class PageContent < ApplicationRecord
  has_rich_text :content if defined?(ActionText)

  # Page paths with editable content. [ "Label", "page_path" ]
  KNOWN_PAGE_PATHS = [
    [ "Home — index", "home/index" ],
    [ "Departments — index", "departments/index" ],
    [ "Programs — new", "programs/new" ],
    [ "Programs — show", "programs/show" ],
    [ "Students — index", "students/index" ],
    [ "Students — bulk upload", "students/bulk_upload" ],
    [ "Questionnaires — show", "questionnaires/show" ],
    [ "Calendar events — bulk upload", "calendar_events/bulk_upload" ],
    [ "Appointments — schedule builder", "appointments/schedule_builder" ],
    [ "Appointments — new", "appointments/new" ],
    [ "Appointments — bulk upload", "appointments/bulk_upload" ],
    [ "VIPs — index", "vips/index" ],
    [ "VIPs — bulk upload", "vips/bulk_upload" ],
    [ "Important links — index", "important_links/index" ]
  ].freeze

  # Page-specific area options. [ "Label", "area_name" ]. Default for other pages: [ ["Instructions", "instructions"] ]
  KNOWN_PAGE_AREAS = {
    "home/index" => [
      [ "Hero title", "hero_title" ],
      [ "Welcome message", "welcome_message" ]
    ]
  }.freeze

  def self.area_options_for(page_path)
    return [] if page_path.blank?

    KNOWN_PAGE_AREAS[page_path] || [ [ "Instructions", "instructions" ] ]
  end

  def self.area_options_map_for_js
    paths = KNOWN_PAGE_PATHS.map { |_, p| p }.uniq
    base = paths.to_h { |p| [ p, [ [ "Instructions", "instructions" ] ] ] }
    base.merge(KNOWN_PAGE_AREAS)
  end

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
