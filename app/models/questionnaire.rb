class Questionnaire < ApplicationRecord
  belongs_to :program
  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :answers, through: :questions

  validates :name, presence: true
end
