module StudentsHelper
  def sort_link(column, label, current_sort:, current_direction:)
    direction = (current_sort == column && current_direction == "asc") ? "desc" : "asc"
    path = department_program_students_path(@department, @program, sort: column, direction: direction)
    indicator = if current_sort == column
      current_direction == "asc" ? " ↑" : " ↓"
    else
      ""
    end
    link_to "#{label}#{indicator}", path, class: "text-gray-700 hover:text-gray-900 font-medium"
  end
end
