#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'

WSRESTFUL SC8_QRY DESCRIPTION 'Consulta Tabela de Cotações' FORMAT APPLICATION_JSON

	WSDATA c8NumSc  AS CHARACTER OPTIONAL

	WSMETHOD GET SC8_COTPROC DESCRIPTION "Retorna o Processo de Cotação" WSSYNTAX "/sc8_cotproc/{c8NumSc}" PATH "/sc8_cotproc/{c8NumSc}" TTALK 'SC8_COTPROC' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET SC8_COTPROC HEADERPARAM c8NumSc WSSERVICE SC8_QRY

	Local cNumSc     := self:c8NumSc
	Local cQuery    := ""
	Local aResponse := {}
	Local oMapCot

	cQuery := "SELECT "
	cQuery += "C8_NUM, "
	cQuery += "C8_FORNOME, "
	cQuery += "C8_CONTATO, "
	cQuery += "SUM(C8_TOTAL) AS TOTAL, "
	cQuery += "C8_NUMPED "
	cQuery += " FROM SC8010"
	cQuery += " WHERE SC8010.D_E_L_E_T_=' ' AND C8_TOTAL > 0 "

	if !EMPTY( cNumSc )
		cQuery += "AND C8_NUMSC ='"+cNumSc+"' "
		cQuery += "GROUP BY C8_NUM, C8_FORNOME, C8_CONTATO, C8_NUMPED "
		cQuery += "ORDER BY C8_NUM;"
	ENDIF

	CONOUT( "Mapa de Cotação API - Piacentini: "+ cQuery)

	DBUSEAREA( .T., "TOPCONN", TCGENQRY(,,cQuery), "SC8", .F.,.T. )
	DBSELECTAREA( "SC8" )
	SC8->(DBGOTOP( ))

	if SC8->(EOF())

		SC8->(DBCLOSEAREA(  ))
		oResponse := JsonObject():New()
		oResponse["Mapa_Cotacao"] := {}
		self:SetResponse( oResponse:ToJson() )
		FREEOBJ( oResponse )
		oResponse := NIL
		RETURN ( lRet )

	else
		while SC8->(!EOF())

			oMapCot := NIL
			oMapCot := JsonObject():New()
			oMapCot["num_cot"]    := SC8->C8_NUM
			oMapCot["fornecedor"] := SC8->C8_FORNOME
			oMapCot["contato"]    := SC8->C8_CONTATO
			oMapCot["valor_total"]:= TOTAL
			oMapCot["pedido"]     := SC8->C8_NUMPED

			AADD( aResponse, oMapCot )
			SC8->(DBSKIP( ))
		ENDDO

		SC8->(DBCLOSEAREA( ))

		oResponse := JsonObject():New()
		oResponse["Mapa_Cotacao"] := aResponse
		self:SetResponse( ENCODEUTF8( oResponse:ToJson()) )
	ENDIF

RETURN
