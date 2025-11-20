class CreateAnswerEdits < ActiveRecord::Migration[8.1]
  def change
    create_table :answer_edits do |t|
      t.references :answer, null: false, foreign_key: true
      t.references :edited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :edited_at, null: false
      t.text :previous_content

      t.timestamps
    end

    add_index :answer_edits, [:answer_id, :edited_at]
  end
end
