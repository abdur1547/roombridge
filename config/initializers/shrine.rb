require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/s3" if defined?(Aws)

# Shrine configuration
if Rails.env.production?
  # Production configuration with S3
  Shrine.storages = {
    cache: Shrine::Storage::S3.new(
      bucket: ENV["S3_CACHE_BUCKET"] || "your-app-cache",
      region: ENV["AWS_REGION"] || "us-east-1",
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    ),
    store: Shrine::Storage::S3.new(
      bucket: ENV["S3_STORE_BUCKET"] || "your-app-store",
      region: ENV["AWS_REGION"] || "us-east-1",
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
  }
else
  # Development and test configuration with filesystem
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store")
  }
end

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data # extracts metadata for assigned cached files
Shrine.plugin :validation_helpers
Shrine.plugin :determine_mime_type
Shrine.plugin :derivatives # enables processing of multiple versions

# Add image processing if MiniMagick is available
if defined?(MiniMagick)
  require "image_processing/mini_magick"
end
