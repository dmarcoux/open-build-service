# frozen_string_literal: true
# FIXME: Remove this monkey-patch once we use Rails 6.1
# From https://github.com/github/view_component/blob/8487515e2e90b4566a061103d873edf065165c99/lib/view_component/render_monkey_patch.rb

module ViewComponent
  module RenderMonkeyPatch # :nodoc:
    def render(options = {}, args = {}, &block)
      if options.respond_to?(:render_in)
        options.render_in(self, &block)
      else
        super
      end
    end
  end
end
