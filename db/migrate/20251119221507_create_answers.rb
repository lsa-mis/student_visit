class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :program, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end

    add_index :answers, [ :question_id, :user_id, :program_id ], unique: true
  end
end
