/*
 * strlen - compute the length of a string
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

	.globl	strlen
	.type	strlen, %function
	.p2align 4
strlen:
	setffr			/* initialize FFR */
	ptrue	p2.b		/* all ones; loop invariant */
	mov	x1, 0		/* initialize length */
	nop

	/* Read a vector's worth of bytes, stopping on first fault.  */
0:	ldff1b	z0.b, p2/z, [x0, x1]
	nop
	rdffrs	p0.b, p2/z
	b.nlast	2f

	/* First fault did not fail: the whole vector is valid.
	   Avoid depending on the contents of FFR beyond the branch.  */
	incb	x1, all			/* speculate increment */
	cmpeq	p1.b, p2/z, z0.b, 0	/* loop if no zeros */
	b.none	0b
	decb	x1, all			/* undo speculate */

	/* Zero found.  Select the bytes before the first and count them.  */
1:	brkb	p0.b, p2/z, p1.b
	incp	x1, p0.b
	mov	x0, x1
	ret

	/* First fault failed: only some of the vector is valid.
	   Perform the comparison only on the valid bytes.  */
2:	cmpeq	p1.b, p0/z, z0.b, 0
	b.any	1b

	/* No zero found.  Re-init FFR, increment, and loop.  */
	setffr
	incp	x1, p0.b
	b	0b

	.size	strlen, . - strlen
