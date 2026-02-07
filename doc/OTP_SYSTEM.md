# OTP (One-Time Password) System

This is a production-ready OTP system for phone number verification with comprehensive security features.

## Features

### Security Features
- **Rate Limiting**: Max 3 OTP requests per phone number per hour
- **Verification Attempts**: Max 5 verification attempts per phone number per hour  
- **Secure Comparison**: Uses `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks
- **Auto Expiry**: OTPs expire in 10 minutes
- **Single Use**: OTPs are marked as consumed after successful verification
- **Phone Validation**: Validates international phone number formats
- **Code Generation**: Uses `SecureRandom` for cryptographically secure 6-digit codes

### API Endpoints

#### Send OTP
```
POST /api/v0/otp/send
```

**Request Body:**
```json
{
  "otp": {
    "phone_number": "+1234567890"
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "OTP sent successfully",
    "phone_number": "+123456****",
    "expires_in_minutes": 10,
    "sent_at": "2026-02-07T10:26:35.123Z"
  }
}
```

**Error Response (422):**
```json
{
  "success": false,
  "errors": {
    "phone_number": ["must be a valid phone number format"]
  }
}
```

#### Verify OTP
```
POST /api/v0/otp/verify
```

**Request Body:**
```json
{
  "otp": {
    "phone_number": "+1234567890",
    "code": "123456"
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "OTP verified successfully",
    "phone_number": "+123456****",
    "verified_at": "2026-02-07T10:26:35.123Z"
  }
}
```

**Error Response (422):**
```json
{
  "success": false,
  "errors": {
    "base": ["Invalid OTP code. Please check and try again."]
  }
}
```

## Database Schema

```ruby
create_table "otp_codes" do |t|
  t.string "phone_number", null: false
  t.string "code", null: false
  t.datetime "expires_at", null: false
  t.datetime "consumed_at"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["phone_number"], name: "index_otp_codes_on_phone_number"
end
```

## Architecture

### Controllers
- `Api::V0::OtpController` - Handles API requests and responses
- Skips authentication (OTP endpoints don't require auth)
- Calls operations for all business logic

### Operations
- `Api::V0::Otp::SendOtpOperation` - Handles OTP generation and sending
- `Api::V0::Otp::VerifyOtpOperation` - Handles OTP verification
- Both use contracts for parameter validation
- Follow railway-oriented programming with `Success`/`Failure` results

### Contracts
- `Api::V0::Otp::SendOtpContract` - Validates send OTP requests
- `Api::V0::Otp::VerifyOtpContract` - Validates verify OTP requests
- Include phone number format validation and rate limiting

### Models
- `OtpCode` - Database model with validations, scopes, and helper methods
- Includes methods for checking expiry, consumption, and cleanup

### Background Jobs
- `CleanupExpiredOtpsJob` - Cleans up expired OTP records (should be scheduled regularly)

## Production Considerations

### SMS Integration
The system is designed to integrate with SMS services. In production, update the `send_otp_message` method in `SendOtpOperation`:

```ruby
def send_otp_message(otp_record)
  begin
    SmsService.send_message(
      to: otp_record.phone_number,
      body: "Your verification code is: #{otp_record.code}. Valid for 10 minutes."
    )
    Success()
  rescue SmsService::Error => e
    Rails.logger.error "SMS sending failed: #{e.message}"
    Failure("Failed to send OTP. Please try again.")
  end
end
```

### Rate Limiting
- Implemented at validation level and in-memory cache
- Consider using Redis for distributed systems
- Phone number rate limiting: 3 requests/hour
- Verification attempts: 5 attempts/hour

### Monitoring
- All operations log important events
- Consider adding metrics for:
  - OTP send success/failure rates
  - Verification success/failure rates
  - Rate limiting hits
  - Expired OTP cleanup stats

### Security Best Practices
- ✅ Secure random code generation
- ✅ Timing attack prevention
- ✅ Rate limiting
- ✅ Phone number masking in responses
- ✅ Auto-expiry and cleanup
- ✅ Single-use enforcement

### Cleanup Job
Schedule the cleanup job to run regularly:

```ruby
# In your scheduler (whenever gem, sidekiq, etc.)
CleanupExpiredOtpsJob.perform_later
```

## Testing

Run the comprehensive test suite:
```bash
bundle exec rspec spec/controllers/api/v0/otp_controller_spec.rb
```

## Usage Examples

### Frontend Integration

```javascript
// Send OTP
const sendOtp = async (phoneNumber) => {
  const response = await fetch('/api/v0/otp/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      otp: { phone_number: phoneNumber }
    })
  });
  return response.json();
};

// Verify OTP
const verifyOtp = async (phoneNumber, code) => {
  const response = await fetch('/api/v0/otp/verify', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      otp: { 
        phone_number: phoneNumber,
        code: code
      }
    })
  });
  return response.json();
};
```

### cURL Examples

```bash
# Send OTP
curl -X POST http://localhost:3000/api/v0/otp/send \
  -H "Content-Type: application/json" \
  -d '{"otp": {"phone_number": "+1234567890"}}'

# Verify OTP
curl -X POST http://localhost:3000/api/v0/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"otp": {"phone_number": "+1234567890", "code": "123456"}}'
```

## Error Handling

The system provides detailed error responses for various scenarios:

- Invalid phone number format
- Rate limiting exceeded
- OTP not found
- OTP expired
- OTP already consumed
- Invalid OTP code
- Too many verification attempts

All errors are logged and return appropriate HTTP status codes with descriptive messages.