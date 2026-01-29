module VipsHelper
  def sortable_header(column, label)
    next_direction = if @sort_column == column
      @sort_direction == "asc" ? "desc" : "asc"
    else
      "asc"
    end
    css = "sortable-header inline-flex items-center gap-1 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hover:text-gray-700 cursor-pointer select-none"
    css += " text-gray-900" if @sort_column == column
    indicator = if @sort_column == column
      @sort_direction == "asc" ? " ↑" : " ↓"
    else
      ""
    end
    link_to "#{label}#{indicator}".html_safe, department_program_vips_path(@department, @program, sort: column, direction: next_direction), class: css
  end
end
