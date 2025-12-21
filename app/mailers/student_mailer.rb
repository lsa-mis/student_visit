class StudentMailer < ApplicationMailer
  def welcome(user, program, is_new_student: false)
    @user = user
    @program = program
    @is_new_student = is_new_student
    mail(
      to: user.email_address,
      subject: "Welcome to #{program.name}"
    )
  end
end
