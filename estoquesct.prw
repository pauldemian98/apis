#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'
#INCLUDE 'FWMVCDEF.CH'

WSRESTFUL ESTCT_POST DESCRIPTION 'ExecAutos para Estoques e Custos' FORMAT APPLICATION_JSON

	WSMETHOD PUT ESTOQUESCT DESCRIPTION "Cadastra Saldo Inicial"         WSSYNTAX "/estoquesct" PATH "/estoquesct"  TTALK "ESTOQUESCT"
	WSMETHOD PUT MTESTOQUES DESCRIPTION "Movimentção de Entrada e Saida" WSSYNTAX "/mtestoques" PATH "/mtestoques"  TTALK "MTESTOQUES"

END WSRESTFUL

//Função que Cadastra Saldo Inicial via API utilizando ExecAuto
WSMETHOD PUT ESTOQUESCT WSSERVICE ESTCT_POST

	Local lRet      := .T.
	Local cJson     := self:GetContent()
	Local oJson     := JsonObject():New()
	Local cError    := {}

	self:SetContentType ('application/json')

	oJson:FromJson(cJson)

	cError  := oJson:FromJson(cJson)

//Se tiver algum erro no Parse, encerra a execução
	IF !Empty(cError)
		SetRestFault(500,'Parser Json Error')
		lRet    := .F.
	ENDIF

//Setando valores da rotina automática
	lMsErroAuto := .F.
	aVetor :={;
		{"B9_FILIAL", oJson["Filial"]  , Nil},;
		{"B9_COD",    oJson["Cod_prod"], Nil},;
		{"B9_LOCAL",  oJson["Local"]   , Nil},;
		{"B9_QINI",   oJson["Qtd_ini"] , Nil},;
		{"B9_NF",     oJson["Nf_num"]  , Nil};
		}

	CONOUT( "ESTOQUESCT"  )

//Iniciando transação e executando saldos iniciais
	Begin Transaction
		MSExecAuto({|x, y| Mata220(x, y)}, aVetor, 3)

		//Se houve erro, mostra mensagem
		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
		EndIf
		
	End Transaction

RETURN lRet

//Função de Movimentação Multipla via API utilizando ExecAuto
WSMETHOD PUT MTESTOQUES WSSERVICE ESTCT_POST

	Local lRet      := .T.
	Local aCab1 := {}
	Local aItem := {}
	Local atotitem:={}
	Local cJson     := self:GetContent()
	Local oJson     := JsonObject():New()
	Local cError    := {}

	Private lMsHelpAuto := .T. // se .t. direciona as mensagens de help
	Private lMsErroAuto := .T. //necessario a criacao

	self:SetContentType ('application/json')

	oJson:FromJson(cJson)

	cError  := oJson:FromJson(cJson)

//Se tiver algum erro no Parse, encerra a execução
	IF !Empty(cError)
		SetRestFault(500,'Parser Json Error')
		lRet    := .F.
	ENDIF

//Setando valores da rotina automática

	aCab1 := {{"D3_TM" ,   oJson["Tipo_mov"]    ,NIL},;
		{"D3_CC" ,   oJson["Centro_custo"],NIL}}

	aItem:={{"D3_COD",   oJson["Cod_Prod"]    ,NIL},;
		{"D3_QUANT", oJson["Quantidade"]  ,NIL},;
		{"D3_LOCAL" ,oJson["Almox"]       ,NIL}}

	aadd(atotitem,aItem)

	CONOUT( "ESTOQUESMT"  )

	MSExecAuto({|x,y,z| MATA241(x,y,z)},aCab1,atotitem,3)

	If lMsErroAuto
		Mostraerro()
		DisarmTransaction()
		break

	EndIf

RETURN lRet
