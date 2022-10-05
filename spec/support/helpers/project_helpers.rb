# frozen_string_literal: true

module Features
  module ProjectHelpers
    def wait_while_uploading_locations
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop while page.body.include?("Upload in progress.")
      end
    end

    def wait_hidden_half_loading_section(check_loading: false, class_section: ".loading-section")
      wait_loading_section("$('#{class_section}').is(':visible')") if check_loading
      wait_loading_section("!$('#{class_section}').length || $('#{class_section}').is(':not(:visible)')", 0.2)
    end

    def wait_loading_section(script_text, sleep_time=0, default_max_wait_time=Capybara.default_max_wait_time)
      Timeout.timeout(default_max_wait_time) do
        sleep sleep_time
        loop until page.evaluate_script(script_text)
      end
    end
  end
end
