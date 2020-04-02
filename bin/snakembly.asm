;Dombi Botond
;dbim1614
;csoport: 511
;Projekt - Snake

%include 'io.inc'
%include 'util.inc'
%include 'gfx.inc'

%define WIDTH  1024
%define HEIGHT 768

global main

section .text

;Beirja a fileba a rendezett listát, névsort
;Innen <- [sorted]
;Ide -> f22
nio_writefile:
	mov eax,f22
	mov ebx,1

	call fio_open

	mov ebx,sorted
	mov ecx,[filesize]

	call fio_write

	call fio_close
ret

;(Submit gomb)
;Felfüzi a listára a játékos eredményét a submit gomb megnyomására
;Ide -> [sorted]
;[name] - név, [score] - eredmény, [scores] - a beolvasott eredmények
nio_writescore:
	
	;Addig irja a [sorted] -ba a [scores] -on beluli eredmenyeket amig az nagyobb
	;Amikor kissebb lesz beirja a jatekos eredmenyet
	;Ezutan visszafuzzik a [sorted] -hez a [scores]-ban maradt eredmenyeket

	xor ecx,ecx
	.loop:
		;[previouspointer] - az elozo elem mutatoja, vagy ha az utolso file utan kell fuzni a szamot akkor az utolso
		mov [previouspointer],ecx

		cmp ecx,[filesize]
		jge .previous
		.name:
			mov ebx,[scores+ecx]

			mov [sorted+ecx],bl

			cmp bl,0
			je .endname

			inc ecx
			jmp .name
		.endname:
			mov [sorted+ecx],bl

			inc ecx
			mov ebx,[scores+ecx]

			mov [sorted+ecx],ebx

			cmp ebx,[score]
			jl .previous

			add ecx,4

			jmp .loop
	.previous:
		mov ecx,[previouspointer]
		;[tmpfilesize] - a beolvasott eredmenyek mutatoja, ezt folytatjuk majd
		mov [tmpfilesize],ecx

	mov edx,ecx
	;edx a [sorted] indexe
	;ecx a [name] indexe (bejarjuk a nevet es berakjuk a sorted-be)

	xor ecx,ecx
	.writename:
		mov ebx,[name+ecx]
		cmp bl,0
		je .endwrite

		mov [sorted+edx],bl

		inc ecx
		inc edx
		jmp .writename
	.endwrite:
	mov [sorted+edx],bl
	inc edx

	mov ebx,[score]
	mov [sorted+edx],ebx

	add edx,4

	;edx a [sorted] indexe tovabbra is
	;ecx most a [scores] indexe, tehat beirjuk a [sorted]-be a maradek [scores]-t

	mov ecx,[tmpfilesize]

	.loopend:
		cmp ecx,[filesize]
		jge .finish
		.nameend:
			mov ebx,[scores+ecx]

			mov [sorted+edx],bl

			cmp bl,0
			je .endnameend

			inc ecx
			inc edx
			jmp .nameend
		.endnameend:
			mov [sorted+edx],bl

			inc edx
			inc ecx
			mov ebx,[scores+ecx]

			mov [sorted+edx],ebx

			add edx,4
			add ecx,4

			jmp .loopend
	.finish:

	;Frissitjuk a filesize-t hogy tudjuk kiiratni azt teljese egeszeben, mostmar 1-el tobb eredemnyunk van
	mov [filesize],edx

ret


;Beolvassa az eredmenyeket
;Ide -> [scores]
;Innen <- f22
nio_readscores:
	push eax
	push ebx
	push ecx
	push edx

	mov eax,f22
	mov ebx,0

	call fio_open

	mov ebx,scores
	mov ecx,1024

	call fio_read

	mov [filesize],edx

	call fio_close

	pop edx
	pop ecx
	pop ebx
	pop eax
ret


;Atalakitja az eredmenyt stringé
;Innen <- [score]
;Ide -> [scorestr]
nscoretostring:
	push eax	
	push ebx	
	push ecx

	xor ecx,ecx
	mov eax,[score]
	.cycle:
	mov ebx,10
	cdq
	idiv ebx

	add edx,48
	push edx

	inc ecx

	cmp eax, 0
	jne .cycle
	.end:

	mov eax,0

	.heap:
		cmp ecx,0
		je .endh

		dec ecx
		
		pop edx
		mov [scorestr+eax],edx

		inc eax
		jmp .heap
	.endh:

	pop ecx
	pop ebx
	pop eax
ret


;A popup ablak esetében, a user gépelését kezeli le
;Innen <- loop gfx_getevent
;Ide -> [name]
nnameread:
	push eax
	push ebx
	push ecx

	mov [event],word 0

	xor ecx,ecx
	.getendofstr:
		cmp [name+ecx],word 0
		je .endofstr
		inc ecx
		jmp .getendofstr
	.endofstr:

	.key:
		call gfx_getevent

		cmp eax,0
		jl .safetycheck

		cmp eax,1
		je .mouse

		cmp eax, 8
		je .pop
		cmp eax,'0'
		jl .none
		cmp eax,'9'
		jle .push
		cmp eax,'A'
		jl .none
		cmp eax,'Z'
		jle .push
		cmp eax,'a'
		jl .none
		cmp eax,'z'
		jg .none
		
		mov [pressed],eax
		sub eax,32
		jmp .pushsafety

		.push:

		mov [pressed],eax

		.pushsafety:

		cmp ecx,10
		jge .none

		mov [name+ecx],eax
		inc ecx
		mov [name+ecx],word 0

		jmp .none
		.pop:

		dec ecx
		mov [name+ecx],word 0

		jmp .none
		.mouse:

		mov [event],word 1

		jmp .none

		;Kezeli a hibat (amit eszleltem gyors gepelesnel)
		;A gombok, legalabbis nalam neha csak minusz erteket adnak vissza
		;Tehat -48 at kapok, mintha felemeltem volna a '0' billentyut pedig szerinte le se nyomtam azt
		;Ezt kezeli le, ugy hogy megnezi a negativ szam eseteben, hogy annak pozitiva volt-e az elozo
		;Ha igen nincs amit tennunk kene, ha nem akkor kiiratjuk
		.safetycheck:
			push ecx
			imul eax,-1
			pop ecx

			mov eax,[pressed]

			cmp eax,[pressed]
			je .none

			cmp eax,'0'
			jl .none
			cmp eax,'9'
			jle .pushsafety
			cmp eax,'A'
			jl .none
			cmp eax,'Z'
			jle .pushsafety
			cmp eax,'a'
			jl .none
			cmp eax,'z'
			jle .pushsafety

		.none:

		test eax,eax
		jnz .key
	
	pop ecx
	pop ebx
	pop eax
ret

;Megnezi hogy a mouse koordinatai x1 x2 y1 y2 kozott van-e
;[x_start] - [x_end] kozott
;[y_start] - [y_end] kozott
nutil_mousecheck:

	push eax
	push ebx

	mov [hover], word 0
	;x
	cmp eax,[x_start]
	jl .end

	cmp eax,[x_end]
	jg .end

	;y
	cmp ebx,[y_start]
	jl .end

	cmp ebx,[y_end]
	jg .end

	mov [hover],word 1

	.end:

	pop ebx
	pop eax
	
ret

;Beolvas egy kepet
;Innen <- ebx
;Ide -> edx
;[tmpwidth] tarolja majd a szelesseget
;[tmpheihgt] tarolja majd a magassagot
;A kepunk tarol 4 byte szelesseget, 4 byte magassagot és magasság * szélességnyi byteot
nio_readimg:
	push edx
	mov eax,ebx
	mov ebx,0
	call fio_open

	mov ebx,tmpwidth
	mov ecx,4
	call fio_read

	mov ebx,tmpheight
	call fio_read

	pop edx
	mov ebx,edx
	mov ecx,[tmpwidth]
	imul ecx,[tmpheight]
	imul ecx,4

	call fio_read

	call fio_close
ret

;Lehelyez egy kepet a kepernyore
;[tmpx] és [tmpy] koordinátátol kezdödöen
nio_placeimg:
	push eax

	mov ebx,[tmpy]
	imul ebx,WIDTH
	add ebx,[tmpx]
	imul ebx,4
	mov [mapoffset],ebx

	;[mapoffset] - segitsegevel toljuk el a sorokat, tehat a kovetkezo sorba irjuk majd a pixeleket
	;kezdeti erteke a tmpx * tmpy * 4 (mutatokent hasznaljuk)

	pop eax

	;dupla forciklus
	;[i] - szellesig megy
	;[j] - magassagig

	mov [i], word 1
	mov [j], word 1
	.sor:
		mov ecx,[i]

		;Ha kifutunk a szelessegbol ugrunk a kovetkezo sorra
		mov edx,[tmpwidth]
		cmp ecx,edx
		jg .sorvege

		mov edx,ecx
		add edx,[tmpx]
		cmp edx,WIDTH
		jge .sorkiugrik
		
		push eax

		mov ebx,ecx
		dec ebx

		;A [mapoffset]-hez folyamatosan adjuk az (i-1) * 4 -et
		;Igy irodik ki a sor

		imul ebx,4
		add ebx,[mapoffset]

		pop eax

		;A gfx_map pointeret atadjuk edx-be
		mov edx,[mappointer]

		push ecx

		;Amennyiben alpha channel nem halvany, tehat egyaltalan nem attetszo akkor iratjuk
		;Azaz nincs alpha blending :/

		mov ecx,[eax+3]
		cmp cl,255

		jg .alphaugras

		;Gond van a filejaimmal ha alpha channel van (Png 256 color?)

		;Beszinezzuk a pixeleket

		mov ecx,[eax+2]
		mov [edx+ebx],cl
		mov ecx,[eax+1]
		mov [edx+ebx+1],cl
		mov ecx,[eax]
		mov [edx+ebx+2],cl

		.alphaugras:

		pop ecx

		.sorkiugrik:

		;Vege a sornak (ugrassal nem idejovunk hulyeseg a neve)
		add eax,4
		inc ecx
		;Noveljuk i-t, uj pixel jon a soron
		mov [i],ecx

		jmp .sor
	.sorvege:
		mov ecx,[j]

		;Ha kifutunk a magassagbol vege a kiiratasnak
		mov edx,[tmpheight]
		cmp ecx,edx
		je .vege

		mov edx,[j]
		add edx,[tmpy]
		cmp edx,HEIGHT
		je .vege

		mov ebx,[mapoffset]

		;A sorhoz hozzaadjuk a kepernyo szelesseget * 4, hogy uj sorra irjuk a kovetkezo pixel sort
		add ebx, WIDTH*4
		mov [mapoffset],ebx

		inc ecx
		mov [j],ecx
		mov [i],word 1
		jmp .sor

	.vege:

ret


;Beolvassuk a font-ot (Nem optimalizalt font)
nio_readfont:
	mov eax,f0
	mov ebx,0
	call fio_open

	mov ebx,font
	mov ecx,302400
	call fio_read

	call fio_close
ret

;Kiiratjuk a font segitsegevel a string-et a kepernyore
;Innen <- esi
;[tmpx] és [tmpy] koordinataktol kezdodoen
;A font is egy "kep", minden 8400 byteonkent tarolunk egy magassagot, szelesseget és utána a pixeleket
nio_writestr:
	
	mov eax,[tmpy]
	imul eax,WIDTH
	add eax,[tmpx]
	imul eax,4
	mov [tmpoffset],eax

	xor ecx,ecx
	.cycle:
		xor eax,eax
		lodsb

		cmp eax,0
		je .cycle_end

		cmp eax, 'A'
		jl .szam
		jmp .betu

		.back:

		inc ecx
		jmp .cycle

	.szam:

		;Ha szamot iratunk ki akkor eltoljuk annyiszor 8400-el
		;De hozzadjuk a 26 * 8400-at is, mert 26 szamunk van
		sub eax,'0'
		imul eax,8400
		add eax,218400

		jmp .draw
	.betu:

		;Eltoljuk az abc sorrendbeli indexevel a szamot * 8400 -el
		sub eax,'A'
		imul eax,8400

		jmp .draw
	.draw:
		push ecx
			;A mapoffset megkapja a tmpoffset erteket, tehat a karakterek eltolasat (lasd lent)
			mov ecx,[tmpoffset]
			mov [mapoffset],ecx

			push eax

			add eax,font

			;Kiolvassuk a magassagot és szélességet

			mov ebx,[eax]
			mov [tmpwidth],ebx

			mov ebx,[eax+4]
			mov [tmpheight],ebx

			pop eax

			add eax,8

			xor ecx,ecx
			xor ebx,ebx

			;Kiirjuk a magassag * szelesseg mennyisegu pixelt
			;ecx - soron levo pixel indexe
			.drawcycle:
				cmp ecx,[tmpwidth]
				je .drawcycle_end

				push ecx

				imul ecx,4
				;[mapoffset] - itt is a sorokat tolja
				add ecx,[mapoffset]
				;[mappointer] - itt is a gfx_map pointeret tarolja
				add ecx,[mappointer]

				push eax

				add eax,font

				mov edx,[eax+3]
				cmp dl,255

				;Ha nincs alpha, vagyis kicsit is attetszo akkor ugrunk
				jg .alphaugras

				push ebx

				mov ebx,[colorg]
				mov [ecx+1], bl

				mov ebx,[colorr]
				mov [ecx+2], bl

				mov ebx,[colorb]
				mov [ecx], bl

				pop ebx

				.alphaugras:

				pop eax

				add eax,4

				pop ecx

				inc ecx
				jmp .drawcycle

			.drawcycle_end:
				cmp ebx,[tmpheight]
				je .end

				;Eltoljuk a mapoffset-et hogy a kovetkezo sorra irjuk a pixeleket
				mov ecx,[mapoffset]
				add ecx, WIDTH*4

				mov [mapoffset],ecx

				xor ecx,ecx

				inc ebx
				jmp .drawcycle
			.end:

			mov ecx,[tmpwidth]

			imul ecx,4
			add ecx,[tmpoffset]
			add ecx,8

			;A [tmpoffset] tarolja az egymas utani karakterek eltolasat
			mov [tmpoffset],ecx

		pop ecx
		jmp .back
	.cycle_end:

ret

main:

	;Beolvassuk a fontot
	call nio_readfont

	;Beolvassuk az osszes kepet (Kicsit csunya tudom)
	;ebx mindig a fileneve lasd lent f1,f2,f3....
	;edx a pixel tomb
	;minden kephez jar egy magassag es szelesseg, ezt kulon vettem mert ugy gondoltam az elejen igy egyszerubb

	mov ebx,f1
	mov edx,img_background
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_background_w],eax
	mov eax,[tmpheight]
	mov [img_background_h],eax

	mov ebx,f2
	mov edx,img_menu_easy
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_easy_w],eax
	mov eax,[tmpheight]
	mov [img_menu_easy_h],eax

	mov ebx,f3
	mov edx,img_menu_medium
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_medium_w],eax
	mov eax,[tmpheight]
	mov [img_menu_medium_h],eax

	mov ebx,f4
	mov edx,img_menu_hard
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_hard_w],eax
	mov eax,[tmpheight]
	mov [img_menu_hard_h],eax

	mov ebx,f5
	mov edx,img_menu_scoreboard
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_scoreboard_w],eax
	mov eax,[tmpheight]
	mov [img_menu_scoreboard_h],eax

	mov ebx,f6
	mov edx,img_menu_easy_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_easy_hover_w],eax
	mov eax,[tmpheight]
	mov [img_menu_easy_hover_h],eax

	mov ebx,f7
	mov edx,img_menu_medium_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_medium_hover_w],eax
	mov eax,[tmpheight]
	mov [img_menu_medium_hover_h],eax

	mov ebx,f8
	mov edx,img_menu_hard_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_hard_hover_w],eax
	mov eax,[tmpheight]
	mov [img_menu_hard_hover_h],eax

	mov ebx,f9
	mov edx,img_menu_scoreboard_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_scoreboard_hover_w],eax
	mov eax,[tmpheight]
	mov [img_menu_scoreboard_hover_h],eax

	mov ebx,f10
	mov edx,img_menu_x
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_x_w],eax
	mov eax,[tmpheight]
	mov [img_menu_x_h],eax

	mov ebx,f11
	mov edx,img_menu_x_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_menu_x_hover_w],eax
	mov eax,[tmpheight]
	mov [img_menu_x_hover_h],eax

	mov ebx,f12
	mov edx,img_a_40
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_a_40_w],eax
	mov eax,[tmpheight]
	mov [img_a_40_h],eax

	mov ebx,f13
	mov edx,img_s_40
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_s_40_w],eax
	mov eax,[tmpheight]
	mov [img_s_40_h],eax

	mov ebx,f16
	mov edx,img_h_40
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_h_40_w],eax
	mov eax,[tmpheight]
	mov [img_h_40_h],eax

	mov ebx,f14
	mov edx,img_game
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_game_w],eax
	mov eax,[tmpheight]
	mov [img_game_h],eax

	mov ebx,f15
	mov edx,img_popup
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_popup_w],eax
	mov eax,[tmpheight]
	mov [img_popup_h],eax

	mov ebx,f17
	mov edx,img_toplist
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_toplist_w],eax
	mov eax,[tmpheight]
	mov [img_toplist_h],eax

	mov ebx,f18
	mov edx,img_btn_menu
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_btn_menu_w],eax
	mov eax,[tmpheight]
	mov [img_btn_menu_h],eax

	mov ebx,f19
	mov edx,img_btn_menu_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_btn_menu_hover_w],eax
	mov eax,[tmpheight]
	mov [img_btn_menu_hover_h],eax

	mov ebx,f20
	mov edx,img_btn_submit
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_btn_submit_w],eax
	mov eax,[tmpheight]
	mov [img_btn_submit_h],eax

	mov ebx,f21
	mov edx,img_btn_submit_hover
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_btn_submit_hover_w],eax
	mov eax,[tmpheight]
	mov [img_btn_submit_hover_h],eax

	mov ebx,f23
	mov edx,img_s_20
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_s_20_w],eax
	mov eax,[tmpheight]
	mov [img_s_20_h],eax

	mov ebx,f24
	mov edx,img_h_20
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_h_20_w],eax
	mov eax,[tmpheight]
	mov [img_h_20_h],eax

	mov ebx,f25
	mov edx,img_a_20
	call nio_readimg
	mov eax,[tmpwidth]
	mov [img_a_20_w],eax
	mov eax,[tmpheight]
	mov [img_a_20_h],eax

	;A grafika elkezdodik (gfxdemo.asm-bol van)
    mov		eax, WIDTH
	mov		ebx, HEIGHT
	mov		ecx, 0	
	mov		edx, title
	call	gfx_init
	
	test	eax, eax
	jnz		.mainloop
	
	mov		eax, error
	call	io_writestr
	call	io_writeln
	ret

;A loop ami ismetlodik mindig
.mainloop:
	
	;A [stage] jeloli a jatek fazisat, 0 - menu, 1 - jatek, 2 - scoreboard
	mov eax,[stage]
	cmp eax,0
	je .menu

	cmp eax,1
	je .game

	jmp .scoreboard

	;Stage = 0, vagyis itt rajzolodik a menu
	.menu:

		call gfx_map
		mov [mappointer], eax

		;Kirajzoljuk a hatteret

		mov [tmpy],word 0
		mov [tmpx],word 0

		mov eax,[img_background_w]
		mov [tmpwidth],eax

		mov eax,[img_background_h]
		mov [tmpheight],eax

		mov eax,img_background
		call nio_placeimg

		;Kirajzoljuk a menuket

		mov [tmpy],word 240
		mov [tmpx],word 280

		mov eax,[img_menu_easy_w]
		mov [tmpwidth],eax

		mov eax,[img_menu_easy_h]
		mov [tmpheight],eax

		mov eax,img_menu_easy
		call nio_placeimg

		mov [tmpy],word 340

		mov eax,[img_menu_medium_w]
		mov [tmpwidth],eax

		mov eax,[img_menu_medium_h]
		mov [tmpheight],eax

		mov eax,img_menu_medium
		call nio_placeimg

		mov [tmpy],word 440

		mov eax,[img_menu_hard_w]
		mov [tmpwidth],eax

		mov eax,[img_menu_hard_h]
		mov [tmpheight],eax

		mov eax,img_menu_hard
		call nio_placeimg

		mov [tmpx],word 270
		mov [tmpy],word 640

		mov eax,[img_menu_x_w]
		mov [tmpwidth],eax

		mov eax,[img_menu_x_h]
		mov [tmpheight],eax

		mov eax,img_menu_x
		call nio_placeimg

		mov [tmpx],word 367

		mov eax,[img_menu_scoreboard_w]
		mov [tmpwidth],eax

		mov eax,[img_menu_scoreboard_h]
		mov [tmpheight],eax

		mov eax,img_menu_scoreboard
		call nio_placeimg

		;Kezeljuk a cursort
		;Hover + Click

		mov [tmpx],word 280

		call gfx_getmouse

		;Megadjuk a hatarokat
		mov [x_start],word 280
		mov [x_end],word 744
		mov [y_start],word 240
		mov [y_end],word 310

		;Megnezzuk ott van-e a mouse
		call nutil_mousecheck

		;Ha igen hover lep fel, tehat lehet hogy clickelunk is eppen
		cmp [hover],word 0
		je .nohover1

		.hover1:
			;Az elso menun rajta van az eger
			push eax

			mov eax,[event]
			cmp eax,1

			;Eppen nem clickeltunk tehat nincs amit kezelni
			jne .noclick1

			;Clickeltunk igy tehat elvegezzuk a szukseges dolgokat
			;Easy gomb
			pop eax

			;Nehezseg 0, es ugrunk a jatekra stage -> 1
			mov [difficulty], word 0
			mov [stage], word 1

			jmp .game_init

			.noclick1:

			;Kirajzoljuk a hover menut az adott menure
			mov [tmpy],word 240

			mov eax,[img_menu_easy_hover_w]
			mov [tmpwidth],eax

			mov eax,[img_menu_easy_hover_h]
			mov [tmpheight],eax

			mov eax,img_menu_easy_hover
			call nio_placeimg

			pop eax
		.nohover1:
			;Johet a kovetkezo gomb hover kezelese... igy tovabb
			mov [y_start],word 340
			mov [y_end],word 410

			call nutil_mousecheck

			cmp [hover],word 0
			je .nohover2
		.hover2:
			push eax

			mov eax,[event]
			cmp eax,1

			jne .noclick2

			;Medium gomb
			pop eax

			;Nehezseg 1, es ugrunk a jatekra stage -> 1
			mov [difficulty], word 1
			mov [stage], word 1

			jmp .game_init

			.noclick2:

				mov [tmpy],word 340

				mov eax,[img_menu_medium_hover_w]
				mov [tmpwidth],eax

				mov eax,[img_menu_medium_hover_h]
				mov [tmpheight],eax

				mov eax,img_menu_medium_hover
				call nio_placeimg

				pop eax
		.nohover2:
			mov [y_start],word 440
			mov [y_end],word 510

			call nutil_mousecheck

			cmp [hover],word 0
			je .nohover3
		.hover3:	
			push eax

			mov eax,[event]
			cmp eax,1

			jne .noclick3

			;Hard gomb
			pop eax

			;Nehezseg 2, es ugrunk a jatekra stage -> 2
			mov [difficulty], word 2
			mov [stage], word 1

			jmp .game_init

			.noclick3:

			mov [tmpy],word 440

			mov eax,[img_menu_hard_hover_w]
			mov [tmpwidth],eax

			mov eax,[img_menu_hard_hover_h]
			mov [tmpheight],eax

			mov eax,img_menu_hard_hover
			call nio_placeimg

			pop eax
		.nohover3:
			mov [x_start],word 276
			mov [x_end],word 370
			mov [y_start],word 640
			mov [y_end],word 710

			call nutil_mousecheck

			cmp [hover],word 0
			je .nohover4
		.hover4:
			push eax

			mov eax,[event]
			cmp eax,1

			jne .noclick4

			;Exit gomb (x)
			pop eax

			;A program vegere ugrunk -> gfx_destroy
			jmp .end

			.noclick4:

			mov [tmpx],word 270
			mov [tmpy],word 640

			mov eax,[img_menu_x_hover_w]
			mov [tmpwidth],eax

			mov eax,[img_menu_x_hover_h]
			mov [tmpheight],eax

			mov eax,img_menu_x_hover
			call nio_placeimg

			pop eax
		.nohover4:
			mov [x_start],word 380
			mov [x_end],word 740

			call nutil_mousecheck

			cmp [hover],word 0
			je .nohover5
		.hover5:

			push eax

			mov eax,[event]
			cmp eax,1

			jne .noclick5

			;A scoreboard gomb
			pop eax

			;Beugrunk a scoreboardba stage -> 2
			mov [stage], word 2

			jmp .scoreboard_init

			.noclick5:

			mov [tmpx],word 367

			mov eax,[img_menu_scoreboard_hover_w]
			mov [tmpwidth],eax

			mov eax,[img_menu_scoreboard_hover_h]
			mov [tmpheight],eax

			mov eax,img_menu_scoreboard_hover
			call nio_placeimg

			pop eax
		.nohover5:

	jmp .mapping
	
	;Inicializaljuk a jatekot, ide mindig csak a menubol lepunk be egyszer jatekonkent
	.game_init:

	;Nincs popup ablak
	mov [popup],word 0

	;Az irany = jobb
	mov [direction],word 1

	;Az eredmeny 0
	mov [score],dword 0

	;A neveunk 0-val kezdodik (biztonsagbol)
	mov [name],dword 0	

	;A kigyo 3 testresze, mindig (0,0) (0,1) (0,2)
	mov [snakex], word 0
	mov [snakex+4], word 1
	mov [snakey], word 0
	mov [snakey+4], word 0
	mov [snakex+8], word 2
	mov [snakey+8], word 0

	;A kigyo merete 3
	mov [snakesize],word 3

	;A nehezseg szerint Inicializaljuk tovabb a jatekonkent
	;Elegge customizeolhato, kicsit tulsagosan annak akartam
	cmp [difficulty],word 0
	je .easy
	cmp [difficulty],word 1
	je .medium
	cmp [difficulty],word 2
	je .hard

	;Easy mode
	.easy:
		;A kigyo merete (pixelekben)
		mov [size], word 40

		;A kigyo texturaja
		mov eax,img_s_40
		mov [snaketexture],eax

		;Az alma texturaja
		mov eax,img_a_40
		mov [appletexture],eax

		;A kigyo fejenek texturaja
		mov eax,img_h_40
		mov [headtexture],eax

		;A mapnak a merete
		mov [mapsize_x],word 24
		mov [mapsize_y],word 16

		;Ne kelljen minden lepesben kiszamolni
		mov [mapsize],word 192

		;A kigyo sebessege
		mov [speed],word 100

		;Az alma elsodleges koordinataja (mindig kozepre)
		;Azaz x = mapszelesseg/2, y = mapmagassag/2

		mov eax,[mapsize_x]
		cdq
		mov ebx,2
		idiv ebx
		mov [applex],eax

		mov eax,[mapsize_y]
		cdq
		mov ebx,2
		idiv ebx
		mov [appley],eax

		;Ugrunk is a mappinghoz, tehat rajzoljuk a jatekot
		jmp .mapping


	;Ugyanigy ertelmezzuk a tobbit is

	;Medium mode
	.medium:
		;Itt mar 20 a kigyo merete
		mov [size], word 20

		mov eax,img_h_20
		mov [snaketexture],eax

		mov eax,img_h_20
		mov [appletexture],eax

		mov eax,img_h_20

		mov [headtexture],eax
		mov [mapsize_x],word 48
		mov [mapsize_y],word 32
		mov [mapsize],word 384
		mov [speed],word 50

		mov eax,[mapsize_x]
		cdq
		mov ebx,2
		idiv ebx
		mov [applex],eax

		mov eax,[mapsize_y]
		cdq
		mov ebx,2
		idiv ebx
		mov [appley],eax
		jmp .mapping
	.hard:
		mov [size], word 20

		mov eax,img_s_20
		mov [snaketexture],eax

		mov eax,img_a_20
		mov [appletexture],eax

		mov eax,img_h_20
		mov [headtexture],eax

		mov [mapsize_x],word 48
		mov [mapsize_y],word 32
		mov [mapsize],word 384
		mov [speed],word 25

		mov eax,[mapsize_x]
		cdq
		mov ebx,2
		idiv ebx
		mov [applex],eax

		mov eax,[mapsize_y]
		cdq
		mov ebx,2
		idiv ebx
		mov [appley],eax
		jmp .mapping
	jmp .mapping

	;Stage = 1, beleptunk a jatekba
	.game:

	;Ha van popup lekezeljuk azt (vagyis vege a jateknak mert vesztettunk)
	cmp [popup],word 0
	je .nopopup

	;Ebben az esetben kezeljuk a nev beirasat
	call nnameread

	jmp .snakeend
	;Nincs popup igy tovabbmegyunk
	.nopopup:

	mov [catch],byte 0

	mov ecx,[snakesize]
	dec ecx

	imul ecx,4

	mov ebx,[snakex+ecx]
	mov edx,[snakey+ecx]

	;Kezeljuk az iranyt, igy kiszamoljuk a kovetkezo lepest
	cmp [direction],word 0
	je .nulla
	cmp [direction],word 1
	je .egy
	cmp [direction],word 2
	je .ketto
		
		dec ebx
		jmp .endif
	.nulla:
		dec edx
		jmp .endif
	.egy:
		inc ebx
		jmp .endif
	.ketto:
		inc edx
		jmp .endif
	.endif:

	;Lekezeljuk a fallal valo utkozest
	cmp ebx,0
	jl .collision
	cmp ebx,[mapsize_x]
	je .collision
	cmp edx,0
	jl .collision
	cmp edx,[mapsize_y]
	je .collision

	jmp .nocollision
	.collision:
		mov [popup], word 1
		jmp .snakeend
	.nocollision:


	;Lekezeljuk az almaval valo utkozest :))
	;Vagyis megettunk egy almat

	cmp ebx,[applex]
	jne .continue
	cmp edx,[appley]
	jne .continue

	;Berakjuk a kigyoba az almat

	mov ecx,[snakesize]
	imul ecx,4

	mov [snakex+ecx],ebx
	mov [snakey+ecx],edx

	mov eax,[snakesize]
	inc eax
	mov [snakesize],eax 

	push ebx

	;Lekezeljuk azt ha mar nemlehet tobb almat rakni

	mov ebx,[mapsize]
	cmp eax,ebx
	jne .noend
	pop ebx

	mov [popup], word 1
	jmp .snakeend

	.noend:
	pop ebx

	;A kovetkezo almat generaljuk le
	.apple_generate:

		;X koordinata
		call rand
		mov ebx,[mapsize_x]
		cdq
		idiv ebx

		cmp edx,0
		jge .skip1
		imul edx,-1

		.skip1:

		mov [applex],edx

		;Y coordinata
		call rand
		mov ebx,[mapsize_y]
		cdq
		idiv ebx

		cmp edx,0
		jge .skip2

		imul edx,-1

		.skip2:

		mov [appley],edx
		mov ebx,[applex]

	;Leellenorizzuk hogy az alma nem-e a kigyoban van...
	mov ecx,0
	.apple_check:
		cmp ecx,[snakesize]
		je .apple_done

		push ecx

		imul ecx,4
		mov eax,[snakex+ecx]
		cmp eax,ebx
		jne .ok1

		mov eax,[snakey+ecx]
		cmp eax,edx

		jne .ok1

		pop ecx
		;Ha igen ujrageneraljuk az almat
		jmp .apple_generate

		.ok1:

		pop ecx

		inc ecx

	jmp .apple_check

	;Legeneraltuk a kovetkezo almat
	.apple_done:
	mov [catch], byte 1
	mov ecx, [score]

	;A nehezsegtol fuggoen adjuk az eredmenyt
	cmp [difficulty],word 1
	je .double
	cmp [difficulty],word 2
	je .triple

	;1 - Easy
	inc ecx
	jmp .scoredone
	.double:
		;2 - Medium
		add ecx,2
		jmp .scoredone
	.triple:
		;3 - Hard
		add ecx,3
		jmp .scoredone
	.scoredone:

	mov [score],ecx

	jmp .snakeend

	.continue:
	;A kigyo sajat magaval valo utközését is megnézzük

	mov ecx,0
	.self_check:
		cmp ecx,[snakesize]
		je .self_done

		push ecx

		imul ecx,4
		mov eax,[snakex+ecx]
		cmp eax,ebx
		jne .ok2

		mov eax,[snakey+ecx]
		cmp eax,edx

		jne .ok2

		pop ecx
		
		;Itt vesztettünk
		mov [popup], word 1
		jmp .snakeend

		.ok2:

		pop ecx

		inc ecx
	jmp .self_check

	.self_done:
	;Vegeztunk az utkozesek figyelésével

	push ebx
	push edx

	;Felepitjuk a kigyot, azaz a lista elejerol popolunk egyet es a vegere rakunk be egy uj elemet
	;Amennyiben megattunk egy almat akkor nem poppolunk csak pusholunk
	mov ecx,1
	.snakebuild:
		cmp ecx,[snakesize]
		jg .snakebuildend
		push ecx

		;Az i+1 kigyo testresz
		imul ecx,4
		mov ebx,[snakex+ecx]
		mov edx,[snakey+ecx]
			
		;Bemegy az i-edik testresz helyere
		sub ecx,4
		mov [snakex+ecx],ebx
		mov [snakey+ecx],edx

		pop ecx
		inc ecx
		jmp .snakebuild
	.snakebuildend:

	;Itt adjuk meg a kigyo fejet

	pop edx
	pop ebx

	mov ecx,[snakesize]
	dec ecx

	imul ecx,4

	mov [snakex+ecx],ebx
	mov [snakey+ecx],edx

	.snakeend:

	;Vege a kigyo kezelésének, igy rajzolhatunk

	call gfx_map
	;mappointer segéd map változo
	mov [mappointer], eax

	mov [tmpy],word 0
	mov [tmpx],word 0

	;Kirajzoljuk jatek hatteret

	mov eax,[img_game_w]
	mov [tmpwidth],eax

	mov eax,[img_game_h]
	mov [tmpheight],eax

	mov eax,img_game
	call nio_placeimg

	.layer:
		mov ecx,0

		.snakeloop:
			cmp ecx,[snakesize]
			je .snakeloopend

			push ecx

			inc ecx
			cmp ecx,[snakesize]
			jne .nothead

			;Kirajzoljuk a fejet

			dec ecx

			imul ecx,4
			mov eax,[snakex+ecx]
			imul eax,[size]
			add eax,33
			mov [tmpx],eax

			mov eax,[snakey+ecx]
			imul eax,[size]
			add eax,104
			mov [tmpy],eax

			mov eax,[size]
			mov [tmpwidth],eax

			mov eax,[size]
			mov [tmpheight],eax

			mov eax,[headtexture]
			call nio_placeimg

			jmp .head
			.nothead:
			pop ecx

			;Kirajzoljuk a testreszt

			push ecx

			imul ecx,4
			mov eax,[snakex+ecx]
			imul eax,[size]
			add eax,33
			mov [tmpx],eax

			mov eax,[snakey+ecx]
			imul eax,[size]
			add eax,104
			mov [tmpy],eax

			mov eax,[size]
			mov [tmpwidth],eax

			mov eax,[size]
			mov [tmpheight],eax

			mov eax,[snaketexture]
			call nio_placeimg

			.head:

			pop ecx

			inc ecx
			jmp .snakeloop
		.snakeloopend:

			;Vege a kigyo rajzolasanak
			;Kirajzoljuk az almat

			mov eax,[applex]
			imul eax,[size]
			add eax,33
			mov [tmpx],eax

			mov eax,[appley]
			imul eax,[size]
			add eax,104
			mov [tmpy],eax

			mov eax,[size]
			mov [tmpwidth],eax

			mov eax,[size]
			mov [tmpheight],eax

			mov eax,[appletexture]
			call nio_placeimg

			;Kiiratjuk a jatek nehezseget
			;str_easy, str_medium, str_hard

			cmp [difficulty],word 0
			je .easystr
			cmp [difficulty],word 1
			je .mediumstr

			;Szinezzuk oket a nehezseg szerint

			mov [colorr],word 210
			mov [colorg],word 0
			mov [colorb],word 0
			mov esi,str_hard

			jmp .strend
			.easystr:
				mov [colorr],word 0
				mov [colorg],word 210
				mov [colorb],word 0
				mov esi,str_easy
				jmp .strend
			.mediumstr:
				mov [colorr],word 255
				mov [colorg],word 165
				mov [colorb],word 0
				mov esi,str_medium
			.strend:

			mov [tmpx],word 260
			mov [tmpy],word 35
			call nio_writestr

			;Kiirjuk az eredemnyt is

			mov [colorr],word 80
			mov [colorg],word 80
			mov [colorb],word 80

			;Atalakitjuk az eredemnyt stringbe
			call nscoretostring

			mov [tmpx],word 845
			mov [tmpy],word 32

			;Kiirjuk az eredményt
			mov esi,scorestr
			call nio_writestr

			cmp [popup],word 0
			jne .popup

			mov eax,[speed]
			call sleep

			jmp .mapping

			.popup:

			;Popup ablak

			mov [tmpy],word 244
			mov [tmpx],word 212

			mov eax,[img_popup_w]
			mov [tmpwidth],eax

			mov eax,[img_popup_h]
			mov [tmpheight],eax

			mov eax,img_popup
			call nio_placeimg

			;Gombok = submit és menu

			;Menu gomb, visszadob a menuhoz ha nem akarjuk berakni az eredményünk

			mov [tmpy],word 507
			mov [tmpx],word 295

			mov eax,[img_btn_menu_w]
			mov [tmpwidth],eax

			mov eax,[img_btn_menu_h]
			mov [tmpheight],eax

			mov eax,img_btn_menu
			call nio_placeimg

			;Submit gomb, berakja az eredmenunk a listaba

			mov [tmpx],word 525

			mov eax,[img_btn_submit_w]
			mov [tmpwidth],eax

			mov eax,[img_btn_submit_h]
			mov [tmpheight],eax

			mov eax,img_btn_submit
			call nio_placeimg

			;A gombok kezelese

			call gfx_getmouse

			mov [x_start],word 295
			mov [x_end],word 498
			mov [y_start],word 507
			mov [y_end],word 560

			call nutil_mousecheck

			cmp [hover],word 0
			je .btn_menu_nohover


			;A menu gomb kezelese
			.btn_menu:
				push eax

				mov eax,[event]
				cmp eax,1

				jne .btn_menu_noclick

				pop eax

				;Visszadob a menube
				mov [stage], word 0

				jmp .game_init

				.btn_menu_noclick:

				;Kirajzoljuk a hover menu-t

				mov [tmpx],word 295

				mov eax,[img_btn_menu_hover_w]
				mov [tmpwidth],eax

				mov eax,[img_btn_menu_hover_h]
				mov [tmpheight],eax

				mov eax,img_btn_menu_hover
				call nio_placeimg

				pop eax
			.btn_menu_nohover:
				mov [x_start],word 525
				mov [x_end],word 728

				call nutil_mousecheck

				cmp [hover],word 0
				je .btn_submit_nohover
			.btn_submit:
				push eax

				mov eax,[event]
				cmp eax,1

				jne .btn_submit_noclick

				pop eax

				;Kiolvassuk az eddigi neveket
				call nio_readscores

				;Beirjuk a listaba a mi nevunket is
				call nio_writescore

				;Kiirjuk fileba
				call nio_writefile

				;Kiolvassuk a mar mi nevunket is tarolo listat
				call nio_readscores

				;A scoreboardra visszuk a jatekost
				mov [stage],word 2

				jmp .game_init

				.btn_submit_noclick:

				mov [tmpx],word 525

				mov eax,[img_btn_submit_hover_w]
				mov [tmpwidth],eax

				mov eax,[img_btn_submit_hover_h]
				mov [tmpheight],eax

				mov eax,img_btn_submit_hover
				call nio_placeimg

				pop eax
			.btn_submit_nohover:

			;Kiirjuk a nevunket amit a popup ablakba gepelunk eppen

			mov [tmpx],word 260
			mov [tmpy],word 426

			mov esi,name

			xor ecx,ecx
			.length:
				cmp [esi+ecx],word 0
				je .lengthend
				inc ecx
				jmp .length
			.lengthend:

			mov eax,14
			imul eax,ecx

			mov ebx,510
			sub ebx,eax

			mov [tmpx],ebx

			mov esi,name
			call nio_writestr

	jmp .mapping


	;Stage = 2
	;A scoreboard inicializalasa, vagyis kiolvassuk a neveket, ez egyszer fut le csak
	.scoreboard_init:

	call nio_readscores

	jmp .mapping

	.scoreboard:

	;Kirajzoljuk a scoreboardot
	call gfx_map
	mov [mappointer], eax

	;Kirajzoljuk a hatteret

	mov [tmpy],word 0
	mov [tmpx],word 0

	mov eax,[img_toplist_w]
	mov [tmpwidth],eax

	mov eax,[img_toplist_h]
	mov [tmpheight],eax

	mov eax,img_toplist
	call nio_placeimg

	;Kirajzoljuk a vissza gombot (x)

	mov [tmpx],word 50
	mov [tmpy],word 640

	mov eax,[img_menu_x_w]
	mov [tmpwidth],eax

	mov eax,[img_menu_x_h]
	mov [tmpheight],eax

	mov eax,img_menu_x
	call nio_placeimg

	;Kezeljuk a vissza gombot

	call gfx_getmouse

	mov [x_start],word 56
	mov [x_end],word 170
	mov [y_start],word 640
	mov [y_end],word 710

	call nutil_mousecheck

	cmp [hover],word 0
	je .nohover

	mov eax,[event]
	cmp eax,1

	jne .noclick

	;Ha clickeltunk rajta akkor visszaugrunk

	mov [stage], word 0
	jmp .mapping

	.noclick:

	mov [tmpx],word 50
	mov [tmpy],word 640

	mov eax,[img_menu_x_hover_w]
	mov [tmpwidth],eax

	mov eax,[img_menu_x_hover_h]
	mov [tmpheight],eax

	mov eax,img_menu_x_hover
	call nio_placeimg

	.nohover:

	mov [bytesread],dword 0


	;Beolvassuk a neveket a memoriabol
	;Ide -> name
	xor ecx,ecx
	.readscore:
		mov esi,[bytesread]
		cmp esi,[filesize]
		jge .endofread

		;Max 10 nevet olvasunk

		cmp ecx,10
		je .endofread

		xor edx,edx
		.readname:
			xor eax,eax
			push edx
				mov edx,[bytesread]
				mov eax,[scores+edx]
			pop edx

			;Vege a nevnek
			cmp al,0
			je .endofname

			mov [name+edx],al

			inc edx

			push edx
				mov edx,[bytesread]
				inc edx
				mov [bytesread],edx
			pop edx

			jmp .readname
		.endofname:
			mov [name+edx],eax

			mov edx,[bytesread]
			inc edx
			mov [bytesread],edx

			xor eax,eax

			mov eax,[scores+edx]

			mov [score],eax

			;Kiiratjuk a nevet

			mov [colorr],word 80
			mov [colorg],word 80
			mov [colorb],word 80

			mov [tmpx],word 220

			push eax

				;Persze az i-edik sorba
				mov eax,56
				imul eax,ecx

				add eax,172

				push ecx

				mov [tmpy],eax
				mov esi,name
				call nio_writestr

				pop ecx

				push ecx

				mov [tmpx],word 720

				;Atalakitjuk az eredmenyt es azt is kiirjuk

				call nscoretostring

				mov esi,scorestr
				call nio_writestr

				pop ecx

			pop eax

			push edx
			mov edx,[bytesread]
			add edx,4
			mov [bytesread],edx
			pop edx

			inc ecx
		jmp .readscore
	.endofread:

.mapping:

	;Vege a mapolasnak

	call	gfx_unmap
	call	gfx_draw

	mov [event],word 0

	mov eax,[direction]
	mov [olddirection],eax

	cmp [popup],word 1
	je .skipevents

.eventloop:
	;Kezeljuk a gombokat (csak game eseteben)
	call	gfx_getevent

	cmp eax, 1
	jne .nocl
	mov [event],word 1

	.nocl:

	cmp		eax, 'w'
	je .up
	cmp		eax, 's'
	je .down
	cmp		eax, 'a'
	je .left
	cmp		eax, 'd'
	je .right

	jmp .directionend
	.up:
		mov eax,[olddirection]
		cmp eax,2
		je .directionend

		mov [direction], word 0
		jmp .directionend
	.down:
		mov eax,[olddirection]
		cmp eax,0
		je .directionend

		mov [direction], word 2
		jmp .directionend
	.left:
		mov eax,[olddirection]
		cmp eax,1
		je .directionend

		mov [direction], word 3
		jmp .directionend
	.right:
		mov eax,[olddirection]
		cmp eax,3
		je .directionend

		mov [direction], word 1
		jmp .directionend
	.directionend:
	

	cmp		eax, 23	
	je		.end
	cmp		eax, 27
	je		.end

	test	eax, eax
	jnz		.eventloop
	
	.skipevents:

	jmp 	.mainloop
    
	;Kilepunk
.end:
	call	gfx_destroy
    ret
    
	
section .data

    title db "Snakembly - Snake written in NASM", 0
	error db "Error:  Couldn't initialize graphics.", 0

	;File nevek
	f0 db "font.slx",0
	f1 db "background.slx",0
	f2 db "easy.slx",0
	f3 db "medium.slx",0
	f4 db "hard.slx",0
	f5 db "scoreboard.slx",0
	f6 db "easy_hover.slx",0
	f7 db "medium_hover.slx",0
	f8 db "hard_hover.slx",0
	f9 db "scoreboard_hover.slx",0
	f10 db "x.slx",0
	f11 db "x_hover.slx",0
	f12 db "a40.slx",0
	f13 db "s40.slx",0
	f14 db "game.slx",0
	f15 db "popup.slx",0
	f16 db "h40.slx",0
	f17 db "toplist.slx",0
	f18 db "btnmenu.slx",0
	f19 db "btnmenu_hover.slx",0
	f20 db "btnsubmit.slx",0
	f21 db "btnsubmit_hover.slx",0
	f22 db "scores.slx",0
	f23 db "s20.slx",0
	f24 db "h20.slx",0
	f25 db "a20.slx",0

	;Str-ek
	str_easy db "EASY",0
	str_medium db "MEDIUM",0
	str_hard db "HARD",0

	;A kep beolvasasahoz valtozok
	tmpwidth dd 0
	tmpheight dd 0
	tmppointer dd 0

	;Elhelyezes x,y
	tmpx dd 0
	tmpy dd 0

	;gfx_map pointer mutatoja es offset (eltolasok)
	mappointer dd 0
	mapoffset dd 0
	tmpoffset dd 0

	;Indexek
	i dd 0
	j dd 0	

	;Fileok pixel tombjei es a hozza tartozo szelesseg + magassagok
	img_background TIMES 3145728 DW 0
	img_background_w dd 0
	img_background_h dd 0

	img_game TIMES 3145728 DW 0
	img_game_w dd 0
	img_game_h dd 0

	img_toplist TIMES 3145728 DW 0
	img_toplist_w dd 0
	img_toplist_h dd 0

	img_menu_easy TIMES 129920 DW 0
	img_menu_easy_w dd 0
	img_menu_easy_h dd 0

	img_menu_medium TIMES 129920 DW 0
	img_menu_medium_w dd 0
	img_menu_medium_h dd 0

	img_menu_hard TIMES 129920 DW 0
	img_menu_hard_w dd 0
	img_menu_hard_h dd 0

	img_menu_scoreboard TIMES 109200 DW 0
	img_menu_scoreboard_w dd 0
	img_menu_scoreboard_h dd 0

	img_menu_easy_hover TIMES 129920 DW 0
	img_menu_easy_hover_w dd 0
	img_menu_easy_hover_h dd 0

	img_menu_medium_hover TIMES 129920 DW 0
	img_menu_medium_hover_w dd 0
	img_menu_medium_hover_h dd 0

	img_menu_hard_hover TIMES 129920 DW 0
	img_menu_hard_hover_w dd 0
	img_menu_hard_hover_h dd 0

	img_menu_scoreboard_hover TIMES 109200 DW 0
	img_menu_scoreboard_hover_w dd 0
	img_menu_scoreboard_hover_h dd 0

	img_menu_x TIMES 30800 DW 0
	img_menu_x_w dd 0
	img_menu_x_h dd 0

	img_menu_x_hover TIMES 30800 DW 0
	img_menu_x_hover_w dd 0
	img_menu_x_hover_h dd 0

	img_popup TIMES 804000 DW 0
	img_popup_w dd 0
	img_popup_h dd 0

	img_s_40 TIMES 6400 DW 0
	img_s_40_w dd 0
	img_s_40_h dd 0

	img_a_40 TIMES 6400 DW 0
	img_a_40_w dd 0
	img_a_40_h dd 0

	img_h_40 TIMES 6400 DW 0
	img_h_40_w dd 0
	img_h_40_h dd 0

	img_s_20 TIMES 1600 DW 0
	img_s_20_w dd 0
	img_s_20_h dd 0

	img_a_20 TIMES 1600 DW 0
	img_a_20_w dd 0
	img_a_20_h dd 0

	img_h_20 TIMES 1600 DW 0
	img_h_20_w dd 0
	img_h_20_h dd 0

	img_btn_menu TIMES 43036 DW 0
	img_btn_menu_w dd 0
	img_btn_menu_h dd 0

	img_btn_menu_hover TIMES 43036 DW 0
	img_btn_menu_hover_w dd 0
	img_btn_menu_hover_h dd 0

	img_btn_submit TIMES 43036 DW 0
	img_btn_submit_w dd 0
	img_btn_submit_h dd 0

	img_btn_submit_hover TIMES 43036 DW 0
	img_btn_submit_hover_w dd 0
	img_btn_submit_hover_h dd 0

	;A font
	font TIMES 302400 DW 0

	;Alma koordinatai 
	applex dd 0
	appley dd 0

	;A kigyo tombjei es merete
	snakex TIMES 1000 dd 0
	snakey TIMES 1000 dd 0
	snakesize dd 0

	;Iranykezeles
	direction dd 1
	olddirection dd 1

	;Elkaptunk egy almat?
	catch dd 0

	stage dd 0;0 - menu, 1 - game, 2 - scoreboard
	difficulty dd 0;0 - easy, ...

	;A hover kezelés határai és változoi
	x_start dd 0
	x_end dd 0
	y_start dd 0
	y_end dd 0

	hover dd 0

	;Clickeltunk
	event dd 0

	;A kigyo texturai
	size dd 0
	snaketexture dd 0
	appletexture dd 0
	headtexture dd 0

	;A map merete
	mapsize_x dd 0
	mapsize_y dd 0
	mapsize dd 0

	;A kigyo sebessege
	speed dd 0

	;Elougro ablak
	popup dd 0

	;Az eredmeny
	score dd 0
	scorestr TIMES 255 db 0
	
	;A nevunk
	name TIMES 255 db 0

	;A szinezes valtozoi
	colorr dd 0
	colorg dd 0
	colorb dd 0

	;Megnyomtunk egy gombot, gfx_getevent hibakezeles
	pressed dd 0

	;Az eredmeny es a rendezett lista
	scores TIMES 6024 db 0
	sorted TIMES 6024 db 0

	;Offset es filemeret valtozok
	filesize dd 0
	bytesread dd 0

	;A lista rendezesehez szukseges valtozok
	tmpfilesize dd 0
	previouspointer dd 0