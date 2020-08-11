require "rails_helper"

RSpec.describe StatusMessageComponent, type: :component do
  context 'for anonymous user' do
    let(:anonymous_user) { build(:user_nobody) }
    let(:status_message) { build(:status_message, message: 'Everything is fine', created_at: Time.now) }

    before do
      User.session = anonymous_user
    end

    it do
      expect(render_inline(described_class.new(status_message: status_message)).to_html).to include('Everything is fine')
    end
  end

  context 'for admin user' do
    let(:admin_user) { create(:admin_user) }
    let(:status_message) { create(:status_message, message: 'Everything is fine for an admin') }

    before do
      User.session = admin_user
    end

    it do
      expect(render_inline(described_class.new(status_message: status_message)).to_html).to include('Everything is fine for an admin')
      expect(render_inline(described_class.new(status_message: status_message)).to_html).to include('Remove status message')
    end
  end
end
