source "https://rubygems.org"
gemspec

gem "chef", git: "https://github.com/chef/chef" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.2.2") # until stable 12.14 is released (won't load new cheffish and such otherwise)

# If you want to customize your local install, you can add stuff to Gemfile.local, which doesn't go to git
eval(IO.read("#{__FILE__}.local")) if File.exist?("#{__FILE__}.local")
