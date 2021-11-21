
; wczytywanie i wyświetlanie tekstu wielkimi literami
; (inne znaki się nie zmieniają)
.686
.model flat
extern _ExitProcess@4 : PROC
extern _MessageBoxW@16 : PROC
extern __write : PROC ; (dwa znaki podkreślenia)
extern __read : PROC ; (dwa znaki podkreślenia)
; obszar danych programu
.data
; wczytywanie liczby dziesiętnej z klawiatury – po
; wprowadzeniu cyfr należy nacisnąć klawisz Enter
; liczba po konwersji na postać binarną zostaje wpisana
; do rejestru EAX
; deklaracja tablicy do przechowywania wprowadzanych cyfr
; (w obszarze danych)
obszar db 12 dup (?)
dziesiec dd 13 ; mnożnik
; deklaracja tablicy 12-bajtowej do przechowywania
; tworzonych cyfr
znaki db 12 dup (?)
znak db ' '
dekoder db '0123456789ABC'
.code
wyswietl_EAX_U2_b13 PROC
mov znak, ' '
bt eax, 31
jnc pomin_negacje
neg eax
mov znak, '-'
pomin_negacje:
mov   esi, 10  ; indeks w tablicy 'znaki' 
mov   ebx, 13  ; dzielnik równy 13
 
konwersja: 
 mov   edx, 0 ; zerowanie starszej części dzielnej 
 div   ebx   ; dzielenie przez 10, reszta w EDX, 
; ASCII 
and dx, 0000000000001111b;
mov dl, dekoder[edx]
 mov   znaki [esi], dl; zapisanie cyfry w kodzie ASCII 
 dec   esi    ; zmniejszenie indeksu 
 cmp   eax, 0  ; sprawdzenie czy iloraz = 0 
 jne   konwersja  ; skok, gdy iloraz niezerowy 
 
; wypełnienie pozostałych bajtów spacjami i wpisanie 
; znaków nowego wiersza 

xor edx,edx
 mov   dl, znak ; kod spacji 
 mov   byte PTR znaki [esi], dl ; kod znaku 
 dec   esi    ; zmniejszenie indeksu 
wypeln: 
 or  esi, esi 
 jz  wyswietl   ; skok, gdy ESI = 0 
 mov   byte PTR znaki [esi], 20H ; kod spacji 
 dec   esi    ; zmniejszenie indeksu 
 jmp   wypeln 
  
wyswietl: 
 mov   byte PTR znaki [0], 0AH ; kod nowego wiersza 
 mov   byte PTR znaki [11], 0AH ; kod nowego wiersza 
 
; wyświetlenie cyfr na ekranie 
 push  dword PTR 12 ; liczba wyświetlanych znaków 
 push  dword PTR OFFSET znaki ; adres wyśw. obszaru 
 push  dword PTR 1; numer urządzenia (ekran ma numer 1) 
 call  __write  ; wyświetlenie liczby na ekranie 
 add   esp, 12  ; usunięcie parametrów ze stosu 
 ret
wyswietl_EAX_U2_b13 ENDP
wczytaj_EAX_U2_b13 PROC
mov znak, ' '
; wczytywanie liczby szesnastkowej z klawiatury – liczba po
; konwersji na postać binarną zostaje wpisana do rejestru EAX
; po wprowadzeniu ostatniej cyfry należy nacisnąć klawisz
; Enter
push ebx
push ecx
push edx
push esi
push edi
push ebp
mov ebx, 13
; rezerwacja 12 bajtów na stosie przeznaczonych na tymczasowe
; przechowanie cyfr szesnastkowych wyświetlanej liczby
sub esp, 12 ; rezerwacja poprzez zmniejszenie ESP
mov esi, esp ; adres zarezerwowanego obszaru pamięci
push dword PTR 10 ; max ilość znaków wczytyw. liczby
push esi ; adres obszaru pamięci
push dword PTR 0; numer urządzenia (0 dla klawiatury)
call __read ; odczytywanie znaków z klawiatury
; (dwa znaki podkreślenia przed read)
add esp, 12 ; usunięcie parametrów ze stosu
mov eax, 0 ; dotychczas uzyskany wynik


mov ecx,-1
licz_ilosc_znakow:
inc ecx
mov dl, [esi+ecx]
cmp dl, 10 ;sprawdzanie czy naciśnięto enter
jnz licz_ilosc_znakow

mov dl, [esi] ; pobranie pierwszego bajtu
cmp dl, '-' ; sprawdzenie czy ujemna
jnz pocz_konw
mov znak, '-'
dec ecx ; wykluczam '-' z ilości znaków
pocz_konw:
mov dx,0 ; zeruje ponieważ wynik mnożenia może naruszyć dh
mov dl, [esi] ; pobranie kolejnego bajtu
inc esi ; inkrementacja indeksu
cmp dl, 10 ; sprawdzenie czy naciśnięto Enter
je gotowe ; skok do końca podprogramu
; sprawdzenie czy wprowadzony znak jest cyfrą 0, 1, 2 , ..., 9
cmp dl, '0'
jb pocz_konw ; inny znak jest ignorowany
cmp dl, '9'
ja sprawdzaj_dalej
sub dl, '0' ; zamiana kodu ASCII na wartość cyfry
dopisz:
; w dl znajduje się cyfra w base13
push eax ; zapisuję eax, ponieważ tam będzie wynik potęgowania
push ecx ; zapisuję ecx, ponieważ użyję go jako wyznacznik potęgi i będzie się on zmniejszać
dec ecx ; gdy liczb są np dwie to największy wyznacznik równa się 1
mov al, dl ; zapisuję pobrany znak, który będę mnożyć przez potęgę bazy
cmp ecx,0 ; nie mnożę, gdy wyznacnzik równy 0
jz koniec_potegowania
do_potegi:
	mul ebx
	loop do_potegi
koniec_potegowania:
mov dl, al ; wynik mnożenie do dl
pop ecx 
pop eax
add al, dl ; dodaję do eax wynik mnożenia
dec ecx ; zmniejszam wykładnik potęgi dla następnego znaku
jmp pocz_konw ; skok na początek pętli konwersji
; sprawdzenie czy wprowadzony znak jest cyfrą A, B, C
sprawdzaj_dalej:
cmp dl, 'A'
jb pocz_konw ; inny znak jest ignorowany
cmp dl, 'C'
ja sprawdzaj_dalej2
sub dl, 'A' - 10 ; wyznaczenie kodu binarnego
jmp dopisz
; sprawdzenie czy wprowadzony znak jest cyfrą a, b, ..., f
sprawdzaj_dalej2:
cmp dl, 'a'
jb pocz_konw ; inny znak jest ignorowany
cmp dl, 'c'
ja pocz_konw ; inny znak jest ignorowany
sub dl, 'a' - 10
jmp dopisz
gotowe:
cmp znak, '-'
jnz nie_neguj
neg eax
nie_neguj:
; zwolnienie zarezerwowanego obszaru pamięci
add esp, 12
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
ret
wczytaj_EAX_U2_b13 ENDP
_main PROC
call wczytaj_EAX_U2_b13    ; wpisujemy 5
sub eax, 10
call wyswietl_EAX_U2_b13       ; w konsoli wyświetla się -5

mov EAX, 144
call wyswietl_EAX_U2_b13   ; -> w konsoli powinno pojawić się: +b1
mov EAX, -144
call wyswietl_EAX_U2_b13   ; -> w konsoli powinno pojawić się: -b1
push 0
call _ExitProcess@4
_main ENDP
END
