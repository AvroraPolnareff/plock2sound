/* SPDX-License-Identifier: GPL-2.0-or-later
 * plock2sound: copy one step's parameter locks into a saveable sound.
 * Digitone mk1 / Digitone Keys, OS 1.43.
 *
 * Hook on the TrackSelectionView SoundCopy call. With exactly one step TRIG
 * held (and the stock handler's exactly-one synth TRK gate already passed),
 * bake that step's 79 lock values over a copy of the track sound and push
 * that copy as SoundCopy, ready to save in the SOUND MANAGER. Every other
 * case replays the stock call. The linker places code in .run and
 * scratch/proxy in .bss; the original jsr at 0x4004e676 runs on every path.
 */
        .section .run, "ax"
        .globl plock2sound_copy
        .equ F_ORIG,      0x40032c88
        .equ RESUME,      0x4004e67c
        .equ F_MEMCPY,    0x400fb864
        .equ PATTERN_PTR, 0x4138e214

plock2sound_copy:
        addq.l  #4, %sp
        lea     -56(%sp), %sp
        movem.l %d1-%d7/%a0-%a6, (%sp)

        movea.l 0x7c(%a2), %a4
        move.l  0x15c(%a4), %d5
        move.l  0x158(%a4), %d4
        move.l  %d5, %d1
        or.l    %d4, %d1
        beq     .stock
        tst.l   %d4
        bne     .high
        move.l  %d5, %d6
        subq.l  #1, %d6
        and.l   %d5, %d6
        bne     .stock
        moveq   #0, %d7
        bra     .scan
.high:
        tst.l   %d5
        bne     .stock
        move.l  %d4, %d6
        subq.l  #1, %d6
        and.l   %d4, %d6
        bne     .stock
        move.l  %d4, %d5
        moveq   #32, %d7
.scan:
        btst    #0, %d5
        bne     .step
        lsr.l   #1, %d5
        addq.l  #1, %d7
        bra     .scan

.step:
        move.l  %a3, %d2
        movea.l PATTERN_PTR, %a4
        tst.l   %a4
        beq     .stock
        move.l  %d2, %d0
        mulu.w  #0x3d0, %d0
        add.l   %d7, %d0
        adda.l  %d0, %a4
        tst.b   0x180(%a4)
        bpl     .stock

        movea.l 56(%sp), %a5
        tst.l   %a5
        beq     .stock
        movea.l (%a5), %a0
        move.l  0x28(%a0), %d0
        cmpi.l  #0x40153350, %d0
        bne     .stock
        movea.l 0x10(%a5), %a1
        tst.l   %a1
        beq     .stock
        pea     0x146
        move.l  %a1, %sp@-
        pea     plock2sound_scratch
        jsr     F_MEMCPY
        lea     12(%sp), %sp

        movea.l PATTERN_PTR, %a0
        move.l  %d2, %d0
        mulu.w  #0x284f, %d0
        adda.l  %d0, %a0
        move.l  %d7, %d0
        mulu.w  #0xa0, %d0
        adda.l  %d0, %a0
        adda.l  #0x1e80, %a0
        movea.l #plock2sound_scratch+0x14, %a3
        moveq   #79, %d6
.overlay:
        move.w  (%a0)+, %d0
        cmpi.w  #-1, %d0
        beq     .next
        move.w  %d0, (%a3)
.next:
        addq.l  #2, %a3
        subq.l  #1, %d6
        bne     .overlay

        movea.l #plock2sound_proxy, %a0
        move.l  (%a5), (%a0)
        move.l  #plock2sound_scratch, %d0
        move.l  %d0, 0x10(%a0)
        movem.l (%sp), %d1-%d7/%a0-%a6
        lea     56(%sp), %sp
        move.l  #plock2sound_proxy, (%sp)
        jsr     F_ORIG
        jmp     RESUME

.stock:
        movem.l (%sp), %d1-%d7/%a0-%a6
        lea     56(%sp), %sp
        jsr     F_ORIG
        jmp     RESUME

        .section .bss, "aw", @nobits
        .balign 4
plock2sound_scratch:
        .space 0x146
        .balign 4
plock2sound_proxy:
        .space 0x14
