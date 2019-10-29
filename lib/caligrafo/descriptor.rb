module Caligrafo
  module Descriptor
    def arquivo(opcoes={}, &bloco)
      @arquivo = Arquivo.new(opcoes)
      @arquivo.executar bloco
    end

    def estrutura
      @arquivo
    end

    module Helpers
      def executar(bloco)
        # We disabled VERBOSE to don't generate "redefined method" warnings.
        #
        # In this case, redefine the method is required to the DSL works how
        # was planned.
        warn_level = $VERBOSE
        $VERBOSE = nil

        self.class.send :define_method, :executar_bloco, &bloco
        self.executar_bloco

        $VERBOSE = warn_level
      end

      def extrair_opcoes(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end
    end

    class Arquivo
      include Helpers

      attr_accessor :bloco, :chave_secao

      def initialize(opcoes={})
        @chave_secao = opcoes[:chave_secao]
      end

      def secoes
        @secoes ||= []
      end

      def secao(nome, &bloco)
        secao = Secao.new(nome, bloco, self)
        secoes << secao
        secao.executar bloco
      end
    end

    class Secao
      include Helpers

      attr_accessor :nome, :bloco, :arquivo

      def initialize(nome, bloco, arquivo)
        @nome = nome
        @bloco = bloco
        @arquivo = arquivo
      end

      def campos
        @campos ||= []
      end

      def campo(nome, *opcoes)
        campo = Campo.new(self, nome, *opcoes)
        self.campos << campo
        campo
      end

      def size
        size = 0
        @campos.each {|field| size += field.tamanho }
        size
      end

      def dessa_linha?(linha)
        if arquivo.chave_secao
          campo_chave = campos.find {|s| s.nome == arquivo.chave_secao } 
          raise "Chave de seção não localizada: #{arquivo.chave_secao}" unless campo_chave

          index = campos.index(campo_chave)
          anteriores = campos[0..index]
          inicio = anteriores.map(&:tamanho).inject(0){|a,b| a + b } - 1
          fim    = inicio + campo_chave.valor_padrao.size - 1
          linha[inicio .. fim] == campo_chave.valor_padrao
        else
          linha =~ /^#{campos.first.valor_padrao}/
        end
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
          when Range then
            self.inicio = posicao.first
            self.fim    = posicao.last
          when Fixnum then
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
        intervalo.count
      end

      def intervalo
        fim = self.fim || 0
        (self.inicio - 1)..(fim - 1)
      end

      def ler(linha)
        substring = linha[self.intervalo]

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
        @valor_guardado ||= nil
      end
      
      def valor_para(objeto)
        valor = if objeto.respond_to? self.nome
          objeto.send(self.nome) 
        else
          self.valor_padrao
        end

        formatar(valor)
      rescue => e
        raise "Erro ao preencher valor para #{objeto.inspect} no campo #{nome} da secao #{secao.nome}: #{e.message}"
      end

      def formatar(valor)
        formatador = self.formatador
        formatador ||= Converter.pesquisar_por_tipo valor.class 

        string = formatador.value_to_string(valor)
        string = formatador.preencher(string, self.tamanho) if self.tamanho
        string
      end

      private
      
      def chamar_metodo?
        @chamar_metodo
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
