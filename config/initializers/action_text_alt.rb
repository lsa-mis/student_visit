# Allow Action Text / Trix attachments to round-trip an `alt` attribute so
# authors can supply text alternatives for images embedded in rich text.
# Mirrors rails/rails#58337 (not yet in Rails 8.1.4.x).
Rails.application.config.to_prepare do
  if defined?(ActionText::Attachment)
    attrs = ActionText::Attachment::ATTRIBUTES
    unless attrs.include?("alt")
      ActionText::Attachment.send(:remove_const, :ATTRIBUTES)
      ActionText::Attachment.const_set(:ATTRIBUTES, (attrs + [ "alt" ]).freeze)
    end

    ActionText::Attachment.class_eval do
      # Empty string is valid (decorative); only treat a missing attribute as unset.
      def alt
        return node["alt"] if node && !node["alt"].nil?
        node_attributes["alt"]
      end
    end
  end

  if defined?(ActionText::TrixAttachment)
    trix_attrs = ActionText::TrixAttachment::ATTRIBUTES
    unless trix_attrs.include?("alt")
      ActionText::TrixAttachment.send(:remove_const, :ATTRIBUTES)
      ActionText::TrixAttachment.const_set(:ATTRIBUTES, (trix_attrs + [ "alt" ]).freeze)
    end
  end
end
