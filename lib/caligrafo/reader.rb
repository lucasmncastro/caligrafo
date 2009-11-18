module Caligrafo
  module Reader
    def ler_arquivo(nome, &bloco)
      raise 'A estrutura nao foi definida' unless self.class.estrutura

      File.open(nomee, 'r') do |file|
        while linha = file.gets
          linha.extend LineExtension
          linha.arquivo = self.class.estrutura
          linha.descobrir_secao

          bloco.call linha
        end
      end
    end

    module LineExtension
      attr_accessor :arquivo

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