require 'caligrafo'
require 'ostruct'

class Telefone < Caligrafo::Formatador::Base
  def formatar(valor, opcoes={})
    valor.to_s.gsub(/(\d\d)(\d\d)(\d\d\d\d)(\d\d\d\d)/,'\1 \2 \3-\4')
  end
end

Caligrafo::Formatador.registrar :fone, Telefone

class Portifolio < OpenStruct
  include Caligrafo

  arquivo do
    secao :cabecalho do
      campo :tipo,      '01'
      campo :nome,      :tamanho => 50
      campo :idade,     :tamanho => 3
      campo :salario,   :tamanho => 7
      campo :vazio,     7.espacos
      campo :linha
    end
    secao :telefones do
      campo :tipo,      '02'
      campo :descricao, :tamanho => 8
      campo :to_s,      :tamanho => 59, :formato => :fone
      campo :linha
    end
    secao :sites do
      campo :tipo,      '03'
      campo :downcase,  :tamanho => 67
      campo :linha
    end
    secao :rodape do
      campo :tipo,      '04'
      campo :fim,       'FIM'
      campo :vazio,     64.espacos
      campo :linha
    end
  end

  def gerar_arquivo(nome_arquivo)
    escrever_arquivo nome_arquivo do |f|
      f.secao :cabecalho do
        f.imprimir :linha, f.numero_linha
      end
      f.secao :telefones do
        f.imprimir :descricao, "Fone##{f.indice + 1}: "
        f.imprimir :linha, f.numero_linha
      end
      f.secao :sites do
        f.imprimir :linha, f.numero_linha
      end
      f.secao :rodape do
        f.imprimir :linha, f.numero_linha
      end
    end
  end
end

