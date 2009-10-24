require 'test_helper'

require 'caligrafo'
require 'ostruct'

class Pessoa < OpenStruct
  include Caligrafo

  arquivo_texto 'arquivo_gerado.txt' do
    secao :cabecalho do |a| 
      campo :idade,  :tamanho => 4
      campo :nome,   :tamanho => 50
      campo :vazio,  10
      campo :altura, 1.7, :tamanho => 5
    end
    secao :telefones do |telefone|
      campo :fone, "Fone#{indice}: #{telefone}"
    end
  end
end

class CaligrafoTest < Test::Unit::TestCase
  def teardown
    File.delete 'arquivo_gerado.txt'
  end
  def test_gerar_arquivo_texto
    pessoa = Pessoa.new :nome => 'Lucas', :idade => 25, :telefones => ['86 2321 2321', '86 3232 1232']
    given_file = pessoa.gerar_arquivo_texto

    File.open('test/arquivo_esperado.txt', 'w') do |file|
      file.puts <<-EOF
0025Lucas                                                       00170
Fone0: 86 2321 2321
Fone1: 86 3232 1232
    EOF
    end
    assert_equal_files 'test/arquivo_esperado.txt', given_file

  end
end
