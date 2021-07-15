require 'rails_helper'

RSpec.describe Workflow, type: :model do
  include_context 'a scm payload hash'

  subject do
    described_class.new(workflow: yaml, scm_extractor_payload: github_extractor_payload, token: build(:workflow_token))
  end

  describe '#steps' do
    let(:yaml) do
      { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }] }
    end

    context 'with a supported step' do
      it 'initializes the supported step objects' do
        expect(subject.steps.first).to be_a(Workflow::Step::BranchPackageStep)
      end
    end

    context 'with several supported steps' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { source_project: 'project',
                                              source_package: 'package' } },
                      { 'configure_repositories' => {
                        'project' => 'home:Admin',
                        'repositories' => [{ 'name' => 'openSUSE_Tumbleweed',
                                             'target_project' => 'openSUSE:Factory',
                                             'target_repository' => 'snapshot',
                                             'architectures' => ['x86_64', 'i586'] }]
                      } }] }
      end

      it 'returns an array with two items' do
        expect(subject.steps.count).to be 2
      end
    end

    context 'with one unsupported step' do
      let(:yaml) do
        { 'steps' => [{ 'unsupported_step' => {} },
                      { 'branch_package' => {} }] }
      end

      it 'returns an array with no items' do
        expect { subject }.to raise_error("Invalid workflow step definition: 'unsupported_step' is not a supported step")
      end
    end

    context 'with no steps specified' do
      let(:yaml) do
        {}
      end

      it 'returns an empty array' do
        expect(subject.steps).to be_empty
      end
    end
  end

  describe '#valid' do
    context 'with a supported step' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }] }
      end

      it { expect(subject).to be_valid }
    end

    context 'with several supported steps' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { source_project: 'project',
                                              source_package: 'package' } },
                      { 'configure_repositories' => {
                        'project' => 'home:Admin',
                        'repositories' => [{ 'name' => 'openSUSE_Tumbleweed',
                                             'target_project' => 'openSUSE:Factory',
                                             'target_repository' => 'snapshot',
                                             'architectures' => ['x86_64', 'i586'] }]
                      } }] }
      end

      it { expect(subject).to be_valid }
    end

    context 'with several unsupported steps' do
      let(:yaml) do
        { 'steps' => [{ 'unsupported_step' => {} },
                      { 'branch_package' => {} }] }
      end

      it { expect { subject }.to raise_error("Invalid workflow step definition: 'unsupported_step' is not a supported step") }
    end
  end

  describe '#errors' do
    context 'with a supported step' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }] }
      end

      it { expect(subject.errors).to be_empty }
    end

    context 'with several supported steps' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { source_project: 'project',
                                              source_package: 'package' } },
                      { 'branch_package' => { source_project: 'project',
                                              source_package: 'package' } }] }
      end

      it { expect(subject.errors).to be_empty }
    end

    context 'with several unsupported steps' do
      let(:yaml) do
        { 'steps' => [{ 'unsupported_step' => {} },
                      { 'unsupported_step' => {} },
                      { 'branch_package' => {} }] }
      end

      it 'has several errors' do
        expect { subject }.to raise_error("Invalid workflow step definition: 'unsupported_step' is not a supported step and 'unsupported_step' is not a supported step")
      end
    end
  end

  describe '#filters' do
    ['architectures', 'repositories'].each do |filter|
      context "with #{filter} filters having valid values" do
        let(:yaml) do
          {
            'filters' => {
              filter => { 'only' => ['s390x', 12.3, 567], 'ignore' => ['i586'] }
            }
          }
        end

        it "returns #{filter} filters with 'only' having precedence over 'ignore'" do
          expect(subject.filters).to eq({ "#{filter}": { only: ['s390x', 12.3, 567] } })
        end
      end

      context "with #{filter} filters having non-valid types" do
        let(:yaml) do
          {
            'filters' => {
              filter => { 'onlyyy' => [{ 'non_valid' => ['ppc'] }, 'x86_64'], 'ignore' => ['i586'] }
            }
          }
        end

        it 'raises a user-friendly error message' do
          expect { subject.filters }.to raise_error(Token::Errors::UnsupportedWorkflowFilterTypes, "Filters #{filter} have unsupported keys. only and ignore are the only supported keys.")
        end
      end
    end

    context 'with unsupported filters' do
      let(:yaml) do
        {
          'filters' => {
            'unsupported_1' => { 'only' => ['foo'] },
            'unsupported_2' => { 'ignore' => ['bar'] }
          }
        }
      end

      it 'raises a user-friendly error message' do
        expect { subject.filters }.to raise_error(Token::Errors::UnsupportedWorkflowFilters, 'Unsupported filters: unsupported_1 and unsupported_2')
      end
    end

    context 'without filters' do
      let(:yaml) do
        {}
      end

      it 'returns nothing' do
        expect(subject.filters).to eq({})
      end
    end
  end
end
