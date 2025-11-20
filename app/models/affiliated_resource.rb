class AffiliatedResource < ApplicationRecord
  belongs_to :department

  validates :name, :url, presence: true

  scope :ordered, -> { order(:position, :name) }
end
