require 'bigdecimal'

module Caligrafo
  module Converter
    def self.formatadores
      @@formatadores ||= {}
    end
  
    def self.registrar(nome, formatador)
      self.formatadores[nome] = formatador.new
    end

    def self.pesquisar_por_nome(nome)
      self.formatadores[nome]
    end

    def self.pesquisar_por_nome!(nome)
      resultado = self.pesquisar_por_nome(nome) 
      raise ConverterNotFound, "O formatador #{nome.inspect} nao foi registrado!" unless resultado
      resultado
    end

    def self.pesquisar_por_tipo(tipo)
      formatador   = self.formatadores.values.find { |f| f.tipos.include? tipo }
      formatador ||= self.formatadores[:default]
    end

    class ConverterNotFound < Exception; end

    class Base
      attr_reader :tipos, :alinhamento, :preenchimento

      def initialize
        @tipos = []
        @alinhamento = :esquerda
        @preenchimento = ' '
      end

      def value_to_string(valor)
        valor.to_s
      end

      def string_to_value(string)
        string.strip
      end

      def preencher(string, tamanho)
        if self.alinhamento == :direita
          string = string.rjust tamanho, self.preenchimento
        else
          string = string.ljust tamanho, self.preenchimento
        end
 
        string = string[0..(tamanho - 1)] if string.size > tamanho
        string
      end
    end

    class Data < Base
      def tipos
        [Date]
      end

      def value_to_string(valor)
        valor.strftime('%Y%m%d')
      end

      def string_to_value(string)
        Date.strptime string, '%Y%m%d'
      end
    end

    class Numerico < Base
      def initialize
        @tipos = [Fixnum]
      end

      def string_to_value(string)
        string.to_i
      end

      def alinhamento
        :direita
      end

      def preenchimento
        '0'
      end
    end

    class Decimal < Numerico
      def initialize
         @tipos = [Float, BigDecimal]
      end

      def value_to_string(valor)
         ('%.2f' % valor.to_f).gsub('.','')
      end
    end

    self.registrar :default,  Base
    self.registrar :alpha,    Base
    self.registrar :numerico, Numerico
    self.registrar :decimal,  Decimal
    self.registrar :data,     Data
  end
end
