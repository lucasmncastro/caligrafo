$:.unshift File.expand_path(File.dirname(__FILE__))

require 'caligrafo/descriptor'
require 'caligrafo/writer'
require 'caligrafo/reader'
require 'caligrafo/fixnum'

module Caligrafo
  include Writer
  include Reader

  def self.included(base)
    base.extend Descriptor
  end
end

Fixnum.send :include, Caligrafo::Fixnum
