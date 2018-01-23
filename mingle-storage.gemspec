description = "Mingle storage API to support filesystem and AWS S3 backed storage"

Gem::Specification.new do |s|
  s.name        = "mingle-storage"
  s.version     = "0.1.0"
  s.date        = "2015-01-26"
  s.summary     = description
  s.description = description
  s.authors     = ["ThoughtWorks Studios"]
  s.email       = "mingle-dev@thoughtworks.com"
  s.files       = Dir.glob("lib/**/*")
  s.homepage    = "http://www.thoughtworks.com/products"
  s.license     = "MIT"

  s.add_runtime_dependency "aws-sdk-s3"
end
