class Answer < ApplicationRecord
  belongs_to :question
  belongs_to :student, class_name: "User", foreign_key: "user_id"
  belongs_to :program
  has_many :answer_edits, dependent: :destroy
  has_rich_text :content if defined?(ActionText)

  validates :question_id, uniqueness: { scope: [:user_id, :program_id] }

  before_update :track_edit

  private

  def track_edit
    return unless content_changed? || content_before_type_cast_changed?

    answer_edits.build(
      edited_by: Current.user || student,
      edited_at: Time.current,
      previous_content: content_was || content_before_type_cast_was
    )
  end
end
