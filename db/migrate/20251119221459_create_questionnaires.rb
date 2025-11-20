class CreateQuestionnaires < ActiveRecord::Migration[8.1]
  def change
    create_table :questionnaires do |t|
      t.references :program, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
