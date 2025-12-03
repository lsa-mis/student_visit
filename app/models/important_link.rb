class ImportantLink < ApplicationRecord
  belongs_to :program

  validates :name, presence: true
  validates :url, presence: true

  scope :ordered, -> { order(:ranking, :name) }
end
