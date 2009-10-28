require 'test_helper'
require 'caligrafo'


class LeituraTest < Test::Unit::TestCase

  class Exemplo
    include Caligrafo

    attr_accessor :posicao, :nome, :situacao

    arquivo do
      secao :cabecalho do
        campo :fixo,        '01'
        campo :com_tamanho, :tamanho => 5
        campo :com_fim,     :fim => 10 
        campo :com_range,   :posicao => 11..15
        campo :com_inicio,  :inicio => 20, :formato => :decimal
      end

      secao :corpo do
        campo :vazio
      end
    end

   def smile
     ':)'
   end

    def ler(nome_arquivo)
      ler_arquivo nome_arquivo do |linha|
        if linha.secao? :cabecalho
          self.posicao = linha.ler(:fixo)
          self.nome = linha.ler_campos[:com_tamanho]
        end
      end
    end
  end

  def test_ler_arquivo
    arquivo = 'test/tmp.txt'
    File.open(arquivo, 'w') do |file|
      file.puts <<-EOF
0100005:)          150
      EOF
    end
    
    exemplo = Exemplo.new
    exemplo.ler(arquivo)
    assert_equal '01', exemplo.posicao
    assert_equal '00005', exemplo.nome
  end

  def test_dsl_com_informacoes_do_arquivo
    arquivo = Exemplo.instance_variable_get "@arquivo"
    assert arquivo
    
    cabecalho = arquivo.secoes.first
    assert_equal :cabecalho, cabecalho.nome

    registros = arquivo.secoes.last
    assert_equal :corpo, registros.nome

    campos = cabecalho.campos
    assert_equal 5, campos.size

    test_campo campos[0], :nome => :fixo, :inicio => 1, :fim => 2, :tamanho => 2, :valor_padrao => '01'
    test_campo campos[1], :nome => :com_tamanho, :inicio => 3, :fim => 7, :tamanho => 5
    test_campo campos[2], :nome => :com_fim, :inicio => 8, :fim => 10, :tamanho => 3
    test_campo campos[3], :nome => :com_range, :inicio => 11, :fim => 15, :tamanho => 5
    test_campo campos[4], :nome => :com_inicio, :inicio => 20, :fim => nil, :tamanho => nil

    assert_equal Caligrafo::Formatador::Decimal, campos[4].formatador.class
  end

  private
  def test_campo(campo, comparacoes = {})
    for campo_do_campo, valor_esperado in comparacoes
      assert_equal valor_esperado, campo.send(campo_do_campo), "campo #{campo.nome} nao bateu no #{campo_do_campo}"
    end
  end
end
