#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'

WSRESTFUL SC7_QRY DESCRIPTION 'Consulta Tabela de Pedidos de Compra' FORMAT APPLICATION_JSON

	WSDATA c7Num AS CHARACTER OPTIONAL

	WSMETHOD GET SC7_PEDIDO DESCRIPTION "Retorna o detalhamento do Pedido" WSSYNTAX "/sc7_pedido/{c7Num}" PATH "/sc7_pedido/{c7Num}" TTALK 'SC7_PEDIDO' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET SC7_PEDIDO HEADERPARAM c7Num WSSERVICE SC7_QRY

	Local cNum      := self:c7Num
	Local oDetPedido

		DBSELECTAREA( "SC7" )
        SC7->(DBSETORDER(27))
		SC7->( DBSEEK(cNum, .F.) )
		oResponse := JsonObject():New()
		oResponse["DetalhamentoPedidos"] := {}

		while (SC7->C7_NUM==cNUM) .and. SC7->(!EOF())

			oDetPedido := JsonObject():New()

			oDetPedido["item"]       := SC7->C7_ITEM
			oDetPedido["fornecedor"] := SC7->C7_FORNECE
			oDetPedido["produto"]    := SC7->C7_DESCRI
			oDetPedido["valor"]      := SC7->C7_TOTAL
			oDetPedido["obssimples"] := SC7->C7_OBS
			oDetPedido["obsmemo"]    := SC7->C7_OBSM
			oDetPedido["numsc"]      := SC7->C7_NUMSC
			oDetPedido["numcot"]     := SC7->C7_NUMCOT
			oDetPedido["nummed"]     := SC7->C7_MEDICAO

			AADD( oResponse["DetalhamentoPedidos"], oDetPedido )
			FREEOBJ( oDetPedido )
			SC7->(DBSKIP( ))
		ENDDO

		SC7->(DBCLOSEAREA( ))

		self:SetResponse(oResponse)

RETURN
