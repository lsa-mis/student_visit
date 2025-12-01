class AppointmentsMailer < ApplicationMailer
  def change_notification(student, appointment, action)
    @student = student
    @appointment = appointment
    @action = action
    @program = appointment.program
    @vip = appointment.vip

    mail(
      to: student.email_address,
      subject: "Appointment #{action == 'selected' ? 'Confirmed' : 'Cancelled'}: #{@vip.name}"
    )
  end
end
