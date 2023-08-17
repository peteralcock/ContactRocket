# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'polipus-storage-s3'
  spec.version       = '0.0.1'
  spec.authors       = ['Francesco Laurita']
  spec.email         = ['francesco.laurita@gmail.com']
  spec.summary       = %q(TODO: Write a short summary. Required.)
  spec.description   = %q(TODO: Write a longer description. Optional.)
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'polipus', '~> 0.3', '>= 0.3.0'
  spec.add_runtime_dependency 'aws-s3', '~> 0.6', '>= 0.6.3'

  spec.add_development_dependency 'rake'
end
