class IdentityUploader < BaseUploader
  # Stricter validations for identity documents
  Attacher.validate do
    validate_max_size 3.megabytes, message: "is too large (max is 3 MB)"
    validate_mime_type_inclusion %w[image/jpeg image/png image/webp]

    # Validate image dimensions for better quality
    validate_max_width 3000
    validate_max_height 3000
    validate_min_width 300
    validate_min_height 300
  end

  # Process identity document derivatives
  Attacher.derivatives do |original, **|
    derivatives = {}

    if original.mime_type&.start_with?("image/")
      # Thumbnail for admin review
      derivatives[:thumb] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_fill(200, 200)
        .format("jpg")
        .call

      # Medium version for detailed review
      derivatives[:medium] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_limit(800, 800)
        .format("jpg")
        .call

      # Compressed version to save storage
      derivatives[:compressed] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_limit(1200, 1200)
        .quality(85)
        .format("jpg")
        .call
    end

    derivatives
  end
end
