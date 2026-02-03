# Quick Reference: Adding File Attachments to Models

## Step-by-Step Guide

### 1. Choose Your Uploader

- **ImageUploader**: For images (photos, avatars, etc.)
- **BaseUploader**: For general files (documents, PDFs, etc.)

### 2. Add Database Column

```bash
# For single attachment
rails generate migration AddAvatarToUsers avatar_data:text

# For multiple attachments  
rails generate migration AddImagesToGalleries images_data:text

rails db:migrate
```

### 3. Update Your Model

```ruby
# Single image attachment
class User < ApplicationRecord
  include ImageUploader::Attachment.new(:avatar)
end

# Single document attachment
class User < ApplicationRecord
  include BaseUploader::Attachment.new(:resume)
end

# Multiple image attachments
class Gallery < ApplicationRecord
  include ImageUploader::Attachment.new(:images, multiple: true)
end
```

### 4. Update Controller

```ruby
# Add to strong parameters
def user_params
  params.require(:user).permit(:name, :email, :avatar)
end

# For multiple files
def gallery_params
  params.require(:gallery).permit(:title, images: [])
end
```

### 5. Update Forms

```erb
<!-- Single file -->
<%= form.file_field :avatar, accept: "image/*" %>

<!-- Multiple files -->
<%= form.file_field :images, multiple: true, accept: "image/*" %>
```

### 6. Display in Views

```erb
<!-- Single image with different versions -->
<% if user.avatar.present? %>
  <%= image_tag user.avatar(:thumb).url, class: "avatar-thumb" %>
  <%= image_tag user.avatar(:medium).url, class: "avatar-medium" %>
  <%= image_tag user.avatar.url, class: "avatar-original" %>
<% end %>

<!-- Multiple images -->
<% gallery.images.each do |image| %>
  <%= image_tag image(:thumb).url %>
<% end %>

<!-- File download link -->
<% if user.resume.present? %>
  <%= link_to "Download Resume", user.resume.url, target: "_blank" %>
<% end %>
```

## Common Patterns

### User Avatar

```ruby
# Migration
rails generate migration AddAvatarToUsers avatar_data:text

# Model
class User < ApplicationRecord
  include ImageUploader::Attachment.new(:avatar)
end

# View
<%= image_tag user.avatar(:thumb).url if user.avatar.present? %>
```

### Product Images

```ruby
# Migration  
rails generate migration AddImagesToProducts images_data:text

# Model
class Product < ApplicationRecord
  include ImageUploader::Attachment.new(:images, multiple: true)
end

# View
<% product.images.each do |image| %>
  <%= image_tag image(:medium).url %>
<% end %>
```

### Document Upload

```ruby
# Migration
rails generate migration AddDocumentToUsers document_data:text

# Model
class User < ApplicationRecord
  include BaseUploader::Attachment.new(:document)
end

# View
<% if user.document.present? %>
  <%= link_to "Download", user.document.url %>
<% end %>
```

## Available Image Versions

- `:thumb` - 150x150px (cropped)
- `:medium` - 400x400px (cropped)  
- `:large` - 1200x1200px (fit)
- No version = original file

## File Size Limits

- **ImageUploader**: 5MB max
- **BaseUploader**: 10MB max

Customize in the uploader files if needed.