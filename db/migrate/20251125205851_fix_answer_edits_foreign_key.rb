class FixAnswerEditsForeignKey < ActiveRecord::Migration[8.1]
  def change
    # Remove incorrect foreign key if it exists
    if foreign_key_exists?(:answer_edits, :edited_bies)
      remove_foreign_key :answer_edits, :edited_bies
    end

    # Add correct foreign key to users table if it doesn't exist
    unless foreign_key_exists?(:answer_edits, column: :edited_by_id)
      add_foreign_key :answer_edits, :users, column: :edited_by_id
    end
  end
end
