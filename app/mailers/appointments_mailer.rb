class AppointmentsMailer < ApplicationMailer
  def change_notification(student, appointment, action)
    @student = student
    @appointment = appointment
    @action = action
    @program = appointment.program
    @vip = appointment.vip

    reply_to = @program&.information_email_address.presence

    mail_options = {
      to: student.email_address,
      subject: "Appointment #{action == 'selected' ? 'Confirmed' : 'Cancelled'}: #{@vip.name}"
    }
    mail_options[:reply_to] = reply_to if reply_to

    mail(mail_options)
  end
end
