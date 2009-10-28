require 'test_helper'
require 'caligrafo'
require 'ostruct'


class Telefone < Caligrafo::Formatador::Base
  def formatar(valor, opcoes={})
    valor.gsub(/(\d\d)(\d\d)(\d\d\d\d)(\d\d\d\d)/,'\1 \2 \3-\4') 
  end
end

Caligrafo::Formatador.registrar :fone, Telefone
  
class CaligrafoTest < Test::Unit::TestCase

  class Portifolio < OpenStruct
    include Caligrafo
  
    def gerar_arquivo(nome_arquivo)
      criar_arquivo nome_arquivo do
        secao :cabecalho do
          imprimir :nome,  :tamanho => 50        # Textos são alinhados à esquerda.
          imprimir :idade, :tamanho => 3         # Números são alinhados à direita com zeros à esquerda.
          imprimir :salario                      # Decimais possuem duas casas decimais.
          imprimir 5.espacos                     # Quando o 1º parâmetro não for um símbolo ele será o conteúdo.
          imprimir numero_linha, :posicao => 100 # 'numero_linha' é um método que guarda a linha corrente do arquivo.
        end
  
        secao :telefones do |telefone|                  # telefones é um método. Escreve uma linha pora cada objeto retornado.
          imprimir :descricao,   "Fone##{indice + 1}: " # Valor fixo sendo usado como 2º parâmetro.
                                                        # O 1º fica sendo usado apenas para descrição.
                                                        # 'indice' é um método que guarda o indice do elemento no array.
          imprimir telefone,     :formato => :fone      # Usando um formatador personalizado.
          imprimir numero_linha, :posicao => 100        # posicao é usado para pular para uma coluna. Até lá tudo será vazio (' ').
        end
  
        secao :sites do |site|                         
          imprimir :downcase                      # Podemos chamar o método do item nas seções.
          imprimir numero_linha, :posicao => 100
        end
  
        secao :rodape do 
          imprimir 'FIM'                          # Uma nova linha é criada sempre que saimos ou entramos numa seção.
          imprimir numero_linha, :posicao => 100  # Como não definimos o tamanho, ficará alinhado à esquerda, mesmo sendo número.
        end
      end
    end
  end

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
