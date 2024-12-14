; IRQinit.s
;
; IRQ init
        .export         initirq, doneirq   ; needed for set_irq call
        .import         callirq

; IRQ location

; ------------------------------------------------------------------------
.segment        "ONCE"   ; ("ONCE" is after my "STARTUP" segment and before my "CODE" segment)

initirq:
       lda     #<IRQStub   ; get the stub addr
       ldx     #>IRQStub
       sei
       sta     $FFFE   ; save the stub addr in the redirected IRQ adr
       stx     $FFFF
       cli
       rts
; ------------------------------------------------------------------------
.segment        "CODE"

doneirq:
        sei               ; disable IRQ
        rts
; ------------------------------------------------------------------------

IRQStub:
        cld            ; Just to be sure
        jsr     callirq      ; Call the functions
        rti
