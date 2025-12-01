if Rails.env.test?
  module StudentVisit
    class Application < Rails::Application
      # Provide an in-memory credentials object so tests don't need the encrypted master key.
      def credentials
        @credentials_stub ||= begin
          stub = ActiveSupport::InheritableOptions.new
          stub.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "test-secret-key")
          stub.google_maps = ActiveSupport::InheritableOptions.new(
            api_key: ENV["GOOGLE_MAPS_API_KEY"] || "test-google-maps-key"
          )
          stub.lsa_tdx_feedback = nil
          stub
        end
      end
    end
  end
end
