# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require "merchant_sidekick"

Gem::Specification.new do |s|
  s.name              = "merchant_sidekick"
  s.version           = MerchantSidekick::VERSION
  s.authors           = ["Juergen Fesslmeier"]
  s.email             = ["jfesslmeier@gmail.com"]
  s.homepage          = ""
  s.summary           = "A light-weight E-commerce plugin."
  s.rubyforge_project = "merchant_sidekick"
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths     = ["lib"]

  s.add_dependency "activerecord", "~> 3.1.0"
  s.add_dependency "money"

  s.add_development_dependency "rspec"
  s.add_development_dependency "sqlite3"

  s.description = <<-EOM
EOM

  s.post_install_message = <<-EOM
NOTE: This is an experimental port of the MerchantSidekick plugin.

https://github.com/chinshr/merchant_sidekick/README.md
EOM

end
