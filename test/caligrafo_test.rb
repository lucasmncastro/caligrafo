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
    expected = <<-EOF
01Lucas da Silva                                    0259000050       1
02Fone#1: 55 86 2222-3333                                            2
02Fone#2: 55 86 9999-1234                                            3
03google.com                                                         4
03blip.tv                                                            5
03slideshare.net                                                     6
04FIM                                                                7
    EOF
    assert_file_content  'test/arquivo_gerado.txt', win_eol(expected)
  end

  def test_tamanho_campo
    cabecalho, telefones, sites, rodape = Portifolio.estrutura.secoes

    tipo, nome,  idade, salario, vazio, linha = cabecalho.campos
    assert_equal  2, tipo.tamanho
    assert_equal 50, nome.tamanho
    assert_equal  3, idade.tamanho
    assert_equal  7, salario.tamanho
    assert_equal  1, linha.tamanho

    tipo, descricao, numero, linha = telefones.campos
    assert_equal  2, tipo.tamanho
    assert_equal  8, descricao.tamanho
    assert_equal 59, numero.tamanho
    assert_equal  1, linha.tamanho

    tipo, site, linha = sites.campos
    assert_equal  2, tipo.tamanho
    assert_equal 67, site.tamanho
    assert_equal  1, linha.tamanho

    tipo, fim, vazio, linha = rodape.campos
    assert_equal  2, tipo.tamanho
    assert_equal  3, fim.tamanho
    assert_equal 64, vazio.tamanho
    assert_equal  1, linha.tamanho
  end

  def test_intervalo_campo
    _cabecalho, telefones, _sites, _rodape = Portifolio.estrutura.secoes

    tipo, descricao, numero, linha = telefones.campos
    assert_equal 0..1,   tipo.intervalo
    assert_equal 2..9,   descricao.intervalo
    assert_equal 10..68, numero.intervalo
    assert_equal 69..69, linha.intervalo
  end

  def test_tamanho_secao
    cabecalho, telefones, sites, rodape = Portifolio.estrutura.secoes
    assert_equal 70, cabecalho.size
    assert_equal 70, telefones.size
    assert_equal 70, sites.size
    assert_equal 70, rodape.size
  end

  def test_imprimir_com_campo_inexistente
    def @portifolio.gerar_arquivo(nome_arquivo)
      escrever_arquivo nome_arquivo do |f|
        f.secao :cabecalho do
          f.imprimir :esse_campo_nao_existe, 'qualquer bobeira'
        end
      end
    end

    assert_raise ArgumentError do
      @portifolio.gerar_arquivo 'test/arquivo_gerado.txt'
    end
  end

  def test_escrever_arquivo_com_linha_predefinida
    def @portifolio.gerar_arquivo(nome_arquivo)
      escrever_arquivo nome_arquivo do |f|
        f.secao :cabecalho do
          f.imprimir :linha, f.numero_linha
        end
        f.secao :telefones do |t|
          f.linha = "02                                                                   ?"
          f.imprimir :descricao, "Fone##{f.indice + 1}: "
        end
        f.secao :sites do
          f.imprimir :linha, f.numero_linha
        end
        f.secao :rodape do
          f.imprimir :linha, f.numero_linha
        end
      end
    end

    @portifolio.gerar_arquivo 'test/arquivo_gerado.txt'
    expected = <<-EOF
01Lucas da Silva                                    0259000050       1
02Fone#1: 55 86 2222-3333                                            ?
02Fone#2: 55 86 9999-1234                                            ?
03google.com                                                         4
03blip.tv                                                            5
03slideshare.net                                                     6
04FIM                                                                7
    EOF
    assert_file_content  'test/arquivo_gerado.txt', win_eol(expected)
  end

  def test_numero_linha
    counter = 0
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      counter += 1
      assert_equal counter, linha.numero
    end
    assert_equal 7, counter
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

  def test_secao_na_segunda_coluna
    Exemplo2.ler_arquivo 'test/example_2.txt' do |linha|
      nome_secao = case linha.numero
        when 1    then :cabecalho
        when 2..3 then :corpo
        when 4    then :rodape
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

  def test_preencher_campo_com_linha_resetada
    @portifolio.ler_arquivo 'test/example.txt' do |linha|
      case linha.secao
      when :cabecalho
        linha.preencher(:nome, 'Lucas de Castro')
        assert_equal 'Lucas de Castro', linha.ler(:nome)
        assert_equal "01Lucas de Castro                                   0259000050       1\n", linha
      end
    end
  end

  def test_criar_arquivo_retorno
    Portifolio.ler_arquivo 'test/example.txt', :arquivo_retorno => 'test/retorno.txt' do |linha|
      case linha.secao
      when :cabecalho
        linha.preencher(:nome, 'Lucas de Castro')
      end
    end
    expected = <<-EOF
01Lucas de Castro                                   0259000050       1
02Fone#1: 55 86 2222-3333                                            2
02Fone#2: 55 86 9999-1234                                            3
03google.com                                                         4
03blip.tv                                                            5
03slideshare.net                                                     6
04FIM                                                                7
    EOF
    assert_file_content  'test/retorno.txt', win_eol(expected)
  end

  def test_criar_arquivo_retorno_limitando_secoes
    Portifolio.ler_arquivo 'test/example.txt', 
                           :arquivo_retorno => 'test/retorno.txt', 
                           :secoes_retorno => [:cabecalho, :rodape] do |linha|
      case linha.secao
      when :cabecalho
        linha.preencher :nome, 'Lucas de Castro'
      when :rodape
        linha.preencher :linha, linha.numero_retorno
      end
    end
    expected = <<-EOF
01Lucas de Castro                                   0259000050       1
04FIM                                                                2
    EOF
    assert_file_content  'test/retorno.txt', win_eol(expected)
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

  private

  def win_eol(string)
    string.gsub("\n", Caligrafo::WINDOWS_EOL)
  end

end
