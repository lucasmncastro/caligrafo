$:.unshift File.expand_path(File.dirname(__FILE__))

require 'caligrafo/descriptor'
require 'caligrafo/writer'
require 'caligrafo/reader'
require 'caligrafo/integer'

module Caligrafo
  include Writer
  include Reader

  def self.included(base)
    base.extend Descriptor
    base.extend Reader
  end
end

Integer.send :include, Caligrafo::Integer
