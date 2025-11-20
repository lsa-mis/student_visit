class Questionnaire < ApplicationRecord
  belongs_to :program
  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :answers, dependent: :destroy

  validates :name, presence: true
end
