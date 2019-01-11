require 'rails_helper'
require 'webmock/rspec'

# WARNING: If you change tests make sure you uncomment this line
# and start a test backend. Some of the actions
# require real backend answers for projects/packages.
# CONFIG['global_write_through'] = true

RSpec.describe StagingProjectCopyJob, type: :job, vcr: true do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:staging_workflow_project) { create(:staging_workflow).project }
    let(:original_staging_project) { staging_workflow_project.staging.staging_projects.first }
    let(:staging_project_copy_name) { "#{original_staging_project.name}-copy" }

    it 'copies the staging project' do
      expect(Project.exists?(name: staging_project_copy_name)).to be false
      StagingProjectCopyJob.new.perform(staging_workflow_project.name, original_staging_project.name, staging_project_copy_name)
      expect(Project.exists?(name: staging_project_copy_name)).to be true
    end
  end
end
