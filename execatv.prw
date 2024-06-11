#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'
#INCLUDE 'FWMVCDEF.CH'

WSRESTFUL EXECATV_PUT DESCRIPTION 'ExecAutos para Estoques e Custos' FORMAT APPLICATION_JSON

	WSMETHOD PUT EX_INC DESCRIPTION "Inclusao de Ativo"  WSSYNTAX '/ex_inc' PATH '/ex_inc' TTALK 'EX_INC'
	WSMETHOD PUT EX_ALT DESCRIPTION "Alteracao de Ativo" WSSYNTAX '/ex_alt' PATH '/ex_alt' TTALK 'EX_ALT'

END WSRESTFUL

//Função para Inclusão de Ativos via ExecAuto
WSMETHOD PUT EX_INC WSSERVICE EXECATV_PUT

	Local lRet   := .T.
	Local cJson  := self:GetContent()
	Local oJson  := JsonObject():New()
	Local cError := {}

	//Para MsExecAuto
	Local aParam := {}
	Local aCab := {}
	Local aItens := {}

	//Dados Para a API - Chumbados
	Local cAtvGroup       := '0001'
	Local cAtvItem        := '0001'
	Local cAtvQtd         := 1
	Local cAtvHist        := 'DEPRECIACAO EQUIPTO INFORMATICA'
	Local cAtvContContab  := '1231020006'
	Local cAtvTipo        := '10'

	//Dados para a API - Json
	//Local cAtvDataAqc    := CTOD(oJson["DATA_AQUISICAO"])

	Private lMsHelpAuto := .T. // se .t. direciona as mensagens de help
	Private lMsErroAuto := .F. //necessario a criacao

	self:SetContentType('application/json')

	oJson:FromJson(cJson)

	cError := oJson:FromJson(cJson)

	IF !Empty(cError)
		SetRestFault(500, 'Erro ao Ler o json')
		lRet := .F.
	ENDIF

	//SN1
	aCab := {}
	AAdd(aCab,{"N1_CBASE" ,PADR(oJson["TAG"], TamSX3('N1_CBASE')[1]) ,NIL})
	AAdd(aCab,{"N1_ITEM" ,  cAtvItem ,NIL})
	//AAdd(aCab,{"N1_AQUISIC", cAtvDataAqc ,NIL})
	AAdd(aCab,{"N1_DESCRIC", PADR(oJson["DESCRICAO"], TamSX3('N1_DESCRIC')[1]) ,NIL})
	AAdd(aCab,{"N1_QUANTD" , cAtvQtd ,NIL})
	AAdd(aCab,{"N1_CHAPA" , PADR(oJson["TAG"], TamSX3('N1_CHAPA')[1]) ,NIL})
	AAdd(aCab,{"N1_GRUPO" , cAtvGroup ,NIL})
	AAdd(aCab,{"N1_NFISCAL" , PADR(oJson["NOTA_FISCAL"], TamSX3('N1_NFISCAL')[1]) ,NIL})
	AAdd(aCab,{"N1_NSERIE" , PADR(oJson["SERIE_NF"], TamSX3('N1_NSERIE')[1]) ,NIL})

	//SN3
	aItens := {}
	AAdd(aItens,{;
		{"N3_CBASE"   , PADR(oJson["TAG"], TamSX3('N3_CBASE')[1]) ,NIL},;
		{"N3_ITEM"    , cAtvItem ,NIL},;
		{"N3_TIPO"    , cAtvTipo ,NIL},;
		{"N3_BAIXA"   , "0" ,NIL},;
		{"N3_HISTOR"  , cAtvHist ,NIL},;
		{"N3_CCONTAB" , cAtvContContab ,NIL},;
		{"N3_CUSTBEM" , PADR(oJson["CUST_BEM"], TamSX3('N3_CUSTBEM')[1]) ,NIL},;
		{"N3_CDEPREC" , cAtvContContab ,NIL},;
		{"N3_CDESP"   , cAtvContContab ,NIL},;
		{"N3_CCORREC" , cAtvContContab ,NIL},;
		{"N3_CCUSTO"  , PADR(oJson["CUST_BEM"], TamSX3('N3_CUSTBEM')[1]) ,NIL},;
		{"N3_VORIG1"  , oJson["VALOR_AQUISICAO"],NIL};
		})


	//Array contendo os parametros do F12
	aParam := {}
	aAdd( aParam, {"MV_PAR01", 1} ) //Pergunta 01 - Mostra Lanc. Contab? 1 = Sim ; 2 = Não
	aAdd( aParam, {"MV_PAR02", 1} ) //Pergunta 02 - Repete Chapa ? 1 = Sim ; 2 = Não
	aAdd( aParam, {"MV_PAR03", 1} ) //Pergunta 03 - Copia Valores 1 = Todos ; 2 = Sem Acumulados
	aAdd( aParam, {"MV_PAR04", 1} ) //Pergunta 04 - Exibe Painel de Detalhes ? 1 = Sim ; 2 = Não
	aAdd( aParam, {"MV_PAR05", 1} ) //Pergunta 05 - Contabilizar Online? 1 = Sim ; 2 = Não
	aAdd( aParam, {"MV_PAR06", 1} ) //Pergunta 06 - Aglutina Lancamentos? 1 = Sim ; 2 = Não

	CONOUT("Inclusao de Ativo")

	Begin Transaction

		MSExecAuto({|w,x,y,z| Atfa012(w,x,y,z)},aCab,aItens,3,aParam)

		// VALIDAÇÃO DE ERRO NA ROTINA
		If (!lMsErroAuto) // OPERAÇÃO FOI EXECUTADA COM SUCESSO
			ConOut(PadC("Automatic routine successfully ended", 80))
		Else // OPERAÇÃO EXECUTADA COM ERRO
			If (!IsBlind()) // COM INTERFACE GRÁFICA
				MostraErro()
			Else // EM ESTADO DE JOB
				cError := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO

				ConOut(PadC("Automatic routine ended with error", 80))
				ConOut("Error: "+ cError)
			EndIf
		EndIf

		CONOUT("Ativo Incluido com sucesso")

	End Transaction

RETURN lRet

//Função para Alteração de Ativos via API sem ExecAuto
WSMETHOD PUT EX_ALT WSSERVICE EXECATV_PUT

	Local lRet   := .T.
	Local cJson  := self:GetContent()
	Local oJson  := JsonObject():New()
	Local cError := {}

	//Para MsExecAuto
	Local aItens := {}

	//Dados Para a API - Chumbados
	Local cAtvHist        := 'DEPRECIACAO EQUIPTO INFORMATICA'
	Local cAtvContContab  := '1231020006'

	//Dados para a API - Json
	Private lMsHelpAuto := .T. // se .t. direciona as mensagens de help
	Private lMsErroAuto := .F. //necessario a criacao

	self:SetContentType('application/json')

	oJson:FromJson(cJson)

	cError := oJson:FromJson(cJson)

	IF !Empty(cError)
		SetRestFault(500, 'Erro ao Ler o json')
		lRet := .F.
	ENDIF


	SN1->(DbSetOrder(1)) //N1_FILIAL+N1_CBASE+N1_ITEM
	If SN1->(DbSeek(xFilial("SN1")+PADR(oJson["TAGANT"], TamSX3('N1_CBASE')[1])+PADR(oJson["ITEM_NF"], TamSX3('N1_ITEM') [1])))
		CONOUT("Encontrou na SN1")

		if SN1->N1_CBASE <> oJson['TAG']
			RecLock('SN1', .F.)
			SN1->N1_CBASE := PADR(oJson['TAG'], TamSX3('N1_CBASE')[1])
			SN1->(MsUnlock())
		EndIf

		if SN1->N1_DESCRIC <> oJson['DESCRICAO']
			RecLock('SN1', .F.)
			SN1->N1_DESCRIC := PADR(oJson['DESCRICAO'], TamSX3('N1_DESCRIC')[1])
			SN1->(MsUnlock())
		endif

		if SN1->N1_CHAPA <> oJson['TAG']
			RecLock('SN1', .F.)
			SN1->N1_CHAPA := PADR(oJson['TAG'], TamSX3('N1_CHAPA') [1])
			SN1->(MsUnlock())
		EndIf

		if SN1->N1_NFISCAL <> PADR(oJson["NOTA_FISCAL"], TamSX3('N1_NFISCAL')[1])
		RecLock('SN1', .F.)
		   SN1->N1_NFISCAL := PADR(oJson["NOTA_FISCAL"], TamSX3('N1_NFISCAL')[1])
		   SN1->N1_NSERIE  := "001"
		   SN1->(MsUnlock())
		endif


		SN3->(DbSetOrder(1))//N3_FILIAL+N3_CBASE+N3_ITEM+N3_TIPO+N3_BAIXA+N3_SEQ
		If SN3->(DbSeek(xFilial("SN3")+PADR(oJson["TAGANT"], TamSX3('N3_CBASE')[1])+PADR(oJson["ITEM_NF"], TamSX3('N3_ITEM') [1])+PADR(oJson['TIPO'], TamSX3('N3_TIPO')[1])+"0"+"001"))
			CONOUT("Encontrou na SN3")
			//SN3
			aItens := {}
			if SN3->N3_CBASE <> oJson['TAG']
				RecLock('SN3', .F.)
				SN3->N3_CBASE := PADR(oJson['TAG'], TamSX3('N3_CBASE')[1])
				SN3->(MsUnlock())
			Endif
			AAdd(aItens, {"N3_ITEM" , SN3->N3_ITEM ,NIL})
			AAdd(aItens, {"N3_TIPO" , SN3->N3_TIPO ,NIL})
			AAdd(aItens, {"N3_BAIXA" , SN3->N3_BAIXA ,NIL})
			if SN3->N3_HISTOR <> cAtvHist
				RecLock('SN3', .F.)
				SN3->N3_HISTOR := PADR(cAtvHist, TamSX3('N3_HISTOR')[1])
				SN3->(MsUnlock())
			endif

			if SN3->N3_CCONTAB <> cAtvContContab
				RecLock('SN3', .F.)
				SN3->N3_CCONTAB := PADR(cAtvContContab, TamSX3('N3_CCONTAB')[1])
				SN3->N3_CDEPREC := PADR(cAtvContContab, TamSX3('N3_CDEPREC')[1])
				SN3->N3_CDESP := PADR(cAtvContContab, TamSX3('N3_CDESP')[1])
				SN3->N3_CCORREC := PADR(cAtvContContab, TamSX3('N3_CCORREC')[1])
				SN3->(MsUnlock())
			endif

			if SN3->N3_CUSTBEM <> oJson["CUST_BEM"]
				RecLock('SN3', .F.)
				SN3->N3_CCUSTO := PADR(oJson["CUST_BEM"], TamSX3('N3_CUSTBEM')[1])
				SN3->N3_CUSTBEM := PADR(oJson["CUST_BEM"], TamSX3('N3_CUSTBEM')[1])
				SN3->(MsUnlock())
			endif

		EndIf

		CONOUT("Inclusao de Ativo")

			// VALIDAÇÃO DE ERRO NA ROTINA
			If (!lMsErroAuto) // OPERAÇÃO FOI EXECUTADA COM SUCESSO
				ConOut(PadC("Automatic routine successfully ended", 80))
			Else // OPERAÇÃO EXECUTADA COM ERRO
				If (!IsBlind()) // COM INTERFACE GRÁFICA
					MostraErro()
				Else // EM ESTADO DE JOB
					cError := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO

					ConOut(PadC("Automatic routine ended with error", 80))
					ConOut("Error: "+ cError)
				EndIf
			EndIf

			CONOUT("Ativo Alterado com sucesso")

	EndIf


RETURN lRet
