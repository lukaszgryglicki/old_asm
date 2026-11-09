.text					#segment tekstu: jedyny
.code16					#w trybie rzeczywistym 16 bit
.set NULL_SEL,0				#NULL selektor
.set LINEAR_SEL, 8			#selektor FLAT 4G
.equ SYS_CODE_SEL, 16			#selektor kodu Ring0
.set SYS_DATA_SEL, 24			#Selektor danych Ring0
.set REAL_CODE_SEL, 32			#Selektor kodu trybu rzeczywistego (aby wrocic)
.set REAL_DATA_SEL, 40			#Selektor danych trybu rzeczywisyego
.set BIOS_LOAD_ADDR, 0x7c0		#Adres pod ktory BIOS wczytuje 1 sektor (512 bajtow)
.set STACK_SIZE,0x1000			#rozmiar stosu
.set TEXT_MODE_MEM,0xb800		#segment trybu tekstowego
.set TEXT_MODE_OFF,0xb8000		#adres rzeczywisty (w LINEAR_SEL) trybu tekstowego tj SEGM<<4
.set TEXT_MODE_LEN,160			#dlugosc lini ekranu: 80*2 po 2 bajty na znak (4bColF-4bColLit-8bLitera)
.set REAL_MASK_CR0, 0xFE		#maska 11111101 do zerowania CR0,1bit <Pmode bit>
.set PROT_MASK_CR0, 0x1			#maska 00000010 do ustawiania CR0,1bit
.set BOOTABLE_MAGIC,0xaa55		#osatnie 2 bajty sektora 510 i 511 (od 0 liczac) - sygnatura "bootowalny"
_start:					#start tutaj pod adresem TEXT 0000
	cli 				#wylacz przerwania
	movw $BIOS_LOAD_ADDR,%ax	#tymczasowo
	movw %ax,%ds			#zaladuj REJESTR SEGMENTOWY DANYCH
	movw %ax,%ss			#i stos
	movw $STACK_SIZE,%sp		#przesun stos o 0x1000 (ustal dlugosc stosu na 4096 bajtow) 
	sti				#wlacz przerwania
	#call init16			#dodatkowe f-cje powinny byc po zaladowaniu reszty kodu z dyskietki poza 0xAA55
	call proton			#wlacz i wylacz tryby: rm16->PM16->PM32->UnReal->rm16
protoff_halt:				#OS halt, infinite_loop
	jmp protoff_halt		#nieskonczona petla
proton:					#odpal tryb chroniony
	xor %ebx,%ebx			#ebx=0
	mov %ds,%bx                     #bx=ds |----------------|DDDDDDDDDDDDDDDD| 
	shll $4,%ebx                    #      |------------DDDD|DDDDDDDDDDDD----| adres rzeczywisty wzgledem 0
	mov %ebx,%eax			#eax=ebx
	mov %ax, (gdt2+2)		#ustal bazy selektorow (16 bitow tych baz) kodu
	mov %ax, (gdt3+2)		#danych
	mov %ax, (gdt4+2)		#kodu real
	mov %ax, (gdt5+2)		#danych real
	shr $0x10,%eax			# |--------AAAAAAAAAAAAAAAAAAAAAAAAA| -> |------------------------AAAAAAAA|
	mov %al, (gdt2+4)		#ustal pozostale 8 bitow adresu bazowego
	mov %al, (gdt3+4)		#w analogicznych selektorach
	mov %al, (gdt4+4)		#bity te sa przesuniete o 4 bajty (mlodsza czesc AL)
	mov %al, (gdt5+4)		#a starsza czasc AH
	mov %ah, (gdt2+7)		#o 7 bajtow
	mov %ah, (gdt3+7)		#ogolnego wygladu selektora poszukaj
	mov %ah, (gdt4+7)		#na internecie
	mov %ah, (gdt5+7)		#zaladuj do EAX 32bitowy adres GDT przesuniety o adres sekcji kodu (bezwzgledny)
	addr32 lea gdt(%ebx), %eax	#po to na poczatku obliczalismy EBX, PROT adresuje przez selektory
        mov %eax, (gdtr+2)		#wyslij ten adres do GDTR+2 (tam adres a +0 ilosc wpisow w tablicy GDT)
	cli					#trzeba chwilowo wylaczyc przerwania
	movw $BIOS_LOAD_ADDR, (RealModeCS)	#tutaj adres sekcji kodu dla trybu rzeczywistego (chcemy wrocic)
	lea do_rm, %ax				#a tutaj jak juz wrocimy do sekcji kodu to gdzie? : do_rm
	movw %ax, (RealModeIP)		#zapamietaj te wartosci w dwoch WORDach, wskaznik instrukcji CPU->do_rm
	mov $TEXT_MODE_MEM, %ax		#w stosie ES (extra segment) chemy miec pamiec trybu tekstowego
	mov %ax,%es			#wiec zaladujmy...
	lgdt (gdtr)			#wczytaj (do CPU) GDT (globalna tablice deskryptorow)
	mov %cr0,%eax			#ustaw bit
	or $PROT_MASK_CR0,%al		#trybu	(TERAZ TRYB CHRONIONY 16 BITOWY -sciscej po ljmp do .code16)
	mov %eax,%cr0 			#chronionego w MSW (Machine Status Word)
        lea msg0, %si			#wez adres msg1 	     SI
        mov $(TEXT_MODE_LEN), %di	#wez adres pamieci tekstowej DI
        mov $0xc,%cx			#ile razy przesylac?         CX
        cld				#w ktora strone zwiekszac? : si++,di++
        rep movsb			#wykonaj przesylanie danych
	#call prot16			#tutaj jestesmy w prot16 (trzeba jeszcze wyczyscic kolejke rozkazow)
	ljmp $SYS_CODE_SEL, $do_pm	#robi to daleki skok (tutaj do .code32 wiec prot32, jesli chcemy prot16 to
.code32					#ljmp do .code16 i wylaczyc bit tryb32 w selektorze kodu/danych - patrz inet)
do_pm:					#mamy 32bit kod, selektory ustawione na 32
        xor %edi,%edi			#trzeba je jeszcze zaladowac... edi=0
        xor %esi,%esi			#esi=0
	lea msg1,%si                   	#SI=&msg1
        mov $(2*TEXT_MODE_LEN), %di	#napisz w kolejnej linijce
        mov $0xc,%ecx			#SI,DI
        cld				#++
        rep movsb			#napisz
	mov $SYS_DATA_SEL, %ax		#wez selektor danych, kodu juz jest zaladowany przez ljmp!!!
	mov %ax,%ds			#ustaw go dla DS i SS (dane i stos)
	mov %ax,%ss			#ustawiamy selectory +RW-X (patrz inet opis selektorow)
	mov $LINEAR_SEL, %ax		#a FLAT 4G ustawimy sobie na
	mov %ax,%es				#ES (extra segment) teraz przez ES mozemy wolac dowolne dane!!!
	movw $0x2030, %es:(TEXT_MODE_OFF)	#0xABHH where AB color B/F HH number of hex
	movw $0x2131, %es:(TEXT_MODE_OFF+2)	#4bity to kolor podloza
	movw $0x2432, %es:(TEXT_MODE_OFF+4)	#4bity to kolor litery
	movw $0x2533, %es:(TEXT_MODE_OFF+6)	#nast 8 to liera np: 2131: podl(0x2),kolor(0x1),litera(0x31)='1'
	lea msg2, %esi					#druga informacja
	mov $(TEXT_MODE_OFF+3*TEXT_MODE_LEN), %edi	#adresowanie po DS (DS ma baze=0 trzeba wyznaczyc adres)
	mov $0xc,%ecx					# ECX dlugosc
	cld					#++
	rep movsb				#wypisz w trybie chronionym!!! PROT32
	call prot32_os				#umiesc tutaj swoj system operacyjny :-)
	ljmp  $REAL_CODE_SEL, $do_16		#skocz do selektora REAL_MODE:funkcji do_16
do_16:					#wrocimy do trybu real, trzeba odzyskac
	.code16				#rejestry segmentowe z selektorow trybu rzeczywistego
	mov $REAL_DATA_SEL,%ax		#selektor danych do
	mov %ax,%ss			#rejestru stosu
	mov %ax,%ds			#i danych
	mov %cr0,%eax			#wyzerowac bit PM
	and $REAL_MASK_CR0,%al		#uzywajac maski
	mov %eax,%cr0			#teraz trzeba zmienic rejestr CS, do tego ljmp przeladuje
	ljmp *(RealModeIP)		#przeskocz do zapisanego IP, ktore wskazuje na do_rm	
					#bierze kolejno z pamieci RealModeIp,RealModeCS
					#i skacze do CS:IP trybu rzeczywistego (uzywa segmentow nie selektorow)
					#odwrotnie jak w PROT
					#TUTAJ UNREAL 32 ??? (przed ljmp i zmiana segmentow ds i ssmamy CHYBA tryb 
					#prawie chroniony 32bity, FLAT ale bez bitu CR0) nazwac go np: UnProtected32 ??
					#nie wiem CZY dziala i JAK dziala, ale po ljmp jestesmy w Unreal na pewno
do_rm:					#tutaj juz jestesmy czesciowo w real_mode (Unreal), real mogacy adresowac
	.code16						#32bitowo, instrukcje sa 16bitowe ale adresy pozostaly 32bit
	addr32 movw $0x2634, %es:(TEXT_MODE_OFF+8)	#ale do instrukcji trzeba dodac prefiks bo ta jest domyslnie
	xor %ax,%ax					#16bitowa, wlacz FLAT_4G dla ES w trybie UnReal
	mov %ax,%es					#teraz DZIALA!!!!
	addr32 movw $0x2735, %es:(TEXT_MODE_OFF+10)	#slabe jest?, wpisuje w dowolne komorki w Unreal >16M np
	addr32 movl $0xdeadfeed, %es:0x0110000		#pod adres FLAT 17M wpisuje DEADFEAD !!!!$$$!!!!!$$$$$!!!!!
	lea msg3, %esi					#informacja 3cia
	mov $(TEXT_MODE_OFF+4*TEXT_MODE_LEN), %edi	#adresowanie z PROT32 a tryb UNREAL 16!!	
	mov $0xc,%ecx					#12 bajtow do przeslania
	cld				#w prawo ++
	addr32 rep movsb		#z prefiksem bo adresowanie musi byc 32bitowe
	#call unreal			#tutaj mozna wstawic kozacki OS dzialajacy w trybie UnReal
	mov %cs,%ax			#ale juz czas na real_mode
	mov %ax,%ds			#dane i stos byly w tym samym segmencie co kod (zegnaj UnReal)
	mov %ax,%ss			#poniewaz komputer startowal poprzez ten program jako MBR
	mov $TEXT_MODE_MEM,%ax		#adres pamieci tekstowej
	mov %ax,%es			#do ES (w ten sposob likidujemy juz bramke UnReal)
	lea msg4, %si			#SI = addres msg4
	mov $(5*TEXT_MODE_LEN), %di	#kolejna (6 linia)	
	mov $0xc,%cx			#jak zwykle SI,DI
	cld				#++
	rep movsb			#kopiowanie CX razy do pamieci (czyli wypisanie tekstu)
	sti				#przerwania juz mozna wlaczyc
	jmp protoff_halt		#real_mode z powrotem skaczemy do protoff_halt
RealModeIP:				#wskaznik instrukcji (16bitowy) z trybu Real_mode
        .word 0				#uzywany przez ljmp CS:IP do powrotu do real_mode
RealModeCS:				#rejestr segmentowy kodu (16bit) z trybu
	.word 0				#real_mode
msg0:   .ascii "r e a l 1 6 "		#teksty, litery
msg1:   .ascii "p(r(o(t(1(6("		#i ich atrybuty
msg2:   .ascii "p%r%o%t%3%2%"		#dlugosc kazdego 12 bajtow
msg3:	.ascii "uznzrzezazlz"		#UnReal the best
msg4:   .ascii "r e a l 1 6 "
gdtr:	.word gdt_end-gdt-1		#dlugosc tablicy GDT
	.long gdt             		#adres tej tablicy w pamieci (i tak programowo zmieniany bo musi to byc
gdt:					#adres rzeczywisty!!)
	.word 0				#NULL descriptor
	.word 0				#zawiera m.in: adres bazowy,wielkosc
	.byte 0				#bity uprawnien,RINGn,bit 32bitowosci, bit ziarnistosci
	.byte 0				#itp glupoty
	.byte 0	
	.byte 0
gdt1:
	.word 0xFFFF			#LINEAR_DESCRIPTOR (na razie wszystkie deskryptory trybu
	.word 0				#chronionego maja baze rowna 0 i wielkosc maksymalna tj. 0xFFFFF
	.byte 0				#a w trybie rzeczywistym wielkosc musi byc 2**16-1
	.byte 0x92			#tj 0XFFFF
        .byte 0xCF                 
	.byte 0
gdt2:   				#SYS_CODE_DESCRIPTOR
	.word 0xFFFF               
	.word 0			
	.byte 0
	.byte 0x9A			
        .byte 0xCF                
	.byte 0
gdt3:   				#SYS_DATA_DESCRIPTOR
	.word 0xFFFF               
	.word 0			
	.byte 0
	.byte 0x92			
        .byte 0xCF                 
	.byte 0
gdt4:   				#REAL_CODE_DESCRIPTOR
	.word 0xFFFF			
	.word 0			
	.byte 0
	.byte 0x9A		
	.byte 0			
	.byte 0
gdt5:   				#REAL_DATA_DESCRIPTOR
	.word 0xFFFF
	.word 0			
	.byte 0
	.byte 0x92			
	.byte 0		
	.byte 0
gdt_end:				#do obliczenia wielkosci GDT
prot32_os:				#tutaj kod "system", powinien uzywajac ??? INT 13H ???
	.code32				#zaladowac reszte kodu pod jakis adres
	#jmp halt			#(to halt OS in PROT32)
	#jmp multi_sector_os_code	#i utworzyc dla tego adresu deskryptor np CS (kodu)
	nop				#(powinno byc JMP (kod wczytany do RAM z dysku/dyskietki) a nie RET)
	nop 				#i potem wykonac skok poza bajt 0x200 (tj 512-sty)
	nop 				#powinno byc jmp multi_sector_os_code
	nop 				#i addr of multi_sector_os_code powinien byc np = 512
	nop				#i tam reszta instrukcji OS (tzw. relokacja!)
	nop 				#te NOPy wypelniaja kod do 513 a potem wstawiaja 0xAA55 = MAGIC_BOOTABLE
	nop 				#aby BIOS mogl zaladowac dyskietke/dysk
	nop 				#zawierajac(a)(y) ten kod, potem musi sie on sam zrelokowac gdzie indziej!
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	nop 
	nop
	nop 
	nop 
	ret 
	.word BOOTABLE_MAGIC
#multi_sector_os_code:		#nie da sie tu "DOSKOCZYC" zadnym jmp bo ten kod >512 bajt nie jest ladowny przez
				#BIOS!!! i trzeba to zrobic recznie, HELP!
#######################################################
#######################################################
###  UNIX Makefile ####  for  #  FreeBSD  #############
#######################################################
#### Should work with any Linux #######################
####################################################### 
#przepisz to makefile
# all: os_unreal.bootimg
# os_unreal.bootimg: os_unreal.relloc
# 	ld -o os_unreal.bootimg --oformat binary -Ttext 0x0000 os_unreal.relloc
# os_unreal.relloc: os_unreal.s
# 	as -o os_unreal.relloc os_unreal.s
# run: os_unreal.bootimg
# 	-bochs -qf ./rc_unreal
# clean: 
# 	-rm os_unreal.relloc os_unreal.bootimg parport.out log.out debugger.out

# opis: przepisz to makefile do pliku Makefile
# i wpisz: make
# utworzysz plik os_unreal.bootimg
# teraz mozna go nagrac na dyskietke
# dd if=./os_unreal.bootimg of=/dev/fd0 (ewentualnie bs=512 count=1)
# upewnij sie czy plik jest bootowalny:
# file os_unreal.bootimg
# powinno byc: os_unreal.bootimg: x86 boot sector
# jak masz emulator BOCHS: bochs.sourceforge.net (darmowy) to:
# wpisz make run, wystartuje OS od razu z Bochsa (plik konfiguracyjny zapisalem ponizej)
# rc_unreal, mozna wylaczyc sprawdzanie sygnatury bootowalnosci (ja tak zrobiulem) tak jest wygodniej!
# w VMware tez mozna testowac:
# cp os_unreal.bootimg /somewhere/floppy.img i dodaj floppy.img do vmware jako ImageFile 
# w biosie vmware wez f2 i ustaw kolejnosc bootowania: najpierw floppy potem cokolwiek
# :-) enjoy
######################################################
## BOCHS' config file skopiuj do ./rc_unreal##########
###################################################### assume bochs 2.0.2 or later
######################################################
######################################################

#romimage: file=/where/your/bochs/data/files/are/BIOS-bochs-latest, address=0xf0000
#megs: 24
#vgaromimage: /somewhere/in/hell/Venom/Black/Metal/VGABIOS-elpin-2.40
#floppya: 1_44=os_unreal.bootimg, status=inserted
#ata0: enabled=0, ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14
#ata1: enabled=0, ioaddr1=0x170, ioaddr2=0x370, irq=15
#ata2: enabled=0, ioaddr1=0x1e8, ioaddr2=0x3e8, irq=11
#ata3: enabled=0, ioaddr1=0x168, ioaddr2=0x368, irq=9
#boot: floppy
#floppy_bootsig_check: disabled=1
#log: log.out
#panic: action=ask
#error: action=report
#info: action=report
#debug: action=ignore
#debugger_log: debugger.out
#parport1: enabled=1, file="parport.out"
#vga_update_interval: 80000
#keyboard_serial_delay: 250
#keyboard_paste_delay: 100000
#floppy_command_delay: 500
#ips: 50000
#mouse: enabled=0
#private_colormap: enabled=0
#fullscreen: enabled=0
#screenmode: name="sample"
#keyboard_mapping: enabled=0, map=
#i440fxsupport: enabled=0
#o selektorach/deskryptorach sugeruje przeczytac : pm1.asm (uzywa NASM)
#
############################# NASTEPNE LINIJKI Z INFORMACJAMI SA SKOPIOWANE Z INNEGO PLIKU
############################# NIE NAPISANEGO PRZEZE MNIE, MAM NADZIEJE ZE W TEN SPOSOB
############################# NIE NARUSZAM ZADNYCH PRAW AUTORSKICH, PONIEWAZ JEST TO TYLKO BIBLIOGRAFIA
#	pm1.asm - protected-mode demo code
#	Christopher Giese <geezer[AT]execpc.com>
#	http://www.execpc.com/~geezer/os
#	Release date 10/7/98. Distribute freely. ABSOLUTELY NO WARRANTY.
#	Assemble with NASM:	nasm -o pm1.com pm1.asm
# Sources:
#   INTEL 80386 PROGRAMMER'S REFERENCE MANUAL 1986
#	http://www.execpc.com/~geezer/os/386intel.zip
#       ftp://ftp.cdrom.com/.20/demos/code/hardware/cpu/386intel.zip
#       http://www.intercom.net/user/jeremyfo/SamOS/Files/386intel.zip
#   Robert Collins' "Intel Secrets" web site:
#       http://www.x86.org
