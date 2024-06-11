#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'Protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'restful.ch'
#INCLUDE 'FWMVCDEF.CH'
 
WSRESTFUL CUSTOM_LIBDOC DESCRIPTION 'Liberação de Documentos - Piacentini' FORMAT APPLICATION_JSON

    WSMETHOD POST LIBDOC DESCRIPTION "Libera Documentos via API"       WSSYNTAX "/libdoc"                              PATH "/libdoc"   TTALK "LIBDOC"
 
END WSRESTFUL
 
//Função que Libera documentos via API
WSMETHOD POST LIBDOC WSSERVICE CUSTOM_LIBDOC
 
    Local lRet      := .T.
    Local lOk       := .T.
    Local oModel    := NIL
    Local cJson     := self:GetContent()
    Local oJson     := JsonObject():New()
    Local oJsonRet  := JsonObject():New()
    Local cError    := {}
 
    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.
    CONOUT( "libdoc" )

    self:SetContentType ('application/json')
 
    oJson:FromJson(cJson)

    cError  := oJson:FromJson(cJson)
 
//Se tiver algum erro no Parse, encerra a execução
IF !Empty(cError)
    SetRestFault(500,'Parser Json Error')
    lRet    := .F.
ENDIF

    if lRet

    	//Setando __cUserId por conta de uma chamada da função RetCodUsr() no MATA094
        DbSelectArea("SAK")
        SAK->(dbSetOrder(1))
        IF SAK->(dbSeek(xFilial("SAK")+oJSon["Aprovador"]))
            //__cUserId Variavel publica
            __cUserId          := SAK->AK_USER
        EndIF

        
		SCR->(DbSetOrder(3))
		If SCR->(DbSeek(xFilial("SCR") + oJSon["Tipo"] + oJson["Documento"] + oJSon["Aprovador"] )) //Respeitar indice e tamanho dos campos
            

            CONOUT("Encontrou Documento")
            
            A094SetOp('001')

            oModel := FWLoadModel('MATA094')
            oModel:SetOperation( MODEL_OPERATION_UPDATE )
            oModel:Activate()

            lOk := oModel:VldData()
            CONOUT("Passou pelo VLDDATA" )

            If lOk
            //-- Se validou, grava o formulário
                lOk := oModel:CommitData()
                CONOUT("Passou pelo Commit ")
            ENDIF


            if !lOk
                
            CONOUT("ERRORLIBDOC: lOk is not Okay: "+ oModel:GetErrorMessage())
            
            ENDIF

        oModel:DeActivate()
        oModel:Destroy()
        oModel := NIL

			//Preenche json retorno 
			oJsonRet['Documento']   := SCR->CR_NUM
			oJsonRet['Total']       := SCR->CR_TOTAL
			oJsonRet['Emissao']     := SCR->CR_EMISSAO
			oJsonRet['Tipo']        := SCR->CR_TIPO
			oJsonRet['Status']      := SCR->CR_STATUS
			lRet := .T.
			self:SetResponse( oJsonRet:toJson() )
		
        Else 
			lRet := .F.
 
            CONOUT("Registro não encontrado na tabela SCR.")

			SetRestFault(2,;
						  'Registro não encontrado na tabela SCR.',;
						  .T.,;
						  400,;
						  'Houve uma falha na leitura dos dados Json, favor valide.')
		EndIf
    else
        lRet := .F.

        CONOUT( "Não foi possível realiar o Parser do Json." )

        SetRestFault(2,;
                      'Não foi possível realiar o Parser do Json.',;
                      .T.,;
                      400,;
                      'Houve uma falha na leitura dos dados Json, favor valide.')
    ENDIF
 
RETURN lRet
