class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: true

  ROLE_TYPES = %w[super_admin department_admin student faculty].freeze

  ROLE_TYPES.each do |role_type|
    define_singleton_method role_type do
      find_or_create_by!(name: role_type)
    end
  end
end
