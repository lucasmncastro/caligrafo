require 'test_helper'
require 'caligrafo'
require 'ostruct'


class Portifolio < OpenStruct
  include Caligrafo

  def gerar_arquivo(nome_arquivo)
    escrever_arquivo nome_arquivo do |f|
      f.secao :cabecalho do
        f.imprimir :nome,  :tamanho => 50        # Textos são alinhados à esquerda.
        f.imprimir :idade, :tamanho => 3         # Números são alinhados à direita com zeros à esquerda.
        f.imprimir :salario                      # Decimais possuem duas casas decimais.
        f.imprimir 5.espacos                     # Quando o 1º parâmetro não for um símbolo ele será o conteúdo.
        f.imprimir f.numero_linha, :posicao => 100 # 'numero_linha' é um método que guarda a linha corrente do arquivo.
      end

      f.secao :telefones do |telefone|                    # telefones é um método. Escreve uma linha pora cada objeto retornado.
        f.imprimir :descricao,   "Fone##{f.indice + 1}: " # Valor fixo sendo usado como 2º parâmetro.
                                                          # O 1º fica sendo usado apenas para descrição.
                                                          # 'indice' é um método que guarda o indice do elemento no array.
        f.imprimir telefone,  :formato => :fone           # Usando um formatador personalizado.
        f.imprimir f.numero_linha, :posicao => 100        # posicao é usado para pular para uma coluna. Até lá tudo será vazio (' ').
      end

      f.secao :sites do |site|                         
        f.imprimir :downcase                      # Podemos chamar o método do item nas seções.
        f.imprimir :numero_linha, f.numero_linha, :posicao => 100
      end

      f.secao :rodape do 
        f.imprimir 'FIM'                          # Uma nova linha é criada sempre que saimos ou entramos numa seção.
        f.imprimir f.numero_linha, :posicao => 100  # Como não definimos o tamanho, ficará alinhado à esquerda, mesmo sendo número.
      end
    end
  end
end

class Telefone < Caligrafo::Formatador::Base
  def formatar(valor, opcoes={})
    valor.gsub(/(\d\d)(\d\d)(\d\d\d\d)(\d\d\d\d)/,'\1 \2 \3-\4') if valor
  end
end
Caligrafo::Formatador.registrar :fone, Telefone

class CaligrafoTest < Test::Unit::TestCase
  def test_gerar_arquivo
    pessoa = Portifolio.new :nome => 'Lucas da Silva', 
                            :idade => 25, 
                            :salario => 90_000.5,
                            :telefones => ['558622223333', '558699991234'],
                            :sites => ['Google.com', 'Blip.tv', 'SlideShare.net']
    pessoa.gerar_arquivo 'test/arquivo_gerado.txt'
    assert_file_content  'test/arquivo_gerado.txt', <<-EOF
Lucas da Silva                                    0259000050                                        1
Fone#1: 55 86 2222-3333                                                                             2
Fone#2: 55 86 9999-1234                                                                             3
google.com                                                                                          4
blip.tv                                                                                             5
slideshare.net                                                                                      6
FIM                                                                                                 7
    EOF
  end
end
