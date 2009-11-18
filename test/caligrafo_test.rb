require 'test_helper'
require 'example'

class CaligrafoTest < Test::Unit::TestCase
  def test_description
    
  end


  def test_writing
    pessoa = Portifolio.new :nome => 'Lucas da Silva', 
                            :idade => 25, 
                            :salario => 90_000.5,
                            :telefones => ['558622223333', '558699991234'],
                            :sites => ['Google.com', 'Blip.tv', 'SlideShare.net']

    pessoa.gerar_arquivo 'test/arquivo_gerado.txt'
    assert_file_content  'test/arquivo_gerado.txt', <<-EOF
01Lucas da Silva                                    0259000050       1
02Fone#1: 55 86 2222-3333                                            2
02Fone#2: 55 86 9999-1234                                            3
03google.com                                                         4
03blip.tv                                                            5
03slideshare.net                                                     6
04FIM                                                                7
    EOF
  end

  def test_description
    arquivo = Portifolio.estrutura
    assert arquivo
    
    cabecalho = arquivo.secoes.first
    assert_equal :cabecalho, cabecalho.nome

    registros = arquivo.secoes.last
    assert_equal :rodape, registros.nome

    campos = cabecalho.campos
    assert_equal 6, campos.size
  end


end
