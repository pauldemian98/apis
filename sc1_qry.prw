#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'

WSRESTFUL SC1_QRY DESCRIPTION 'Consulta Tabela de Solicitação de Compra' FORMAT APPLICATION_JSON

	WSDATA c1Num AS CHARACTER OPTIONAL
	WSMETHOD GET SC1_SOLIC DESCRIPTION "Retorna o detalhamento do Solicitação" WSSYNTAX "/sc1_solic/{c1Num}" PATH "/sc1_solic/{c1Num}" TTALK 'SC1_SOLIC' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET SC1_SOLIC HEADERPARAM c1Num WSSERVICE SC1_QRY

	Local cNum      := self:c1Num
	Local oDetSC

		DBSELECTAREA( "SC1" )
        SC1->(DBSETORDER(14))
		SC1->( DBSEEK(cNum, .F.) )
		oResponse := JsonObject():New()
		oResponse["DetalhamentoSolicitacao"] := {}

		while (SC1->C1_NUM==cNUM) .and. SC1->(!EOF())

			oDetSC := JsonObject():New()

			oDetSC["item"]         := SC1->C1_ITEM
			oDetSC["produto"]      := SC1->C1_DESCRI
			oDetSC["obssimples"]   := SC1->C1_OBS
			oDetSC["Solicitante"]  := SC1->C1_SOLICIT
            oDetSC["Centro_Custo"] := SC1->C1_CC
            oDetSC["NumSc"]        := SC1->C1_NUM

			AADD( oResponse["DetalhamentoSolicitacao"], oDetSC )
			FREEOBJ( oDetSC )
			SC1->(DBSKIP( ))
		ENDDO

		SC1->(DBCLOSEAREA( ))
		self:SetResponse(oResponse)

RETURN
