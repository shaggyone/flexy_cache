# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flexy_cache/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Victor Zagorski"]
  gem.email         = ["victor@zagorski.ru"]
  gem.description   = %q{Caches values for method calls. When cached value is expired, tries to refresh it. If refresh is failed for some reason, returns value stored in cache. Usefull for interacting with unstable web services, providing some unfrequently changed data.}
  gem.summary       = %q{Caches values. When expired tries to refresh it. If failed returns cached value.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flexy_cache"
  gem.require_paths = ["lib"]
  gem.version       = FlexyCache::VERSION

  # Dependencies
  gem.add_dependency 'redis'
  gem.add_dependency 'activesupport'
end
