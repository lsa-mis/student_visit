class DepartmentAdminMailer < ApplicationMailer
  def welcome(user, department)
    @user = user
    @department = department
    mail(
      to: user.email_address,
      subject: "Welcome as Department Admin for #{department.name}"
    )
  end
end
