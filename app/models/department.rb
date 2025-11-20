class Department < ApplicationRecord
  belongs_to :active_program, class_name: "Program", optional: true
  has_many :programs, dependent: :destroy
  has_many :department_admins, dependent: :destroy
  has_many :admin_users, through: :department_admins, source: :user
  has_many :vips, dependent: :destroy
  has_many :affiliated_resources, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true, uniqueness: true
  has_rich_text :mission_statement if defined?(ActionText)

  def admin_users_for(user)
    return admin_users if user&.super_admin?
    admin_users
  end
end
