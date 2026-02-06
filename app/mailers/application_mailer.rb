class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@student-visit.lsa.umich.edu"
  layout "mailer"

  before_action :attach_inline_lsa_logo

  private

  def attach_inline_lsa_logo
    return if attachments.inline["LSA_Logo.png"].present?

    attachments.inline["LSA_Logo.png"] = {
      mime_type: "image/png",
      content: File.binread(Rails.root.join("app", "assets", "images", "LSA_Logo.png"))
    }
  end
end
