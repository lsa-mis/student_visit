class AnswerEdit < ApplicationRecord
  belongs_to :answer
  belongs_to :edited_by, class_name: "User"

  validates :edited_at, presence: true
end
