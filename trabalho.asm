
;
;====================================================================
;	Trabalho INTEL 8086 Pedro Emilio ARQI-23/1
;====================================================================
;
		.model small
		.stack

CR		equ		0dh
LF		equ		0ah

		.data
;variavel de chamada
StringChamada   db      256 dup (?)
varteste        db      256 dup (?)
FstChamada      db      256 dup (?)
varteste2       db      0
TamanhoChamada  dw      0
NParamString    db		10 dup (?)
NParamStringP   dw		0
TamanhoSN		dw		0
NParamInt		dw		0
OutPadrao		db		"a.out", 0      ;saida padrao quando -o nao for informado
;variaveis parametro acgt+
IsAOn 			db		0				;flags com a informacao do parametro +acgt
IsCOn 			db		0
IsGOn 			db		0
IsTOn			db		0
IsPlusOn		db		0
TamanhoACGT     dw		0
ParamACGTptr	dw		0
ParamACGTptrIn	dw		0
MaxNGrupos		dw		0				;guarda o maximo de grupo n que o arquivo pode ter
CountNParam		dw		0				;controla o laco de repeticao dos grupos
CountBase		dw		0				;controla o laco de repeticao DENTRO de cada grupo
ErroCritico     db      0				;informa que o programa deve parar por erro critico
;variaveis de arquivos
FileNameSRC		db		256 dup (?)		; Nome do arquivo a ser lido
FileNameSRCptr1 dw      0               ;ponteiro do inicio do nome do arquivo de origem
FileNameDSTptr1 dw      0               ;ponteiro do inicio do nome do arquivo de destino
TamanhoNomeSrc  dw      0               ;tamanho do nome do arquivo de origem
TamanhoNomeDST  dw      0               ;tamanho do nome do arquivo de origem
FileNameDST		db		256 dup (?)		; Nome do arquivo a ser escrito
FileBuffer  	db		10 dup (?)		; Buffer de leitura do arquivo
FileHandleSRC	dw		0				; Handler do arquivo de origem
FileHandleDST	dw		0				; Handler do arquivo de destino
FileNameBuffer	db		150 dup (?)
FileBufferDst   dw      256 dup (?)      ;usado para escrever no arquivo
ptrFile			dw		0				 ;ponteiro para definir a partir de qual byte sera a leitura
FileSize		dw		0				 ;tamanho do arquivo de leitura
CountLinha		dw		0				 ;conta a linha de leitura do arquivo
NumBases		dw		0				 ;numero de bases no arquivo
CountCR			dw		0				 ;numero de CR no arquivo
CountLF			dw		0				 ;numero de LF no arquivo
NumLinhas		dw		0				 ;numero total de linhas no 
AchouLF			db		0				 ;flag para contar as linhas

;Mensagens
MsgPedeArquivo		    db	"Nome do arquivo: ", 0
MsgPedeArquivoDst		db	"Nome do arquivo destino: ", 0
MsgErroCreateFile		db	"Erro na criacao do arquivo.", CR, LF, 0
MsgErroWriteFile		db	"Erro na escrita do arquivo.", CR, LF, 0
MsgErroOpenFile		    db	"O arquivo ", 0
MsgErroOpenFile2		db	" nao existe!", 0
MsgErroReadFile		    db	"Erro na leitura do arquivo.", CR, LF, 0
MsgCRLF				    db	 CR, LF, 0
MsgSCC                  db  "Arquivo aberto com sucesso", CR, LF, 0
MsgSCC2                 db  "Arquivo criado com sucesso", CR, LF, 0
msgNomearquivoEntrada   db  "Nome do arquivo de entrada: ", 0
msgNomearquivoSaida     db  CR, LF, "Nome do arquivo de saida: ", 0
msgTamanhoGrupos		db	CR, LF, "Tamanho dos grupos calculados: ", 0
msgOpcoesEscolhidas		db	CR, LF, "Bases contabilizadas no arquivo de saida: ", 0
msgNumbases				db  CR, LF, "Numero de bases no arquivo de entrada: ", 0
msgNumGrupos			db	CR, LF, "Numero de grupos processados: ", 0
msgNumLinhas			db  CR, LF, "Numero de linhas com base do arquivo de entrada: ", 0
MsgIgual			    db	" = ", 0
CabPlus					db	"A+T;C+G", 0
msgErroCaracter			db  "Foi encontrado um caracter '", 0
msgErroCaracter2        db  "' na linha ", 0
msgFaltaNome			db	"Falta o nome do arquivo de entrada da seguinte forma:", CR, LF, " -f nomedoarquivo.ext", 0
msgFaltaNParam			db	"Voce deve fornecer o parametro -n !", 0
msgFaltaACTG			db	"Voce de fornecer pelo menos um dos parametros ACGT+", 0
msgFileGrande			db	"O arquivo possui mais de 10000 bases e nao pode ser processado!", 0
msgFilepeq				db	"O arquivo tem menos bases do que o minimo.", CR, LF, "Minimo de bases aceitas para essa chamada: ",0
msgBaseA				db	"'A'", 0
msgBaseT				db	"'T'", 0
msgBaseC				db	"'C'", 0
msgBaseG				db	"'G'", 0
msgPVirgula				db	";", 0

; Variavel interna usada na rotina printf_w
BufferWRWORD	db		10 dup (?)
; Variaveis para uso interno na funcao sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0
;variaveis geneticas
CountA              dw  0               ;guarda o numero de As no arquivo
CountT              dw  0               ;guarda o numero de Ts no arquivo
CountC              dw  0               ;guarda o numero de Cs no arquivo
CountG              dw  0               ;guarda o numero de Gs no arquivo
CountAT				dw 	0				;guarta G + T
CountCG				dw	0				;guarda A + C

		.code
		.startup
;coloca as informacoes da chamada do programa na variavel StringChamada
    push ds ; salva as informações de segmentos
    push es
    mov ax,ds ; troca DS <-> ES, para poder usa o MOVSB
    mov bx,es
    mov ds,bx
    mov es,ax
    mov si,80h ; obtém o tamanho do string e coloca em CX
    mov ch,0
    mov cl,[si]
    mov dx, cx          ;salva o tamanho da chamda para passar para uma variavel após a troca de segmentos
    mov si,81h ; inicializa o ponteiro de origem
    lea di,StringChamada ; inicializa o ponteiro de destino
    rep movsb
    pop es ; retorna as informações dos registradores de segmentos 
    pop ds

    mov TamanhoChamada, dx
    


    mov		ax,ds				; Seta ES = DS
	mov		es,ax


;------------------------------------------
;abre o arquivo
;------------------------------------------
    call	GetFileName                     ;pega o nome do arquivo de origem da string de entrada
	mov		al,0
	lea		dx,FileNameSRC
	mov		ah,3dh
	int		21h
	jnc		sem_erro_abertura
	lea		bx,MsgErroOpenFile              ;imprime a mensagem de erro
	call	printf_s
	lea 	bx, FileNameSRC
	call	printf_s
	lea		bx, MsgErroOpenFile2
	call	printf_s
	mov		al,1
	jmp		TERMINA    
sem_erro_abertura:
    mov		FileHandleSRC,ax



;----------------------------------------------
;define quais bases devem ser impressas
;----------------------------------------------
	call setFlagsACGT

;--------------------------------------------
;Pega o parametro -n
;--------------------------------------------
	call GetNParam


;--------------------------------------------
;calcula o tamanho do arquivo e coloca em FileSize
;--------------------------------------------
	mov ah, 42h
	mov al, 2
	mov bx, FileHandleSRC
	mov dx, 0
	mov cx, 0
	int 21h
	mov FileSize, ax

;--------------------------------------------
;calcula a quantidade de LF e CR
;bases = FileSize - LF - CR
;Linhas = LF (funciona em Unix e Wnds).
;Linhas soh eh incrementado com quando AchouLF == 1 && (FileBuffer != CR & FB != LF) & Arquvio nao acabou
;isso evita que sejam contadas linhas que contem so CRLF/LF  
;--------------------------------------------
	mov		CountCR, 0
	mov		CountLF, 0
	mov		NumLinhas, 1
;seta o ponteiro de arquivo para o inicio, apos ele ser mudado pela funcao que calcula o file size
	mov ah, 42h
	mov al, 0
	mov bx, FileHandleSRC
	mov dx, 0
	mov cx, 0
	int 21h
loop_contalinha:
    mov		bx,FileHandleSRC
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
;verifica erro de leitura
	jnc		conseguiu_ler_contalinha	
	lea		bx,MsgErroReadFile
	call	printf_s
	mov		al,1
	jmp		TERMINA
conseguiu_ler_contalinha:
;verifica se terminou o arquivo
	cmp		ax,0
	je		fim_contalinha
;verifica requisitos para incrementar linha
	cmp		AchouLF, 1
	jne		nao_incrementa_linhas
    mov     bl, FileBuffer
    CMP     bl, CR
	je		nao_incrementa_linhas
    CMP     bl, LF
	je		nao_incrementa_linhas
;se chegou aqui o arquvio nao acabou e o prox caracter nao eh crlf, logo deve ser uma base e a linha conta
	inc		NumLinhas
nao_incrementa_linhas:
;conta se o caracter eh CR:
    mov     bl, FileBuffer
    CMP     bl, CR
    jne     nao_eh_CR
    inc     CountCR
    jmp     loop_contalinha
nao_eh_CR:
;conta se o caracter eh LF:
    mov     bl, FileBuffer
    CMP     bl, LF
    jne     nao_eh_LF_1
    inc     CountLF
	mov		AchouLF, 1
	jmp		loop_contalinha
nao_eh_lf_1:
	mov		AchouLF, 0
	jmp		loop_contalinha
fim_contalinha:
	mov 	ax, FileSize
	sub		ax, CountLF
	sub		ax, CountCR
	mov		NumBases, ax

;----------------------------------------------------
;verifica se o arquivo tem tamanho correto
;----------------------------------------------------
	cmp 	NumBases, 10000
	jg		arquivo_grande
	mov		bx, NParamInt
	cmp		Numbases, bx
	jl		arquivo_pequeno
	jmp		tamanho_correto
arquivo_grande:
	lea		bx, msgFileGrande
	call	printf_s
	jmp		TERMINA
arquivo_pequeno:
	lea		bx, msgFilepeq
	call	printf_s
	mov		ax, NParamInt
	call	printf_w
	jmp		TERMINA
tamanho_correto:

;----------------------------------------------
;cria arquivo de destino
;----------------------------------------------
    call 	GetFileNameDst
    lea		dx,FileNameDst
	call	fcreate
	mov		FileHandleDst,bx
	jnc		criou_arquivo
	mov		bx,FileHandleSrc
	call	fclose
	lea		bx, MsgErroCreateFile
	call	printf_s
criou_arquivo:

	
;--------------------------------------------
;imprime o cabecalho de acordo com as flags
;--------------------------------------------
	call writeHead

;--------------------------------------------
;calcula o maximo de grupos
;MaxGrupos = NumBases - Nparam
;--------------------------------------------
	mov ax, NParamInt
	mov bx, NumBases
	mov MaxNGrupos, bx
	sub MaxNGrupos, ax
	inc MaxNGrupos					;se n for igual a quantidade de bases, deve haver um grupo


;----------------------------------------------
;le e contabiliza um grupo de "n" bases
;comecando em ptrFile
;a cada ciclo, move o ptrFile um byte para a direita, 
;comecando assim o proximo grupo
;se o proximo grupo comeca com LF ou CR, pula o grupo
;----------------------------------------------
	mov CountLinha, 1
	mov ptrFile, 0
	mov CountNParam, 0
loop_gruposn:
;seta o ponteiro do arquivo para o inicio do bloco
  	mov 	ah, 42h         
  	mov  	al, 0         
  	mov  	bx, FileHandleSRC 
  	mov  	cx, 0            
  	mov  	dx, ptrFile        
  	int  	21h
;le o primeiro byte do grupo        
    mov		bx,FileHandleSRC
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
;Verifica se eh CR/LF:
    mov     bl, FileBuffer
    CMP     bl, CR
    jne     nao_eh_CR_1
	inc		ptrFile
	jmp		loop_gruposn
nao_eh_CR_1:
    CMP     bl, LF
    jne     nao_eh_LF_2
	inc		ptrFile
	jmp		loop_gruposn
nao_eh_lf_2:
;faz a leitura do grupo	
	call readNGroup
;confere se houve erro de caracter
	mov al, 1
	cmp ErroCritico, al
	je TERMINA
;imprime a linha com os resultados do grupo
	call printLine
	inc CountNParam
	inc ptrFile
;verifica se ja contabilizou todos os grupos
	mov ax, CountNParam
	cmp ax, MaxNGrupos
	je terminou_grupos
	jmp loop_gruposn
terminou_grupos:

;------------------------------------------
;finaliza o programa
;------------------------------------------

    call    print_end

;fecha arquivos
	mov		bx,FileHandleSRC
	mov		ah,3eh
	int		21h
	mov		bx,FileHandleDST
	mov		ah,3eh
	int		21h
TERMINA:	
		.exit


;*********************************************************************************************************
;--------------------------------------------------------------------
;Funções
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;Funcao pega o nome do arquivo origem da string de entrada
;--------------------------------------------------------------------
GetFileName	proc	near
    ;procura - na string de chamada
    mov al, "-"
    mov di, offset StringChamada
    mov cx, TamanhoChamada
    repne scasb

confere_f:
    ;confere se o proximo caractere eh f
    mov cl, byte ptr [di]
    cmp cl, "f"
    je achou_nome

    ;procura o proximo "-" na string de chamada
    repne scasb
	jnz sem_nome_entrada
    jmp confere_f
	

achou_nome:  
    inc di                              ;tira o proprio f
    inc di                              ;tira o espaco
    mov FileNameSRCptr1, di             ;salva o offset do inicio do nome

    ;procura o prox " " na string de chamada
    mov al, " "
    repne scasb
	dec di							   ;impede o " " de entrar na conta
    mov TamanhoNomeSrc, di             ;salva o offset do fim do nome
    mov dx, FileNameSRCptr1
    sub TamanhoNomeSrc, dx             ;obtem o tamanho do nome do arquivo de entrada

;
    mov si,FileNameSRCptr1
    mov di, offset FileNameSRC
    mov cx, TamanhoNomeSrc
    rep movsb
    ret

sem_nome_entrada:
	lea bx, msgFaltaNome
	call printf_s
	jmp TERMINA

GetFileName	endp

;--------------------------------------------------------------------
;Funcao Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp

;
;--------------------------------------------------------------------
;Funcao: Escreve o valor de AX na tela
;		printf("%
;--------------------------------------------------------------------
printf_w	proc	near
	; sprintf_w(AX, BufferWRWORD)
	lea		bx,BufferWRWORD
	call	sprintf_w
	
	; printf_s(BufferWRWORD)
	lea		bx,BufferWRWORD
	call	printf_s
	
	ret
printf_w	endp

;
;--------------------------------------------------------------------
;Funcao: Converte um inteiro (n) para (string)
;		 sprintf(string->BX, "%d", n->AX)
;--------------------------------------------------------------------
sprintf_w	proc	near
	mov		sw_n,ax
	mov		cx,5
	mov		sw_m,10000
	mov		sw_f,0
	
sw_do:
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
	mov		sw_n,dx
	
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	dec		cx
	cmp		cx,0
	jnz		sw_do

	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx], "0"
	inc		bx
sw_continua2:

	mov		byte ptr[bx],0
	ret		
sprintf_w	endp


;-------------------------------------------------------------------
;funcao: coloca o resumo final na tela
;-------------------------------------------------------------------
print_end   proc    near 
;Nome do arquivo de entrada: arquivo.txt
    lea     bx, msgNomearquivoEntrada
    call    printf_s
    lea     bx, FileNameSRC
    call    printf_s
;Nome do arquivo de saida: arquivo.csv
    lea     bx, msgNomearquivoSaida
    call    printf_s
    lea     bx, FileNameDST
    call    printf_s
;Tamanho dos grupos: n
    lea     bx, msgTamanhoGrupos
    call    printf_s
    mov		ax, NParamInt
    call    printf_w
;Informacoes a serem colocadas no grupo de saida
	lea 	bx, msgOpcoesEscolhidas
	call	printf_s
;a
	cmp 	IsAOn, 1
	jnz 	sem_a_resumo
	lea 	bx, msgBaseA
	call	printf_s
	lea		bx, msgPVirgula
	call	printf_s
sem_a_resumo:
;t
	cmp 	IsTOn, 1
	jnz 	sem_t_resumo
	lea 	bx, msgBaseT
	call	printf_s
	lea		bx, msgPVirgula
	call	printf_s
sem_t_resumo:
;c
	cmp 	IsCOn, 1
	jnz 	sem_c_resumo
	lea 	bx, msgBaseC
	call	printf_s
	lea		bx, msgPVirgula
	call	printf_s
sem_c_resumo:
;G
	cmp 	IsGOn, 1
	jnz 	sem_g_resumo
	lea 	bx, msgBaseG
	call	printf_s
	lea		bx, msgPVirgula
	call	printf_s
sem_g_resumo:
;+
	cmp 	IsPlusOn, 1
	jnz 	sem_plus_resumo
	lea		bx, CabPlus
	call	printf_s
	lea		bx, msgPVirgula
	call 	printf_s
sem_plus_resumo:

;Bases no arquivo de entrada = numBases
    lea     bx, msgNumbases
    call    printf_s
    mov		ax, NumBases
    call    printf_w
;Numero grupos = MaxGrupos
    lea     bx, msgNumGrupos
    call    printf_s
    mov		ax, MaxNGrupos
    call    printf_w
;Numero de linhas = NumLinhas
    lea     bx, msgNumLinhas
    call    printf_s
    mov		ax, NumLinhas
    call    printf_w
    ret
print_end endp

;--------------------------------------------------------------------
;Funcao pega o nome do arquvio de destino da string de entrada
;--------------------------------------------------------------------
GetFileNameDst	proc	near
	 ;procura - na string de chamada
    mov al, "-"
    mov di, offset StringChamada
    mov cx, TamanhoChamada
    repne scasb
confere_o:
    ;confere se o proximo caractere eh o
    mov ah, byte ptr [di]
    cmp ah, "o"
    je achou_nome_dst

    ;procura o proximo "-" na string de chamada
    repne scasb
	jnz nao_achou_o					   ;pula para rotina de destino automatico
    jmp confere_o


achou_nome_dst:  
    inc di                              ;tira o proprio f
    inc di                              ;tira o espaco
    mov FileNameDSTptr1, di             ;salva o offset do inicio do nome

    ;procura o prox " " na string de chamada
    mov al, " "
    repne scasb
	dec di							   ;impede o " " de entrar na conta
    mov TamanhoNomeDST, di             ;salva o offset do fim do nome
    mov dx, FileNameDSTptr1
    sub TamanhoNomeDST, dx             ;obtem o tamanho do nome do arquivo de entrada

;
    mov si,FileNameDSTptr1
    mov di, offset FileNameDST
    mov cx, TamanhoNomeDST
    rep movsb
    ret
nao_achou_o:
    mov si, offset OutPadrao
    mov di, offset FileNameDST
    mov cx, 5
    rep movsb	
	ret
GetFileNameDst	endp


;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp

;--------------------------------------------------------------------
;Fun��o Cria o arquivo cujo nome est� no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;-------------------------------------------------------------------
;funcao processa o parametro +acgt na chamada
;-------------------------------------------------------------------
setFlagsACGT proc near
	;zera todos os flags
	xor ax, ax
	mov IsAOn, al
	mov IsCOn, al
	mov IsGOn, al
	mov IsTOn, al
	mov IsPlusOn, al

	 ;procura - na string de chamada
    mov al, "-"
    mov di, offset StringChamada
    mov cx, TamanhoChamada
    repne scasb
confere_a:
    ;confere se o proximo caractere eh a
    mov ah, byte ptr [di]
    cmp ah, "a"
    je achou_flags
;confere c
    mov ah, byte ptr [di]
    cmp ah, "c"
    je achou_flags
;confere g
    mov ah, byte ptr [di]
    cmp ah, "g"
    je achou_flags
;confere t
    mov ah, byte ptr [di]
    cmp ah, "t"
    je achou_flags
;confere +
    mov ah, byte ptr [di]
    cmp ah, "+"
    je achou_flags
;nao eh nenhuma das letras, procura o prox '-'
    repne scasb
	jnz erro_falta_acgt
    jmp confere_a
	

achou_flags:  
	mov ParamACGTptrIn, di			;salva o endereco do inicio do parametro
;calcula o tamanho do parametro
    mov al, " "
    repne scasb
    mov TamanhoACGT, di             ;salva o offset do fim do nome
    mov dx, ParamACGTptr			;ponteiro para o fim do parametro
    sub TamanhoACGT, dx         	;obtem o tamanho do parametro
;confere se tem a no parametro
	mov al, "a"
	mov di, ParamACGTptrIn
	mov cx, TamanhoACGT
	repne scasb
	jnz sem_a
	mov IsAOn, 1
sem_a:
;confere se tem c no parametro
	mov al, "c"
	mov di, ParamACGTptrIn
	mov cx, TamanhoACGT
	repne scasb
	jnz sem_c
	mov IsCOn, 1
sem_c:
;confere se tem g no parametro
	mov al, "g"
	mov di, ParamACGTptrIn
	mov cx, TamanhoACGT
	repne scasb
	jnz sem_g
	mov IsGOn, 1
sem_g:
;confere se tem t no parametro
	mov al, "t"
	mov di, ParamACGTptrIn
	mov cx, TamanhoACGT
	repne scasb
	jnz sem_t
	mov IsTOn, 1
sem_t:
;confere se tem + no parametro
	mov al, "+"
	mov di, ParamACGTptrIn
	mov cx, TamanhoACGT
	repne scasb
	jnz sem_plus
	mov IsPlusOn, 1
sem_plus:
	ret

erro_falta_acgt:
	lea bx, msgFaltaACTG
	call printf_s
	jmp TERMINA
setFlagsACGT endp

;--------------------------------------------------------------------
;Funcao pega o valor do parametro -n e converte para inteiro
;coloca o valor como string em NParamString e como interio em
;NParamInt
;--------------------------------------------------------------------
GetNParam	proc	near
	 ;procura - na string de chamada
    mov al, "-"
    mov di, offset StringChamada
    mov cx, TamanhoChamada
    repne scasb

confere_n:
    ;confere se o proximo caractere eh n
    mov ah, byte ptr [di]
    cmp ah, "n"
    je achou_n_param

    ;procura o proximo "-" na string de chamada
    repne scasb
	jnz erro_sem_nparam
    jmp confere_n
	

achou_n_param:  
	inc di
	inc di
    mov NParamStringP, di            	;salva o offset do inicio do parametro n

    ;procura o prox " " na string de chamada
    mov al, " "
    repne scasb
	dec di							   ;evita que se conte o " " no tamanho
    mov TamanhoSN, di            	   ;salva o offset do parametro n
    mov dx, NParamStringP
    sub TamanhoSN, dx             	   ;obtem o tamanho do string parametro n

	;coloca a string n em NParamString
    mov si, NParamStringP
    mov di, offset NParamString
    mov cx, TamanhoSN
    rep movsb

	;coloca o inteiro n em NParamInt
	lea bx, NParamString
	call atoi
	mov NParamInt, ax
    ret
erro_sem_nparam:
	lea bx, msgFaltaNParam
	call printf_s
	jmp TERMINA
GetNParam	endp

;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;Entra: (S) -> DS:BX -> Ponteiro para o string de origem
;Sai:	(A) -> AX -> Valor "Hex" resultante
;Algoritmo:
;	A = 0;
;	while (*S!='\0') {
;		A = 10 * A + (*S - '0')
;		++S;
;	}
;	return
;--------------------------------------------------------------------
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp

;---------------------------------------------------------------------
;funcao imprime ";" no documento
;--------------------------------------------------------------------
printPV 	proc near

   		mov     bx, FileHandleDST
		mov		FileBuffer, ";"
		lea		dx, FileBuffer
    	mov     cx, 1
    	mov     ah, 40h
    	int     21h
		ret
printPV		endp

;----------------------------------------------------------------------
;imprime o cabecalho do coumento de acordo com as flags de bases
;----------------------------------------------------------------------
writeHead	proc near

	mov bx, FileHandleDST
;a
	cmp IsAOn, 1
	jnz sem_a_cabecalho
	mov FileBuffer, 'A'
	lea dx, FileBuffer
	mov cx, 1
	mov ah, 40h
	int 21h
	jc erro_escrita
	call printPV
    jc erro_escrita
sem_a_cabecalho:
;t
	cmp IsTOn, 1
	jnz sem_t_cabecalho
	mov FileBuffer, 'T'
	lea dx, FileBuffer
	mov cx, 1
	mov ah, 40h
	int 21h
	jc erro_escrita
	call printPV
    jc erro_escrita
sem_t_cabecalho:
;c
	cmp IsCOn, 1
	jnz sem_c_cabecalho
	mov FileBuffer, 'C'
	lea dx, FileBuffer
	mov cx, 1
	mov ah, 40h
	int 21h
	jc erro_escrita
	call printPV
    jc erro_escrita	
sem_c_cabecalho:
;g
	cmp IsGOn, 1
	jnz sem_g_cabecalho
	mov FileBuffer, 'G'
	lea dx, FileBuffer
	mov cx, 1
	mov ah, 40h
	int 21h
	jc erro_escrita
	call printPV
    jc erro_escrita	
sem_G_cabecalho:
;+
	cmp IsPlusOn, 1
	jnz sem_plus_cabecalho
	lea dx, CabPlus
	mov cx, 7
	mov ah, 40h
	int 21h
	jc erro_escrita
sem_plus_cabecalho:
	jmp fim_cabecalho
erro_escrita:
	lea     bx, MsgErroWriteFile
    call    printf_s
    mov     bx, FileHandleDST
    call    fclose

fim_cabecalho:
	lea	dx, MsgCRLF							;pula para nova linha para entrada de dados
	mov cx, 2
	mov ah, 40h
	int 21h
	ret

writeHead endp


;-----------------------------------------
;imprime uma linha do resultado
;-----------------------------------------
printLine	proc near
;a
	cmp IsAOn, 1
	jnz sem_a_resultado
	mov ax, CountA
	lea bx, FileBufferDst
	call sprintf_w
	mov bx, FileHandleDST
	lea dx, FileBufferDst
	mov cx, 1
loop_resultado_a:
	mov ah, 40h
	mov di,dx
	cmp [di], 0
	jz fim_resultado_a
	int 21h
	inc dx
	jmp loop_resultado_a
fim_resultado_a:
	call printPV
sem_a_resultado:
;t
	cmp IsTOn, 1
	jnz sem_t_resultado
	mov ax, CountT
	lea bx, FileBufferDst
	call sprintf_w
	mov bx, FileHandleDST
	lea dx, FileBufferDst
	mov cx, 1
loop_resultado_t:
	mov ah, 40h
	mov di,dx
	cmp [di], 0
	jz fim_resultado_t
	int 21h
	inc dx
	jmp loop_resultado_t
fim_resultado_t:
	call printPV
sem_t_resultado:
;c
	cmp IsCOn, 1
	jnz sem_c_resultado
	mov ax, CountC
	lea bx, FileBufferDst
	call sprintf_w
	mov bx, FileHandleDST
	lea dx, FileBufferDst
	mov cx, 1
loop_resultado_c:
	mov ah, 40h
	mov di,dx
	cmp [di], 0
	jz fim_resultado_c
	int 21h
	inc dx
	jmp loop_resultado_c
fim_resultado_c:
	call printPV
sem_c_resultado:
;g
	cmp IsGOn, 1
	jnz sem_g_resultado
	mov ax, CountG
	lea bx, FileBufferDst
	call sprintf_w
	mov bx, FileHandleDST
	lea dx, FileBufferDst
	mov cx, 1
loop_resultado_g:
	mov ah, 40h
	mov di,dx
	cmp [di], 0
	jz fim_resultado_g
	int 21h
	inc dx
	jmp loop_resultado_g
fim_resultado_g:
	call printPV
sem_g_resultado:
;+
;a+t
	cmp IsPlusOn, 1
	jnz sem_plus_resultado
	mov ax, CountAT
	lea bx, FileBufferDst
	call sprintf_w
	mov bx, FileHandleDST
	lea dx, FileBufferDst
	mov cx, 1
loop_resultado_plus_at:
	mov ah, 40h
	mov di,dx
	cmp [di], 0
	jz fim_resultado_plus_at
	int 21h
	inc dx
	jmp loop_resultado_plus_at
fim_resultado_plus_at:
	call printPV
;c+g:
	mov ax, CountCG
	lea bx, FileBufferDst
	call sprintf_w
	mov bx, FileHandleDST
	lea dx, FileBufferDst
	mov cx, 1
loop_resultado_plus_cg:
	mov ah, 40h
	mov di,dx
	cmp [di], 0
	jz fim_resultado_plus_cg
	int 21h
	inc dx
	jmp loop_resultado_plus_cg
fim_resultado_plus_cg:
	call printPV
sem_plus_resultado:

	lea	dx, MsgCRLF							;pula para nova linha
	mov cx, 2
	mov ah, 40h
	int 21h
	ret
printLine endp


;----------------------------------------------
;le e contabiliza um grupo de "n" bases
;comecando em ptrFile
;----------------------------------------------
readNGroup	proc near
;zera os contadores do bloco anterior
	mov		CountA, 0
	mov		CountC, 0
	mov		CountG, 0
	mov		CountT, 0
	mov 	CountAT, 0
	mov 	CountCG, 0
	mov		CountBase, 0
;seta o ponteiro do arquivo para o inicio do bloco
  	mov 	ah, 42h         
  	mov  	al, 0         
  	mov  	bx, FileHandleSRC 
  	mov  	cx, 0            
  	mov  	dx, ptrFile        
  	int  	21h
;faz a leitura de um bloco n            
again:
    mov		bx,FileHandleSRC
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
;verifica erro de leitura
	jnc		conseguiu_ler	
	lea		bx,MsgErroReadFile
	call	printf_s
	mov		al,1
	jmp		end_line
conseguiu_ler:
;verifica se terminou o arquivo
	cmp		ax,0
	je		end_line
;verifica se acabou o grupo 
	mov		bx, NParamInt
	cmp		CountBase, bx
	je		end_line

;conta se o caracter eh A:
    mov     bl, FileBuffer
    CMP     bl, "A"
    jne     nao_eh_A
    inc     CountA
	inc		CountBase
    jmp     again
nao_eh_A:
;conta se o caracter eh T:
    mov     bl, FileBuffer
    CMP     bl, "T"
    jne     nao_eh_T
    inc     CountT
	inc		CountBase
    jmp     again
nao_eh_T:       
;conta se o caracter eh C:
    mov     bl, FileBuffer
    CMP     bl, "C"
    jne     nao_eh_C
    inc     CountC
	inc		CountBase
    jmp     again
nao_eh_C:
;conta se o caracter eh G:
    mov     bl, FileBuffer
    CMP     bl, "G"
    jne     nao_eh_G
    inc     CountG
	inc		CountBase
	jmp		again
nao_eh_G:
;verifica se o caracter é LF
;se for LF, verifica se deve contar linha
	mov		bl, FileBuffer
	cmp		bl, LF
	jne		nao_eh_lf
	mov 	bx, CountBase
	inc		bx
	cmp 	NParamInt, bx
	jne 	again
	inc 	CountLinha
	jmp 	end_line
nao_eh_lf:
;verifica se o caracter é CR
	mov		bl, FileBuffer
	cmp		bl, CR
	je		again
;se nao for nenhum dos acima, eh um caractere errado, envia para erro
;so entrata no erro quando o caracter errado for o ultimo do seu grupo (countBase==0)
;isso garante que a linha estará certa, pois countLine só atualiza quando LF é o primeiro do grupo
	jmp		ERRO_CARACTER
;se for clrf nao faz nada:

end_line:
;calcula A + T do grupo
	mov 	ax, 0
	add 	ax, CountA
	add		ax, CountT
	mov		CountAT, ax
;calcula C + G do grupo
	mov 	ax, 0
	add 	ax, CountC
	add		ax, CountG
	mov		CountCG, ax	
	mov		ax,0
	ret

;so irá incrementar a linha se o LF for o ultimo caracter do grupo a ser lido
;isso evita que se tenham N incrementos de linha
conta_linha:
	mov bx, NParamInt
	cmp CountBase, bx
	jne again
	inc CountLinha
	jmp end_line


ERRO_CARACTER:
	lea bx, msgErroCaracter
	call printf_s
	lea bx, FileBuffer
	call printf_s
	lea bx, msgErroCaracter2
	call printf_s
	mov ax, CountLinha
	call printf_w
	mov ErroCritico, 1
	ret

readNGroup endp

;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------


