# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$:.push(lib) unless $:.include?(lib)
require 'randexp/version'

Gem::Specification.new do |s|
  s.name        = 'randexp'
  s.version     = Randexp::VERSION
  s.authors     = ['Ben Burkert', 'no3rror']
  s.email       = %W(ben@benburkert.com 3rror@tutanota.com)
  s.homepage    = 'https://github.com/no3rror/randexp'
  s.summary     = %q{Library for generating random strings.}
  s.description = %q{Library for generating random strings from regular expressions.}

  s.rubyforge_project = 'randexp'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = %W(README LICENSE TODO)
  s.require_paths    = %W(lib)

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
