# frozen_string_literal: true

# Enable coverage 
def coverage
	ENV['COVERAGE'] = 'PartialSummary'
end

def test
	system("rspec") or abort
end
