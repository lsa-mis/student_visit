class Vip < ApplicationRecord
  belongs_to :program
  has_many :calendar_event_faculty, dependent: :destroy
  has_many :calendar_events, through: :calendar_event_faculty
  has_many :appointments, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> {
    # Order by last name (last word in the name field)
    # Extract last name by finding everything after the last space
    # For SQLite, we use a subquery with a recursive CTE to find the last space position
    sql = <<-SQL.squish
      SELECT vips.*,
        CASE
          WHEN INSTR(vips.name, ' ') = 0 THEN vips.name
          ELSE SUBSTR(vips.name, (
            WITH RECURSIVE last_space AS (
              SELECT vips.name as name, 0 as pos
              UNION ALL
              SELECT last_space.name,
                CASE WHEN INSTR(SUBSTR(last_space.name, last_space.pos + 1), ' ') > 0
                  THEN last_space.pos + INSTR(SUBSTR(last_space.name, last_space.pos + 1), ' ')
                  ELSE last_space.pos
                END
              FROM last_space
              WHERE INSTR(SUBSTR(last_space.name, last_space.pos + 1), ' ') > 0
            )
            SELECT MAX(pos) FROM last_space WHERE last_space.name = vips.name
          ) + 1)
        END as last_name
      FROM vips
    SQL
    from("(#{sql}) as vips").order(:last_name)
  }
  scope :for_student_dashboard, -> { where(display_on_student_dashboard: true) }

  def display_name
    [ name, title ].compact.reject(&:blank?).join(" - ")
  end
end
