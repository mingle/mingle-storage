description = "Mingle storage API to support filesystem and AWS S3 backed storage"

Gem::Specification.new do |s|
  s.name        = "mingle-storage"
  s.version     = "0.0.11"
  s.date        = "2014-07-28"
  s.summary     = description
  s.description = description
  s.authors     = ["ThoughtWorks Studios"]
  s.email       = "mingle-dev@thoughtworks.com"
  s.files       = Dir.glob("lib/**/*")
  s.homepage    = "http://www.thoughtworks.com/products"
  s.license     = "MIT"

  s.add_dependency "aws-sdk"
end
