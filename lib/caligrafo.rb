module Caligrafo
  def self.included(base)
    base.instance_eval do
      extend  ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    def arquivo_info 
      @@arquivo_info
    end

    def arquivo_info=(arquivo_info)
      @@arquivo_info = arquivo_info
    end

    def arquivo_texto(nome, &bloco)
      self.arquivo_info = ArquivoInfo.new nome
      bloco.call
    end

    def secao(nome, &bloco)
      info_secao = SecaoInfo.new(nome, bloco)
      self.arquivo_info.secoes << info_secao 
    end

    def campo(nome, valor = nil, opcoes = {})
      self.arquivo_info.secao_atual.campos << CampoInfo.new(nome, valor, opcoes)
    end

    def indice
      self.arquivo_info.indice
    end
  end

  module InstanceMethods
    def gerar_arquivo_texto
      info = self.class.arquivo_info

      nome_arquivo = case info.nome
        when Symbol: send(info.nome)
        when String: info.nome
      end

      File.open(nome_arquivo, 'w') do |file|
        for secao in info.secoes
          if self.respond_to? secao.nome
            objetos = self.send(secao.nome)
            objetos = [objetos] if objetos.nil? or !objetos.is_a?(Array)
          else
            objetos = [self]
          end

          info.secao_atual = secao

          objetos.each_with_index do |objeto, index|
            info.indice = index
            file.puts secao.linha(objeto)
          end
        end
      end

      nome_arquivo
    end
  end

  class ArquivoInfo
    attr_accessor :nome, :secoes, :secao_atual, :indice
    def initialize(nome)
      @nome = nome
      @secoes = []
    end
  end


  # campo :metodo
  # campo :nome, 'alor'
  # campo :metodo, :alinhamento => :esquerda, :tamanho => 10
  class CampoInfo
    attr_accessor :nome, :valor, :opcoes
    def initialize(nome, valor = nil, opcoes = {})
      @nome = nome
      if valor.is_a? Hash
        @valor = nil
        @opcoes = valor
      else
        @valor = valor
        @opcoes = opcoes
      end
    end

    def valor_para(objeto)
      valor = if vazio?
        ' ' * self.valor
      elsif self.valor
        self.valor
      else
        begin
          objeto.send(nome) 
        rescue Exception => e
          raise "Erro ao chamar #{nome} em #{objeto}: #{e.message}"
        end
      end

      formatar(valor)
    end

    private
    def vazio?
      nome == :vazio
    end
    def formatar(valor)
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

      string
    end
  end

  class SecaoInfo
    attr_accessor :nome, :bloco, :campos
    def initialize(nome, bloco)
      @nome = nome
      @bloco = bloco
      @campos = []
    end
    def linha(objeto)
      self.campos.clear
      bloco.call objeto
      self.campos.collect {|campo| campo.valor_para(objeto) }.join
    end
  end
end

