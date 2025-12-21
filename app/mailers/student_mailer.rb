class StudentMailer < ApplicationMailer
  def welcome(user, program)
    @user = user
    @program = program
    mail(
      to: user.email_address,
      subject: "Welcome to #{program.name}"
    )
  end
end
