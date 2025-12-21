class StudentMailer < ApplicationMailer
  def welcome(user, program, is_new_student: false)
    @user = user
    @program = program
    @is_new_student = is_new_student

    # Attach LSA logo for email
    attachments.inline["LSA_Logo.svg"] = File.read(Rails.root.join("app", "assets", "images", "LSA_Logo.svg"))

    mail(
      to: user.email_address,
      subject: "Welcome to #{program.name}"
    )
  end
end
