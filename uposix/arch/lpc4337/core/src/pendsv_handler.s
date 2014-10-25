/* Copyright 2014, Pablo Ridolfi (UTN-FRBA)
 *
 * This file is part of CIAA Firmware and uPOSIX.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

/** \brief Cortex-M PendSV Interrupt Handler, used for context switch.
 **/

/** \addtogroup uPOSIX uPOSIX
 ** @{ */
/** \addtogroup core1769 Core/LPCXpresso/LPC1769
 *
 * Architecture dependent files (LPCXpresso/LPC1769).
 *
 ** @{ */

/*
 * Initials     Name
 * ---------------------------
 * PR		Pablo Ridolfi
 */

/*
 * modification history (new versions first)
 * -----------------------------------------------------------
 * 20140929 v0.1.1 PR	uPOSIX implementation.
 * 20140608 v0.1.0 PR	Initial version.
 */
	.syntax unified

	.text

	.global PendSV_Handler
	.extern current_context, next_context, arch_check_stack_overflow

/* Pendable Service Call, used for context-switching in all Cortex-M processors */
	.thumb_func
PendSV_Handler:
	/* disable IRQs */
	cpsid f

	/* uso el sp correspondiente, segun si vengo de user o kernel */
	tst lr,4
	ite eq
	mrseq r0,msp
	mrsne r0,psp

	/* FPU context saving, only for ARMv7E-M */
	tst lr,0x10
	it eq
	vstmdbeq r0!,{s16-s31}

	/* Integer context saving */
	stmdb r0!,{r4-r11,lr}

	/* Check if current stack overflowed due to context saving */
	push {lr}
	bl arch_check_stack_overflow
	pop {lr}

	/* restituyo MSP, por si existen irqs anidadas */
	tst lr,4
	it eq
	msreq msp,r0

	/* guardo stack actual si corresponde */
	ldr r1,=current_context
	ldr r1,[r1]
	cmp r1,0
	it ne
	strne r0,[r1]

	/* cargo stack siguiente */
	ldr r1,=next_context
	ldr r1,[r1]
	ldr r0,[r1]

	/* recupero contexto actual */
	ldmia r0!,{r4-r11,lr}

	/* FPU context restoring, only for ARMv7E-M */
	tst lr,0x10
	it eq
	vldmiaeq r0!,{s16-s31}

	/* Me fijo si tengo que volver a modo privilegiado.
	   Actualizo el registro CONTROL */
	mrs r1,control
	tst lr,4
	ittee eq
	/* modo thread -> privilegiado, usar MSP */
	biceq r1,3
	msreq msp,r0
	/* modo thread -> privilegiado, usar PSP */
	orrne r1,2
	msrne psp,r0

	msr control,r1

	/* enable IRQs */
	cpsie f

	bx lr

	.end
/** @} doxygen end group definition */
/** @} doxygen end group definition */
/*==================[end of file]============================================*/
