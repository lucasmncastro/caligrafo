module Caligrafo
  module Reader
    def ler_arquivo(nome, &bloco)
      estrutura = (self.is_a?(Class) ? self.estrutura : self.class.estrutura)
      raise 'A estrutura nao foi definida' unless estrutura

      File.open(nome, 'r') do |file|
        while linha = file.gets
          linha.extend LineExtension
          linha.arquivo = estrutura
          linha.descobrir_secao
          linha.numero = file.lineno

          bloco.call linha
        end
      end
    end

    def criar_arquivo_retorno(arquivo_origem, arquivo_destino, &bloco)
      estrutura = (self.is_a?(Class) ? self.estrutura : self.class.estrutura)
      raise 'A estrutura nao foi definida' unless estrutura

      destino = File.new(arquivo_destino, 'w')
      File.open(arquivo_origem, 'r') do |file|
        while linha = file.gets
          linha.extend LineExtension
          linha.arquivo = estrutura
          linha.descobrir_secao
          linha.numero = file.lineno

          bloco.call linha

          destino.print linha
        end
      end
      destino.close
    end

    module LineExtension
      attr_accessor :arquivo, :numero

      def secao
        @secao.nome
      end
       
      def secao?(nome_secao)
        @arquivo.secoes.find {|s| s.nome == nome_secao }
      end

      def ler(nome_campo)
        self.campo(nome_campo).ler(self)
      end

      def preencher(nome_campo, novo_valor)
        campo = self.campo(nome_campo)
        self[campo.intervalo] = campo.formatar(novo_valor)
        self
      end

      def ler_campos
        hash = {}
        @secao.campos.each {|c| hash[c.nome] = c.ler(self) }
        hash
      end

      def descobrir_secao
        @secao = @arquivo.secoes.find {|s| s.dessa_linha?(self) }
      end

      def campo(nome_campo)
        campo = @secao.campos.find {|c| c.nome == nome_campo }
        raise ArgumentError, "campo com o nome '#{nome_campo}' nao foi encontrado." unless campo
        campo
      end
    end
  end
end
