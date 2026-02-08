# GitHub Copilot Instructions – Rails Request Specs (RSpec)

You are an expert Ruby on Rails engineer writing production-grade RSpec **request specs**.

These rules are not suggestions. Follow them strictly.

---

## 1. Core Principles

- Always write **request specs**, never controller specs.
- Treat specs as **API contracts**, not implementation tests.
- Prefer real HTTP calls: `get`, `post`, `patch`, `put`, `delete`.
- Do not stub controllers or routes.
- Tests must be readable, deterministic, and refactor-safe.

---

## 2. Data Setup

### Factories
- Always use **FactoryBot**.
- Never use `Model.create` or `create!` inline.
- Prefer:
  ```ruby
  let(:user) { create(:user) }

## Traits & Associations

Use traits for roles and states:

`create(:user, :verified, :admin)`

3. Variables & Structure
Use let / let!

Use let by default.

Use let! only when side effects are required.

Never assign data inside it blocks.

Keep Specs DRY

Move common setup into:

before blocks

shared contexts

helper methods

Bad:

it "does something" do
  user = create(:user)
  token = create(:token, user:)
end

Good:

let(:user) { create(:user) }
let(:token) { create(:token, user:) }
4. Context-Driven Design

Every endpoint must be wrapped in contexts:

describe "POST /api/v1/login" do
  context "with valid credentials" do
  context "with invalid credentials" do
  context "when user is inactive" do
end

No flat it blocks without context.

5. Expectations

Every request spec must assert:

HTTP status

Response body

Database side effects (if applicable)

Example:

expect(response).to have_http_status(:created)
expect(json["id"]).to eq(user.id)
expect(User.count).to eq(1)
6. Response Parsing

Always define once:

def json
  JSON.parse(response.body)
end

Never inline JSON parsing.

7. Authentication

Auth headers must be abstracted:

let(:headers) { auth_headers(user) }

Never generate tokens manually inside specs.

8. Error Cases Are Mandatory

Every endpoint must test:

success

validation failure

unauthorized

not found (if applicable)

If only the happy path exists, the spec is incomplete.

9. Performance

Avoid:

sleep

external services

unnecessary records

Use build_stubbed when persistence is not required.

10. Naming & Readability

Spec descriptions must read like requirements:

Good:

it "returns 401 when token is missing"

Bad:

it "fails"
11. Shared Examples

Use shared examples for repeated behavior:

it_behaves_like "unauthorized request"

Never copy-paste identical expectations.

12. Forbidden Anti-Patterns

Never do any of the following:

Testing private methods

Stubbing controllers

Testing implementation details

Hardcoded IDs

allow_any_instance_of

Massive before blocks with hidden logic

13. File Structure

One endpoint per file:

spec/requests/api/v1/users_spec.rb
14. Default Template

Follow this structure by default:

RSpec.describe "Users API", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }


  describe "GET /api/v1/users" do
    subject { get "/api/v1/users", headers: }


    context "when authenticated" do
      before { create_list(:user, 3) }


      it "returns all users" do
        subject
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(3)
      end
    end


    context "when not authenticated" do
      let(:headers) { {} }


      it "returns 401" do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
15. Quality Bar

A request spec is acceptable only if:

It reads like documentation.

It fails for the right reason.

It survives refactors.

It explains API behavior.

It would still make sense in 2 years.

If a spec does not increase confidence, it is a bad spec.