class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :questionnaire, null: false, foreign_key: true
      t.text :text, null: false
      t.string :question_type, null: false
      t.text :options
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :questions, [:questionnaire_id, :position]
  end
end
