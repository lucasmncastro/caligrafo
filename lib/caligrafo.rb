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

  @@formatos = {
    :decimal => Proc.new do |valor|
       ('%.2f' % valor).gsub('.','')
    end 
  }

  def self.formatos
    @@formatos
  end

  def self.formato(nome, &bloco)
    @@formatos[nome] = bloco
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
    attr_accessor :nome, :valor, :opcoes
    def initialize(*args)
      @opcoes = (args.last.is_a?(Hash) ? args.pop : {})

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

    def posicao
      opcoes[:posicao]
    end
    private
    def chamar_metodo?
      (self.nome && self.valor.nil?)
    end
    def formatar(valor)
       string = valor.to_s
      if opcoes[:formato]
        string = Caligrafo.formatos[opcoes[:formato]].call valor
      else
        if valor.is_a? Float 
          string = ('%.2f' % valor).gsub('.','')
        else
          string = valor.to_s
        end
  
        if tamanho = opcoes[:tamanho]
          if [Fixnum, Float].include? valor.class
            opcoes[:alinhamento]   ||= :direita
            opcoes[:preenchimento] ||= '0'
          else
            opcoes[:alinhamento]   ||= :esquerda
            opcoes[:preenchimento] ||= ' '
          end
          alinhamento = opcoes[:alinhamento]
          preenchimento = opcoes[:preenchimento]
  
          if opcoes[:alinhamento] == :direita
            string = string.rjust tamanho, preenchimento
          else
            string = string.ljust tamanho, preenchimento
          end
  
          string = string[0..(tamanho - 1)] if string.size > tamanho
        end
      end

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

