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

    module LineExtension
      attr_accessor :arquivo, :numero

      def secao
        if @secao
          @secao.nome
        end
      end
       
      def secao?(nome_secao)
        @arquivo.secoes.find {|s| s.nome == nome_secao }
      end

      def ler(nome_campo)
        if @secao
          campo = @secao.campos.find {|c| c.nome == nome_campo }
          campo.ler(self) if campo
        end
      end

      def ler_campos
        if @secao
          hash = {}
          @secao.campos.each {|c| hash[c.nome] = c.ler(self) }
          hash
        end
      end

      def descobrir_secao
        @secao = @arquivo.secoes.find {|s| s.dessa_linha?(self) }
      end
    end
  end
end
