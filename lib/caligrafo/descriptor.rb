module Caligrafo
  module Descriptor
    def arquivo(&bloco)
      @@arquivo = Arquivo.new
      @@arquivo.executar bloco
    end

    def estrutura
      @@arquivo
    end

    module Helpers
      def executar(bloco)
        self.class.send :define_method, :executar_bloco, &bloco
        self.executar_bloco
      end

      def extrair_opcoes(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end
    end

    class Arquivo
      include Helpers

      attr_accessor :bloco

      def secoes
        @secoes ||= []
      end

      def secao(nome, &bloco)
        secao = Secao.new(nome, bloco)
        secoes << secao
        secao.executar bloco
      end
    end

    class Secao
      include Helpers

      attr_accessor :nome, :bloco

      def initialize(nome, bloco)
        @nome = nome
        @bloco = bloco
      end

      def campos
        @campos ||= []
      end

      def campo(nome, *opcoes)
        campo = Campo.new(self, nome, *opcoes)
        self.campos << campo
        campo
      end

      def dessa_linha?(linha)
        linha =~ /^#{campos.first.valor_padrao}/
      end
    end

    class Campo
      include Helpers

      attr_accessor :secao, :nome, :inicio, :fim, :formatador, :valor_padrao

      def initialize(secao, nome, *args)
        self.secao = secao
        self.nome = nome
        configura(args) 
      end
      
      def configura(args)
        opcoes = extrair_opcoes(args)
        self.inicio     = opcoes.delete(:inicio)
        self.fim        = opcoes.delete(:fim)
        self.formatador = Converter.pesquisar_por_nome(opcoes.delete(:formato))

        valor_padrao = args.first
        if valor_padrao
          self.valor_padrao = valor_padrao
          opcoes[:tamanho]  = self.valor_padrao.to_s.size
        else
          @chamar_metodo = true
        end
        
        if opcoes.key? :posicao
          posicao = opcoes.delete(:posicao)
          case posicao
          when Range:
            self.inicio = posicao.first
            self.fim    = posicao.last
          when Fixnum:
            self.inicio = calcular_inicio - posicao
            self.fim = self.inicio + posicao
          else
            raise ArgumentError, 'use um Range ou Fixnum para definir a posicao do campo.'
          end
        else
          ajustar_inicio_e_fim(opcoes.delete(:tamanho))
        end
      end

      def tamanho
        if self.fim and self.inicio
          self.fim - self.inicio + 1 # Inclui o ultimo elemento
        else
          nil
        end
      end

      def ler(linha)
        fim = self.fim || 0
        substring = linha[(self.inicio - 1)..(fim - 1)]

        if formatador
          formatador.string_to_value substring
        else
          Converter.formatadores[:default].string_to_value substring
        end
      end
      
      def guarda_valor_para(objeto, valor)
        @valor_guardado = formatar(valor)
      end
      
      def valor_guardado
        @valor_guardado
      end
      
      def valor_para(objeto)
        valor = if objeto.respond_to? self.nome
          objeto.send(self.nome) 
        else
          self.valor_padrao
        end

        formatar(valor)
      rescue => e
        raise "Erro ao preencher valor para #{objeto.inspect} no campo #{self.inspect}: #{e.message}"
      end

      private
      
      def chamar_metodo?
        @chamar_metodo
      end
      
      def formatar(valor)
        formatador = self.formatador
        formatador ||= Converter.pesquisar_por_tipo valor.class 

        string = formatador.value_to_string(valor)
        string = formatador.preencher(string, self.tamanho) if self.tamanho
        string
      end

      def ajustar_inicio_e_fim(tamanho)
        self.inicio ||= calcular_inicio
        self.fim    ||= self.inicio + tamanho - 1 if tamanho
      end

      def calcular_inicio
        campo_anterior = self.secao.campos.last
        if campo_anterior
          ultima_posicao = campo_anterior.fim 
          (ultima_posicao ? ultima_posicao + 1 : 1)
        else
          1
        end
      end
    end
  end
end
