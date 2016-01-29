;
; sctio-ser.s -- disk sector I/O for disk made available by serial interface
;

;***************************************************************

	.export	sctcapser		; determine disk capacity
	.export	sctioser		; do disk I/O

	.import	ser1in
	.import	ser1out
	.import	ser1inchk
	.import	puts

	; constants for communication with disk server
	.set	SYN,0x16		; to initiate the three-way handshake
	.set	ACK,0x06		; acknowledgement for handshake
	.set	RESULT_OK,0x00		; server successfully executed cmd
					; everything else means error

	.set	WAIT_DELAY,800000	; count for delay loop

;***************************************************************

	.code
	.align	4

sctcapser:
	sub	$29,$29,16
	stw	$16,$29,0
	stw	$17,$29,4
	stw	$18,$29,8
	stw	$31,$29,12
	add	$4,$0,trymsg		; say what we are doing
	jal	puts
	add	$18,$0,$0		; capacity == 0 if disk not present
	add	$16,$0,10		; 10 tries to get a connection
handshake1:
	sub	$16,$16,1
	add	$4,$0,SYN
	jal	ser1out			; send SYN
	add	$17,$0,WAIT_DELAY	; wait for ACK
handshake2:
	sub	$17,$17,1
	jal	ser1inchk
	bne	$2,$0,handshake3
	bne	$17,$0,handshake2
	add	$4,$0,timeoutmsg
	jal	puts
	bne	$16,$0,handshake1
	add	$4,$0,frustratedmsg
	jal	puts
	j	sctcapx
handshake3:
	jal	ser1in
	add	$8,$0,ACK
	bne	$2,$8,sctcapx
	; we got an ACK so we return it
	add	$4,$0,ACK
	jal	ser1out

	; ask it for its capacity
	add	$4,$0,'c'
	jal	ser1out			; request
	jal	ser1in			; first byte of response
	bne	$2,$0,sctcapx		; exit if error

	; all is well and the server will give us the capacity
	add	$16,$0,4		; 4 bytes to read
sctcap1:
	sll	$18,$18,8
	jal	ser1in
	or	$18,$18,$2		; most significant byte first
	sub	$16,$16,1
	bne	$16,$0,sctcap1

	; return value is in $18
sctcapx:
	add	$2,$0,$18
	ldw	$16,$29,0
	ldw	$17,$29,4
	ldw	$18,$29,8
	ldw	$31,$29,12
	add	$29,$29,16
	jr	$31

	.data
	.align	4

trymsg:
	.byte	"Trying to connect to disk server..."
	.byte	0x0A, 0

timeoutmsg:
	.byte	"Connection timed out..."
	.byte	0x0A, 0

frustratedmsg:
	.byte	"Unable to establish connection to disk server, giving up"
	.byte	0x0A, 0

	.code
	.align	4

sctioser:
	sub	$29,$29,24
	stw	$16,$29,0
	stw	$17,$29,4
	stw	$18,$29,8
	stw	$19,$29,12
	stw	$20,$29,16
	stw	$31,$29,20
	add	$16,$0,$4		; command
	add	$17,$0,$5		; start at sector
	add	$8,$0,0xc0000000
	or	$18,$8,$6		; memory address (logicalized)
	add	$19,$0,$7		; number of sectors

	; switch over command
	add	$8,$0,'r'
	beq	$8,$16,sctior		; read
	add	$8,$0,'w'
	beq	$8,$16,sctiow		; write
	; unknown command
	add	$2,$0,1			; value != 0 signifies error
	j	sctiox

	; read from disk
sctior:
sctior1:				; loop over number of sectors
	beq	$19,$0,sctiorsuc	; successful return
	sub	$19,$19,1
	; read a sector
	add	$4,$0,'r'
	jal	ser1out
	; send sector number
	add	$20,$0,32		; 4 bytes
sctior2:
	sub	$20,$20,8
	slr	$4,$17,$20
	and	$4,$4,0xff
	jal	ser1out
	bne	$20,$0,sctior2
	add	$17,$17,1
	; get answer
	jal	ser1in
	bne	$2,$0,sctiox		; $2 != 0 so we use it as return code
	; read data
	add	$20,$0,512
sctior3:
	sub	$20,$20,1
	jal	ser1in
	stb	$2,$18,0
	add	$18,$18,1
	bne	$20,$0,sctior3
	j	sctior1
sctiorsuc:
	add	$2,$0,$0
	j	sctiox

	; write to disk
sctiow:
sctiow1:				; loop over number of sectors
	beq	$19,$0,sctiowsuc	; successful return
	sub	$19,$19,1
	; write a sector
	add	$4,$0,'w'
	jal	ser1out
	; send sector number
	add	$20,$0,32		; 4 bytes
sctiow2:
	sub	$20,$20,8
	slr	$4,$17,$20
	and	$4,$4,0xff
	jal	ser1out
	bne	$20,$0,sctiow2
	add	$17,$17,1
	; write data
	add	$20,$0,512
sctiow3:
	sub	$20,$20,1
	ldbu	$4,$18,0
	jal	ser1out
	add	$18,$18,1
	bne	$20,$0,sctiow3
	; get answer
	jal	ser1in
	bne	$2,$0,sctiox
	j	sctiow1
sctiowsuc:
	add	$2,$0,$0
sctiox:
	ldw	$16,$29,0
	ldw	$17,$29,4
	ldw	$18,$29,8
	ldw	$19,$29,12
	ldw	$20,$29,16
	ldw	$31,$29,20
	add	$29,$29,24
	jr	$31
