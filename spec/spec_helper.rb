# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.extend SampleJson
  config.include SampleJson
  config.filter_run_excluding :broken => true
end

module SpecValues
  TOTAL_R4D_DOCUMENTS = 35182
  TOTAL_ELDIS_DOCUMENTS = 37515 
  TOTAL_DOCUMENTS = TOTAL_R4D_DOCUMENTS + TOTAL_ELDIS_DOCUMENTS

  TOTAL_R4D_THEMES = 34835
  TOTAL_ELDIS_THEMES = 1112
  TOTAL_THEMES = TOTAL_R4D_THEMES + TOTAL_ELDIS_THEMES

  TOTAL_ELDIS_COUNTRIES = 216
  TOTAL_R4D_COUNTRIES = 192
  TOTAL_COUNTRIES = TOTAL_ELDIS_COUNTRIES + TOTAL_R4D_COUNTRIES

  TOTAL_ELDIS_REGIONS = 10
  TOTAL_R4D_REGIONS = 26 # There are 27 in total, but only 26 linked
                         # against documents in our test data.
  TOTAL_REGIONS = TOTAL_ELDIS_REGIONS + TOTAL_R4D_REGIONS
end
