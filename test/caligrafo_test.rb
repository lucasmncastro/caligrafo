require 'test_helper'
require 'example'

class CaligrafoTest < Test::Unit::TestCase
  def setup
    @portifolio = Portifolio.new :nome => 'Lucas da Silva', 
                                 :idade => 25, 
                                 :salario => 90_000.5,
                                 :telefones => ['558622223333', '558699991234'],
                                 :sites => ['Google.com', 'Blip.tv', 'SlideShare.net']
  end

  def test_writing
    @portifolio.gerar_arquivo 'test/arquivo_gerado.txt'
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

  def test_numero_linha
    counter = 1
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      assert counter, linha.numero
      counter += 1
    end
    assert 7, counter
  end

  def test_ler_da_classe
    Portifolio.ler_arquivo 'test/example.txt' do |linha|
      assert true
      break
    end
  end

  def test_secao
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      nome_secao = case linha.numero
        when 1    then :cabecalho
        when 2..3 then :telefones
        when 4..6 then :sites
        when 7    then :rodape
      end    
      assert_equal nome_secao, linha.secao, "secao nao eh #{nome_secao.inspect}"
    end
  end

  def test_secao?
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      assert linha.secao?(linha.secao)
    end
  end

  def test_ler_campo
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      case linha.secao
      when :cabecalho
        assert_equal '01',             linha.ler(:tipo)
        assert_equal 'Lucas da Silva', linha.ler(:nome)
        assert_equal 25,               linha.ler(:idade)
      end
    end
  end

  def test_preencher_campo
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      case linha.secao
      when :cabecalho
        linha.preencher(:nome, 'Lucas de Castro')
        assert_equal 'Lucas de Castro', linha.ler(:nome)
        assert_equal "01Lucas de Castro                                   0259000050       1\n", linha
      end
    end
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
