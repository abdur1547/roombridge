class ImageUploader < BaseUploader
  # Additional validations specific to images
  Attacher.validate do
    validate_max_size 5.megabytes, message: "is too large (max is 5 MB)"
    validate_mime_type_inclusion %w[image/jpeg image/png image/gif image/webp image/svg+xml]

    # Validate image dimensions
    validate_max_width 4000
    validate_max_height 4000
    validate_min_width 100
    validate_min_height 100
  end

  # Process image derivatives
  Attacher.derivatives do |original, **|
    derivatives = {}

    if original.mime_type&.start_with?("image/") && original.mime_type != "image/svg+xml"
      # Thumbnail version
      derivatives[:thumb] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_fill(150, 150)
        .format("jpg")
        .call

      # Medium version
      derivatives[:medium] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_fill(400, 400)
        .format("jpg")
        .call

      # Large version
      derivatives[:large] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_limit(1200, 1200)
        .format("jpg")
        .call
    end

    derivatives
  end
end
