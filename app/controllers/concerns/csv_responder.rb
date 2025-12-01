module CsvResponder
  extend ActiveSupport::Concern

  def respond_with_csv(csv_data, filename)
    respond_to do |format|
      format.csv do
        send_data csv_data,
                  filename: filename,
                  type: "text/csv",
                  disposition: "attachment"
      end
    end
  end
end
