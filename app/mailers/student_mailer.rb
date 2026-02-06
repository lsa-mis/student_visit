class StudentMailer < ApplicationMailer
  def welcome(user, program, is_new_student: false)
    @user = user
    @program = program
    @is_new_student = is_new_student

    reply_to = @program&.information_email_address.presence

    mail_options = {
      to: user.email_address,
      subject: "Welcome to #{program.name}"
    }
    mail_options[:reply_to] = reply_to if reply_to

    mail(mail_options)
  end
end
