# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Import Locations Using CSV", :devise do
  let(:user) { create(:user, password: "Password123") }

  describe "Add locations for service and check pagination" do
    let(:file_path) { "./spec/fixtures/files/locations_to_check_pagination.csv" }
    let(:file) { file_fixture("locations_to_check_pagination.csv").read }

    it "Check pagination", js: true do
      steps_to_upload_csv
      page.attach_file("file", file_path, make_visible: true)
      ProjectLocationsCsvJob.perform_later(file_path, Project.last.id)
      wait_while_uploading_locations
      expect(page).to have_content "Upload Successful"
      expect(page).to have_button("View Uploaded Locations", disabled: false)
      click_button "View Uploaded Locations"
      wait_hidden_half_loading_section
      within ".row.pagination-section" do
        expect(page).to have_content "11 Results"
      end
      within first(".content.added-locations") do
        expect(all(".row.searchbox.single.active-after-request").length).to eq 10
        find("a.new-pagination", text: 2).click
        expect(all(".row.searchbox.single.active-after-request").length).to eq 1
        find("a.new-pagination", text: 1).click
      end
    end
  end

  describe "Add location using invalid csv file" do
    let(:file_path) { "./spec/fixtures/configurations_csv_template.csv" }
    let(:file) { file_fixture("configurations_csv_template.csv").read }

    it "Show unsuccessful message", js: true do
      steps_to_upload_csv
      page.attach_file("file", file_path, make_visible: true)
      ProjectLocationsCsvJob.perform_later(file_path, Project.last.id)
      wait_while_uploading_locations
      expect(page).to have_content "Upload Unsuccessful"
      expect(page).to have_content "Please check that the file formatting matches the template " \
                                   "and that encoding is set to UTF-8."
    end
  end

  private

  def steps_to_upload_csv
    signin(user.email, user.password)
    expect(page).to have_current_path(projects_path)
    click_button "Start A New Project"
    expect(page).to have_current_path(project_path)
    expect(page).to have_button("Start A New Project", disabled: true)
    find(".new-service-type-card", text: "Data Center Colocation").click
    find(".new-service-type-card", text: "Unified Communications").click
    expect(page).to have_button("Start A New Project", disabled: false)
    click_button "Start A New Project"
    wait_hidden_half_loading_section
    find(".upload-download-csv.adjust-top", text: "Upload/Download As CSV").click
    expect(page).to have_content "Upload/Download Known Locations Using CSV"
  end
end


