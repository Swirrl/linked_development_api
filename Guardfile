guard :rspec,
  all_on_start:     true, # Enabled while the project is young :-)
  all_after_pass:   true,
  focus_on_failed:  false, # This is just annoying
  cmd:              "spring rspec --format Fuubar" do

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }

  
  # Temporary mapping to use the DocumentService spec as in integration test
  watch(%r{^app/application/(.+)\.rb$}) { |m| "spec/application/#{m[1]}_spec.rb" }
  watch(%r{^app/models/(.+)_repository\.rb$}) { |m| "spec/application/#{m[1]}_service_spec.rb" }
end
