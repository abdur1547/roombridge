# Shrine File Upload Setup and Usage Guide

## Overview

This project uses [Shrine](https://shrinerb.com/) for handling file uploads. Shrine is a toolkit for file attachments in Ruby applications that provides a flexible and composable solution.

## Setup

### 1. Gems Added

```ruby
gem "shrine", "~> 3.6"
gem "aws-sdk-s3", "~> 1.130" # for S3 storage
gem "mini_magick", "~> 5.0" # for image processing
```

### 2. Configuration

Shrine is configured in `config/initializers/shrine.rb` with:
- **Development/Test**: FileSystem storage in `public/uploads/`
- **Production**: AWS S3 storage (requires environment variables)

### 3. Environment Variables (Production)

Add these to your `config/application.yml`:

```yaml
AWS_ACCESS_KEY_ID: "your-access-key"
AWS_SECRET_ACCESS_KEY: "your-secret-key"
AWS_REGION: "us-east-1"
S3_CACHE_BUCKET: "your-app-cache"
S3_STORE_BUCKET: "your-app-store"
```

## Uploaders

### Base Uploader (`app/uploaders/base_uploader.rb`)
- General file upload handling
- 10MB file size limit
- Basic image format validation

### Identity Uploader (`app/uploaders/identity_uploader.rb`)
- For verification documents (selfies, CNIC, etc.)
- 3MB file size limit
- Stricter validations for document quality
- Automatic processing (thumb, medium, compressed versions)

## Adding Attachments to Models

### Basic Setup

1. **Add attachment field to your model:**

```ruby
class User < ApplicationRecord
  include ImageUploader::Attachment.new(:avatar)
  # or for general files:
  # include BaseUploader::Attachment.new(:document)
end
```

2. **Add database column:**

Create a migration:

```ruby
class AddAvatarToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_data, :text
  end
end
```

### Example Implementation

Here's a complete example of adding an avatar to the User model:

#### 1. Migration

```bash
rails generate migration AddAvatarToUsers avatar_data:text
rails db:migrate
```

#### 2. Update User Model

```ruby
class User < ApplicationRecord
  # File attachments
  include ImageUploader::Attachment.new(:profile_picture)
  include IdentityUploader::Attachment.new(:verification_selfie)
  include IdentityUploader::Attachment.new(:cnic_images, multiple: true)
  
  # Your existing code...
  
  def verification_documents_complete?
    verification_selfie.present? && cnic_images.present?
  end
end
```

#### 3. Update Controller (Strong Parameters)

```ruby
class UsersController < ApplicationController
  private

  def user_params
    params.require(:user).permit(
      :phone_number, :full_name, :cnic, :gender, :role,
      :profile_picture, :verification_selfie, cnic_images: []
    )
  end
end
```

#### 4. Update Forms

```erb
<%= form_with model: @user, local: true do |form| %>
  <!-- Profile Picture -->
  <div class="field">
    <%= form.label :profile_picture %>
    <%= form.file_field :profile_picture, accept: "image/*" %>
  </div>
  
  <!-- Verification Selfie -->
  <div class="field">
    <%= form.label :verification_selfie, "Verification Selfie" %>
    <%= form.file_field :verification_selfie, accept: "image/*" %>
  </div>
  
  <!-- CNIC Images -->
  <div class="field">
    <%= form.label :cnic_images, "CNIC Photos (Front & Back)" %>
    <%= form.file_field :cnic_images, multiple: true, accept: "image/*" %>
  </div>
  
  <%= form.submit %>
<% end %>
```

#### 5. Display Images in Views

```erb
<!-- Profile Picture -->
<% if user.profile_picture.present? %>
  <%= image_tag user.profile_picture(:medium).url, alt: "Profile Picture", class: "profile-img" %>
<% end %>

<!-- Verification Selfie (for admin review) -->
<% if user.verification_selfie.present? %>
  <%= image_tag user.verification_selfie(:medium).url, alt: "Verification Selfie" %>
<% end %>

<!-- CNIC Images -->
<% if user.cnic_images.present? %>
  <div class="cnic-images">
    <% user.cnic_images.each_with_index do |cnic_image, index| %>
      <div class="cnic-image">
        <h5>CNIC <%= index == 0 ? 'Front' : 'Back' %></h5>
        <%= image_tag cnic_image(:medium).url %>
      </div>
    <% end %>
  </div>
<% end %>
```

#### Original Example: Adding Avatar to User Model

```ruby
class User < ApplicationRecord
  include ImageUploader::Attachment.new(:avatar)
  
  # Optional: Add validation
  validates :avatar, presence: true
end
```

#### 3. Update Controller (Strong Parameters)

```ruby
class UsersController < ApplicationController
  private

  def user_params
    params.require(:user).permit(:name, :email, :avatar)
  end
end
```

#### 4. Update Forms

```erb
<%= form_with model: @user, local: true do |form| %>
  <div class="field">
    <%= form.label :avatar %>
    <%= form.file_field :avatar, accept: "image/*" %>
  </div>
  
  <%= form.submit %>
<% end %>
```

#### 5. Display Images in Views

```erb
<% if user.avatar.present? %>
  <!-- Display thumbnail -->
  <%= image_tag user.avatar(:thumb).url, alt: "Avatar" %>
  
  <!-- Display medium version -->
  <%= image_tag user.avatar(:medium).url, alt: "Avatar" %>
  
  <!-- Display original -->
  <%= image_tag user.avatar.url, alt: "Avatar" %>
<% end %>
```

## Available Image Versions

When using `ImageUploader`, the following versions are automatically generated:

- `:original` - Original uploaded image
- `:thumb` - 150x150px thumbnail (cropped, JPG format)
- `:medium` - 400x400px medium size (cropped, JPG format)  
- `:large` - 1200x1200px large size (fit within bounds, JPG format)

## Usage Examples

### Multiple File Attachments

For multiple files on a single model:

```ruby
class Post < ApplicationRecord
  include ImageUploader::Attachment.new(:featured_image)
  include BaseUploader::Attachment.new(:document)
end
```

### Array of Attachments

For multiple files of the same type:

```ruby
class Gallery < ApplicationRecord
  include ImageUploader::Attachment.new(:images, multiple: true)
end
```

Migration:
```ruby
add_column :galleries, :images_data, :text
```

View:
```erb
<%= form.file_field :images, multiple: true, accept: "image/*" %>

<!-- Display all images -->
<% gallery.images.each do |image| %>
  <%= image_tag image(:thumb).url %>
<% end %>
```

## File Validation

Common validations you can add:

```ruby
class User < ApplicationRecord
  include ImageUploader::Attachment.new(:avatar)
  
  validates :avatar, presence: true
  
  # Custom validation
  validate :avatar_validation

  private

  def avatar_validation
    return unless avatar.present?
    
    errors.add(:avatar, "must be an image") unless avatar.mime_type.start_with?("image/")
    errors.add(:avatar, "is too small") if avatar.width < 200 || avatar.height < 200
  end
end
```

## Background Jobs

For large file processing, you can use background jobs:

```ruby
class ImageUploader < BaseUploader
  Attacher.promote_block do
    ImageProcessingJob.perform_async(record, name, file_data)
  end
end
```

## Direct Uploads (Advanced)

For direct client-to-S3 uploads, see the [Shrine documentation](https://shrinerb.com/docs/direct-s3).

## Troubleshooting

### Common Issues

1. **Missing MiniMagick**: Install ImageMagick system dependency
2. **AWS Credentials**: Ensure environment variables are set correctly
3. **File Permissions**: Check upload directory permissions in development

### Useful Commands

```bash
# Install ImageMagick (Ubuntu/Debian)
sudo apt-get install imagemagick

# Install ImageMagick (macOS)
brew install imagemagick

# Bundle install after adding gems
bundle install
```

## References

- [Shrine Documentation](https://shrinerb.com/docs/)
- [ImageProcessing Gem](https://github.com/janko/image_processing)
- [AWS SDK for Ruby](https://docs.aws.amazon.com/sdk-for-ruby/)