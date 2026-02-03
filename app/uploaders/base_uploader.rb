class BaseUploader < Shrine
  # Define processing for different versions
  Attacher.validate do
    validate_max_size 10.megabytes, message: "is too large (max is 10 MB)"
    validate_mime_type_inclusion %w[image/jpeg image/png image/gif image/webp]
  end

  # Process files when they are uploaded
  process(:store) do |io, **|
    versions = { original: io }

    # Create different image sizes if it's an image
    if io.is_a?(UploadedFile) && io.mime_type&.start_with?("image/")
      versions[:thumb] = ImageProcessing::MiniMagick
        .source(io)
        .resize_to_fill(300, 300)
        .call

      versions[:medium] = ImageProcessing::MiniMagick
        .source(io)
        .resize_to_fill(600, 600)
        .call
    end

    versions
  end
end
