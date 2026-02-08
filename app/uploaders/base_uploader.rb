class BaseUploader < Shrine
  # Store image dimensions metadata for validation
  plugin :store_dimensions

  # Define processing for different versions
  Attacher.validate do
    validate_max_size 10.megabytes, message: "is too large (max is 10 MB)"
    validate_mime_type_inclusion %w[image/jpeg image/png image/gif image/webp]
  end

  # Process files when they are uploaded
  Attacher.derivatives do |original, **|
    derivatives = {}

    # Create different image sizes if it's an image
    if original.mime_type&.start_with?("image/")
      derivatives[:thumb] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_fill(300, 300)
        .call

      derivatives[:medium] = ImageProcessing::MiniMagick
        .source(original)
        .resize_to_fill(600, 600)
        .call
    end

    derivatives
  end
end
