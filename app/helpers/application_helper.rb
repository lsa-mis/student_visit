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

    if user.first_name.present? && user.last_name.present?
      "#{user.first_name} #{user.last_name}"
    else
      user.email_address.split("@").first
    end
  end

  # Render page content for a specific page and area
  # Usage: <%= render_page_content("home/index", "welcome_message") %>
  def render_page_content(page_path, area_name, default: nil)
    content = PageContent.for_page(page_path, area_name)

    if content.persisted? && content.content.present?
      content_tag(:div, content.content.to_s, class: "page-content", data: { page: page_path, area: area_name })
    elsif default.present?
      content_tag(:div, default.html_safe, class: "page-content", data: { page: page_path, area: area_name })
    end
  end

  # Safely validate and return a URL for use in link_to
  # Returns the URL if it's safe (starts with http:// or https://), otherwise returns "#"
  def safe_url(url)
    return "#" if url.blank?

    url_string = url.to_s.strip
    return "#" unless url_string.match?(/\Ahttps?:\/\//i)

    url_string
  end
end
