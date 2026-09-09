require "rails_helper"

RSpec.describe SentrySensitivePathFilter do
  describe ".redact_path" do
    it "redacts tokens in password reset show paths" do
      expect(described_class.redact_path("/passwords/live-reset-token")).to eq("/passwords/[FILTERED]")
    end

    it "redacts tokens in password reset edit paths" do
      expect(described_class.redact_path("/passwords/live-reset-token/edit")).to eq("/passwords/[FILTERED]/edit")
    end

    it "redacts tokens in absolute URLs" do
      url = "https://example.test/passwords/live-reset-token/edit"
      expect(described_class.redact_path(url)).to eq("https://example.test/passwords/[FILTERED]/edit")
    end

    it "leaves the new password form path unchanged" do
      expect(described_class.redact_path("/passwords/new")).to eq("/passwords/new")
    end

    it "leaves unrelated paths unchanged" do
      expect(described_class.redact_path("/session/new")).to eq("/session/new")
    end

    it "returns non-strings unchanged" do
      expect(described_class.redact_path(nil)).to be_nil
    end
  end

  describe ".redact_log" do
    it "redacts path attributes on structured logs" do
      log = Struct.new(:attributes).new({ path: "/passwords/live-reset-token/edit", controller: "PasswordsController" })

      described_class.redact_log(log)

      expect(log.attributes[:path]).to eq("/passwords/[FILTERED]/edit")
      expect(log.attributes[:controller]).to eq("PasswordsController")
    end

    it "redacts token params that bypass filter_parameters" do
      log = Struct.new(:attributes).new({ path: "/home", params: { token: "live-reset-token" } })

      described_class.redact_log(log)

      expect(log.attributes[:params][:token]).to eq("[FILTERED]")
    end
  end

  describe ".redact_event" do
    it "redacts request urls on error events" do
      request = Struct.new(:url, :path, :env).new("https://example.test/passwords/live-reset-token", "/passwords/live-reset-token", { "PATH_INFO" => "/passwords/live-reset-token" })
      event = Struct.new(:request).new(request)

      described_class.redact_event(event)

      expect(event.request.url).to eq("https://example.test/passwords/[FILTERED]")
      expect(event.request.path).to eq("/passwords/[FILTERED]")
      expect(event.request.env["PATH_INFO"]).to eq("/passwords/[FILTERED]")
    end
  end
end

RSpec.describe "Sentry sensitive path hooks" do
  it "redacts password reset tokens from structured logs before send" do
    log = Struct.new(:attributes).new({ path: "/passwords/live-reset-token/edit" })

    result = Sentry.configuration.before_send_log.call(log)

    expect(result.attributes[:path]).to eq("/passwords/[FILTERED]/edit")
  end
end
