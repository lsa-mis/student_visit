module DepartmentsHelper
  def format_department_address(department)
    parts = []
    parts << department.street_address if department.street_address.present?
    parts << department.building_name if department.building_name.present?
    parts << "Room #{department.main_office_room_number}" if department.main_office_room_number.present?

    city_state_zip = []
    city_state_zip << department.city if department.city.present?
    city_state_zip << department.state if department.state.present?
    city_state_zip << department.zipcode if department.zipcode.present?

    parts << city_state_zip.join(", ") if city_state_zip.any?

    parts.join(", ")
  end

  def format_department_address_for_map(department)
    parts = []
    parts << department.street_address if department.street_address.present?
    parts << department.city if department.city.present?
    parts << department.state if department.state.present?
    parts << department.zipcode if department.zipcode.present?

    parts.join(", ")
  end

  def google_maps_url(department)
    address = format_department_address_for_map(department)
    return nil if address.blank?

    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(address)}"
  end
end
