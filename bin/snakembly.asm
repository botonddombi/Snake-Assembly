;nev: Dombi Botond
;id: dbim1614
;csoport: 511
;feladat: Projekt - Snake

%include 'io.inc'
%include 'mio.inc'
%include 'util.inc'
%include 'gfx.inc'

%define WIDTH  1024
%define HEIGHT 768

global main

section .text

;nutil + nio => sajat fuggvenyek


nutil_mousecheck:
;ellenorzi egy x1,x2 es y1,y2 koordinata kozott a mouse jelenletet
;hover = 1 ha igen
;hover = 0 ha nem
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

	;end

	.end:

	pop ebx
	pop eax
	
ret

nio_readimg:
;beolvas a memoriaba egy filet, igazabol egy kepet
;az elso 8 byteja, fejenkent 4-4 a hosszusag es szelesseg a tobbi RGBA
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

nio_placeimg:
;elhelyezi a beolvasott kepet a kepernyon
	push eax

	mov ebx,[tmpy]
	imul ebx,WIDTH
	add ebx,[tmpx]
	imul ebx,4
	mov [mapoffset],ebx

	pop eax


	mov [i], word 1
	mov [j], word 1
	.sor:
		mov ecx,[i]

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

		imul ebx,4
		add ebx,[mapoffset]

		pop eax

		mov edx,[mappointer]

		push ecx

		mov ecx,[eax+3]
		cmp cl,255

		jg .alphaugras

		;Magamnak - Gond van a filejaimmal ha alpha channel van (Png nem 256 color?)

		mov ecx,[eax+2]
		mov [edx+ebx],cl
		mov ecx,[eax+1]
		mov [edx+ebx+1],cl
		mov ecx,[eax]
		mov [edx+ebx+2],cl


		.alphaugras:


		pop ecx
		.sorkiugrik:

		add eax,4
		inc ecx
		mov [i],ecx

		jmp .sor
	.sorvege:
		mov ecx,[j]

		mov edx,[tmpheight]
		cmp ecx,edx
		je .vege

		mov edx,[j]
		add edx,[tmpy]
		cmp edx,HEIGHT
		je .vege


		mov ebx,[mapoffset]

		add ebx, WIDTH*4
		mov [mapoffset],ebx

		inc ecx
		mov [j],ecx
		mov [i],word 1
		jmp .sor

	.vege:

ret

nio_readfont:
;beolvassa a fontot (sajatos file)
	mov eax,f0
	mov ebx,0
	call fio_open

	mov ebx,font
	mov ecx,115200
	call fio_read

	call fio_close
ret

nio_writestr:
;kiir egy stringet az adott font segitsegevel
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

		sub eax,'0'
		imul eax,3200
		add eax,83200

		jmp .draw
	.betu:

		sub eax,'A'
		imul eax,3200

		jmp .draw
	.draw:
		push ecx
			mov ecx,[tmpoffset]
			mov [mapoffset],ecx
			xor ecx,ecx
			xor ebx,ebx

			.drawcycle:
				cmp ecx,20
				je .drawcycle_end

				push ecx

				imul ecx,4
				add ecx,[mapoffset]
				add ecx,[mappointer]

				push eax

				add eax,font

				mov edx,[eax+3]
				cmp dl,255

				jg .alphaugras

				mov edx,[eax]
				mov [ecx], word 80
				mov edx,[eax+1]
				mov [ecx+1], word 80
				mov edx,[eax+2]
				mov [ecx+2], word 80

				.alphaugras:

				pop eax

				add eax,4

				pop ecx

				inc ecx
				jmp .drawcycle

			.drawcycle_end:
				cmp ebx,40
				je .end

				mov ecx,[mapoffset]
				add ecx, WIDTH*4
				mov [mapoffset],ecx
				xor ecx,ecx

				inc ebx
				jmp .drawcycle
			.end:
			mov ecx,[tmpoffset]
			add ecx,80
			mov [tmpoffset],ecx

		pop ecx
		jmp .back
	.cycle_end:



ret

main:
	call nio_readfont

	;Betolt minden szukseges kepet
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

	;Grafika inicializalasa
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

.mainloop:
;A stage szerint vagy a scoreboardot, jatekot, vagy a menut rajzoljuk
	mov eax,[stage]
	cmp eax,0
	je .menu

	cmp eax,1
	je .game

	jmp .scoreboard

	.menu:;Stage = 0

		call gfx_map
		mov [mappointer], eax
		mov [p], eax

		;Hatter

		mov [tmpy],word 0
		mov [tmpx],word 0

		mov eax,[img_background_w]
		mov [tmpwidth],eax

		mov eax,[img_background_h]
		mov [tmpheight],eax

		mov eax,img_background
		call nio_placeimg

		;Menuk

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

		;Cursor kezeles

		mov [tmpx],word 280

		call gfx_getevent
		mov [event],eax

		call gfx_getmouse

		mov [x_start],word 280
		mov [x_end],word 744
		mov [y_start],word 240
		mov [y_end],word 310

		call nutil_mousecheck

		cmp [hover],word 0
		je .nohover1

		;Cursor menuk kezelese
		;Egyelore hianyos (Medium + Hard nem mukodik)
		.hover1:
			push eax

			mov eax,[event]
			cmp eax,1

			jne .noclick1

			pop eax

			mov [difficulty], word 0
			mov [stage], word 1

			jmp .game_init

			.noclick1:

			mov [tmpy],word 240

			mov eax,[img_menu_easy_hover_w]
			mov [tmpwidth],eax

			mov eax,[img_menu_easy_hover_h]
			mov [tmpheight],eax

			mov eax,img_menu_easy_hover
			call nio_placeimg

			pop eax
		.nohover1:
			mov [y_start],word 340
			mov [y_end],word 410

			call nutil_mousecheck

			cmp [hover],word 0
			je .nohover2
		.hover2:
			push eax

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

			pop eax
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

			pop eax

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

	jmp .mapolas
	;A jatek inicializalasa (Stage=0 - > Stage = 1)
	.game_init:

	mov [snakex], word 0
	mov [snakex+4], word 1
	mov [snakey], word 0
	mov [snakey+4], word 0
	mov [snakex+8], word 2
	mov [snakey+8], word 0

	mov [snakesize],word 3

	cmp [difficulty],word 0
	je .easy
	cmp [difficulty],word 1
	je .medium
	cmp [difficulty],word 2
	je .hard


	;Jatek beallitasok
	.easy:
		mov [size], word 40

		mov eax,img_s_40
		mov [snaketexture],eax
		mov eax,img_a_40
		mov [appletexture],eax
		mov eax,img_h_40
		mov [headtexture],eax
		mov [mapsize_x],word 24
		mov [mapsize_y],word 16
		mov [mapsize],word 192
		mov [speed],word 100

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

		jmp .mapolas
	;Medium + Hard hianyos egyelore
	.medium:
		mov [size], word 40
		jmp .mapolas
	.hard:
		mov [size], word 20
	jmp .mapolas

	.game:; Stage = 1 (ekkor a jatekot rajzoljuk)

	cmp [popup],word 0
	je .nopopup

	;Lekezelni az irast
	;Itt kezeljuk majd azt ha a user beirja a nevet
	;HIANYZIK

	jmp .snakeend
	.nopopup:
	;Nincs popup ablak, vagyis nincs vege a jateknak, a user nem kell irjon

	mov [catch],byte 0

	mov ecx,[snakesize]
	dec ecx

	imul ecx,4

	mov ebx,[snakex+ecx]
	mov edx,[snakey+ecx]

	;Iranykezeles

	cmp [direction],byte 0
	je .nulla
	cmp [direction],byte 1
	je .egy
	cmp [direction],byte 2
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

	;Leteszteljuk a fallal valo utkozest
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


	;Almaval valo utkozes

	cmp ebx,[applex]
	jne .continue
	cmp edx,[appley]
	jne .continue

	mov ecx,[snakesize]
	imul ecx,4

	mov [snakex+ecx],ebx
	mov [snakey+ecx],edx

	mov eax,[snakesize]
	inc eax
	mov [snakesize],eax 

	push ebx

	mov ebx,[mapsize]
	cmp eax,ebx
	jne .noend
	pop ebx

	mov [popup], word 1
	jmp .snakeend

	.noend:
	pop ebx

	;Uj alma
	.apple_generate:
		call rand
		mov ebx,[mapsize_x]
		cdq
		idiv ebx

		cmp edx,0
		jge .skip1

		imul edx,-1

		.skip1:

		mov [applex],edx

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
		;Ujrageneraljuk az almat
		jmp .apple_generate

		.ok1:

		pop ecx

		inc ecx

	jmp .apple_check

	;Legeneraltuk az almat
	.apple_done:
	mov [catch], byte 1

	jmp .snakeend

	.continue:
	;A kigyo sajat magaval valo utkozeset is leteszteljuk

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
		

		mov [popup], word 1
		jmp .snakeend

		;GAME OVER
		;Utkoztunk

		.ok2:

		pop ecx

		inc ecx
	jmp .self_check


	;Epitjuk a kigyot
	.self_done:

	push ebx
	push edx

	mov ecx,1
	;A kigyo tombbol mindig "poppolunk egye elemet elolrol, es a hatara pedig pusholunk egyet"
	.snakebuild:
	;Pop	
		cmp ecx,[snakesize]
		jg .snakebuildend
		push ecx

		imul ecx,4
		mov ebx,[snakex+ecx]
		mov edx,[snakey+ecx]
		
		sub ecx,4
		mov [snakex+ecx],ebx
		mov [snakey+ecx],edx

		pop ecx
		inc ecx
		jmp .snakebuild
	.snakebuildend:
	;Push
	pop edx
	pop ebx

	mov ecx,[snakesize]
	dec ecx

	imul ecx,4

	mov [snakex+ecx],ebx
	mov [snakey+ecx],edx
	
	.snakeend:
	;Megkezdjuk a rajzolast

	call gfx_map	
	mov [mappointer], eax
	mov [p], eax

	mov [tmpy],word 0
	mov [tmpx],word 0

	mov eax,[img_game_w]
	mov [tmpwidth],eax

	mov eax,[img_game_h]
	mov [tmpheight],eax

	mov eax,img_game
	call nio_placeimg

	.layer1:
		mov ecx,0

		.snakeciklus:
			cmp ecx,[snakesize]
			je .snakevege

			;Fej

			push ecx

			inc ecx
			cmp ecx,[snakesize]
			jne .nothead

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

			;Test

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
			jmp .snakeciklus
		;Kirajzoljuk az almat is
		.snakevege:

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

			;cmp [catch], word 1
			;je .mapolas

			;Str kiiratas

			;Kiirjuk a nehezseget a font segitsegevel

			cmp [difficulty],word 0
			je .easystr
			cmp [difficulty],word 1
			je .mediumstr
			mov esi,str_hard

			jmp .strend
			.easystr:
				mov esi,str_easy
				jmp .strend
			.mediumstr:
				mov esi,str_medium
			.strend:

			mov [tmpx],word 260
			mov [tmpy],word 50
			call nio_writestr


			cmp [popup],word 0
			jne .popup

			mov eax,[speed]
			call sleep

			jmp .mapolas


			;Popup ablak rajzolasa ha szukseges (ideugrassal)
			.popup:

			mov [tmpy],word 244
			mov [tmpx],word 212

			mov eax,[img_popup_w]
			mov [tmpwidth],eax

			mov eax,[img_popup_h]
			mov [tmpheight],eax

			mov eax,img_popup
			call nio_placeimg

	jmp .mapolas

	.scoreboard_init:

	jmp .mapolas


	;A scoreboard (hianyos)
	.scoreboard:

	;Kirajzoljuk
	call gfx_map	
	mov [mappointer], eax
	mov [p], eax

	mov [tmpy],word 0
	mov [tmpx],word 0

	mov eax,[img_toplist_w]
	mov [tmpwidth],eax

	mov eax,[img_toplist_h]
	mov [tmpheight],eax

	mov eax,img_toplist
	call nio_placeimg

	mov [tmpx],word 170
	mov [tmpy],word 640

	mov eax,[img_menu_x_w]
	mov [tmpwidth],eax

	mov eax,[img_menu_x_h]
	mov [tmpheight],eax

	mov eax,img_menu_x
	call nio_placeimg


	;Az exit button kezelese
	call gfx_getevent
	mov [event],eax

	call gfx_getmouse

	mov [x_start],word 176
	mov [x_end],word 270
	mov [y_start],word 640
	mov [y_end],word 710

	call nutil_mousecheck

	cmp [hover],word 0
	je .nohover

	mov eax,[event]
	cmp eax,1

	jne .noclick

	mov [stage], word 0
	jmp .mapolas

	.noclick:

	mov [tmpx],word 170
	mov [tmpy],word 640

	mov eax,[img_menu_x_hover_w]
	mov [tmpwidth],eax

	mov eax,[img_menu_x_hover_h]
	mov [tmpheight],eax

	mov eax,img_menu_x_hover
	call nio_placeimg

	.nohover:


.mapolas:
	call	gfx_unmap
	call	gfx_draw
.eventloop:
	call	gfx_getevent
		
	;Az iranyitas kezelese
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
		mov eax,[direction]
		cmp eax,2
		je .directionend

		mov [direction], byte 0
		jmp .directionend
	.down:
		mov eax,[direction]
		cmp eax,0
		je .directionend

		mov [direction], byte 2
		jmp .directionend
	.left:
		mov eax,[direction]
		cmp eax,1
		je .directionend

		mov [direction], byte 3
		jmp .directionend
	.right:
		mov eax,[direction]
		cmp eax,3
		je .directionend

		mov [direction], byte 1
		jmp .directionend
	.directionend:
	

	cmp		eax, 23	
	je		.end
	cmp		eax, 27	
	je		.end
	test	eax, eax
	jnz		.eventloop
	
	
	cmp		dword [movemouse], 0
	je		.updateoffset
	call	gfx_getmouse
	mov		ecx, eax
	mov		edx, ebx
	sub		eax, [prevmousex]
	sub		ebx, [prevmousey]
	sub		[offsetx], eax
	sub		[offsety], ebx
	mov		[prevmousex], ecx
	mov		[prevmousey], edx
	
.updateoffset:
	add		[offsetx], esi
	add		[offsety], edi

	cmp [catch],byte 1
	je .nosleep

	.nosleep:

	jmp 	.mainloop
    
.end:
	call	gfx_destroy
    ret
    
	
section .data
    title db "Snakembly - Snake written in NASM", 0
	error db "Error:  Couldn't initialize graphics.", 0
	
	
	offsetx dd 0
	offsety dd 0
	
	movemouse dd 0 
	prevmousex dd 0
	prevmousey dd 0
	
	p dd 0
	q dd 0


	;Filenevek
	f db "image.slx",0
	g db "image2.slx",0
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

	;Stringek
	str1 db "EASY",0
	str_easy db "EASY",0
	str_medium db "MEDIUM",0
	str_hard db "HARD",0

	;Valtozok
	char dd 0
	x dd 0
	y dd 0

	;Fuggveny segedvaltozok
	tmpwidth dd 0
	tmpheight dd 0
	tmppointer dd 0
	tmpf dd 0

	tmpx dd 0
	tmpy dd 0

	mappointer dd 0
	mapoffset dd 0
	tmpoffset dd 0

	i dd 0
	j dd 0


	;Dev uzenetek
	devmsg1 db "Reading image with size of: ",0
	devmsg2 db "Reading done.",0


	;Kepek tombjei
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


	;Font
	font TIMES 115200 DW 0


	;Alma x,y
	applex dd 20
	appley dd 20


	;A kigyo tombjei,merete
	snakex TIMES 1000 dd 0
	snakey TIMES 1000 dd 0
	snakesize dd 0

	;Irany
	direction dd 1

	;Fogtunk e almat?
	catch dd 0

	;Testnek, alpha channel blend
	opacity dd 0


	stage dd 0;0 - menu, 1 - game, 2 - scoreboard
	difficulty dd 0;0 - easy, ...

	;nutil_mousecheck segedvaltozoi
	x_start dd 0
	x_end dd 0

	y_start dd 0
	y_end dd 0

	hover dd 0
	event dd 0


	;Jatekbeallitasok valtozoi
	size dd 0
	snaketexture dd 0
	appletexture dd 0
	headtexture dd 0

	mapsize_x dd 0
	mapsize_y dd 0
	mapsize dd 0

	speed dd 0

	;Felugro ablak kezelese
	popup dd 0

	;Eredmeny
	score dd 0