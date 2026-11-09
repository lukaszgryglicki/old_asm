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
	movw $BIOS_LOAD_ADDR,%ax	#tymczasowo
	movw %ax,%ds			#zaladuj REJESTR SEGMENTOWY DANYCH
	movw %ax,%ss			#i stos
	movw $STACK_SIZE,%sp		#przesun stos o 0x1000 (ustal dlugosc stosu na 4096 bajtow) 
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
	lgdt (gdtr)			#wczytaj (do CPU) GDT (globalna tablice deskryptorow)
	mov %cr0,%eax			#ustaw bit
	or $PROT_MASK_CR0,%al		#trybu	(TERAZ TRYB CHRONIONY 16 BITOWY -sciscej po ljmp do .code16)
	mov %eax,%cr0 			#chronionego w MSW (Machine Status Word)
	ljmp $SYS_CODE_SEL, $do_pm	#robi to daleki skok (tutaj do .code32 wiec prot32, jesli chcemy prot16 to
.code32					#ljmp do .code16 i wylaczyc bit tryb32 w selektorze kodu/danych - patrz inet)
do_pm:					#mamy 32bit kod, selektory ustawione na 32
        xor %edi,%edi			#trzeba je jeszcze zaladowac... edi=0
        xor %esi,%esi			#esi=0
	mov $SYS_DATA_SEL, %ax		#wez selektor danych, kodu juz jest zaladowany przez ljmp!!!
	mov %ax,%ds			#ustaw go dla DS i SS (dane i stos)
	mov %ax,%ss			#ustawiamy selectory +RW-X (patrz inet opis selektorow)
	mov $LINEAR_SEL, %ax		#a FLAT 4G ustawimy sobie na
	mov %ax,%es				#ES (extra segment) teraz przez ES mozemy wolac dowolne dane!!!
	lea msg, %esi					#druga informacja
	mov $(TEXT_MODE_OFF+TEXT_MODE_LEN), %edi	#adresowanie po DS (DS ma baze=0 trzeba wyznaczyc adres)
	mov $0xc,%ecx					# ECX dlugosc
	cld					#++
	rep movsb				#wypisz w trybie chronionym!!! PROT32
	call prot32_os				#umiesc tutaj swoj system operacyjny :-)
do_rm:
	.code16
	ret
RealModeIP:				#wskaznik instrukcji (16bitowy) z trybu Real_mode
        .word 0				#uzywany przez ljmp CS:IP do powrotu do real_mode
RealModeCS:				#rejestr segmentowy kodu (16bit) z trybu
	.word 0				#real_mode
msg:   .ascii "p%r%o%t%3%2%"		#dlugosc kazdego 12 bajtow
dbg:	.ascii "d b g "
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
	call reloca_self		#to 1M offset!
	jmp .+0x1000000
	call debug
halt:
	jmp halt
reloca_self:
	xor %esi, %esi
	movl $0x1000000, %edi
	movl $0x200, %ecx
	cld
	rep movsb
	ret
debug:
	lea dbg, %esi
	mov $(TEXT_MODE_OFF+2*TEXT_MODE_LEN), %edi
	mov $0x6,%ecx
	cld
	rep movsb
	ret
	.word BOOTABLE_MAGIC
