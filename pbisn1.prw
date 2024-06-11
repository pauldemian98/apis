#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'

WSRESTFUL PBI_ATIVOS DESCRIPTION "API que retorna dados da tabela SN1 para o conexao do Power B.I - Projeto: Relatorio de Ativos" FORMAT APPLICATION_JSON

    WSDATA cCHAPA AS OPTIONAL

    WSMETHOD GET SN1_MAIN DESCRIPTION "Retorna todos Ativos por Categoria Cadastrados no sistema" PATH "/sn1_main/" WSSYNTAX "/sn1_main/" TTALK "SN1_MAIN" PRODUCES APPLICATION_JSON
    WSMETHOD GET SC7_AUX  DESCRIPTION "Retorna todos os pedidos realizados pela T.I no sistema"   PATH "/sc7_aux/"        WSSYNTAX "/sc7_aux/"        TTALK "SC7_AUX"  PRODUCES APPLICATION_JSON
    WSMETHOD GET SN1_AUX DESCRIPTION "Retorna de forma especi�fica por TAG O ativo cadastrado no sistema" PATH "/sn1_aux/{cCHAPA}" WSSYNTAX "/sn1_aux/{cCHAPA}" TTALK "SN1_AUX" PRODUCES APPLICATION_JSON
    WSMETHOD GET SN1_PEN DESCRIPTION "Retorna de forma especi�fica os ativos pendentes de cadastro de TAG no sistema" PATH "/sn1_pen/" WSSYNTAX "/sn1_pen/" TTALK "SN1_PEN" PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET SN1_MAIN WSSERVICE PBI_ATIVOS

    Local lRet      := .T.
    Local oResultAtv       
    Local aResponse := {}
    Local cQuery    := "" 

        cQuery += " SELECT"
        cQuery += " N1_CHAPA   AS 'TAG',"
        cQuery += " N1_ITEM AS 'ITEM_NF',"
        cQuery += " N1_DESCRIC AS 'DESCRICAO',"
        cQuery += " N1_QUANTD  AS 'QUANTIDADE',"
        cQuery += " N1_NFISCAL AS 'NOTA_FISCAL',"
        cQuery += " SUBSTRING(N1_AQUISIC,7,2)+'/'+SUBSTRING(N1_AQUISIC,5,2)+'/'+SUBSTRING(N1_AQUISIC,1,4) AS 'DATA_AQUISICAO',"
        cQuery += " N1_VLAQUIS AS 'VALOR_AQUISICAO',"
        cQuery += " CTT_DESC01 AS 'CENTRO_CUSTO', "
        cQuery += " CTD_DESC01 AS 'PROJETO' "
        cQuery += " FROM SN1010"
        cQuery += " LEFT JOIN SN3010 ON SN3010.N3_CBASE = SN1010.N1_CBASE AND SN3010.D_E_L_E_T_=' '"
        cQuery += " LEFT JOIN CTT010 ON CTT010.CTT_CUSTO = SN3010.N3_CUSTBEM AND CTT010.D_E_L_E_T_=' '"
        cQuery += " LEFT JOIN CTD010 ON CTD010.CTD_ITEM = SUBSTRING(CTT010.CTT_CUSTO,1,3) AND CTD010.D_E_L_E_T_=' '"
        cQuery += " WHERE SN1010.D_E_L_E_T_=' ' AND SN1010.N1_CHAPA != ' '"
                                                  
        CONOUT( "API Ativos SN1_MAIN - Principal PBI_ATIVOS: "+ cQuery ) 
        MPSysOpenQuery( cQuery, 'QRYATV' )
 
        DbSelectArea('QRYATV')
 
            while !EOF()
 
                oResultAtv := NIL
                oResultAtv := JsonObject():New()
 
                //Definindo campos de Detalhes no Json:
                oResultAtv["TAG"]            := TAG
                oResultAtv["DESCRICAO"]      := DESCRICAO
                oResultAtv["QUANTIDADE"]     := QUANTIDADE
                oResultAtv["NOTA_FISCAL"]    := NOTA_FISCAL
                oResultAtv["DATA_AQUISICAO"] := DATA_AQUISICAO
                oResultAtv["VALOR_AQUISICAO"]:= VALOR_AQUISICAO
                oResultAtv["CENTRO_CUSTO"]   := CENTRO_CUSTO
                oResultAtv["PROJETO"]        := PROJETO

                AADD( aResponse, oResultAtv )
                (DBSKIP( ))
            ENDDO

                oResponse := JsonObject():New()

                //Definindo o CabeÃ§alho do Json que vai conter todo o detalhe
                oResponse["SN1_MAIN"] := aResponse   

                self:SetResponse( ENCODEUTF8( oResponse:ToJson()) ) 
                
    FREEOBJ( oResponse )
    oResponse := NIL

RETURN (lRet)

WSMETHOD GET SC7_AUX WSSERVICE PBI_ATIVOS

    Local lRet      := .T.
    Local oResultAtv       
    Local aResponse := {}
    Local cQuery    := "" 

    cQuery += " SELECT DISTINCT"
    cQuery += " C7_NUM      AS 'PEDIDO',"
    cQuery += " SUBSTRING(C7_EMISSAO,7,2)+'/'+SUBSTRING(C7_EMISSAO,5,2)+'/'+SUBSTRING(C7_EMISSAO,1,4)  AS 'EMISSAO',"
    cQuery += " C7_ITEM     AS 'ITEM',"
    cQuery += " C7_DESCRI   AS 'DESCRICAO',"
    cQuery += " C7_QUANT    AS 'QUANTIDADE',"
    cQuery += " C7_PRECO    AS 'VLR_UNIT',"
    cQuery += " C7_TOTAL    AS 'VLR_TOTAL',"
    cQuery += " A2_NOME     AS 'FORNECEDOR',"
    cQuery += " C7_NUMSC    AS 'SOLICITACAO',"
    cQuery += " C7_NUMCOT   AS 'COTACAO',"
    cQuery += " C7_CONTRA   AS 'CONTRATO',"
    cQuery += " CTD_DESC01 AS 'PROJETO', "
    cQuery += " C7_MEDICAO  AS 'MEDICAO'"
    cQuery += " FROM SC7010"
    cQuery += " LEFT JOIN SA2010 ON SA2010.A2_COD = SC7010.C7_FORNECE AND SA2010.D_E_L_E_T_=' '"
    cQuery += " LEFT JOIN CTD010 ON CTD010.CTD_ITEM = SC7010.C7_ITEMCTA AND CTD010.D_E_L_E_T_=' '"
    cQuery += " WHERE SC7010.D_E_L_E_T_=' ' AND SC7010.C7_USER = '000022' OR SC7010.C7_USER = '000167'  "

        CONOUT( "API Compras SC7_AUX - Auxiliar PBI_ATIVOS: "+ cQuery ) 
        MPSysOpenQuery( cQuery, 'QRYATV' )
 
        DbSelectArea('QRYATV')
 
            while !EOF()
 
                oResultAtv := NIL
                oResultAtv := JsonObject():New()
 
                //Definindo campos de Detalhes no Json:
                oResultAtv["PEDIDO"]            := PEDIDO
                oResultAtv["EMISSAO"]           := EMISSAO
                oResultAtv["ITEM"]              := ITEM
                oResultAtv["DESCRICAO"]         := DESCRICAO
                oResultAtv["QUANTIDADE"]        := QUANTIDADE
                oResultAtv["VLR_UNIT"]          := VLR_UNIT
                oResultAtv["VLR_TOTAL"]         := VLR_TOTAL
                oResultAtv["FORNECEDOR"]        := FORNECEDOR
                oResultAtv["SOLICITACAO"]       := SOLICITACAO
                oResultAtv["COTACAO"]           := COTACAO
                oResultAtv["CONTRATO"]          := CONTRATO
                oResultAtv["MEDICAO"]           := MEDICAO

                AADD( aResponse, oResultAtv )
                (DBSKIP( ))
            ENDDO

                oResponse := JsonObject():New()

                //Definindo o CabeÃ§alho do Json que vai conter todo o detalhe
                oResponse["SC7_AUX"] := aResponse   

                self:SetResponse( ENCODEUTF8( oResponse:ToJson()) ) 
                
    FREEOBJ( oResponse )
    oResponse := NIL

RETURN (lRet)

 

WSMETHOD GET SN1_AUX HEADERPARAM cCHAPA WSSERVICE PBI_ATIVOS

    Local lRet      := .T.
    Local cChapa      := self:cCHAPA
    Local oResultAtv       
    Local aResponse := {}
    Local cQuery    := "" 

        cQuery += " SELECT"
        cQuery += " N1_CHAPA   AS 'TAG',"
        cQuery += " N1_DESCRIC AS 'DESCRICAO',"
        cQuery += " N1_QUANTD  AS 'QUANTIDADE',"
        cQuery += " N1_NFISCAL AS 'NOTA_FISCAL',"
        cQuery += " N1_NSERIE   AS 'SERIE_NF',"
        cQuery += " N3_TIPO    AS  'TIPO',"
        cQuery += " N1_ITEM AS 'ITEM_NF',"
        cQuery += " SUBSTRING(N1_AQUISIC,7,2)+'/'+SUBSTRING(N1_AQUISIC,5,2)+'/'+SUBSTRING(N1_AQUISIC,1,4) AS 'DATA_AQUISICAO',"
        cQuery += " N1_VLAQUIS AS 'VALOR_AQUISICAO',"
        cQuery += " CTT_DESC01 AS 'CENTRO_CUSTO', "
        cQuery += " CTD_DESC01 AS 'PROJETO' "
        cQuery += " FROM SN1010"
        cQuery += " LEFT JOIN SN3010 ON SN3010.N3_CBASE = SN1010.N1_CBASE AND SN3010.D_E_L_E_T_=' '"
        cQuery += " LEFT JOIN CTT010 ON CTT010.CTT_CUSTO = SN3010.N3_CUSTBEM AND CTT010.D_E_L_E_T_=' '"
        cQuery += " LEFT JOIN CTD010 ON CTD010.CTD_ITEM = SUBSTRING(CTT010.CTT_CUSTO,1,3) AND CTD010.D_E_L_E_T_=' '"
        cQuery += " WHERE SN1010.D_E_L_E_T_=' ' AND SN1010.N1_CHAPA = '"+cChapa+"' AND SN1010.N1_CHAPA != ' '"
                                                    
        CONOUT( "API Ativos SN1_AUX - Principal PBI_ATIVOS: "+ cQuery ) 
        MPSysOpenQuery( cQuery, 'QRYATV' )
 
        DbSelectArea('QRYATV')
 
            while !EOF()
 
                oResultAtv := NIL
                oResultAtv := JsonObject():New()
 
                //Definindo campos de Detalhes no Json:
                oResultAtv["TAG"]            := TAG
                oResultAtv["ITEM_NF"]        := ITEM_NF
                oResultAtv["DESCRICAO"]      := DESCRICAO
                oResultAtv["QUANTIDADE"]     := QUANTIDADE
                oResultAtv["NOTA_FISCAL"]    := NOTA_FISCAL
                oResultAtv["SERIE_NF"]       := SERIE_NF
                oResultAtv["TIPO"]           := TIPO
                oResultAtv["DATA_AQUISICAO"] := DATA_AQUISICAO
                oResultAtv["VALOR_AQUISICAO"]:= VALOR_AQUISICAO
                oResultAtv["CENTRO_CUSTO"]   := CENTRO_CUSTO
                oResultAtv["PROJETO"]        := PROJETO

                AADD( aResponse, oResultAtv )
                (DBSKIP( ))
            ENDDO

                oResponse := JsonObject():New()

                //Definindo o CabeÃ§alho do Json que vai conter todo o detalhe
                oResponse["SN1_AUX"] := aResponse   

                self:SetResponse( ENCODEUTF8( oResponse:ToJson()) ) 
                
    FREEOBJ( oResponse )
    oResponse := NIL

RETURN (lRet)

WSMETHOD GET SN1_PEN WSSERVICE PBI_ATIVOS

    Local lRet      := .T.
    Local oResultAtv       
    Local aResponse := {}
    Local cQuery    := "" 

        cQuery += " SELECT DISTINCT"
        cQuery += " N1_CBASE   AS 'TAGANT',"
        cQuery += " N1_DESCRIC AS 'DESCRICAO',"
        cQuery += " N1_QUANTD  AS 'QUANTIDADE',"
        cQuery += " N1_NFISCAL AS 'NOTA_FISCAL',"
        cQuery += " N1_NSERIE   AS 'SERIE_NF',"
        cQuery += " N3_TIPO    AS  'TIPO',"
        cQuery += " N1_ITEM AS 'ITEM_NF',"
        cQuery += " SUBSTRING(N1_AQUISIC,7,2)+'/'+SUBSTRING(N1_AQUISIC,5,2)+'/'+SUBSTRING(N1_AQUISIC,1,4) AS 'DATA_AQUISICAO',"
        cQuery += " N1_VLAQUIS AS 'VALOR_AQUISICAO',"
        cQuery += " CTT_DESC01 AS 'CENTRO_CUSTO', "
        cQuery += " CTD_DESC01 AS 'PROJETO' "
        cQuery += " FROM SN1010"
        cQuery += " LEFT JOIN SN3010 ON SN3010.N3_CBASE = SN1010.N1_CBASE AND SN3010.D_E_L_E_T_=' '"
        cQuery += " LEFT JOIN CTT010 ON CTT010.CTT_CUSTO = SN3010.N3_CUSTBEM AND CTT010.D_E_L_E_T_=' '"
        cQuery += " LEFT JOIN CTD010 ON CTD010.CTD_ITEM = SUBSTRING(CTT010.CTT_CUSTO,1,3) AND CTD010.D_E_L_E_T_=' '"
        cQuery += " WHERE SN1010.D_E_L_E_T_=' ' AND SN1010.N1_CHAPA = ' '"
                                                  
        CONOUT( "API Ativos SN1_PEN - Principal PBI_ATIVOS: "+ cQuery ) 
        MPSysOpenQuery( cQuery, 'QRYATV' )
 
        DbSelectArea('QRYATV')
 
            while !EOF()
 
                oResultAtv := NIL
                oResultAtv := JsonObject():New()
 
                //Definindo campos de Detalhes no Json:
                oResultAtv["TAGANT"]         := TAGANT
                oResultAtv["ITEM_NF"]        := ITEM_NF
                oResultAtv["DESCRICAO"]      := DESCRICAO
                oResultAtv["QUANTIDADE"]     := QUANTIDADE
                oResultAtv["NOTA_FISCAL"]    := NOTA_FISCAL
                oResultAtv["SERIE_NF"]       := SERIE_NF
                oResultAtv["TIPO"]           := TIPO
                oResultAtv["DATA_AQUISICAO"] := DATA_AQUISICAO
                oResultAtv["VALOR_AQUISICAO"]:= VALOR_AQUISICAO
                oResultAtv["CENTRO_CUSTO"]   := CENTRO_CUSTO
                oResultAtv["PROJETO"]        := PROJETO

                AADD( aResponse, oResultAtv )
                (DBSKIP( ))
            ENDDO

                oResponse := JsonObject():New()

                //Definindo o CabeÃ§alho do Json que vai conter todo o detalhe
                oResponse["SN1_PEN"] := aResponse   

                self:SetResponse( ENCODEUTF8( oResponse:ToJson()) ) 
                
    FREEOBJ( oResponse )
    oResponse := NIL

RETURN (lRet)
