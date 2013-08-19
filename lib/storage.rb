require 'rubygems'
require 'aws-sdk'
require 'storage/filesystem_store.rb'
require 'storage/s3_store.rb'

module Storage
  @@store_classes = {}

  class Builder
    def initialize(type)
      @type = type
    end

    def build(path_prefix, options={})
      Storage.store_class_for(@type).new(path_prefix, options)
    end
  end

  def self.store(type, path_prefix, options={})
    builder = Builder.new(type)
    builder.build(path_prefix, options)
  end

  def self.add_store_class(label, clazz)
    @@store_classes[label.to_sym] = clazz
  end

  def self.store_class_for(label)
    @@store_classes[label.to_sym]
  end


  add_store_class(:filesystem, Storage::FilesystemStore)
  add_store_class(:s3, Storage::S3Store)
end
