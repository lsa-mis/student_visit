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
    # For ActionText, check if the content has changed
    # In before_update, use will_save_change_to_content? or content_changed?
    content_has_changed = will_save_change_to_content? || content_changed?

    # Also check if the rich text body has changed
    if !content_has_changed && content.respond_to?(:body_changed?)
      content_has_changed = content.body_changed?
    end

    return unless content_has_changed

    # Get previous content - for ActionText, try multiple approaches
    previous_content_value = begin
      if content.respond_to?(:body_was) && content.body_was.present?
        content.body_was.to_s
      elsif will_save_change_to_content?
        # Get the old value from the change tracking
        attribute_in_database(:content)&.to_s || content_was
      else
        content_was
      end
    rescue
      # Last resort: try to get from database
      if persisted?
        self.class.find(id).content.to_s rescue content.to_s
      else
        content.to_s
      end
    end

    answer_edits.build(
      edited_by: Current.user || student,
      edited_at: Time.current,
      previous_content: previous_content_value
    )
  end
end
