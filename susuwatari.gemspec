$:.push File.expand_path("../lib", __FILE__)
require "susuwatari/version"

Gem::Specification.new do |s|
  s.name        = "susuwatari"
  s.version     = Susuwatari::VERSION
  s.authors     = ["Benjamin Krause", "Adolfo Builes", "Brian Goad"]
  s.email       = ["bk@benjaminkrause.com", "builes.adolfo@gmail.com", "bdgoad@gmail.com"]
  s.homepage    = "https://github.com/moviepilot/susuwatari"
  s.summary     = %q{Simple Wrapper around the API of webpagetest.org}
  s.description = %q{Allows to schedule tests on webpagetest.org}

  s.rubyforge_project = "susuwatari"

  s.files         = %w[
    .gitignore
    .rvmrc
    Gemfile
    README.md
    Rakefile
    lib/susuwatari.rb
    lib/susuwatari/client.rb
    lib/susuwatari/error.rb
    lib/susuwatari/result.rb
    lib/susuwatari/version.rb
    spec/spec_helper.rb
    spec/susuwatari_spec.rb
    susuwatari.gemspec
    ]
  s.test_files    = %w[
    spec/spec_helper.rb
    spec/susuwatari_spec.rb
    ]
  s.executables   = []
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "crack"
  s.add_runtime_dependency "json", ">= 1.5.0"
  s.add_runtime_dependency "hashie", "~> 1.2.0"
  s.add_runtime_dependency "rest-client", "~> 1.6.7"
end
