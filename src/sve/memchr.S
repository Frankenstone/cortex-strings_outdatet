/*
 * memchr - find a character in a memory zone
 *
 * Copyright (c) 2018, Linaro Limited
 * All rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the company nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* Assumptions:
 *
 * ARMv8-a, AArch64
 * SVE Available.
 */

	.arch	armv8-a+sve
	.text

	.globl	memchr
	.type	memchr, %function
	.p2align 4
memchr:
	dup	z1.b, w1			/* duplicate c to a vector */
	setffr					/* initialize FFR */
	mov	x3, 0				/* initialize off */
	nop

0:	whilelo	p1.b, x3, x2			/* make sure off < max */
	b.none	9f

	/* Read a vector's worth of bytes, bounded by max,
	   stopping on first fault.  */
	ldff1b	z0.b, p1/z, [x0, x3]
	rdffrs	p0.b, p1/z
	b.nlast	2f

	/* First fault did not fail: the vector bounded by max is valid.
	   Avoid depending on the contents of FFR beyond the branch.  */
	incb	x3				/* speculate increment */
	cmpeq	p2.b, p1/z, z0.b, z1.b		/* search for c */
	b.none	0b
	decb	x3				/* undo speculate */

	/* Found C.  */
1:	brkb	p2.b, p1/z, p2.b	/* find the first c */
	add	x0, x0, x3		/* form partial pointer */
	incp	x0, p2.b		/* form final pointer to c */
	ret

	/* First fault failed: only some of the vector is valid.
	   Perform the comparision only on the valid bytes.  */
2:	cmpeq	p2.b, p0/z, z0.b, z1.b
	b.any	1b

	/* No C found.  Re-init FFR, increment, and loop.  */
	setffr
	incp	x3, p0.b
	b	0b

	/* Found end of count.  */
9:	mov	x0, 0			/* return null */
	ret

	.size	memchr, . - memchr
