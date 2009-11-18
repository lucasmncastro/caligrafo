require 'test_helper'
require 'caligrafo'


class FormatadorTest < Test::Unit::TestCase

  def test_formatador_default
    test_formatador Caligrafo::Converter::Base, 12, 10, '12        ' 
  end

  def test_formatador_personalizado
    test_formatador Telefone, '558632323344', 15, '55 86 3232-3344' 
  end

  def test_pesquisar_formatador_inexistente
    assert_raise Caligrafo::Converter::ConverterNotFound do
      Caligrafo::Converter.pesquisar_por_nome! :bolinha
    end

    assert_nothing_raised do
      Caligrafo::Converter.pesquisar_por_nome! :numerico
    end
  end

  private
  def test_formatador(formatador, valor_original, tamanho, valor_esperado)
    f = formatador.new

    valor_formatado  = f.value_to_string valor_original
    valor_preenchido = f.preencher valor_formatado, tamanho
    assert_equal valor_esperado, valor_preenchido
  end

end
