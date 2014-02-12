require 'spec_helper'

describe ResearchOutputRepository do 
  subject(:repository) { ResearchOutputRepository.new }

  context '#get_r4d' do
    describe 'pagination' do
      describe 'default limit' do
        let(:results) { repository.get_r4d({type: "r4d", id: "GB-1-203193", detail: "full"}) }
        specify { expect(results.length).to be 4 }
      end

      context 'per_project' do
        describe '1' do
          let(:results) { repository.get_r4d({type: "r4d", id: "GB-1-203193", detail: "full"}, :limit => 1, :per_project => 1) }
          subject { results[0]['research_outputs'] }
          specify { expect(subject.length).to be 1 }
        end

        describe '5' do
          let(:results) { repository.get_r4d({type: "r4d", id: "GB-1-203193", detail: "full"}, :limit => 1, :per_project => 5) }
          subject { results[0]['research_outputs'] }
          specify { expect(subject.length).to be 5 }
        end
      end
      
      describe 'limit 1' do
        let(:results) { repository.get_r4d({type: "r4d", id: "GB-1-203193", detail: "full"}, :limit => 1) }
        specify { expect(results.length).to be 1 }
      end
    end
  end
end
