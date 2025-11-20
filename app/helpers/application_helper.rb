module ApplicationHelper
  def user_initials(user)
    return "?" unless user&.email_address

    parts = user.email_address.split("@").first.split(/[._-]/)
    if parts.length >= 2
      "#{parts[0][0]}#{parts[1][0]}".upcase
    else
      user.email_address[0..1].upcase
    end
  end

  def user_display_name(user)
    return "Guest" unless user&.email_address
    user.email_address.split("@").first
  end
end
