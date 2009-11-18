module Caligrafo
  module Formatador
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
      raise FormatadorNaoEncontrado, "O formatador #{nome.inspect} nao foi registrado!" unless resultado
      resultado
    end

    def self.pesquisar_por_tipo(tipo)
      formatador   = self.formatadores.values.find { |f| f.tipos.include? tipo }
      formatador ||= self.formatadores[:default]
    end

    class FormatadorNaoEncontrado < Exception; end

    class Base
      attr_reader :tipos, :alinhamento, :preenchimento

      def initialize
        @tipos = []
        @alinhamento = :esquerda
        @preenchimento = ' '
      end

      def formatar(valor, opcoes = {})
        valor.to_s
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

      def formatar(valor, opcoes={})
        valor.strftime('%Y%m%d')
      end
    end

    class Numerico < Base
      def initialize
        @tipos = [Fixnum]
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
         @tipos = [Float]
      end

      def formatar(valor, opcoes = {})
         ('%.2f' % valor).gsub('.','')
      end
    end

    self.registrar :default,  Base
    self.registrar :alpha,    Base
    self.registrar :numerico, Numerico
    self.registrar :decimal,  Decimal
    self.registrar :data,     Data
  end
end
