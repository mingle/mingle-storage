description = "Mingle storage API to support filesystem and AWS S3 backed storage"

Gem::Specification.new do |s|
  s.name        = "mingle-storage"
  s.version     = "0.0.1"
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = description
  s.description = description
  s.authors     = ["ThoughtWorks Studios"]
  s.email       = "mingle-dev@thoughtworks.com"
  s.files       = Dir.glob("lib/**/*")
  s.homepage    = "http://www.thoughtworks.com/products"
  s.license     = "MIT"

  s.add_dependency "aws-sdk", "~>1.11.3"
end