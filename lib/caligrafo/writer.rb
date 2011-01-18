require 'caligrafo/converter'

module Caligrafo
  module Writer
    def escrever_arquivo(nome, &bloco)
      raise 'A estrutura nao foi definida' unless self.class.estrutura
    
      File.open(nome, 'w') do |file|
        file.extend FileExtension
        file.estrutura = self.class.estrutura
        file.linha = ''
        file.numero_linha = 0
        file.objeto = self
        file.bloco = bloco

        bloco.call file
      end

      nome
    end

    module FileExtension
      attr_accessor :objeto, :indice, :linha, :numero_linha, :bloco, :estrutura, :secao_corrente

      def secao(nome, &bloco)
        self.secao_corrente = self.estrutura.secoes.find {|secao| secao.nome == nome }
        raise "Seção #{nome.inspect} não encontrada, verifique a descrição do arquivo." unless self.secao_corrente
         
        if self.objeto.respond_to? nome
          objetos = self.objeto.send nome
          objetos = [objetos] if objetos.nil? or !objetos.is_a?(Array)
        else
          objetos = [objeto]
        end

        objetos.each_with_index do |objeto, index|
          self.objeto = objeto
          self.indice = index

          nova_linha
          bloco.call objeto
          for campo in self.secao_corrente.campos
            valor = (campo.valor_guardado || campo.valor_para(self.objeto))

            # Só preenche o espaço quando o novo valor não for vazio.
            # Isso permite que a inicialização da linha inteira não seja sobrescrita com espaços em branco.
            self.linha[campo.intervalo] = valor if not valor.strip.empty?
          end
          self.print self.linha
          self.print "\n"
        end

        self.objeto = self.bloco.binding.send :eval, "self"
      end

      def nova_linha
        self.linha = ' ' * self.secao_corrente.size
        self.numero_linha += 1
      end
      
      # Sobrescreve a definição do arquivo.
      def imprimir(nome_campo, valor)
        campo = self.secao_corrente.campos.find {|campo_pre_definido| campo_pre_definido.nome == nome_campo} 
        raise ArgumentError, "campo '#{nome_campo}' inexistente na seção '#{self.secao_corrente.nome}'" unless campo
        campo.guarda_valor_para(self.objeto, valor)
      end
    end
  end
end
