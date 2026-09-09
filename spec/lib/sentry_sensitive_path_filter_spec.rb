# frozen_string_literal: true

require "rails_helper"

RSpec.describe SentrySensitivePathFilter do
  let(:token) { "abc123--signed-password-reset-token" }

  describe ".redact" do
    it "redacts password reset tokens in edit paths" do
      expect(described_class.redact("/passwords/#{token}/edit"))
        .to eq("/passwords/[FILTERED]/edit")
    end

    it "redacts password reset tokens in update paths" do
      expect(described_class.redact("/passwords/#{token}"))
        .to eq("/passwords/[FILTERED]")
    end

    it "redacts tokens in absolute URLs" do
      expect(described_class.redact("https://example.test/passwords/#{token}/edit"))
        .to eq("https://example.test/passwords/[FILTERED]/edit")
    end

    it "redacts the path segment when a query string is present" do
      expect(described_class.redact("/passwords/#{token}/edit?foo=bar"))
        .to eq("/passwords/[FILTERED]/edit?foo=bar")
    end

    it "leaves the new-password collection path unchanged" do
      expect(described_class.redact("/passwords/new")).to eq("/passwords/new")
      expect(described_class.redact("/passwords/new?foo=bar")).to eq("/passwords/new?foo=bar")
    end

    it "leaves unrelated paths unchanged" do
      expect(described_class.redact("/departments/1/programs")).to eq("/departments/1/programs")
    end

    it "returns non-string values unchanged" do
      expect(described_class.redact(nil)).to be_nil
      expect(described_class.redact(404)).to eq(404)
    end
  end

  describe ".apply_to_log" do
    it "redacts path attributes used by ActionController structured logs" do
      log = Sentry::LogEvent.new(
        level: :info,
        body: "PasswordsController#edit",
        attributes: { path: "/passwords/#{token}/edit", controller: "PasswordsController" }
      )

      described_class.apply_to_log(log)

      expect(log.attributes[:path]).to eq("/passwords/[FILTERED]/edit")
      expect(log.attributes[:controller]).to eq("PasswordsController")
      expect(log.body).to eq("PasswordsController#edit")
    end

    it "redacts string-keyed path attributes" do
      log = Sentry::LogEvent.new(
        level: :info,
        body: "PasswordsController#update",
        attributes: { "path" => "/passwords/#{token}" }
      )

      described_class.apply_to_log(log)

      expect(log.attributes["path"]).to eq("/passwords/[FILTERED]")
    end
  end

  describe ".apply_to_breadcrumb" do
    it "redacts tokens in breadcrumb messages and data" do
      breadcrumb = Sentry::Breadcrumb.new(
        message: "GET /passwords/#{token}/edit",
        data: { url: "https://example.test/passwords/#{token}/edit" }
      )

      described_class.apply_to_breadcrumb(breadcrumb)

      expect(breadcrumb.message).to eq("GET /passwords/[FILTERED]/edit")
      expect(breadcrumb.data[:url]).to eq("https://example.test/passwords/[FILTERED]/edit")
    end
  end

  describe ".apply_to_event" do
    it "returns the event unchanged when there is no request" do
      event = instance_double(Sentry::ErrorEvent, request: nil)

      expect(described_class.apply_to_event(event)).to eq(event)
    end

    it "redacts request URLs on error events" do
      request = instance_double(
        Sentry::RequestInterface,
        url: "https://example.test/passwords/#{token}/edit",
        headers: { "Referer" => "https://example.test/passwords/#{token}/edit" },
        data: { referer: "https://example.test/passwords/#{token}/edit" }
      )
      allow(request).to receive(:url=)
      event = instance_double(Sentry::ErrorEvent, request: request)

      described_class.apply_to_event(event)

      expect(request).to have_received(:url=).with("https://example.test/passwords/[FILTERED]/edit")
      expect(request.headers["Referer"]).to eq("https://example.test/passwords/[FILTERED]/edit")
      expect(request.data[:referer]).to eq("https://example.test/passwords/[FILTERED]/edit")
    end
  end

  describe "Sentry hooks" do
    it "filters structured logs with before_send_log" do
      log = Sentry::LogEvent.new(
        level: :info,
        body: "PasswordsController#edit",
        attributes: { path: "/passwords/#{token}/edit" }
      )

      result = Sentry.configuration.before_send_log.call(log)

      expect(result.attributes[:path]).to eq("/passwords/[FILTERED]/edit")
    end
  end
end
