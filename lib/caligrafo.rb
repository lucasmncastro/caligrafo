module Caligrafo
  def self.included(base)
    base.instance_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods
    def criar_arquivo(nome_arquivo, &bloco)
      arquivo = Arquivo.new(nome_arquivo, bloco)
      arquivo.criar_arquivo
      nome_arquivo    
    end
  end

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
      self.pesquisar_por_nome(nome) or raise FormatadorNaoEncontrado, "O formatador #{nome.inspect} nao foi registrado!"
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
    self.registrar :data,     Caligrafo::Formatador::Data
  end

  class Arquivo
    attr_reader   :nome, :bloco
    attr_accessor :objeto, :indice, :linha, :numero_linha, :file

    def initialize(nome, bloco)
      @nome = nome
      @bloco = bloco
      @linha = ''
      @numero_linha = 1
    end

    def criar_arquivo
      # Se eu simplesmente chamasse o bloco, os método de Arquivo
      # não estariam disponíveis. ;)
      self.class.send :define_method, :executar_bloco, &bloco 

      self.objeto = bloco.binding.eval "self"

      File.open(nome, 'w') do |file|
        self.file = file
        executar_bloco
      end

      nome
    end

    def secao(nome, &bloco)
      if self.objeto.respond_to? nome
        objetos = self.objeto.send nome
        objetos = [objetos] if objetos.nil? or !objetos.is_a?(Array)
      else
        objetos = [objeto]
      end

      objetos.each_with_index do |objeto, index|
        self.objeto = objeto
        self.indice = index
        bloco.call objeto
        nova_linha
      end

      self.objeto = self.bloco.binding.eval "self"
    end

    def nova_linha
      self.linha = ''
      self.numero_linha += 1
      self.file.print "\n"
    end

    def imprimir(*args)
      campo = Campo.new(*args)
      valor_campo = campo.valor_para(objeto)

      posicao = campo.posicao
      if posicao
        valor_campo = valor_campo.rjust(posicao - self.linha.size + 1)
      end

      self.linha << valor_campo
      self.file.print valor_campo
    end
  end

  # campo :nome
  # campo :profisao, 'Programador'
  # campo :idade, 46, :posicao => 12
  # campo :tentativas, :alinhamento => :esquerda, :tamanho => 10
  # campo :salario, :formato => :decimal
  # campo 'FIM'
  class Campo
    attr_accessor :nome, :valor, :posicao, :formato, :tamanho, :opcoes_para_formatador

    def initialize(*args)
      opcoes = (args.last.is_a?(Hash) ? args.pop : {})
      @formato = opcoes.delete(:formato)
      @posicao = opcoes.delete(:posicao)
      @tamanho = opcoes.delete(:tamanho)
      @opcoes_para_formatador = opcoes

      if args.first.is_a? Symbol
        @nome = args.first
        @valor = args[1]
      else
        @valor = args.first
      end
    end

    def valor_para(objeto)
      valor = if chamar_metodo?
        begin
          objeto.send(self.nome) 
        rescue Exception => e
          raise "Erro ao chamar #{self.nome.inspect} em #{objeto}: #{e.message}"
        end
      else
        self.valor
      end

      formatar(valor)
    end

    private
    def chamar_metodo?
      (self.nome && self.valor.nil?)
    end
    def formatar(valor)
      if self.formato
        formatador = Formatador.pesquisar_por_nome self.formato
      else
        formatador = Formatador.pesquisar_por_tipo valor.class 
      end

      string = formatador.formatar(valor, self.opcoes_para_formatador)
      string = formatador.preencher(string, self.tamanho) if self.tamanho
      string
    end
  end
end

# TODO criar arquivo de extensoes.
class ::Fixnum
  def espacos
    ' ' * self
  end
end

