class Question < ApplicationRecord
  belongs_to :questionnaire
  has_many :answers, dependent: :destroy

  validates :text, :question_type, presence: true
  validates :question_type, inclusion: { in: %w[text rich_text checkbox radio datetime link] }

  QUESTION_TYPES = %w[text rich_text checkbox radio datetime link].freeze

  serialize :options, coder: YAML

  def options_array
    options.is_a?(Array) ? options : []
  end

  def options_hash
    return {} unless options.is_a?(Hash)
    options
  end
end
